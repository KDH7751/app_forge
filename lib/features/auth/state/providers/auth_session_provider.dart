// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Auth Session Provider
///
/// 역할:
/// - auth state layer의 provider로 FirebaseAuth session stream을 AuthSession contract로 노출함.
///
/// 경계:
/// - auth는 UI page를 소유하지 않음.
/// - FirebaseUser를 직접 노출하지 않음.
/// - redirect 판단은 app layer가 소유함.
/// - facade/action assembly와 독립된 session 기반 축이다.
/// ===================================================================

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/users_document_datasource.dart';
import '../../data/factories/auth_runtime_factory.dart';
import '../../domain/session/auth_session.dart';
import 'auth_runtime_provider.dart';

/// 서버 계정 invalid 사유.
enum AuthSessionInvalidationReason {
  missingUserDocument,
  blockedUser,
  disabledUser,
  missingAuthProviderUser,
  disabledAuthProviderUser,
}

/// auth session 관찰 중 감지한 invalid 신호.
class AuthSessionInvalidation {
  const AuthSessionInvalidation({required this.uid, required this.reason});

  final String uid;
  final AuthSessionInvalidationReason reason;
}

/// auth session 관찰 경로의 현재 raw observation.
class AuthSessionObservation {
  const AuthSessionObservation({
    required this.authenticated,
    required this.invalidation,
    required this.userReady,
    required this.providerReady,
  });

  final Authenticated? authenticated;
  final AuthSessionInvalidation? invalidation;
  final bool userReady;
  final bool providerReady;
}

typedef AuthProviderInvalidationWatcher =
    Stream<AuthSessionInvalidation?> Function(String uid);

/// login/signup 중 users 문서 복구를 기다리는 auth action 수.
final authSessionRecoveryInFlightCountProvider = StateProvider<int>((ref) {
  return 0;
});

/// auth session stream source provider.
final authSessionStreamProvider = Provider<Stream<Authenticated?>>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);

  return watchAuthSessions(firebaseAuth).asBroadcastStream();
});

/// auth provider 서버 상태 probe 주기 provider.
final authProviderProbeIntervalProvider = Provider<Duration>((ref) {
  return const Duration(seconds: 30);
});

/// auth provider invalidation watcher provider.
final authProviderInvalidationWatcherProvider =
    Provider<AuthProviderInvalidationWatcher>((ref) {
      final firebaseAuth = ref.watch(firebaseAuthProvider);
      final probeInterval = ref.watch(authProviderProbeIntervalProvider);

      return (uid) => _watchAuthProviderInvalidation(
        firebaseAuth: firebaseAuth,
        uid: uid,
        probeInterval: probeInterval,
      );
    });

/// auth session observation stream provider.
final authSessionObservationStreamProvider =
    Provider<Stream<AuthSessionObservation>>((ref) {
      final authSessions = ref.watch(authSessionStreamProvider);
      final usersDataSource = ref.watch(usersDocumentDataSourceProvider);
      final watchAuthProviderInvalidation = ref.watch(
        authProviderInvalidationWatcherProvider,
      );
      final recoveryInFlightCount = ref.watch(
        authSessionRecoveryInFlightCountProvider.notifier,
      );

      return _watchAuthSessionObservation(
        authSessions: authSessions,
        usersDataSource: usersDataSource,
        watchAuthProviderInvalidation: watchAuthProviderInvalidation,
        recoveryInFlightCount: recoveryInFlightCount,
      );
    });

/// 현재 auth session observation provider.
final authSessionObservationProvider = StreamProvider<AuthSessionObservation>((
  ref,
) {
  return ref.watch(authSessionObservationStreamProvider);
});

/// app이 공식적으로 소비하는 auth session public contract provider.
final authSessionProvider = Provider<AuthSession>((ref) {
  return switch (ref.watch(authSessionObservationProvider)) {
    AsyncData<AuthSessionObservation>(value: final observation) =>
      _resolvePublicAuthSession(observation),
    AsyncError<AuthSessionObservation>() => const Pending(),
    _ => const Pending(),
  };
});

Stream<AuthSessionObservation> _watchAuthSessionObservation({
  required Stream<Authenticated?> authSessions,
  required UsersDocumentDataSource usersDataSource,
  required AuthProviderInvalidationWatcher watchAuthProviderInvalidation,
  required StateController<int> recoveryInFlightCount,
}) {
  return Stream<AuthSessionObservation>.multi((controller) {
    StreamSubscription<Authenticated?>? authSubscription;
    StreamSubscription<UserDocumentServerState>? userStateSubscription;
    StreamSubscription<AuthSessionInvalidation?>?
    authProviderInvalidationSubscription;
    Authenticated? currentSession;
    AuthSessionInvalidation? userDocumentInvalidation;
    AuthSessionInvalidation? authProviderInvalidation;
    var userReady = true;
    var providerReady = true;

    void emitObservation() {
      controller.add(
        AuthSessionObservation(
          authenticated: currentSession,
          invalidation: authProviderInvalidation ?? userDocumentInvalidation,
          userReady: userReady,
          providerReady: providerReady,
        ),
      );
    }

    authSubscription = authSessions.listen(
      (session) {
        currentSession = session;
        userDocumentInvalidation = null;
        authProviderInvalidation = null;
        final userDocumentCancellation = userStateSubscription?.cancel();
        final authProviderCancellation = authProviderInvalidationSubscription
            ?.cancel();
        userStateSubscription = null;
        authProviderInvalidationSubscription = null;

        if (userDocumentCancellation != null) {
          unawaited(userDocumentCancellation);
        }

        if (authProviderCancellation != null) {
          unawaited(authProviderCancellation);
        }

        if (session == null) {
          userReady = true;
          providerReady = true;
          emitObservation();
          return;
        }

        userReady = false;
        providerReady = false;
        emitObservation();
        userStateSubscription = usersDataSource
            .watchUserServerState(uid: session.uid)
            .listen((userState) {
              final nextInvalidation = _resolveUserDocumentInvalidation(
                session: session,
                userState: userState,
              );
              final recovering = recoveryInFlightCount.mounted
                  ? recoveryInFlightCount.state > 0
                  : false;

              final shouldHoldForRecovery =
                  recovering &&
                  nextInvalidation?.reason ==
                      AuthSessionInvalidationReason.missingUserDocument;

              userReady = !shouldHoldForRecovery;
              userDocumentInvalidation = shouldHoldForRecovery
                  ? null
                  : nextInvalidation;
              emitObservation();
            });
        authProviderInvalidationSubscription =
            watchAuthProviderInvalidation(session.uid).listen((invalidation) {
              providerReady = true;
              authProviderInvalidation = invalidation;
              emitObservation();
            });
      },
      onError: controller.addError,
      onDone: () async {
        await userStateSubscription?.cancel();
        await authProviderInvalidationSubscription?.cancel();
        await controller.close();
      },
    );

    controller.onCancel = () async {
      await userStateSubscription?.cancel();
      await authProviderInvalidationSubscription?.cancel();
      await authSubscription?.cancel();
    };
  });
}

AuthSessionInvalidation? _resolveUserDocumentInvalidation({
  required Authenticated session,
  required UserDocumentServerState userState,
}) {
  if (!userState.exists) {
    return AuthSessionInvalidation(
      uid: session.uid,
      reason: AuthSessionInvalidationReason.missingUserDocument,
    );
  }

  if (userState.isBlocked) {
    return AuthSessionInvalidation(
      uid: session.uid,
      reason: AuthSessionInvalidationReason.blockedUser,
    );
  }

  if (userState.isDisabled) {
    return AuthSessionInvalidation(
      uid: session.uid,
      reason: AuthSessionInvalidationReason.disabledUser,
    );
  }

  return null;
}

AuthSession _resolvePublicAuthSession(AuthSessionObservation observation) {
  if (observation.authenticated == null) {
    return const Unauthenticated();
  }

  if (!observation.userReady || !observation.providerReady) {
    return const Pending();
  }

  if (observation.invalidation != null) {
    return Invalid(reason: _mapPublicInvalidReason(observation.invalidation!));
  }

  return observation.authenticated!;
}

InvalidReason _mapPublicInvalidReason(AuthSessionInvalidation invalidation) {
  return switch (invalidation.reason) {
    AuthSessionInvalidationReason.missingUserDocument ||
    AuthSessionInvalidationReason.missingAuthProviderUser =>
      InvalidReason.missingAccount,
    AuthSessionInvalidationReason.blockedUser => InvalidReason.blocked,
    AuthSessionInvalidationReason.disabledUser ||
    AuthSessionInvalidationReason.disabledAuthProviderUser =>
      InvalidReason.disabled,
  };
}

Stream<AuthSessionInvalidation?> _watchAuthProviderInvalidation({
  required FirebaseAuth firebaseAuth,
  required String uid,
  required Duration probeInterval,
}) {
  return Stream<AuthSessionInvalidation?>.multi((controller) {
    Timer? probeTimer;

    Future<void> probe() async {
      final user = firebaseAuth.currentUser;

      if (user == null || user.uid != uid) {
        controller.add(null);
        return;
      }

      try {
        await user.reload();
        final refreshedUser = firebaseAuth.currentUser;

        if (refreshedUser == null || refreshedUser.uid != uid) {
          controller.add(
            AuthSessionInvalidation(
              uid: uid,
              reason: AuthSessionInvalidationReason.missingAuthProviderUser,
            ),
          );
          return;
        }

        controller.add(null);
      } on FirebaseAuthException catch (error) {
        switch (error.code) {
          case 'user-not-found':
            controller.add(
              AuthSessionInvalidation(
                uid: uid,
                reason: AuthSessionInvalidationReason.missingAuthProviderUser,
              ),
            );
          case 'user-disabled':
            controller.add(
              AuthSessionInvalidation(
                uid: uid,
                reason: AuthSessionInvalidationReason.disabledAuthProviderUser,
              ),
            );
          default:
            controller.add(null);
        }
      } catch (_) {
        controller.add(null);
      }
    }

    unawaited(probe());
    probeTimer = Timer.periodic(probeInterval, (_) => unawaited(probe()));

    controller.onCancel = () {
      probeTimer?.cancel();
    };
  });
}

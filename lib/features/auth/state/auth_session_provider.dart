// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Auth Session Provider
///
/// 역할:
/// - auth state layer의 provider로 FirebaseAuth session stream을 AuthSession 기준으로 노출함.
///
/// 경계:
/// - auth는 UI page를 소유하지 않음.
/// - FirebaseUser를 직접 노출하지 않음.
/// - redirect 판단은 app layer가 소유함.
/// ===================================================================

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_data_factory.dart';
import '../data/users_document_datasource.dart';
import '../domain/auth_session.dart';
import 'auth_repository_provider.dart';

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
    required this.session,
    required this.invalidation,
    required this.hasResolvedUserDocumentState,
    required this.hasResolvedAuthProviderState,
  });

  final AuthSession? session;
  final AuthSessionInvalidation? invalidation;
  final bool hasResolvedUserDocumentState;
  final bool hasResolvedAuthProviderState;
}

typedef AuthProviderInvalidationWatcher =
    Stream<AuthSessionInvalidation?> Function(String uid);

/// login/signup 중 users 문서 복구를 기다리는 auth action 수.
final authSessionRecoveryInFlightCountProvider = StateProvider<int>((ref) {
  return 0;
});

/// auth session stream source provider.
final authSessionStreamProvider = Provider<Stream<AuthSession?>>((ref) {
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

/// 현재 유효 auth session provider.
final authSessionProvider = Provider<AsyncValue<AuthSession?>>((ref) {
  return switch (ref.watch(authSessionObservationProvider)) {
    AsyncData<AuthSessionObservation>(value: final observation)
        when observation.session != null &&
            (!observation.hasResolvedUserDocumentState ||
                !observation.hasResolvedAuthProviderState) =>
      const AsyncLoading<AuthSession?>(),
    AsyncData<AuthSessionObservation>(value: final observation)
        when observation.invalidation != null =>
      const AsyncData<AuthSession?>(null),
    AsyncData<AuthSessionObservation>(value: final observation) =>
      AsyncData<AuthSession?>(observation.session),
    AsyncError<AuthSessionObservation>(:final error, :final stackTrace) =>
      AsyncError<AuthSession?>(error, stackTrace),
    _ => const AsyncLoading<AuthSession?>(),
  };
});

/// 현재 auth session invalidation signal provider.
final authSessionInvalidationProvider =
    Provider<AsyncValue<AuthSessionInvalidation?>>((ref) {
      return switch (ref.watch(authSessionObservationProvider)) {
        AsyncData<AuthSessionObservation>(value: final observation)
            when observation.session != null &&
                (!observation.hasResolvedUserDocumentState ||
                    !observation.hasResolvedAuthProviderState) =>
          const AsyncLoading<AuthSessionInvalidation?>(),
        AsyncData<AuthSessionObservation>(value: final observation) =>
          AsyncData<AuthSessionInvalidation?>(observation.invalidation),
        AsyncError<AuthSessionObservation>(:final error, :final stackTrace) =>
          AsyncError<AuthSessionInvalidation?>(error, stackTrace),
        _ => const AsyncLoading<AuthSessionInvalidation?>(),
      };
    });

Stream<AuthSessionObservation> _watchAuthSessionObservation({
  required Stream<AuthSession?> authSessions,
  required UsersDocumentDataSource usersDataSource,
  required AuthProviderInvalidationWatcher watchAuthProviderInvalidation,
  required StateController<int> recoveryInFlightCount,
}) {
  return Stream<AuthSessionObservation>.multi((controller) {
    StreamSubscription<AuthSession?>? authSubscription;
    StreamSubscription<UserDocumentServerState>? userStateSubscription;
    StreamSubscription<AuthSessionInvalidation?>?
    authProviderInvalidationSubscription;
    AuthSession? currentSession;
    AuthSessionInvalidation? userDocumentInvalidation;
    AuthSessionInvalidation? authProviderInvalidation;
    var hasResolvedUserDocumentState = true;
    var hasResolvedAuthProviderState = true;

    void emitObservation() {
      controller.add(
        AuthSessionObservation(
          session: currentSession,
          invalidation: authProviderInvalidation ?? userDocumentInvalidation,
          hasResolvedUserDocumentState: hasResolvedUserDocumentState,
          hasResolvedAuthProviderState: hasResolvedAuthProviderState,
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
          hasResolvedUserDocumentState = true;
          hasResolvedAuthProviderState = true;
          emitObservation();
          return;
        }

        hasResolvedUserDocumentState = false;
        hasResolvedAuthProviderState = false;
        emitObservation();
        userStateSubscription = usersDataSource
            .watchUserServerState(uid: session.uid)
            .listen((userState) {
              final nextInvalidation = _resolveUserDocumentInvalidation(
                session: session,
                userState: userState,
              );

              final shouldHoldForRecovery =
                  recoveryInFlightCount.state > 0 &&
                  nextInvalidation?.reason ==
                      AuthSessionInvalidationReason.missingUserDocument;

              hasResolvedUserDocumentState = !shouldHoldForRecovery;
              userDocumentInvalidation = shouldHoldForRecovery
                  ? null
                  : nextInvalidation;
              emitObservation();
            });
        authProviderInvalidationSubscription =
            watchAuthProviderInvalidation(session.uid).listen((invalidation) {
              hasResolvedAuthProviderState = true;
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
  required AuthSession session,
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
            return;
          case 'user-disabled':
            controller.add(
              AuthSessionInvalidation(
                uid: uid,
                reason: AuthSessionInvalidationReason.disabledAuthProviderUser,
              ),
            );
            return;
          default:
            controller.add(null);
            return;
        }
      } catch (_) {
        controller.add(null);
      }
    }

    unawaited(probe());
    probeTimer = Timer.periodic(probeInterval, (_) {
      unawaited(probe());
    });

    controller.onCancel = () {
      probeTimer?.cancel();
    };
  });
}

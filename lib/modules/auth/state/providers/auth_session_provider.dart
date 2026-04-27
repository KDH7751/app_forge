// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Auth Session Provider
///
/// 역할:
/// - 선택된 auth provider set의 raw session 관찰을 public `AuthSession`으로 수렴한다.
///
/// 경계:
/// - redirect 판단은 app layer가 소유하고, 이 파일은 session contract만 결정한다.
/// - facade/action assembly와 입력 기준은 공유할 수 있어도 실행 흐름에는 의존하지 않는다.
/// - invalidation 해석은 여기서 닫고, data layer는 raw fact만 제공한다.
/// ===================================================================

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/users_document_datasource.dart';
import '../../domain/session/auth_session.dart';
import 'auth_assembly_provider.dart';
import 'auth_recovery_provider.dart';
import 'auth_session_models.dart';

/// 선택된 provider set이 제공하는 raw authenticated session stream.
///
/// session contract는 provider set에 따라 달라질 수 있지만,
/// 외부 소비자는 항상 이 provider를 통해 같은 public contract로 수렴한다.
final authSessionStreamProvider = Provider<Stream<Authenticated?>>((ref) {
  return ref.watch(authAssemblyProvider).watchSessions().asBroadcastStream();
});

/// provider set invalidation polling이 사용할 기본 probe 간격.
///
/// 현재는 Firebase watcher가 사용하며, probe 전략이 바뀌면 이 값의 소비처도 함께 확인해야 한다.
final authProviderProbeIntervalProvider = Provider<Duration>((ref) {
  return const Duration(seconds: 30);
});

/// 선택된 provider set이 제공하는 invalidation watcher factory.
///
/// session provider는 구체 runtime을 직접 알지 않고 이 factory를 통해 provider-side invalidation을 구독한다.
final authInvalidationWatcherProvider =
    Provider<AuthProviderInvalidationWatcher>((ref) {
      final assembly = ref.watch(authAssemblyProvider);
      final probeInterval = ref.watch(authProviderProbeIntervalProvider);

      return assembly.createInvalidationWatcher(probeInterval: probeInterval);
    });

/// raw session, user document fact, provider invalidation을 하나의 observation으로 합친다.
///
/// bootstrap의 forced logout wiring은 public session이 아니라 이 observation을 구독한다.
final authObservationStreamProvider = Provider<Stream<AuthSessionObservation>>((
  ref,
) {
  final authSessions = ref.watch(authSessionStreamProvider);
  final watchUserServerState = ref.watch(authUserServerStateWatcherProvider);
  final watchAuthProviderInvalidation = ref.watch(
    authInvalidationWatcherProvider,
  );
  final recoveryInFlightCount = ref.watch(authRecoveryCountProvider.notifier);

  return _watchAuthSessionObservation(
    authSessions: authSessions,
    watchUserServerState: watchUserServerState,
    watchAuthProviderInvalidation: watchAuthProviderInvalidation,
    recoveryInFlightCount: recoveryInFlightCount,
  );
});

/// Selected provider set account-state watcher.
final authUserServerStateWatcherProvider =
    Provider<Stream<UserDocumentServerState> Function(String uid)>((ref) {
      final assembly = ref.watch(authAssemblyProvider);

      return (uid) => assembly.watchUserServerState(uid: uid);
    });

/// bootstrap과 테스트가 내부 관찰 상태를 읽을 때 사용하는 provider.
final authObservationProvider = StreamProvider<AuthSessionObservation>((ref) {
  return ref.watch(authObservationStreamProvider);
});

/// app redirect와 root runtime이 소비하는 최종 auth session public contract.
///
/// 외부는 이 provider만 보면 되고, recovery/userReady/providerReady 같은 내부 상태는 노출하지 않는다.
final authSessionProvider = Provider<AuthSession>((ref) {
  return switch (ref.watch(authObservationProvider)) {
    AsyncData<AuthSessionObservation>(value: final observation) =>
      _resolvePublicAuthSession(observation),
    AsyncError<AuthSessionObservation>() => const Pending(),
    _ => const Pending(),
  };
});

Stream<AuthSessionObservation> _watchAuthSessionObservation({
  required Stream<Authenticated?> authSessions,
  required Stream<UserDocumentServerState> Function(String uid)
  watchUserServerState,
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

    // user document와 provider invalidation을 합쳐 단일 observation으로 내보낸다.
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
        userStateSubscription = watchUserServerState(session.uid).listen((
          userState,
        ) {
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

/// users/{uid} raw fact를 session invalidation 신호로 바꾼다.
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

/// 내부 observation을 외부 public session contract로 축약한다.
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

/// 내부 invalidation reason을 public invalid reason으로 매핑한다.
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

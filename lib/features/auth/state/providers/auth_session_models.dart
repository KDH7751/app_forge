import '../../domain/session/auth_session.dart';

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

/// app이 공식적으로 소비하는 auth session public contract.
sealed class AuthSession {
  const AuthSession();
}

/// 보호 라우트를 허용할 수 있는 유효 세션.
class Authenticated extends AuthSession {
  const Authenticated({required this.uid, required this.email});

  final String uid;
  final String email;

  @override
  bool operator ==(Object other) {
    return other is Authenticated && other.uid == uid && other.email == email;
  }

  @override
  int get hashCode => Object.hash(runtimeType, uid, email);
}

/// 로그인 세션이 없는 상태.
class Unauthenticated extends AuthSession {
  const Unauthenticated();

  @override
  bool operator ==(Object other) => other is Unauthenticated;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// public invalid reason contract.
enum InvalidReason { missingAccount, blocked, disabled }

/// 세션 흔적은 있지만 정상 세션으로 볼 수 없는 상태.
class Invalid extends AuthSession {
  const Invalid({required this.reason});

  final InvalidReason reason;

  @override
  bool operator ==(Object other) {
    return other is Invalid && other.reason == reason;
  }

  @override
  int get hashCode => Object.hash(runtimeType, reason);
}

/// 최종 판정이 아직 닫히지 않은 합법적 과도 상태.
class Pending extends AuthSession {
  const Pending();

  @override
  bool operator ==(Object other) => other is Pending;

  @override
  int get hashCode => runtimeType.hashCode;
}

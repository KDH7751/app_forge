import 'auth_session.dart';
import 'result.dart';

/// auth 기능 계약.
abstract interface class AuthRepository {
  /// 이메일/비밀번호 login 수행.
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  });

  /// 현재 세션 logout 수행.
  Future<Result<void>> logout();

  /// 현재 auth session 조회.
  AuthSession? currentSession();

  /// auth session 변경 스트림.
  Stream<AuthSession?> watchSession();
}

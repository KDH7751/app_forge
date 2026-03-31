import 'result.dart';

/// auth 기능 계약.
abstract interface class AuthRepository {
  /// 이메일/비밀번호 login 수행.
  Future<Result<void>> login({required String email, required String password});

  /// 이메일/비밀번호 signup 수행.
  Future<Result<void>> signup({
    required String email,
    required String password,
  });

  /// 현재 세션 logout 수행.
  Future<Result<void>> logout();

  /// 비밀번호 재설정 이메일 발송.
  Future<Result<void>> sendPasswordResetEmail({required String email});

  /// login submit validation.
  Result<void> validateLogin({required String email, required String password});

  /// signup submit validation.
  Result<void> validateSignup({
    required String email,
    required String password,
    required String confirmPassword,
  });

  /// reset submit validation.
  Result<void> validateReset({required String email});
}

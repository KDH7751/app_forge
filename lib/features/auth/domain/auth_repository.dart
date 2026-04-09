import 'change_password_input.dart';
import 'delete_account_input.dart';
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

  /// 인증된 사용자 비밀번호 변경 수행.
  Future<Result<void>> changePassword(ChangePasswordInput input);

  /// 인증된 사용자 계정 삭제 수행.
  Future<Result<void>> deleteAccount(DeleteAccountInput input);

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

  /// change password submit validation.
  Result<void> validateChangePassword(ChangePasswordInput input);

  /// delete account submit validation.
  Result<void> validateDeleteAccount(DeleteAccountInput input);
}

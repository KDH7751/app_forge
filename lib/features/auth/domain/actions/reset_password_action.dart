import '../core/result.dart';

/// reset password 기능 실행 계약.
abstract interface class ResetPasswordAction {
  /// 비밀번호 재설정 이메일 발송.
  Future<Result<void>> execute({required String email});
}

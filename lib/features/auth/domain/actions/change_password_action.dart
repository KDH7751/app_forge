import '../core/result.dart';
import '../models/change_password_input.dart';

/// change password 기능 실행 계약.
abstract interface class ChangePasswordAction {
  /// 인증된 사용자 비밀번호 변경 수행.
  Future<Result<void>> execute(ChangePasswordInput input);
}

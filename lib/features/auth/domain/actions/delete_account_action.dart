import '../core/result.dart';
import '../models/delete_account_input.dart';

/// delete account 기능 실행 계약.
abstract interface class DeleteAccountAction {
  /// 인증된 사용자 계정 삭제 수행.
  Future<Result<void>> execute(DeleteAccountInput input);
}

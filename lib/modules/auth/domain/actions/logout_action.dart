import '../../../foundation/foundation.dart';

/// logout 기능 실행 계약.
abstract interface class LogoutAction {
  /// 현재 세션 logout 수행.
  Future<Result<void>> execute();
}

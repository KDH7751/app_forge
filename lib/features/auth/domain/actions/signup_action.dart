import '../core/result.dart';

/// signup 기능 실행 계약.
abstract interface class SignupAction {
  /// 이메일/비밀번호 signup 수행.
  Future<Result<void>> execute({
    required String email,
    required String password,
  });
}

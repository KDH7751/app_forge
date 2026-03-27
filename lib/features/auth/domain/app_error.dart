/// auth slice 내부 임시 generic core AppError category.
enum AppErrorCategory { auth, permission, notFound, network, parsing, unknown }

/// auth slice 내부 임시 generic core AppError 모델.
class AppError {
  const AppError({required this.category, required this.message, this.code});

  final AppErrorCategory category;
  final String message;
  final String? code;

  /// 사용자를 찾을 수 없음.
  static const AppError userNotFound = AppError(
    category: AppErrorCategory.auth,
    code: 'user-not-found',
    message: '사용자를 찾을 수 없습니다',
  );

  /// 비밀번호 불일치.
  static const AppError wrongPassword = AppError(
    category: AppErrorCategory.auth,
    code: 'wrong-password',
    message: '비밀번호가 올바르지 않습니다',
  );

  /// 네트워크 문제.
  static const AppError network = AppError(
    category: AppErrorCategory.network,
    code: 'network',
    message: '네트워크 문제로 로그인할 수 없습니다',
  );

  /// 일반 로그인 실패.
  static const AppError loginFailed = AppError(
    category: AppErrorCategory.unknown,
    code: 'login-failed',
    message: '로그인에 실패했습니다. 다시 시도해주세요',
  );
}

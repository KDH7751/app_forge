/// 여러 module과 feature가 함께 사용할 수 있는 최소 에러 타입.
enum AppErrorType {
  userNotFound,
  wrongPassword,
  emailAlreadyInUse,
  weakPassword,
  invalidEmail,
  invalidPassword,
  passwordMismatch,
  currentPasswordRequired,
  newPasswordRequired,
  confirmPasswordRequired,
  samePassword,
  network,
  unknown,
}

/// modules/features가 함께 기대는 얇은 공통 기반 AppError 모델.
class AppError {
  const AppError({required this.type, this.code});

  final AppErrorType type;
  final String? code;

  /// 사용자를 찾을 수 없음.
  static const AppError userNotFound = AppError(
    type: AppErrorType.userNotFound,
    code: 'user-not-found',
  );

  /// 비밀번호 불일치.
  static const AppError wrongPassword = AppError(
    type: AppErrorType.wrongPassword,
    code: 'wrong-password',
  );

  /// 이미 사용 중인 이메일.
  static const AppError emailAlreadyInUse = AppError(
    type: AppErrorType.emailAlreadyInUse,
    code: 'email-already-in-use',
  );

  /// 약한 비밀번호.
  static const AppError weakPassword = AppError(
    type: AppErrorType.weakPassword,
    code: 'weak-password',
  );

  /// 이메일 형식 오류.
  static const AppError invalidEmail = AppError(
    type: AppErrorType.invalidEmail,
    code: 'invalid-email',
  );

  /// 비밀번호 validation 오류.
  static const AppError invalidPassword = AppError(
    type: AppErrorType.invalidPassword,
    code: 'invalid-password',
  );

  /// 비밀번호 확인 불일치.
  static const AppError passwordMismatch = AppError(
    type: AppErrorType.passwordMismatch,
    code: 'password-mismatch',
  );

  /// 현재 비밀번호 미입력.
  static const AppError currentPasswordRequired = AppError(
    type: AppErrorType.currentPasswordRequired,
    code: 'current-password-required',
  );

  /// 새 비밀번호 미입력.
  static const AppError newPasswordRequired = AppError(
    type: AppErrorType.newPasswordRequired,
    code: 'new-password-required',
  );

  /// 새 비밀번호 확인 미입력.
  static const AppError confirmPasswordRequired = AppError(
    type: AppErrorType.confirmPasswordRequired,
    code: 'confirm-password-required',
  );

  /// 현재 비밀번호와 동일한 새 비밀번호.
  static const AppError samePassword = AppError(
    type: AppErrorType.samePassword,
    code: 'same-password',
  );

  /// 네트워크 문제.
  static const AppError network = AppError(
    type: AppErrorType.network,
    code: 'network',
  );

  /// 일반 실패.
  static const AppError unknown = AppError(
    type: AppErrorType.unknown,
    code: 'unknown',
  );
}

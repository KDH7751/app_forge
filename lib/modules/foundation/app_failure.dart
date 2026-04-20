/// 여러 module과 feature가 함께 사용할 수 있는 최소 실패 타입.
enum AppFailureType {
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

/// modules/features가 함께 기대는 얇은 공통 기반 AppFailure 모델.
class AppFailure {
  const AppFailure({required this.type, this.code});

  final AppFailureType type;
  final String? code;

  /// 사용자를 찾을 수 없음.
  static const AppFailure userNotFound = AppFailure(
    type: AppFailureType.userNotFound,
    code: 'user-not-found',
  );

  /// 비밀번호 불일치.
  static const AppFailure wrongPassword = AppFailure(
    type: AppFailureType.wrongPassword,
    code: 'wrong-password',
  );

  /// 이미 사용 중인 이메일.
  static const AppFailure emailAlreadyInUse = AppFailure(
    type: AppFailureType.emailAlreadyInUse,
    code: 'email-already-in-use',
  );

  /// 약한 비밀번호.
  static const AppFailure weakPassword = AppFailure(
    type: AppFailureType.weakPassword,
    code: 'weak-password',
  );

  /// 이메일 형식 오류.
  static const AppFailure invalidEmail = AppFailure(
    type: AppFailureType.invalidEmail,
    code: 'invalid-email',
  );

  /// 비밀번호 validation 오류.
  static const AppFailure invalidPassword = AppFailure(
    type: AppFailureType.invalidPassword,
    code: 'invalid-password',
  );

  /// 비밀번호 확인 불일치.
  static const AppFailure passwordMismatch = AppFailure(
    type: AppFailureType.passwordMismatch,
    code: 'password-mismatch',
  );

  /// 현재 비밀번호 미입력.
  static const AppFailure currentPasswordRequired = AppFailure(
    type: AppFailureType.currentPasswordRequired,
    code: 'current-password-required',
  );

  /// 새 비밀번호 미입력.
  static const AppFailure newPasswordRequired = AppFailure(
    type: AppFailureType.newPasswordRequired,
    code: 'new-password-required',
  );

  /// 새 비밀번호 확인 미입력.
  static const AppFailure confirmPasswordRequired = AppFailure(
    type: AppFailureType.confirmPasswordRequired,
    code: 'confirm-password-required',
  );

  /// 현재 비밀번호와 동일한 새 비밀번호.
  static const AppFailure samePassword = AppFailure(
    type: AppFailureType.samePassword,
    code: 'same-password',
  );

  /// 네트워크 문제.
  static const AppFailure network = AppFailure(
    type: AppFailureType.network,
    code: 'network',
  );

  /// 일반 실패.
  static const AppFailure unknown = AppFailure(
    type: AppFailureType.unknown,
    code: 'unknown',
  );
}

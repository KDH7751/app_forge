import '../../../modules/auth/auth.dart';

/// auth_flow consumer feature가 루트 알림으로 위임할 auth 실패인지 판단한다.
bool shouldReportAuthFlowError(Object? error) {
  if (error is! AppError) {
    return false;
  }

  return switch (error.type) {
    AppErrorType.invalidEmail => false,
    AppErrorType.invalidPassword => false,
    AppErrorType.passwordMismatch => false,
    AppErrorType.currentPasswordRequired => false,
    AppErrorType.newPasswordRequired => false,
    AppErrorType.confirmPasswordRequired => false,
    AppErrorType.samePassword => false,
    _ => true,
  };
}

import '../../auth/domain/app_error.dart';

/// profile UI가 로컬 처리 대신 루트 알림으로 올릴 auth 실패인지 판단한다.
bool shouldReportProfileActionError(Object? error) {
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
    AppErrorType.wrongPassword => false,
    AppErrorType.weakPassword => false,
    _ => true,
  };
}

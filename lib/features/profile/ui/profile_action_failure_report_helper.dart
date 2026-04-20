import '../../../modules/auth/auth.dart';

/// profile UI가 로컬 처리 대신 루트 알림으로 올릴 auth 실패인지 판단한다.
bool shouldReportProfileActionFailure(Object? failure) {
  if (failure is! AppFailure) {
    return false;
  }

  return switch (failure.type) {
    AppFailureType.invalidEmail => false,
    AppFailureType.invalidPassword => false,
    AppFailureType.passwordMismatch => false,
    AppFailureType.currentPasswordRequired => false,
    AppFailureType.newPasswordRequired => false,
    AppFailureType.confirmPasswordRequired => false,
    AppFailureType.samePassword => false,
    AppFailureType.wrongPassword => false,
    AppFailureType.weakPassword => false,
    _ => true,
  };
}

import '../../../modules/auth/auth.dart';

/// auth_flow consumer feature가 루트 알림으로 위임할 auth 실패인지 판단한다.
bool shouldReportAuthFlowFailure(Object? failure) {
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
    _ => true,
  };
}

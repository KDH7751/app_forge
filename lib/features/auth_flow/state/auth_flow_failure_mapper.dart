import '../../../modules/auth/auth.dart';

/// auth_flow consumer feature가 auth AppFailure를 UI 문구로 해석한다.
String mapAuthFlowFailure(AppFailure failure) {
  return switch (failure.type) {
    AppFailureType.userNotFound => '사용자를 찾을 수 없습니다',
    AppFailureType.wrongPassword => '비밀번호가 올바르지 않습니다',
    AppFailureType.emailAlreadyInUse => '이미 사용 중인 이메일입니다',
    AppFailureType.weakPassword => '비밀번호가 너무 약합니다',
    AppFailureType.invalidEmail => '올바른 이메일 형식을 입력해주세요',
    AppFailureType.invalidPassword => '비밀번호는 8자 이상이어야 합니다',
    AppFailureType.passwordMismatch => '비밀번호가 일치하지 않습니다',
    AppFailureType.currentPasswordRequired => '현재 비밀번호를 입력해주세요',
    AppFailureType.newPasswordRequired => '새 비밀번호를 입력해주세요',
    AppFailureType.confirmPasswordRequired => '새 비밀번호 확인을 입력해주세요',
    AppFailureType.samePassword => '현재 비밀번호와 다른 새 비밀번호를 입력해주세요',
    AppFailureType.network => '네트워크 문제로 요청을 처리할 수 없습니다',
    AppFailureType.unknown => '요청을 처리할 수 없습니다. 다시 시도해주세요',
  };
}

/// auth_flow 입력 필드가 쓰는 nullable 실패 문구 매퍼.
String? mapAuthFlowFailureText(Object? failure) {
  if (failure is! AppFailure) {
    return null;
  }

  return mapAuthFlowFailure(failure);
}

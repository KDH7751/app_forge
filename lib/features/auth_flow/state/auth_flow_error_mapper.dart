import '../../../modules/auth/auth.dart';

/// auth_flow consumer feature가 auth AppError를 UI 문구로 해석한다.
String mapAuthFlowError(AppError error) {
  return switch (error.type) {
    AppErrorType.userNotFound => '사용자를 찾을 수 없습니다',
    AppErrorType.wrongPassword => '비밀번호가 올바르지 않습니다',
    AppErrorType.emailAlreadyInUse => '이미 사용 중인 이메일입니다',
    AppErrorType.weakPassword => '비밀번호가 너무 약합니다',
    AppErrorType.invalidEmail => '올바른 이메일 형식을 입력해주세요',
    AppErrorType.invalidPassword => '비밀번호는 8자 이상이어야 합니다',
    AppErrorType.passwordMismatch => '비밀번호가 일치하지 않습니다',
    AppErrorType.currentPasswordRequired => '현재 비밀번호를 입력해주세요',
    AppErrorType.newPasswordRequired => '새 비밀번호를 입력해주세요',
    AppErrorType.confirmPasswordRequired => '새 비밀번호 확인을 입력해주세요',
    AppErrorType.samePassword => '현재 비밀번호와 다른 새 비밀번호를 입력해주세요',
    AppErrorType.network => '네트워크 문제로 요청을 처리할 수 없습니다',
    AppErrorType.unknown => '요청을 처리할 수 없습니다. 다시 시도해주세요',
  };
}

/// auth_flow 입력 필드가 쓰는 nullable 에러 문구 매퍼.
String? mapAuthFlowErrorText(Object? error) {
  if (error is! AppError) {
    return null;
  }

  return mapAuthFlowError(error);
}

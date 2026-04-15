import '../../foundation/foundation.dart';

/// auth UI에서 재사용하는 nullable 에러 문구 매퍼.
String? mapAuthErrorText(Object? error) {
  if (error is! AppError) {
    return null;
  }

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
    _ => '요청을 처리할 수 없습니다. 다시 시도해주세요',
  };
}

/// logout 전용 에러 문구 매퍼.
String? mapLogoutErrorText(Object? error) {
  if (error is! AppError) {
    return null;
  }

  return switch (error.type) {
    AppErrorType.network => '네트워크 문제로 로그아웃할 수 없습니다',
    _ => '로그아웃에 실패했습니다. 다시 시도해주세요',
  };
}

/// change password 전용 에러 문구 매퍼.
String? mapChangePasswordErrorText(Object? error) {
  return mapAuthErrorText(error);
}

/// delete account 전용 에러 문구 매퍼.
String? mapDeleteAccountErrorText(Object? error) {
  return mapAuthErrorText(error);
}

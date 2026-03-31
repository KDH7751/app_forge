import '../../auth/domain/app_error.dart';

/// auth_entry에서 사용하는 auth 에러 문구 매퍼.
String mapAuthEntryError(AppError error) {
  return switch (error.type) {
    AppErrorType.userNotFound => '사용자를 찾을 수 없습니다',
    AppErrorType.wrongPassword => '비밀번호가 올바르지 않습니다',
    AppErrorType.emailAlreadyInUse => '이미 사용 중인 이메일입니다',
    AppErrorType.weakPassword => '비밀번호가 너무 약합니다',
    AppErrorType.invalidEmail => '올바른 이메일 형식을 입력해주세요',
    AppErrorType.invalidPassword => '비밀번호는 8자 이상이어야 합니다',
    AppErrorType.passwordMismatch => '비밀번호가 일치하지 않습니다',
    AppErrorType.network => '네트워크 문제로 요청을 처리할 수 없습니다',
    AppErrorType.unknown => '요청을 처리할 수 없습니다. 다시 시도해주세요',
  };
}

/// auth_entry에서 사용하는 nullable 에러 문구 매퍼.
String? mapAuthEntryErrorText(Object? error) {
  if (error is! AppError) {
    return null;
  }

  return mapAuthEntryError(error);
}

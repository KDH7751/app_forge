import '../domain/app_error.dart';

/// auth UI에서 재사용하는 nullable 에러 문구 매퍼.
String? mapAuthErrorText(Object? error) {
  if (error is! AppError) {
    return null;
  }

  return switch (error.type) {
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

/// 전역 notify로 올릴 가치가 있는 auth 실패인지 판단한다.
bool shouldReportAuthErrorNotification(Object? error) {
  if (error is! AppError) {
    return false;
  }

  return switch (error.type) {
    AppErrorType.invalidEmail => false,
    AppErrorType.invalidPassword => false,
    AppErrorType.passwordMismatch => false,
    _ => true,
  };
}

/// auth slice 내부 임시 generic core logger port.
abstract interface class AuthLogger {
  /// 일반 정보 로그.
  void info(String message);

  /// 경고 로그.
  void warn(String message);

  /// 에러 로그.
  void error(String message, {Object? error, StackTrace? stackTrace});
}

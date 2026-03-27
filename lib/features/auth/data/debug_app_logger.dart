import 'package:flutter/foundation.dart';

import '../domain/app_logger.dart';

/// debugPrint 기반 최소 logger 구현.
class DebugAppLogger implements AppLogger {
  const DebugAppLogger();

  /// 정보 로그 출력.
  @override
  void info(String message) {
    debugPrint('[INFO] $message');
  }

  /// 경고 로그 출력.
  @override
  void warn(String message) {
    debugPrint('[WARN] $message');
  }

  /// 에러 로그 출력.
  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    debugPrint('[ERROR] $message');

    if (error != null) {
      debugPrint('error: $error');
    }

    if (stackTrace != null) {
      debugPrint('$stackTrace');
    }
  }
}

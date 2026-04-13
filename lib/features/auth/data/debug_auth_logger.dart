import 'package:flutter/foundation.dart';

import '../domain/core/auth_logger.dart';

/// debugPrint 기반 최소 logger 구현.
class DebugAuthLogger implements AuthLogger {
  const DebugAuthLogger();

  @override
  void info(String message) {
    debugPrint('[INFO] $message');
  }

  @override
  void warn(String message) {
    debugPrint('[WARN] $message');
  }

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

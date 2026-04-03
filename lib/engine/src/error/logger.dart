import 'error_models.dart';

/// 외부 로깅 시스템으로 전달하는 최소 logger port.
abstract class Logger {
  void log(ErrorEnvelope error, ErrorSeverity severity);
}

/// 여러 logger에 동일한 envelope를 fan-out한다.
class MultiLogger implements Logger {
  const MultiLogger(this.loggers);

  final List<Logger> loggers;

  @override
  void log(ErrorEnvelope error, ErrorSeverity severity) {
    for (final logger in loggers) {
      logger.log(error, severity);
    }
  }
}

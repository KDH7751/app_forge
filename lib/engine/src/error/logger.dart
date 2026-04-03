import 'error_models.dart';

/// ErrorHub가 로그 출력을 위임할 때 쓰는 logger contract.
abstract class Logger {
  void log(ErrorEnvelope error, ErrorSeverity severity);
}

/// 같은 에러를 여러 logger로 전달할 때 쓰는 조합 logger.
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

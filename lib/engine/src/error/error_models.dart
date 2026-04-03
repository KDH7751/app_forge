/// ErrorHub가 에러 출처를 구분할 때 쓰는 source 값.
enum ErrorSource { ui, async, framework, platform, unknown }

/// policy와 logger가 공통으로 쓰는 에러 severity.
enum ErrorSeverity { info, warning, error, fatal }

/// ErrorPolicy가 반환하는 처리 결정값.
class ErrorDecision {
  const ErrorDecision({
    required this.shouldLog,
    required this.shouldNotify,
    required this.severity,
  });

  final bool shouldLog;
  final bool shouldNotify;
  final ErrorSeverity severity;
}

/// ErrorHub가 정책 판단과 로그 전달에 쓰는 에러 envelope.
class ErrorEnvelope {
  const ErrorEnvelope({
    required this.error,
    required this.source,
    required this.timestamp,
    this.stackTrace,
    this.domainError,
  });

  final Object error;
  final StackTrace? stackTrace;
  final Object? domainError;
  final ErrorSource source;
  final DateTime timestamp;
}

/// UI와 runtime listener가 구독하는 에러 stream 이벤트.
class ErrorEvent {
  const ErrorEvent({required this.envelope, required this.decision});

  final ErrorEnvelope envelope;
  final ErrorDecision decision;
}

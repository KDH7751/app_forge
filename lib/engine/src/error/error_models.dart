/// 에러가 capture된 진입 레이어.
enum ErrorSource { ui, async, framework, platform, unknown }

/// 에러 처리 강도를 나타내는 공통 severity.
enum ErrorSeverity { info, warning, error, fatal }

/// policy가 반환하는 최소 처리 결정값.
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

/// raw error와 capture 메타데이터를 함께 묶는 envelope.
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

/// UI가 소비하는 에러 stream 이벤트.
class ErrorEvent {
  const ErrorEvent({required this.envelope, required this.decision});

  final ErrorEnvelope envelope;
  final ErrorDecision decision;
}

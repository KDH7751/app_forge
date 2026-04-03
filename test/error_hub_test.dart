import 'package:flutter_test/flutter_test.dart';

import 'package:app_forge/engine/engine.dart';

void main() {
  test(
    'domainError failure becomes notify event with default ui source',
    () async {
      final logger = _RecordingLogger();
      final errorHub = ErrorHub(
        policy: const DefaultErrorPolicy(),
        logger: logger,
      );
      addTearDown(errorHub.dispose);

      final eventFuture = errorHub.stream.first;
      final error = StateError('submit failed');

      errorHub.handle(error, domainError: error);

      final event = await eventFuture;

      expect(event.envelope.error, same(error));
      expect(event.envelope.domainError, same(error));
      expect(event.envelope.source, ErrorSource.ui);
      expect(event.decision.shouldLog, isTrue);
      expect(event.decision.shouldNotify, isTrue);
      expect(event.decision.severity, ErrorSeverity.warning);
      expect(logger.logged.single.$1, same(error));
      expect(logger.logged.single.$2, ErrorSeverity.warning);
    },
  );

  test('platform failure becomes fatal log-only event', () async {
    final logger = _RecordingLogger();
    final errorHub = ErrorHub(
      policy: const DefaultErrorPolicy(),
      logger: logger,
    );
    addTearDown(errorHub.dispose);

    final eventFuture = errorHub.stream.first;
    final error = Exception('platform failed');

    errorHub.handle(error, source: ErrorSource.platform);

    final event = await eventFuture;

    expect(event.decision.shouldLog, isTrue);
    expect(event.decision.shouldNotify, isFalse);
    expect(event.decision.severity, ErrorSeverity.fatal);
    expect(logger.logged.single.$1, same(error));
    expect(logger.logged.single.$2, ErrorSeverity.fatal);
  });
}

class _RecordingLogger implements Logger {
  final List<(Object, ErrorSeverity)> logged = <(Object, ErrorSeverity)>[];

  @override
  void log(ErrorEnvelope error, ErrorSeverity severity) {
    logged.add((error.error, severity));
  }
}

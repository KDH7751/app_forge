import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'error_models.dart';
import 'error_policy.dart';
import 'logger.dart';

/// ===================================================================
/// ErrorHub
///
/// 역할:
/// - 앱 전역 에러를 단일 envelope/decision/stream 흐름으로 묶음.
///
/// 경계:
/// - UI 렌더링이나 navigation을 직접 호출하지 않음.
/// - domainError의 구체 타입을 해석하지 않음.
/// ===================================================================
class ErrorHub {
  ErrorHub({required ErrorPolicy policy, required Logger logger})
    : _policy = policy,
      _logger = logger;

  final ErrorPolicy _policy;
  final Logger _logger;
  final StreamController<ErrorEvent> _controller =
      StreamController<ErrorEvent>.broadcast(sync: true);

  Stream<ErrorEvent> get stream => _controller.stream;

  /// raw error를 중앙 처리 흐름으로 전달한다.
  void handle(
    Object error, {
    StackTrace? stackTrace,
    Object? domainError,
    ErrorSource? source,
  }) {
    final envelope = ErrorEnvelope(
      error: error,
      stackTrace: stackTrace,
      domainError: domainError,
      source: source ?? ErrorSource.ui,
      timestamp: DateTime.now(),
    );
    final decision = _policy.decide(envelope);

    if (decision.shouldLog) {
      _logger.log(envelope, decision.severity);
    }

    _controller.add(ErrorEvent(envelope: envelope, decision: decision));
  }

  /// 내부 stream controller를 정리한다.
  Future<void> dispose() {
    return _controller.close();
  }
}

/// 위젯 트리에 공유된 ErrorHub 접근 scope.
class ErrorHubScope extends InheritedWidget {
  const ErrorHubScope({
    super.key,
    required this.errorHub,
    required super.child,
  });

  final ErrorHub errorHub;

  static ErrorHub of(BuildContext context) {
    final scope = maybeOf(context);

    assert(scope != null, 'ErrorHubScope not found in context.');

    return scope!.errorHub;
  }

  static ErrorHubScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ErrorHubScope>();
  }

  @override
  bool updateShouldNotify(ErrorHubScope oldWidget) {
    return errorHub != oldWidget.errorHub;
  }
}

/// UI layer에서 공유 ErrorHub로 server failure를 전달한다.
void reportUiError(
  BuildContext context,
  Object error, {
  StackTrace? stackTrace,
  Object? domainError,
  ErrorSource? source,
}) {
  ErrorHubScope.of(context).handle(
    error,
    stackTrace: stackTrace,
    domainError: domainError,
    source: source,
  );
}

/// Flutter framework 에러 capture 연결.
void installFlutterErrorCapture(ErrorHub errorHub) {
  FlutterError.onError = (details) {
    errorHub.handle(
      details.exception,
      stackTrace: details.stack,
      source: ErrorSource.framework,
    );
  };
}

/// PlatformDispatcher 에러 capture 연결.
void installPlatformErrorCapture(ErrorHub errorHub) {
  PlatformDispatcher.instance.onError = (error, stack) {
    errorHub.handle(error, stackTrace: stack, source: ErrorSource.platform);
    return true;
  };
}

/// runZonedGuarded 기반 async 에러 capture 실행기.
Future<void> runWithErrorCapture(
  ErrorHub errorHub,
  Future<void> Function() body,
) {
  return runZonedGuarded<Future<void>>(body, (error, stack) {
        errorHub.handle(error, stackTrace: stack, source: ErrorSource.async);
      }) ??
      Future<void>.value();
}

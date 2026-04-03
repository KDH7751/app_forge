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
/// - 전역 에러를 단일 envelope / decision / stream 흐름으로 수집하고 전달한다.
///
/// 결정:
/// - raw error가 ErrorEnvelope로 감싸지고, policy와 logger를 거쳐 stream으로 전달되는 순서가 여기서 정해진다.
///
/// 주의:
/// - UI 렌더링이나 navigation을 직접 호출하지 않는다.
/// - domainError의 구체 타입을 해석하지 않는다.
/// - policy와 logger contract만 사용하고 상위 구성에 의존하지 않는다.
/// ===================================================================
class ErrorHub {
  ErrorHub({required ErrorPolicy policy, required Logger logger})
    : _policy = policy,
      _logger = logger;

  final ErrorPolicy _policy;
  final Logger _logger;
  final StreamController<ErrorEvent> _controller =
      StreamController<ErrorEvent>.broadcast(sync: true);

  /// 외부가 구독하는 전역 에러 stream.
  ///
  /// 상위 runtime과 UI listener는 이 stream을 통해
  /// 처리 결정이 포함된 ErrorEvent를 공통으로 받는다.
  Stream<ErrorEvent> get stream => _controller.stream;

  /// raw error를 ErrorEnvelope로 감싼 뒤 전역 처리 흐름으로 보낸다.
  ///
  /// framework / platform / async / UI 진입점의 모든 에러는
  /// 최종적으로 이 메서드를 통해 policy, logger, stream 전파를 거친다.
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

  /// 내부 stream controller를 정리해 더 이상 이벤트를 내보내지 않게 한다.
  Future<void> dispose() {
    return _controller.close();
  }
}

/// 위젯 트리에서 공유 ErrorHub를 노출하는 scope.
class ErrorHubScope extends InheritedWidget {
  const ErrorHubScope({
    super.key,
    required this.errorHub,
    required super.child,
  });

  final ErrorHub errorHub;

  /// 트리에서 공유된 ErrorHub를 반드시 가져온다.
  static ErrorHub of(BuildContext context) {
    final scope = maybeOf(context);

    assert(scope != null, 'ErrorHubScope not found in context.');

    return scope!.errorHub;
  }

  /// 트리에서 공유된 ErrorHub를 선택적으로 조회한다.
  static ErrorHubScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ErrorHubScope>();
  }

  @override
  bool updateShouldNotify(ErrorHubScope oldWidget) {
    return errorHub != oldWidget.errorHub;
  }
}

/// 현재 BuildContext에 연결된 ErrorHub로 에러를 보고한다.
///
/// UI code는 ErrorHub 인스턴스를 직접 들고 다니지 않고
/// 이 진입점을 통해 동일한 전역 처리 흐름으로 합류한다.
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

/// Flutter framework 에러를 ErrorHub.handle로 연결한다.
///
/// FlutterError.onError를 교체해 framework 레이어 예외를
/// 공통 에러 흐름으로 보낼 때 사용한다.
void installFlutterErrorCapture(ErrorHub errorHub) {
  FlutterError.onError = (details) {
    errorHub.handle(
      details.exception,
      stackTrace: details.stack,
      source: ErrorSource.framework,
    );
  };
}

/// PlatformDispatcher 에러를 ErrorHub.handle로 연결한다.
///
/// 플랫폼 경계에서 올라오는 uncaught error를
/// 공통 에러 흐름으로 흘려보낼 때 사용한다.
void installPlatformErrorCapture(ErrorHub errorHub) {
  PlatformDispatcher.instance.onError = (error, stack) {
    errorHub.handle(error, stackTrace: stack, source: ErrorSource.platform);
    return true;
  };
}

/// body를 runZonedGuarded로 실행해 async uncaught error를 수집한다.
///
/// runtime 시작부는 이 함수를 통해 zone 경계를 만들고,
/// 비동기 예외를 ErrorHub로 전달한다.
Future<void> runWithErrorCapture(
  ErrorHub errorHub,
  Future<void> Function() body,
) {
  return runZonedGuarded<Future<void>>(body, (error, stack) {
        errorHub.handle(error, stackTrace: stack, source: ErrorSource.async);
      }) ??
      Future<void>.value();
}

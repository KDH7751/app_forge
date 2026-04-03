import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app_forge/engine/engine.dart';

import '../app/app_config.dart';
import '../app/app_plugins.dart';

/// ===================================================================
/// Bootstrap Runtime
///
/// 역할:
/// - app runtime을 단일 zone과 ErrorHub로 시작한다.
///
/// 흐름:
/// - binding 초기화 → ErrorHub 준비 → error capture 연결 → plugin 초기화 → runApp
///
/// 영향:
/// - 초기화 순서와 capture 설정에 따라 앱 전역 에러 처리와 시작 흐름이 달라진다.
///
/// 주의:
/// - 모든 초기화는 같은 zone 안에서 실행되어야 한다.
/// ===================================================================

/// app을 ErrorHub와 함께 실행한다.
///
/// 이 함수에서 정한 초기화 순서와 capture 범위에 따라
/// app 전역 실행 흐름이 결정된다.
Future<void> runAppWithErrorHandling(
  Widget Function(ErrorHub errorHub) builder,
) async {
  late final ErrorHub errorHub;

  return runZonedGuarded<Future<void>>(
        () async {
          WidgetsFlutterBinding.ensureInitialized();

          errorHub = ErrorHub(policy: appConfig.errorPolicy, logger: appLogger);

          installFlutterErrorCapture(errorHub);
          installPlatformErrorCapture(errorHub);

          await initializeAppPlugins();

          runApp(builder(errorHub));
        },
        (error, stack) {
          errorHub.handle(error, stackTrace: stack, source: ErrorSource.async);
        },
      ) ??
      Future<void>.value();
}

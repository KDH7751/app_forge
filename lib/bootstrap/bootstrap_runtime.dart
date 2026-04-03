import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app_forge/engine/engine.dart';

import '../app/app_config.dart';
import '../app/app_plugins.dart';

/// ===================================================================
/// Bootstrap Runtime
///
/// 역할:
/// - app runtime 시작에 필요한 zone/error/plugin orchestration 담당.
///
/// 경계:
/// - app 설정은 소비만 하고 재정의하지 않음.
/// - Feature 구현이나 UI 정책을 직접 소유하지 않음.
/// ===================================================================

/// app runtime을 단일 zone과 ErrorHub로 시작한다.
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

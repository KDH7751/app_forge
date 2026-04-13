// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// AppPlugins
///
/// 역할:
/// - app에서 사용할 plugin과 logger 구성을 정의한다.
///
/// 영향:
/// - 이 설정에 따라 app 시작 준비 단계와 외부 시스템 연결 방식이 달라진다.
///
/// 주의:
/// - plugin이나 logger를 바꾸면 app 시작과 전역 로그 흐름을 함께 확인해야 한다.
/// ===================================================================

import 'package:app_forge/engine/engine.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

import '../features/auth/state/providers/auth_app_input_provider.dart';

/// app이 auth 전체에 대해 선택한 backend family.
final appAuthBackendFamily = AuthBackendFamily.firebase;

/// app이 실제로 사용할 plugin 등록 목록.
///
/// 이 목록에 따라 app 시작 전에 준비되는
/// 외부 시스템 연결 범위가 달라진다.
final appPlugins = <EnginePlugin>[
  if (appAuthBackendFamily == AuthBackendFamily.firebase)
    const EnginePlugin(name: 'firebase_core', run: _runFirebaseCorePlugin),
];

/// app에서 사용하는 logger 조합.
///
/// 여기서 등록된 logger에 따라
/// 에러 로그가 외부로 전달되는 방식이 달라진다.
final appLogger = MultiLogger(<Logger>[const ConsoleLogger()]);

/// app 시작 전에 plugin 초기화를 실행한다.
///
/// 이 단계가 바뀌면 app 시작 준비 흐름에도
/// 직접 영향이 생긴다.
Future<void> initializeAppPlugins() {
  return runEnginePlugins(appPlugins);
}

/// Firebase Core plugin을 한 번만 초기화한다.
///
/// 이 초기화가 실패하면 Firebase에 의존하는
/// app 시작 흐름도 함께 영향을 받는다.
Future<void> _runFirebaseCorePlugin() async {
  if (Firebase.apps.isNotEmpty) {
    return;
  }

  // 실제 project wiring은 flutterfire configure와 플랫폼 설정이 담당한다.
  await Firebase.initializeApp();
}

/// 개발 중 전역 에러를 확인하는 기본 logger.
///
/// 별도 로깅을 붙이기 전까지
/// app 전역 에러 흐름을 가장 먼저 확인하는 출력 대상이다.
class ConsoleLogger implements Logger {
  const ConsoleLogger();

  @override
  void log(ErrorEnvelope error, ErrorSeverity severity) {
    debugPrint(
      '[${severity.name.toUpperCase()}]'
      '[${error.source.name}] ${error.error}',
    );

    if (error.domainError != null) {
      debugPrint('domainError: ${error.domainError}');
    }

    if (error.stackTrace != null) {
      debugPrint('${error.stackTrace}');
    }
  }
}

// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// AppPlugins
///
/// 역할:
/// - app이 직접 고르는 provider set 입력과 그로부터 파생되는 runtime 준비를 함께 둔다.
///
/// 영향:
/// - 상단 입력 구역을 바꾸면 하단 plugin/runtime 준비 결과가 함께 달라진다.
/// - bootstrap runtime은 이 파일의 파생값을 그대로 소비하므로 app 시작 흐름에 직접 영향이 있다.
///
/// 주의:
/// - 사용자가 직접 수정할 값은 상단 입력 구역만 본다.
/// - 하단 파생 구역은 입력으로부터 계산되는 값이므로, 특별한 이유 없이 직접 수정하지 않는다.
/// ===================================================================

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import '../engine/engine.dart';
import '../modules/auth/auth.dart';

/// -------------------------------------------------------------------
/// User-Editable App Assembly Input
///
/// 이 구역은 app 조립 시 사용자가 직접 선택/설정하는 입력만 둔다.
/// provider set 교체, 최소 config 변경, 영역별 runtime 전략 변경은 여기서 시작한다.
/// bootstrap과 각 feature assembly는 이 값을 입력으로 받고,
/// 파일 하단 파생 구역은 이 값을 바탕으로만 계산된다.
/// -------------------------------------------------------------------

/// auth 영역 assembly가 소비할 provider 선택값.
///
/// bootstrap은 이 값을 auth 입력 provider로 전달하고,
/// 하단 파생 구역은 이 값이 Firebase runtime을 요구하는지 함께 계산한다.
final authProvider = AuthProviderSet.firebaseAuth;

/// 선택된 auth provider set이 동작하는 데 필요한 최소 config.
///
/// 사용자가 직접 auth 조립 입력을 바꾸는 위치는 여기까지이며,
/// action wiring 세부나 endpoint 수준 설정은 이 파일에 두지 않는다.
final authConfig = const FirebaseAuthConfig();

/// domain data 영역은 auth와 분리된 별도 provider 축이다.
///
/// auth가 Firebase가 아니어도 이 축이 Firebase runtime을 요구할 수 있으므로,
/// plugin 준비는 항상 auth와 별개로 이 값을 본다.
enum DomainDataProviderSet { firebaseFirestore }

/// domain data provider set 최소 config.
///
/// domain data 내부 concrete wiring은 이 config 아래에서 닫히며,
/// app은 provider set이 돌기 위한 최소 설정까지만 소유한다.
class FirebaseDomainDataProviderSetConfig {
  const FirebaseDomainDataProviderSetConfig();
}

final dataProvider = DomainDataProviderSet.firebaseFirestore;
final dataConfig = const FirebaseDomainDataProviderSetConfig();

/// file/storage 영역은 auth, domain data와 분리된 별도 provider 축이다.
///
/// 파일 저장 전략을 바꾸면 이 값과 최소 config만 바꾸고,
/// 실제 concrete storage wiring은 각 provider set 내부에 둔다.
enum FileStorageProviderSet { localDevice }

/// file/storage provider set 최소 config.
class LocalFileStorageProviderSetConfig {
  const LocalFileStorageProviderSetConfig();
}

final storageProvider = FileStorageProviderSet.localDevice;
final storageConfig = const LocalFileStorageProviderSetConfig();

/// analytics/crash 영역도 별도 provider 축으로 유지한다.
///
/// 현재는 비활성화지만, 이후 provider set을 추가할 때도
/// runtime 준비 기준은 auth와 합치지 않고 이 축 자체로 판단한다.
enum AnalyticsCrashProviderSet { disabled }

/// analytics/crash provider set 최소 config.
class DisabledAnalyticsCrashProviderSetConfig {
  const DisabledAnalyticsCrashProviderSetConfig();
}

final observabilityProvider = AnalyticsCrashProviderSet.disabled;
final observabilityConfig = const DisabledAnalyticsCrashProviderSetConfig();

/// -------------------------------------------------------------------
/// Derived Runtime Preparation
///
/// 이 구역은 상단 입력을 바탕으로 계산되거나 준비되는 값만 둔다.
/// bootstrap runtime은 이 결과만 직접 소비하므로,
/// 사용자는 먼저 상단 입력을 바꾸고 이 구역은 계산 결과로 읽는 편이 맞다.
/// 여기 값을 직접 바꾸면 상단 입력과 실제 runtime 준비가 어긋날 수 있다.
/// -------------------------------------------------------------------

/// app 전체 provider set 선택을 기준으로 Firebase runtime 필요 여부를 계산한다.
///
/// `appPlugins`와 `_runFirebaseCorePlugin()` 호출 여부가 이 값으로 닫힌다.
/// 새로운 Firebase 계열 provider set을 추가하면 이 계산을 같이 갱신해야
/// bootstrap이 필요한 runtime을 빠뜨리지 않는다.
final needsFirebaseRuntime =
    _authProviderRequiresFirebaseRuntime(authProvider) ||
    _dataProviderRequiresFirebaseRuntime(dataProvider) ||
    _storageProviderRequiresFirebaseRuntime(storageProvider) ||
    _observabilityProviderRequiresFirebaseRuntime(observabilityProvider);

/// bootstrap runtime이 실제로 실행할 plugin 목록.
///
/// `initializeAppPlugins()`는 이 목록만 소비하므로,
/// 여기에 빠진 runtime 준비는 앱 시작 전에 실행되지 않는다.
/// plugin 종류를 직접 늘리기보다 상단 provider set 입력이 어떤 runtime을 요구하는지
/// 먼저 맞는지 확인하는 편이 구조적으로 안전하다.
final appPlugins = <EnginePlugin>[
  if (needsFirebaseRuntime)
    const EnginePlugin(name: 'firebase_core', run: _runFirebaseCorePlugin),
];

/// app 전역 ErrorHub가 사용하는 logger 조합.
///
/// bootstrap은 ErrorHub 생성 시 이 값을 그대로 사용한다.
/// 출력 목적지를 바꾸면 app 전체 에러 관찰 방식이 함께 달라진다.
final appLogger = MultiLogger(<Logger>[const ConsoleLogger()]);

/// app 시작 전에 필요한 runtime 준비를 순서대로 실행한다.
///
/// bootstrap runtime은 이 함수만 호출하므로,
/// plugin orchestration을 바꾸려면 이 경로를 기준으로 확인하면 된다.
Future<void> initializeAppPlugins() {
  return runEnginePlugins(appPlugins);
}

/// Firebase 계열 provider set이 하나라도 있을 때 필요한 공통 runtime 준비.
///
/// auth, domain data, analytics처럼 서로 다른 축이 같은 Firebase runtime을 공유할 수 있다.
/// 따라서 특정 축 전용 초기화가 아니라, app 전체 provider set 조합 기준으로 한 번만 호출된다.
Future<void> _runFirebaseCorePlugin() async {
  if (Firebase.apps.isNotEmpty) {
    return;
  }

  // 실제 project wiring은 flutterfire configure와 플랫폼 설정이 담당한다.
  await Firebase.initializeApp();
}

/// 개발 중 전역 에러 흐름을 확인하는 기본 logger.
///
/// `appLogger`의 기본 구성원이며,
/// 별도 외부 로거를 붙이기 전까지 app root ErrorHub 출력이 여기로 모인다.
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

/// auth provider set이 Firebase 공통 runtime을 요구하는지 계산한다.
///
/// `needsFirebaseRuntime`의 auth 축 판단에만 쓰이며,
/// 새 auth provider set을 추가하면 이 switch가 함께 갱신되어야 한다.
bool _authProviderRequiresFirebaseRuntime(AuthProviderSet provider) {
  return switch (provider) {
    AuthProviderSet.firebaseAuth => true,
  };
}

/// domain data provider set이 Firebase 공통 runtime을 요구하는지 계산한다.
///
/// auth와 별도 축이므로, auth가 Firebase가 아니어도 이 함수 결과에 따라
/// `firebase_core` 준비가 필요할 수 있다.
bool _dataProviderRequiresFirebaseRuntime(DomainDataProviderSet provider) {
  return switch (provider) {
    DomainDataProviderSet.firebaseFirestore => true,
  };
}

/// file/storage provider set이 Firebase 공통 runtime을 요구하는지 계산한다.
///
/// storage 축이 Firebase 기반으로 바뀌면 이 helper를 갱신해
/// 상단 입력과 plugin 준비 기준이 어긋나지 않게 맞춘다.
bool _storageProviderRequiresFirebaseRuntime(FileStorageProviderSet provider) {
  return switch (provider) {
    FileStorageProviderSet.localDevice => false,
  };
}

/// analytics/crash provider set이 Firebase 공통 runtime을 요구하는지 계산한다.
///
/// analytics/crash는 현재 비활성화지만 별도 축으로 유지되므로,
/// 이후 Firebase 계열 set을 추가하면 이 helper도 runtime 준비 기준에 포함된다.
bool _observabilityProviderRequiresFirebaseRuntime(
  AnalyticsCrashProviderSet provider,
) {
  return switch (provider) {
    AnalyticsCrashProviderSet.disabled => false,
  };
}

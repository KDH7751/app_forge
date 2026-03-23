// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Main App Bootstrap
///
/// 역할:
/// - Phase 1 placeholder composition으로 Flutter app을 시작한다
///
/// 책임:
/// - app Plugin 초기화를 수행한다
/// - app config, 등록된 Feature, Engine shell을 연결한다
///
/// 경계:
/// - app composition 세부 사항은 안다
/// - Router policy나 Feature 비즈니스 로직은 구현하지 않는다
///
/// 의존성:
/// - app layer와 public Engine barrel만 참조한다
/// ===================================================================

import 'package:flutter/material.dart';
import 'package:app_forge/engine/engine.dart';
import 'app/app_config.dart';
import 'app/app_features.dart';
import 'app/app_plugins.dart';

/// app을 부트스트랩한다.
///
/// 계약:
/// - UI를 렌더링하기 전에 app level Plugin을 초기화한다
/// - Phase 1에서 정의한 placeholder shell로 시작한다
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeAppPlugins();

  runApp(const MainApp());
}

/// 현재 app composition의 root widget이다.
///
/// 계약:
/// - app이 소유한 config와 Feature 등록 정보만 읽는다
/// - shell 렌더링은 Engine layer에 위임한다
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final initialFeature = findInitialFeature(
      appFeatures,
      appConfig.initialFeatureKey,
    );

    return MaterialApp(
      title: appConfig.appTitle,
      debugShowCheckedModeBanner: appConfig.showDebugBanner,
      theme: appConfig.theme,
      home: EnginePlaceholderShell(
        title: appConfig.appTitle,
        features: appFeatures,
        selectedFeature: initialFeature,
      ),
    );
  }
}

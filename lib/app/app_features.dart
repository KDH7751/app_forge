// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// App Features
///
/// 역할:
/// - 이 app에서 사용할 Feature slice를 등록한다
///
/// 책임:
/// - app이 소유한 Feature composition을 Engine shell에 노출한다
///
/// 경계:
/// - 어떤 Feature가 활성화됐는지는 안다
/// - Engine 내부에서 Router policy를 구현하지는 않는다
///
/// 의존성:
/// - public Engine barrel과 app local Feature page를 참조한다
/// ===================================================================

import 'package:app_forge/engine/engine.dart';
import '../features/home/presentation/home_page.dart';
import '../features/settings/presentation/settings_page.dart';

/// Phase 1에서 app bootstrap이 사용하는 Feature registry이다.
final appFeatures = <EngineFeature>[
  EngineFeature(
    key: 'home',
    path: '/home',
    label: 'Home',
    builder: (_) => const HomePage(),
  ),
  EngineFeature(
    key: 'settings',
    path: '/settings',
    label: 'Settings',
    builder: (_) => const SettingsPage(),
  ),
];

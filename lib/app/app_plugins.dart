// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// App Plugins
///
/// 역할:
/// - 이 app이 Engine에 주입할 concrete Plugin 목록 조립.
///
/// 경계:
/// - bootstrap 정책은 Engine에 둠.
/// - 실제 Plugin 선택은 app이 소유함.
/// ===================================================================

import 'package:app_forge/engine/engine.dart';
import 'package:firebase_core/firebase_core.dart';

/// app 소유 Plugin 등록 목록.
final appPlugins = <EnginePlugin>[
  const EnginePlugin(
    name: 'firebase_core',
    bootstrap: _bootstrapFirebaseCorePlugin,
  ),
];

/// app 등록 Plugin bootstrap의 Engine 위임 진입점.
Future<void> initializeAppPlugins() {
  return bootstrapEnginePlugins(appPlugins);
}

/// Firebase Core bootstrap.
Future<void> _bootstrapFirebaseCorePlugin() async {
  if (Firebase.apps.isNotEmpty) {
    return;
  }

  // 실제 project wiring은 flutterfire configure와 플랫폼 설정이 담당한다.
  await Firebase.initializeApp();
}

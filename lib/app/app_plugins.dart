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

/// app 소유 Plugin 등록 목록.
final appPlugins = <EnginePlugin>[
  const EnginePlugin(
    name: 'placeholder_observe',
    bootstrap: _bootstrapObservePlugin,
  ),
];

/// app 등록 Plugin bootstrap의 Engine 위임 진입점.
Future<void> initializeAppPlugins() {
  return bootstrapEnginePlugins(appPlugins);
}

/// placeholder observe Plugin bootstrap.
Future<void> _bootstrapObservePlugin() async {}

// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// App Plugins
///
/// 역할:
/// - 이 app의 concrete Plugin bootstrap을 조립한다
///
/// 책임:
/// - Engine에 주입되는 app 측 구현 목록 역할을 한다
///
/// 경계:
/// - composition root 입력으로서 app layer에 속한다
/// - Engine policy나 Feature UI는 정의하지 않는다
///
/// 의존성:
/// - public Engine barrel만 참조한다
/// ===================================================================

import 'package:app_forge/engine/engine.dart';

/// app layer가 소유하는 Plugin 목록이다.
final appPlugins = <EnginePlugin>[
  const EnginePlugin(
    name: 'placeholder_observe',
    bootstrap: _bootstrapObservePlugin,
  ),
];

/// app composition root에 등록된 모든 Plugin을 초기화한다.
///
/// 계약:
/// - 등록 순서대로 Plugin bootstrap을 수행한다
/// - bootstrap 흐름은 Engine 추상화에 위임한다
Future<void> initializeAppPlugins() {
  return bootstrapEnginePlugins(appPlugins);
}

Future<void> _bootstrapObservePlugin() async {}

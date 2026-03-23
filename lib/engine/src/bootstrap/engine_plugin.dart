/// ===================================================================
/// Engine Plugin Contracts
///
/// 역할:
/// - Engine이 소유하는 Plugin bootstrap 계약을 정의한다
///
/// 책임:
/// - app이 concrete Plugin 초기화를 제공하되
///   Engine core에는 Plugin 구현 세부 사항을 노출하지 않게 한다
///
/// 경계:
/// - Engine은 bootstrap 흐름만 알고 Plugin 구현 세부 사항은 모른다
/// - app이나 Feature 코드는 import하지 않는다
///
/// 의존성:
/// - Dart async 함수 type만 참조한다
/// ===================================================================
typedef EnginePluginBootstrap = Future<void> Function();

/// app layer에서 주입하는 Plugin bootstrap 작업을 설명한다.
///
/// 계약:
/// - 진단에 사용할 안정적인 Plugin name을 가진다
/// - app layer가 소유한 async bootstrap callback을 제공한다
class EnginePlugin {
  const EnginePlugin({required this.name, required this.bootstrap});

  final String name;
  final EnginePluginBootstrap bootstrap;
}

/// app layer가 제공한 순서대로 Plugin bootstrap을 수행한다.
///
/// 계약:
/// - 각 Plugin을 순차적으로 await한다
/// - 흐름은 Engine이 관리하고 concrete Plugin 동작은 app이 소유한다
Future<void> bootstrapEnginePlugins(Iterable<EnginePlugin> plugins) async {
  for (final plugin in plugins) {
    await plugin.bootstrap();
  }
}

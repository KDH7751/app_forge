// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Engine Plugin Contracts
///
/// 역할:
/// - Engine이 소비하는 Plugin bootstrap 계약 제공.
///
/// 경계:
/// - bootstrap 순서만 Engine이 소유함.
/// - concrete Plugin 초기화는 app이 제공함.
/// ===================================================================
/// app bootstrap callback 시그니처.
typedef EnginePluginBootstrap = Future<void> Function();

/// app 주입용 Plugin bootstrap 계약.
class EnginePlugin {
  const EnginePlugin({required this.name, required this.bootstrap});

  final String name;
  final EnginePluginBootstrap bootstrap;
}

/// app 등록 순서 기준 Plugin bootstrap 수행.
Future<void> bootstrapEnginePlugins(Iterable<EnginePlugin> plugins) async {
  for (final plugin in plugins) {
    await plugin.bootstrap();
  }
}

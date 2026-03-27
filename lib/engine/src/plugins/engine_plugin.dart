// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Engine Plugin Contracts
///
/// 역할:
/// - Engine이 소비하는 plugin 실행 계약 제공.
///
/// 경계:
/// - plugin 실행 순서만 Engine이 소유함.
/// - concrete plugin 초기화는 app이 제공함.
/// ===================================================================
/// app 제공 plugin 실행 callback 시그니처.
typedef EnginePluginRun = Future<void> Function();

/// app 주입용 plugin 실행 계약.
class EnginePlugin {
  const EnginePlugin({required this.name, required this.run});

  final String name;
  final EnginePluginRun run;
}

/// app 등록 순서 기준 plugin 실행.
Future<void> runEnginePlugins(Iterable<EnginePlugin> plugins) async {
  for (final plugin in plugins) {
    await plugin.run();
  }
}

// ignore_for_file: dangling_library_doc_comments

/// runtime 초기화에서 쓰는 plugin 실행 callback 시그니처.
typedef EnginePluginRun = Future<void> Function();

/// engine runtime이 소비하는 plugin 실행 계약.
class EnginePlugin {
  const EnginePlugin({required this.name, required this.run});

  final String name;
  final EnginePluginRun run;
}

/// 등록된 plugin을 runtime 시작 순서대로 실행한다.
Future<void> runEnginePlugins(Iterable<EnginePlugin> plugins) async {
  for (final plugin in plugins) {
    await plugin.run();
  }
}

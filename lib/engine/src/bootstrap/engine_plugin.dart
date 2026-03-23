typedef EnginePluginBootstrap = Future<void> Function();

class EnginePlugin {
  const EnginePlugin({required this.name, required this.bootstrap});

  final String name;
  final EnginePluginBootstrap bootstrap;
}

Future<void> bootstrapEnginePlugins(Iterable<EnginePlugin> plugins) async {
  for (final plugin in plugins) {
    await plugin.bootstrap();
  }
}

import 'package:app_forge/engine/engine.dart';

final appPlugins = <EnginePlugin>[
  const EnginePlugin(
    name: 'placeholder_observe',
    bootstrap: _bootstrapObservePlugin,
  ),
];

Future<void> initializeAppPlugins() {
  return bootstrapEnginePlugins(appPlugins);
}

Future<void> _bootstrapObservePlugin() async {}

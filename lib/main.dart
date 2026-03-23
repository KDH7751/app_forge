import 'package:flutter/material.dart';
import 'package:app_forge/engine/engine.dart';
import 'app/app_config.dart';
import 'app/app_features.dart';
import 'app/app_plugins.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeAppPlugins();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final initialFeature = findInitialFeature(
      appFeatures,
      appConfig.initialFeatureKey,
    );

    return MaterialApp(
      title: appConfig.appTitle,
      debugShowCheckedModeBanner: appConfig.showDebugBanner,
      theme: appConfig.theme,
      home: EnginePlaceholderShell(
        title: appConfig.appTitle,
        features: appFeatures,
        selectedFeature: initialFeature,
      ),
    );
  }
}

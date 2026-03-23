import 'package:app_forge/engine/engine.dart';
import '../features/home/presentation/home_page.dart';
import '../features/settings/presentation/settings_page.dart';

final appFeatures = <EngineFeature>[
  EngineFeature(
    key: 'home',
    path: '/home',
    label: 'Home',
    builder: (_) => const HomePage(),
  ),
  EngineFeature(
    key: 'settings',
    path: '/settings',
    label: 'Settings',
    builder: (_) => const SettingsPage(),
  ),
];

import 'package:flutter/material.dart';

class AppConfig {
  const AppConfig({
    required this.appTitle,
    required this.initialFeatureKey,
    required this.theme,
    this.showDebugBanner = false,
  });

  final String appTitle;
  final String initialFeatureKey;
  final ThemeData theme;
  final bool showDebugBanner;
}

final appConfig = AppConfig(
  appTitle: 'App Forge',
  initialFeatureKey: 'home',
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D3557)),
    useMaterial3: true,
  ),
);

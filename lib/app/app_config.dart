// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// App Config
///
/// 역할:
/// - app composition root가 사용하는 설정 입력 제공.
///
/// 경계:
/// - Engine 내부 구현은 여기서 다루지 않음.
/// - Feature 세부 구현도 여기서 다루지 않음.
/// ===================================================================

import 'package:flutter/material.dart';
import 'package:app_forge/engine/engine.dart';

/// bootstrap 시점 app composition root용 설정 계약.
class AppConfig {
  const AppConfig({
    required this.appTitle,
    required this.initialLocation,
    required this.theme,
    required this.shellConfig,
    this.showDebugBanner = false,
  });

  final String appTitle;
  final String initialLocation;
  final ThemeData theme;
  final EngineShellConfig shellConfig;
  final bool showDebugBanner;
}

/// 현재 app 조립용 기본 설정.
final appConfig = AppConfig(
  appTitle: 'App Forge',
  initialLocation: '/home',
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D3557)),
    useMaterial3: true,
  ),
  shellConfig: const EngineShellConfig(
    drawer: Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'App Forge Menu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);

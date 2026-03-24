// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// App Config
///
/// 역할:
/// - app이 소유하는 설정 값을 정의한다
///
/// 책임:
/// - title, theme, 초기 Feature 선택을 한곳에 모은다
///
/// 경계:
/// - composition input으로서 app layer에 속한다
/// - Feature 내부 구현이나 Engine 내부 구현은 모른다
///
/// 의존성:
/// - Flutter UI type만 참조한다
/// ===================================================================

import 'package:flutter/material.dart';
import 'package:app_forge/engine/engine.dart';

/// app level 설정 계약이다.
///
/// 계약:
/// - app이 소유한 설정만 가진다
/// - bootstrap 시점에 app composition root가 사용한다
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

/// Phase 2 router bootstrap에서 사용하는 기본 app config이다.
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

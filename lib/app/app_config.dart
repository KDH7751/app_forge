// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// AppConfig
///
/// 역할:
/// - app 전역 설정 값을 정의한다.
///
/// 영향:
/// - 이 설정에 따라 app 초기 진입, 공통 UI, 전역 에러 정책이 달라진다.
///
/// 주의:
/// - app 전체 동작에 영향을 주므로 변경 시 관련 화면과 흐름을 함께 확인해야 한다.
/// ===================================================================

import 'package:flutter/material.dart';
import 'package:app_forge/engine/engine.dart';

/// app 전역 설정 계약.
///
/// app 시작, 공통 UI, 전역 정책처럼
/// feature 바깥에서 공유되는 값을 한곳에 모은다.
class AppConfig {
  const AppConfig({
    required this.appTitle,
    required this.initialLocation,
    required this.theme,
    required this.shellConfig,
    required this.errorPolicy,
    this.showDebugBanner = false,
  });

  /// MaterialApp과 OS 레벨 UI에 노출되는 앱 이름.
  final String appTitle;

  /// app 시작 시 진입할 기본 location.
  ///
  /// 이 값을 바꾸면 첫 화면과 초기 접근 흐름이 함께 달라진다.
  final String initialLocation;

  /// shell을 포함한 app 전체 기본 시각 스타일.
  final ThemeData theme;

  /// app 공통 shell UI 설정.
  ///
  /// 이 값을 바꾸면 shell을 쓰는 화면들의 공통 UI가 함께 달라진다.
  final EngineShellConfig shellConfig;

  /// app 전역 에러 처리 정책.
  ///
  /// 이 값을 바꾸면 앱 전체 에러 처리 방식에 영향을 준다.
  final ErrorPolicy errorPolicy;

  /// 개발용 debug banner 노출 여부.
  ///
  /// 이 값을 바꾸면 app 전체 화면의 개발 표시 상태가 함께 달라진다.
  final bool showDebugBanner;
}

/// 현재 앱이 실제 runtime에서 사용하는 기본 설정.
///
/// 여기 값을 바꾸면 app 시작 방식과
/// 전역 기본 동작이 함께 달라진다.
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
  errorPolicy: const DefaultErrorPolicy(),
);

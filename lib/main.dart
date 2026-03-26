// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Main App Bootstrap
///
/// 역할:
/// - app Plugin 초기화와 Router composition bootstrap 담당.
///
/// 경계:
/// - app composition 세부 사항만 조립함.
/// - Router policy나 Feature 비즈니스 로직은 구현하지 않음.
/// ===================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_forge/engine/engine.dart';
import 'app/app_config.dart';
import 'app/app_features.dart';
import 'app/app_plugins.dart';

/// app bootstrap 진입점.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeAppPlugins();

  runApp(const MainApp());
}

/// app composition root widget.
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  /// stateful app root state 생성.
  @override
  State<MainApp> createState() => _MainAppState();
}

/// app Router와 notifier를 소유하는 root state.
class _MainAppState extends State<MainApp> {
  late final NavigationStateNotifier _navigationNotifier;
  late final RouterEngine _routerEngine;
  late final GoRouter _router;

  /// 초기 navigation 상태와 RouterEngine 구성.
  @override
  void initState() {
    super.initState();

    _navigationNotifier = NavigationStateNotifier(
      initialState: resolveNavigationState(
        location: appConfig.initialLocation,
        routes: appRoutes,
      ),
    );
    _routerEngine = RouterEngine(
      routes: appRouteTrees,
      initialLocation: appConfig.initialLocation,
      shellConfig: appConfig.shellConfig,
      navigationNotifier: _navigationNotifier,
    );
    _router = _routerEngine.build();
  }

  /// Router와 notifier 정리.
  @override
  void dispose() {
    _router.dispose();
    _navigationNotifier.dispose();
    super.dispose();
  }

  /// ProviderScope와 MaterialApp.router 조립.
  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: <Override>[
        navigationStateNotifierProvider.overrideWithValue(_navigationNotifier),
      ],
      child: MaterialApp.router(
        title: appConfig.appTitle,
        debugShowCheckedModeBanner: appConfig.showDebugBanner,
        theme: appConfig.theme,
        routerConfig: _router,
      ),
    );
  }
}

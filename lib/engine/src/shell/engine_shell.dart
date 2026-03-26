// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Engine Shell
///
/// 역할:
/// - shell route를 감싸는 공통 Scaffold 제공.
///
/// 경계:
/// - 개별 화면 구현은 알지 않음.
/// - 공통 UI 제어는 route metadata에 한정함.
/// ===================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routing/engine_feature.dart';
import '../routing/route_def.dart';
import '../routing/route_matcher.dart';

/// app 주입용 shell 최소 config.
class EngineShellConfig {
  const EngineShellConfig({this.drawer});

  final Widget? drawer;
}

/// shell config / route metadata 기반 공통 chrome.
class EngineShell extends StatelessWidget {
  const EngineShell({
    super.key,
    required this.shellConfig,
    required this.shellRoutes,
    required this.child,
  });

  final EngineShellConfig shellConfig;
  final List<RouteDef> shellRoutes;
  final Widget child;

  /// 현재 route metadata 기준 shell UI 렌더링.
  @override
  Widget build(BuildContext context) {
    final currentRoute = _resolveCurrentRoute(
      GoRouterState.of(context).uri.toString(),
    );

    return Scaffold(
      appBar: _buildAppBar(currentRoute),
      drawer: _buildDrawer(currentRoute),
      body: child,
      bottomNavigationBar: _buildBottomNavigationBar(
        context: context,
        currentRoute: currentRoute,
      ),
    );
  }

  /// app bar 노출 route용 AppBar 구성.
  PreferredSizeWidget? _buildAppBar(RouteDef? currentRoute) {
    if (currentRoute == null || !currentRoute.showAppBar) {
      return null;
    }

    return AppBar(title: Text(currentRoute.label ?? currentRoute.name));
  }

  /// drawer 노출 route용 drawer 결정.
  Widget? _buildDrawer(RouteDef? currentRoute) {
    if (currentRoute == null || !currentRoute.showDrawer) {
      return null;
    }

    return shellConfig.drawer;
  }

  /// bottom nav 노출 route용 NavigationBar 구성.
  Widget? _buildBottomNavigationBar({
    required BuildContext context,
    required RouteDef? currentRoute,
  }) {
    if (currentRoute == null || !currentRoute.showBottomNav) {
      return null;
    }

    final items = _bottomNavRoutes;
    if (items.isEmpty) {
      return null;
    }

    final currentIndex = _resolveCurrentIndex(currentRoute, items);

    return NavigationBar(
      selectedIndex: currentIndex,
      destinations: items
          .map(
            (route) => NavigationDestination(
              icon: Icon(route.icon!),
              label: route.label!,
            ),
          )
          .toList(),
      onDestinationSelected: (index) {
        context.go(items[index].path);
      },
    );
  }

  /// 현재 route에 대응하는 bottom nav index 계산.
  int _resolveCurrentIndex(RouteDef currentRoute, List<RouteDef> items) {
    final exactIndex = items.indexWhere(
      (route) => route.path == currentRoute.path,
    );
    if (exactIndex >= 0) {
      return exactIndex;
    }

    return 0;
  }

  /// bottom nav 표시 대상 route 목록.
  List<RouteDef> get _bottomNavRoutes {
    return shellRoutes.where(_isBottomNavRoute).toList();
  }

  /// bottom nav destination 자격 여부 확인.
  bool _isBottomNavRoute(RouteDef route) {
    return route.showBottomNav && route.icon != null && route.label != null;
  }

  /// 현재 location 기준 shell 내부 current route 조회.
  RouteDef? _resolveCurrentRoute(String location) {
    final flatRoutes = <RouteDef>[];

    for (final route in shellRoutes) {
      flatRoutes.addAll(flattenRouteTree(route));
    }

    return matchRouteLocation(location, flatRoutes)?.route;
  }
}

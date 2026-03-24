// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Engine Shell
///
/// 역할:
/// - shell route를 위한 최소 Scaffold 컨테이너를 제공한다
///
/// 책임:
/// - 현재 route 정책에 따라 app bar, bottom nav, drawer 노출을 결정한다
/// - shell route 목록을 기반으로 기본 bottom nav를 구성한다
///
/// 경계:
/// - app의 개별 화면 구현이나 비즈니스 로직은 모른다
/// - shell 외형 주입은 최소 config 범위만 허용한다
///
/// 의존성:
/// - Flutter material과 route metadata만 참조한다
/// ===================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routing/engine_feature.dart';
import '../routing/route_def.dart';
import '../routing/route_matcher.dart';

/// app이 shell 외형 일부를 주입하는 최소 config다.
class EngineShellConfig {
  const EngineShellConfig({this.drawer});

  final Widget? drawer;
}

/// Engine이 소유하는 최소 shell scaffold다.
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

  PreferredSizeWidget? _buildAppBar(RouteDef? currentRoute) {
    if (currentRoute == null || !currentRoute.showAppBar) {
      return null;
    }

    return AppBar(title: Text(currentRoute.label ?? currentRoute.name));
  }

  Widget? _buildDrawer(RouteDef? currentRoute) {
    if (currentRoute == null || !currentRoute.showDrawer) {
      return null;
    }

    return shellConfig.drawer;
  }

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

  int _resolveCurrentIndex(RouteDef currentRoute, List<RouteDef> items) {
    final exactIndex = items.indexWhere(
      (route) => route.path == currentRoute.path,
    );
    if (exactIndex >= 0) {
      return exactIndex;
    }

    return 0;
  }

  List<RouteDef> get _bottomNavRoutes {
    return shellRoutes.where(_isBottomNavRoute).toList();
  }

  bool _isBottomNavRoute(RouteDef route) {
    return route.showBottomNav && route.icon != null && route.label != null;
  }

  RouteDef? _resolveCurrentRoute(String location) {
    final flatRoutes = <RouteDef>[];

    for (final route in shellRoutes) {
      flatRoutes.addAll(flattenRouteTree(route));
    }

    return matchRouteLocation(location, flatRoutes)?.route;
  }
}

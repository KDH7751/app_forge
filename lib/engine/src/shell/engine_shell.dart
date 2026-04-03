// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// EngineShell
///
/// 역할:
/// - shell route를 감싸는 공통 Scaffold와 chrome 구성을 제공한다.
///
/// 결정:
/// - 현재 route metadata를 기준으로 app bar, drawer, bottom navigation이 어떻게 표시될지 여기서 정해진다.
///
/// 주의:
/// - 개별 화면 구현이나 도메인 상태는 알지 않는다.
/// - 공통 UI 제어는 route metadata와 shell config 범위에 한정한다.
/// ===================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routing/engine_feature.dart';
import '../routing/route_def.dart';
import '../routing/route_matcher.dart';

/// shell chrome에서 공통으로 참조하는 최소 config.
class EngineShellConfig {
  const EngineShellConfig({this.drawer});

  final Widget? drawer;
}

/// shell config와 route metadata로 공통 chrome을 렌더링한다.
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

  /// 현재 location에 대응하는 route metadata를 찾아 shell UI를 렌더링한다.
  ///
  /// shell 내부 모든 화면은 이 build를 거치며,
  /// 공통 chrome 노출 여부도 이 단계에서 함께 결정된다.
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

  /// 현재 route metadata를 기준으로 AppBar를 만든다.
  PreferredSizeWidget? _buildAppBar(RouteDef? currentRoute) {
    if (currentRoute == null || !currentRoute.showAppBar) {
      return null;
    }

    return AppBar(title: Text(currentRoute.label ?? currentRoute.name));
  }

  /// 현재 route metadata를 기준으로 drawer를 결정한다.
  Widget? _buildDrawer(RouteDef? currentRoute) {
    if (currentRoute == null || !currentRoute.showDrawer) {
      return null;
    }

    return shellConfig.drawer;
  }

  /// bottom nav 대상 route가 있을 때 NavigationBar를 구성한다.
  ///
  /// bottom navigation 표시는 현재 route metadata와
  /// shell route 목록에서 추린 destination 후보를 함께 사용한다.
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

  /// 현재 route에 대응하는 bottom navigation index를 계산한다.
  int _resolveCurrentIndex(RouteDef currentRoute, List<RouteDef> items) {
    final exactIndex = items.indexWhere(
      (route) => route.path == currentRoute.path,
    );
    if (exactIndex >= 0) {
      return exactIndex;
    }

    return 0;
  }

  /// bottom navigation destination으로 표시할 route 목록을 모은다.
  List<RouteDef> get _bottomNavRoutes {
    return shellRoutes.where(_isBottomNavRoute).toList();
  }

  /// bottom navigation destination 자격이 되는 route인지 확인한다.
  bool _isBottomNavRoute(RouteDef route) {
    return route.showBottomNav && route.icon != null && route.label != null;
  }

  /// 현재 location에 대응하는 shell 내부 current route를 찾는다.
  ///
  /// shell chrome은 현재 route metadata를 직접 알아야 하므로,
  /// shell route tree를 평탄화한 뒤 matcher로 현재 route를 찾는다.
  RouteDef? _resolveCurrentRoute(String location) {
    final flatRoutes = <RouteDef>[];

    for (final route in shellRoutes) {
      flatRoutes.addAll(flattenRouteTree(route));
    }

    return matchRouteLocation(location, flatRoutes)?.route;
  }
}

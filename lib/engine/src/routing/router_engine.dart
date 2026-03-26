// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Router Engine
///
/// 역할:
/// - RouteDef tree를 GoRouter로 조립.
/// - Router 변경을 NavigationState sync로 연결.
///
/// 경계:
/// - auth redirect 같은 app policy는 직접 다루지 않음.
/// - app/Feature 구현 세부 사항은 import하지 않음.
/// ===================================================================

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../shell/engine_shell.dart';
import 'engine_feature.dart';
import 'navigation_state.dart';
import 'route_def.dart';
import 'route_matcher.dart';

/// Engine route tree 기반 Router 조립기.
class RouterEngine {
  RouterEngine({
    required this.routes,
    required this.initialLocation,
    required this.shellConfig,
    required this.navigationNotifier,
  });

  final List<RouteDef> routes;

  final String initialLocation;

  final EngineShellConfig shellConfig;

  final NavigationStateNotifier navigationNotifier;

  late final List<RouteDef> _flatRoutes = _flattenRouteTrees(routes);
  GoRouter? _router;

  /// 동일한 입력 기준 재사용되는 GoRouter 인스턴스 생성.
  GoRouter build() {
    return _router ??= _buildRouter();
  }

  /// route tree 기반 GoRouter 실제 조립.
  GoRouter _buildRouter() {
    final shellRouteTrees = routes.where((route) => route.useShell).toList();
    final standaloneRouteTrees = routes
        .where((route) => !route.useShell)
        .toList();
    final rootObserver = _NavigationSyncObserver(
      onRouteChanged: _syncNavigationState,
    );
    final shellObserver = _NavigationSyncObserver(
      onRouteChanged: _syncNavigationState,
    );

    final router = GoRouter(
      initialLocation: initialLocation,
      observers: <NavigatorObserver>[rootObserver],
      routes: <RouteBase>[
        if (shellRouteTrees.isNotEmpty)
          ShellRoute(
            observers: <NavigatorObserver>[shellObserver],
            builder: (context, state, child) {
              return EngineShell(
                shellConfig: shellConfig,
                shellRoutes: shellRouteTrees,
                child: child,
              );
            },
            routes: shellRouteTrees.map(_buildGoRoute).toList(),
          ),
        ...standaloneRouteTrees.map(_buildGoRoute),
      ],
    );
    _router = router;

    return router;
  }

  /// RouteDef를 GoRoute tree로 변환.
  GoRoute _buildGoRoute(RouteDef route, {String? parentPath}) {
    return GoRoute(
      path: _resolveGoRoutePath(route.path, parentPath: parentPath),
      name: route.name,
      builder: route.builder,
      routes: route.children
          .map((child) => _buildGoRoute(child, parentPath: route.path))
          .toList(),
    );
  }

  /// child absolute path를 GoRouter 상대 path로 변환.
  String _resolveGoRoutePath(String routePath, {String? parentPath}) {
    final normalizedPath = normalizeLocationPath(routePath);

    if (parentPath == null) {
      return normalizedPath;
    }

    final normalizedParentPath = normalizeLocationPath(parentPath);
    final childPrefix = '$normalizedParentPath/';

    assert(
      normalizedPath.startsWith(childPrefix),
      'Child route path must extend its parent absolute path.',
    );

    return normalizedPath.substring(childPrefix.length);
  }

  /// Router 상태를 NavigationState로 동기화.
  void _syncNavigationState() {
    final router = _router;
    if (router == null) {
      return;
    }

    final routeInformation = router.routeInformationProvider.value;
    final location = routeInformation.uri.toString();

    try {
      navigationNotifier.updateFromLocation(
        location: location,
        routes: _flatRoutes,
        extra: router.state.extra,
      );
    } on StateError {
      navigationNotifier.updateFromLocation(
        location: location,
        routes: _flatRoutes,
      );
    }
  }
}

/// route tree 컬렉션 flat 목록화.
List<RouteDef> _flattenRouteTrees(Iterable<RouteDef> routes) {
  final flatRoutes = <RouteDef>[];

  for (final route in routes) {
    flatRoutes.addAll(flattenRouteTree(route));
  }

  return flatRoutes;
}

/// Router observer 기반 navigation sync 트리거.
class _NavigationSyncObserver extends NavigatorObserver {
  _NavigationSyncObserver({required this.onRouteChanged});

  final VoidCallback onRouteChanged;

  /// push 시 navigation sync 트리거.
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteChanged();
  }

  /// pop 시 navigation sync 트리거.
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteChanged();
  }

  /// remove 시 navigation sync 트리거.
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteChanged();
  }

  /// replace 시 navigation sync 트리거.
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    onRouteChanged();
  }
}

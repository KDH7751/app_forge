// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Router Engine
///
/// 역할:
/// - Engine route tree를 GoRouter 구조로 변환한다
///
/// 책임:
/// - route tree를 재귀적으로 GoRoute tree로 변환한다
/// - shell route와 standalone route를 분리해 구성한다
/// - Router 변화와 NavigationState 갱신을 한 지점에서 연결한다
///
/// 경계:
/// - redirect와 auth policy는 이번 단계에서 다루지 않는다
/// - app이나 Feature 구현을 직접 import하지 않는다
///
/// 의존성:
/// - GoRouter, navigation state, shell widget 계약만 참조한다
/// ===================================================================

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../shell/engine_shell.dart';
import 'engine_feature.dart';
import 'navigation_state.dart';
import 'route_def.dart';
import 'route_matcher.dart';

/// Engine Router 조립 입력이다.
class RouterEngine {
  RouterEngine({
    required this.routes,
    required this.initialLocation,
    required this.shellConfig,
    required this.navigationNotifier,
  });

  /// Router tree 구성에 사용하는 route tree다.
  final List<RouteDef> routes;

  /// app이 소유한 초기 진입 location이다.
  final String initialLocation;

  /// shell 외형 일부를 app이 주입하는 최소 config다.
  final EngineShellConfig shellConfig;

  /// GoRouter 변화와 동기화할 navigation notifier다.
  final NavigationStateNotifier navigationNotifier;

  late final List<RouteDef> _flatRoutes = _flattenRouteTrees(routes);
  GoRouter? _router;

  /// Engine route tree로부터 GoRouter를 만든다.
  GoRouter build() {
    return _router ??= _buildRouter();
  }

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

List<RouteDef> _flattenRouteTrees(Iterable<RouteDef> routes) {
  final flatRoutes = <RouteDef>[];

  for (final route in routes) {
    flatRoutes.addAll(flattenRouteTree(route));
  }

  return flatRoutes;
}

class _NavigationSyncObserver extends NavigatorObserver {
  _NavigationSyncObserver({required this.onRouteChanged});

  final VoidCallback onRouteChanged;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteChanged();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteChanged();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteChanged();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    onRouteChanged();
  }
}

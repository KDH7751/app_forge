// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// RouterEngine
///
/// 역할:
/// - RouteDef tree를 GoRouter로 조립한다.
/// - Router 변경을 NavigationState 동기화로 연결한다.
///
/// 결정:
/// - shell route와 standalone route가 어떻게 분리되어 GoRouter로 구성되는지가 여기서 정해진다.
/// - Router 변경이 언제 NavigationStateNotifier로 반영되는지도 여기서 정해진다.
///
/// 주의:
/// - redirect 정책 자체는 해석하지 않고 외부 callback만 호출한다.
/// - route contract만 사용하며 화면 구현 세부 사항을 알지 않는다.
/// ===================================================================

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../shell/engine_shell.dart';
import 'engine_feature.dart';
import 'navigation_state.dart';
import 'route_def.dart';
import 'route_matcher.dart';

/// route tree와 sync 의존성을 받아 GoRouter를 조립하는 engine core.
class RouterEngine {
  RouterEngine({
    required this.routes,
    required this.initialLocation,
    required this.shellConfig,
    required this.navigationNotifier,
    this.redirect,
    this.refreshListenable,
  });

  final List<RouteDef> routes;

  final String initialLocation;

  final EngineShellConfig shellConfig;

  final NavigationStateNotifier navigationNotifier;

  final GoRouterRedirect? redirect;

  final Listenable? refreshListenable;

  late final List<RouteDef> _flatRoutes = _flattenRouteTrees(routes);
  GoRouter? _router;

  /// 동일한 입력 기준으로 재사용되는 GoRouter 인스턴스를 돌려준다.
  ///
  /// runtime 조립부는 이 메서드를 호출해 router를 얻고,
  /// 이후 같은 RouterEngine 인스턴스에서는 같은 GoRouter를 재사용한다.
  GoRouter build() {
    return _router ??= _buildRouter();
  }

  /// route tree를 shell / standalone 경로로 나눠 GoRouter를 실제 조립한다.
  ///
  /// build가 최초 호출될 때 실행되며,
  /// observer와 shell route 구조도 이 단계에서 함께 연결된다.
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
      redirect: redirect,
      refreshListenable: refreshListenable,
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

  /// 단일 RouteDef tree를 GoRoute tree로 변환한다.
  ///
  /// shell route와 standalone route 조립 모두
  /// 최종적으로 이 함수를 통해 GoRouter route 구조가 만들어진다.
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

  /// child absolute path를 GoRouter child path 규칙에 맞는 상대 경로로 바꾼다.
  ///
  /// RouteDef는 절대경로를 source of truth로 유지하므로,
  /// GoRoute tree 조립 시에만 parent 기준 상대 path로 변환한다.
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

  /// 현재 GoRouter 상태를 NavigationStateNotifier에 동기화한다.
  ///
  /// navigator observer가 route 변경을 감지할 때 호출되며,
  /// 현재 location과 extra를 navigation 원시 상태로 갱신한다.
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

/// route tree 컬렉션을 matching / sync용 flat 목록으로 평탄화한다.
List<RouteDef> _flattenRouteTrees(Iterable<RouteDef> routes) {
  final flatRoutes = <RouteDef>[];

  for (final route in routes) {
    flatRoutes.addAll(flattenRouteTree(route));
  }

  return flatRoutes;
}

/// navigator 변경 시 navigation sync를 트리거하는 내부 observer.
class _NavigationSyncObserver extends NavigatorObserver {
  _NavigationSyncObserver({required this.onRouteChanged});

  final VoidCallback onRouteChanged;

  /// push 이후 현재 route 상태 동기화를 요청한다.
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteChanged();
  }

  /// pop 이후 현재 route 상태 동기화를 요청한다.
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteChanged();
  }

  /// remove 이후 현재 route 상태 동기화를 요청한다.
  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onRouteChanged();
  }

  /// replace 이후 현재 route 상태 동기화를 요청한다.
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    onRouteChanged();
  }
}

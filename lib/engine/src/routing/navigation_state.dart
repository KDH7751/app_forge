// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Navigation State
///
/// 역할:
/// - Engine Router가 공유할 최소 navigation 원시 상태를 정의한다
///
/// 책임:
/// - 현재 location, route, path/query param, extra만 저장한다
/// - 상태 갱신 주체는 별도 notifier/provider가 맡는다
///
/// 경계:
/// - UI 파생값이나 redirect 사유는 담지 않는다
/// - build 시점 동기화 책임을 가지지 않는다
///
/// 의존성:
/// - Riverpod state 관리와 route matcher만 참조한다
/// ===================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'route_def.dart';
import 'route_matcher.dart';

/// 순수 navigation 상태 모델이다.
///
/// 계약:
/// - 현재 navigation을 설명하는 원시 값만 가진다
/// - bottom nav index 같은 UI 파생값은 보관하지 않는다
class NavigationState {
  const NavigationState({
    required this.location,
    required this.currentRoute,
    this.pathParams = const <String, String>{},
    this.queryParams = const <String, String>{},
    this.extra,
  });

  const NavigationState.initial()
    : location = '/',
      currentRoute = null,
      pathParams = const <String, String>{},
      queryParams = const <String, String>{},
      extra = null;

  final String location;
  final RouteDef? currentRoute;
  final Map<String, String> pathParams;
  final Map<String, String> queryParams;
  final Object? extra;

  NavigationState copyWith({
    String? location,
    RouteDef? currentRoute,
    bool clearCurrentRoute = false,
    Map<String, String>? pathParams,
    Map<String, String>? queryParams,
    Object? extra,
    bool clearExtra = false,
  }) {
    return NavigationState(
      location: location ?? this.location,
      currentRoute: clearCurrentRoute
          ? null
          : (currentRoute ?? this.currentRoute),
      pathParams: pathParams ?? this.pathParams,
      queryParams: queryParams ?? this.queryParams,
      extra: clearExtra ? null : (extra ?? this.extra),
    );
  }
}

/// location과 route 목록으로부터 순수 navigation 상태를 계산한다.
NavigationState resolveNavigationState({
  required String location,
  required Iterable<RouteDef> routes,
  Object? extra,
}) {
  final match = matchRouteLocation(location, routes);
  final uri = Uri.parse(location);

  return NavigationState(
    location: normalizeLocationPath(location),
    currentRoute: match?.route,
    pathParams: match?.pathParams ?? const <String, String>{},
    queryParams: uri.queryParameters,
    extra: extra,
  );
}

/// navigation 상태 갱신 주체다.
///
/// 계약:
/// - Router 변화는 한 지점에서만 state로 반영한다
/// - route matching과 query parsing을 일관되게 처리한다
class NavigationStateNotifier extends ValueNotifier<NavigationState> {
  NavigationStateNotifier({NavigationState? initialState})
    : super(initialState ?? const NavigationState.initial());

  void updateFromLocation({
    required String location,
    required Iterable<RouteDef> routes,
    Object? extra,
  }) {
    final nextState = resolveNavigationState(
      location: location,
      routes: routes,
      extra: extra,
    );

    if (_isSameNavigationState(value, nextState)) {
      return;
    }

    value = nextState;
  }

  void reset() {
    value = const NavigationState.initial();
  }
}

/// app과 Engine이 공유하는 navigation controller provider다.
final navigationStateNotifierProvider = Provider<NavigationStateNotifier>(
  (ref) => throw UnimplementedError(
    'navigationStateNotifierProvider must be overridden by app composition.',
  ),
);

bool _isSameNavigationState(NavigationState current, NavigationState next) {
  return current.location == next.location &&
      identical(current.currentRoute, next.currentRoute) &&
      _mapEquals(current.pathParams, next.pathParams) &&
      _mapEquals(current.queryParams, next.queryParams) &&
      current.extra == next.extra;
}

bool _mapEquals(Map<String, String> left, Map<String, String> right) {
  if (left.length != right.length) {
    return false;
  }

  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) {
      return false;
    }
  }

  return true;
}

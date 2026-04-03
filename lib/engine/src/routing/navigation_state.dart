// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// NavigationState
///
/// 역할:
/// - router가 공유하는 navigation 원시 상태와 sync 진입점을 제공한다.
///
/// 결정:
/// - location, currentRoute, path/query params, extra가 어떤 기준으로 현재 navigation 상태로 계산되는지 여기서 정해진다.
///
/// 주의:
/// - UI 파생값은 이 계층에 두지 않는다.
/// - redirect 정책이나 화면 표시 여부는 이 계층에서 해석하지 않는다.
/// ===================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'route_def.dart';
import 'route_matcher.dart';

/// 현재 router 위치를 나타내는 최소 navigation 원시 상태.
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

  /// 일부 navigation 필드만 바꾼 복사본을 만든다.
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

/// location과 route 목록으로 현재 navigation 원시 상태를 계산한다.
///
/// RouterEngine과 외부 sync 로직은 이 함수를 통해
/// 현재 route, path params, query params, extra를 한 번에 해석한다.
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

/// router 변경을 value 기반 상태로 반영하는 단일 sync 진입점.
class NavigationStateNotifier extends ValueNotifier<NavigationState> {
  NavigationStateNotifier({NavigationState? initialState})
    : super(initialState ?? const NavigationState.initial());

  /// location 기준으로 다음 NavigationState를 계산해 갱신한다.
  ///
  /// RouterEngine의 observer sync가 이 메서드를 호출하며,
  /// 실질적으로 달라진 값이 있을 때만 notifier value를 교체한다.
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

  /// navigation 상태를 초기값으로 되돌린다.
  void reset() {
    value = const NavigationState.initial();
  }
}

/// 외부 구성에서 override해야 하는 navigation notifier provider contract.
final navigationStateNotifierProvider = Provider<NavigationStateNotifier>(
  (ref) => throw UnimplementedError(
    'navigationStateNotifierProvider must be overridden by app composition.',
  ),
);

/// 두 NavigationState가 실질적으로 같은지 비교한다.
bool _isSameNavigationState(NavigationState current, NavigationState next) {
  return current.location == next.location &&
      identical(current.currentRoute, next.currentRoute) &&
      _mapEquals(current.pathParams, next.pathParams) &&
      _mapEquals(current.queryParams, next.queryParams) &&
      current.extra == next.extra;
}

/// String map 동등성을 비교한다.
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

// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Navigation State
///
/// 역할:
/// - RouterEngine이 공유하는 navigation 원시 상태와 sync 진입점 제공.
///
/// 경계:
/// - UI 파생값은 이 계층에 두지 않음.
/// - redirect 정책은 이 계층에서 해석하지 않음.
/// ===================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'route_def.dart';
import 'route_matcher.dart';

/// 현재 navigation 원시 상태.
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

  /// 일부 navigation 값만 바꾼 복사본.
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

/// location / route 목록 기반 navigation 원시 상태 계산.
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

/// Router 변경 반영용 단일 sync 지점.
class NavigationStateNotifier extends ValueNotifier<NavigationState> {
  NavigationStateNotifier({NavigationState? initialState})
    : super(initialState ?? const NavigationState.initial());

  /// location 변경 기준 state 갱신.
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

  /// 초기 navigation 상태로 리셋.
  void reset() {
    value = const NavigationState.initial();
  }
}

/// app composition override 대상 navigation notifier provider.
final navigationStateNotifierProvider = Provider<NavigationStateNotifier>(
  (ref) => throw UnimplementedError(
    'navigationStateNotifierProvider must be overridden by app composition.',
  ),
);

/// 두 NavigationState의 실질적 동일성 비교.
bool _isSameNavigationState(NavigationState current, NavigationState next) {
  return current.location == next.location &&
      identical(current.currentRoute, next.currentRoute) &&
      _mapEquals(current.pathParams, next.pathParams) &&
      _mapEquals(current.queryParams, next.queryParams) &&
      current.extra == next.extra;
}

/// String map 동등성 비교.
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

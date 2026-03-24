// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Route Definition Contracts
///
/// 역할:
/// - Engine Router가 소비하는 최소 route DSL을 정의한다
///
/// 책임:
/// - route path, name, builder와 shell 노출 정책을 담는다
/// - nested route를 children 트리로 표현한다
///
/// 경계:
/// - child path도 모두 절대경로로 유지한다
/// - redirect, analytics, transition 같은 확장 필드는 다루지 않는다
///
/// 의존성:
/// - Flutter widget type과 GoRouter state만 참조한다
/// ===================================================================

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Engine route page를 빌드한다.
typedef RouteDefBuilder =
    Widget Function(BuildContext context, GoRouterState state);

/// Engine이 소유하는 최소 route descriptor다.
///
/// 계약:
/// - path는 절대경로만 허용한다
/// - children은 구조 표현용이며 child path도 절대경로를 쓴다
/// - shell 적용 여부는 useShell로만 결정한다
class RouteDef {
  RouteDef({
    required this.path,
    required this.name,
    required this.builder,
    this.icon,
    this.label,
    this.children = const <RouteDef>[],
    this.showAppBar = true,
    this.showBottomNav = false,
    this.showDrawer = false,
    this.useShell = true,
  }) : assert(_isAbsolutePath(path), 'RouteDef.path must be an absolute path.'),
       assert(
         _childrenUseAbsolutePaths(children),
         'RouteDef.children paths must all be absolute.',
       );

  final String path;
  final String name;
  final RouteDefBuilder builder;
  final IconData? icon;
  final String? label;
  final List<RouteDef> children;
  final bool showAppBar;
  final bool showBottomNav;
  final bool showDrawer;
  final bool useShell;

  bool get hasChildren => children.isNotEmpty;

  RouteDef copyWith({
    String? path,
    String? name,
    RouteDefBuilder? builder,
    IconData? icon,
    String? label,
    List<RouteDef>? children,
    bool? showAppBar,
    bool? showBottomNav,
    bool? showDrawer,
    bool? useShell,
  }) {
    return RouteDef(
      path: path ?? this.path,
      name: name ?? this.name,
      builder: builder ?? this.builder,
      icon: icon ?? this.icon,
      label: label ?? this.label,
      children: children ?? this.children,
      showAppBar: showAppBar ?? this.showAppBar,
      showBottomNav: showBottomNav ?? this.showBottomNav,
      showDrawer: showDrawer ?? this.showDrawer,
      useShell: useShell ?? this.useShell,
    );
  }
}

bool _isAbsolutePath(String path) {
  return path.startsWith('/');
}

bool _childrenUseAbsolutePaths(List<RouteDef> children) {
  for (final child in children) {
    if (!_isAbsolutePath(child.path)) {
      return false;
    }
  }

  return true;
}

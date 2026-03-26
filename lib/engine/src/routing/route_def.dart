// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// RouteDef
///
/// 역할:
/// - Engine Router가 소비하는 최소 route DSL 제공.
///
/// 경계:
/// - child route를 포함해 path는 항상 절대경로를 source of truth로 유지함.
/// - shell 정책은 metadata로만 표현함.
/// ===================================================================

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// RouteDef page builder 시그니처.
typedef RouteDefBuilder =
    Widget Function(BuildContext context, GoRouterState state);

/// shell metadata를 포함한 최소 route descriptor.
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

  /// child route 존재 여부.
  bool get hasChildren => children.isNotEmpty;

  /// 일부 metadata만 바꾼 RouteDef 복사본.
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

/// 절대경로 여부 확인.
bool _isAbsolutePath(String path) {
  return path.startsWith('/');
}

/// child route path의 절대경로 사용 여부 확인.
bool _childrenUseAbsolutePaths(List<RouteDef> children) {
  for (final child in children) {
    if (!_isAbsolutePath(child.path)) {
      return false;
    }
  }

  return true;
}

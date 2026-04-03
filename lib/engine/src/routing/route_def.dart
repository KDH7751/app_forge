// ignore_for_file: dangling_library_doc_comments

/// router_engine이 라우팅을 조립할 때 쓰는 route 정의 구조.

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// RouteDef가 화면 빌더를 보관할 때 쓰는 시그니처.
typedef RouteDefBuilder =
    Widget Function(BuildContext context, GoRouterState state);

/// shell metadata를 포함한 route 입력 모델.
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

  /// child route가 있는지 확인할 때 쓰는 값.
  bool get hasChildren => children.isNotEmpty;

  /// route metadata 일부만 바꿔 새 RouteDef를 만들 때 쓴다.
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

/// route path 검증에 쓰는 절대경로 확인 함수.
bool _isAbsolutePath(String path) {
  return path.startsWith('/');
}

/// child route path 검증에 쓰는 절대경로 확인 함수.
bool _childrenUseAbsolutePaths(List<RouteDef> children) {
  for (final child in children) {
    if (!_isAbsolutePath(child.path)) {
      return false;
    }
  }

  return true;
}

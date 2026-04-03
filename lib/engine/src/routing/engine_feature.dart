// ignore_for_file: dangling_library_doc_comments

/// app이 feature route를 등록할 때 쓰는 route 조립 계약.

import 'route_def.dart';

/// feature 단위 route 묶음을 등록할 때 쓰는 entry.
class EngineFeature {
  const EngineFeature({required this.key, required this.routes});

  final String key;
  final List<RouteDef> routes;
}

/// 등록된 feature에서 top-level route tree만 모은다.
List<RouteDef> collectFeatureRouteTrees(Iterable<EngineFeature> features) {
  return features.expand((feature) => feature.routes).toList(growable: false);
}

/// 등록된 feature route를 matching용 flat 목록으로 모은다.
List<RouteDef> collectFeatureRoutes(Iterable<EngineFeature> features) {
  final routes = <RouteDef>[];

  for (final feature in features) {
    for (final route in feature.routes) {
      routes.addAll(flattenRouteTree(route));
    }
  }

  return routes;
}

/// 단일 RouteDef tree를 flat route 목록으로 펼친다.
List<RouteDef> flattenRouteTree(RouteDef route) {
  final routes = <RouteDef>[route];

  for (final child in route.children) {
    routes.addAll(flattenRouteTree(child));
  }

  return routes;
}

// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Engine Feature Contracts
///
/// 역할:
/// - app 등록용 Feature route 계약 제공.
///
/// 경계:
/// - Engine은 Feature 내부 구현을 알지 않음.
/// - Router 입력으로는 route 계약만 소비함.
/// ===================================================================

import 'route_def.dart';

/// app 등록용 Feature route entry.
class EngineFeature {
  const EngineFeature({required this.key, required this.routes});

  final String key;
  final List<RouteDef> routes;
}

/// top-level Feature route tree 수집.
List<RouteDef> collectFeatureRouteTrees(Iterable<EngineFeature> features) {
  return features.expand((feature) => feature.routes).toList(growable: false);
}

/// app 등록 Feature route flat 목록.
List<RouteDef> collectFeatureRoutes(Iterable<EngineFeature> features) {
  final routes = <RouteDef>[];

  for (final feature in features) {
    for (final route in feature.routes) {
      routes.addAll(flattenRouteTree(route));
    }
  }

  return routes;
}

/// 단일 RouteDef tree 평탄화.
List<RouteDef> flattenRouteTree(RouteDef route) {
  final routes = <RouteDef>[route];

  for (final child in route.children) {
    routes.addAll(flattenRouteTree(child));
  }

  return routes;
}

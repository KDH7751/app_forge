// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Engine Feature Contracts
///
/// 역할:
/// - app이 등록하는 최소 Feature entry 계약을 정의한다
///
/// 책임:
/// - Feature별 route 묶음을 app composition에 노출한다
/// - 여러 Feature route를 Engine Router 입력으로 평탄화한다
///
/// 경계:
/// - Engine은 Feature 내부 구현을 모른 채 route 계약만 소비한다
/// - Feature key 외의 app policy는 담지 않는다
///
/// 의존성:
/// - route DSL만 참조한다
/// ===================================================================

import 'route_def.dart';

/// app이 등록하는 최소 Feature entry다.
///
/// 계약:
/// - Feature는 안정적인 key를 가진다
/// - Feature는 자신이 노출할 route 목록만 Engine에 전달한다
class EngineFeature {
  const EngineFeature({required this.key, required this.routes});

  final String key;
  final List<RouteDef> routes;
}

/// app이 등록한 Feature route tree를 top-level 입력 그대로 수집한다.
List<RouteDef> collectFeatureRouteTrees(Iterable<EngineFeature> features) {
  return features.expand((feature) => feature.routes).toList(growable: false);
}

/// app이 등록한 모든 Feature route를 평탄화한다.
///
/// 계약:
/// - top-level route와 children route를 모두 반환한다
/// - child route path는 이미 절대경로라고 가정한다
List<RouteDef> collectFeatureRoutes(Iterable<EngineFeature> features) {
  final routes = <RouteDef>[];

  for (final feature in features) {
    for (final route in feature.routes) {
      routes.addAll(flattenRouteTree(route));
    }
  }

  return routes;
}

/// Route tree를 평탄화한다.
List<RouteDef> flattenRouteTree(RouteDef route) {
  final routes = <RouteDef>[route];

  for (final child in route.children) {
    routes.addAll(flattenRouteTree(child));
  }

  return routes;
}

// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// RouteMatcher
///
/// 역할:
/// - location을 등록된 RouteDef와 매칭한다.
///
/// 결정:
/// - exact path, param path, path 길이 우선순위를 기준으로 어떤 route가 현재 location에 대응하는지 결정한다.
///
/// 주의:
/// - redirect나 navigation side effect는 다루지 않는다.
/// - query는 matching 기준으로 쓰지 않고 path 정규화에만 사용한다.
/// ===================================================================

import 'route_def.dart';

/// route match 결과 모델.
class RouteMatchResult {
  const RouteMatchResult({required this.route, required this.pathParams});

  final RouteDef route;
  final Map<String, String> pathParams;
}

/// 현재 location에 가장 잘 맞는 RouteDef를 찾는다.
///
/// router sync와 shell current route 판별은 모두 이 함수를 사용한다.
/// 우선순위는 exact path, 더 긴 path, 더 많은 static segment 순서다.
RouteMatchResult? matchRouteLocation(
  String location,
  Iterable<RouteDef> routes,
) {
  final normalizedPath = normalizeLocationPath(location);
  final candidates = <_RouteCandidate>[];

  for (final route in routes) {
    final match = _matchPath(
      routePath: normalizeLocationPath(route.path),
      locationPath: normalizedPath,
    );

    if (match == null) {
      continue;
    }

    candidates.add(
      _RouteCandidate(
        route: route,
        pathParams: match.pathParams,
        isExactPath: match.isExactPath,
        segmentCount: _segmentCount(route.path),
        staticSegmentCount: _staticSegmentCount(route.path),
      ),
    );
  }

  if (candidates.isEmpty) {
    return null;
  }

  candidates.sort(_compareCandidates);
  final best = candidates.first;

  return RouteMatchResult(route: best.route, pathParams: best.pathParams);
}

/// matching 기준으로 location을 정규화한다.
///
/// query를 제거하고 trailing slash를 정리해
/// 동일한 경로가 같은 비교 기준을 갖게 만든다.
String normalizeLocationPath(String location) {
  final uri = Uri.parse(location);
  final rawPath = uri.path.isEmpty ? '/' : uri.path;

  if (rawPath.length > 1 && rawPath.endsWith('/')) {
    return rawPath.substring(0, rawPath.length - 1);
  }

  return rawPath;
}

/// 두 route 후보의 우선순위를 비교한다.
///
/// 더 구체적인 후보가 앞에 오도록 정렬할 때 사용한다.
int _compareCandidates(_RouteCandidate left, _RouteCandidate right) {
  if (left.isExactPath != right.isExactPath) {
    return left.isExactPath ? -1 : 1;
  }

  final segmentCountCompare = right.segmentCount.compareTo(left.segmentCount);
  if (segmentCountCompare != 0) {
    return segmentCountCompare;
  }

  return right.staticSegmentCount.compareTo(left.staticSegmentCount);
}

/// route path와 location path를 segment 단위로 비교한다.
///
/// param segment는 pathParams로 수집하고,
/// 불일치가 발생하면 null을 반환해 후보에서 제외한다.
_PathMatch? _matchPath({
  required String routePath,
  required String locationPath,
}) {
  if (routePath == locationPath) {
    return const _PathMatch(pathParams: <String, String>{}, isExactPath: true);
  }

  final routeSegments = _segmentsOf(routePath);
  final locationSegments = _segmentsOf(locationPath);

  if (routeSegments.length != locationSegments.length) {
    return null;
  }

  final pathParams = <String, String>{};

  for (var index = 0; index < routeSegments.length; index++) {
    final routeSegment = routeSegments[index];
    final locationSegment = locationSegments[index];

    if (_isParamSegment(routeSegment)) {
      pathParams[routeSegment.substring(1)] = locationSegment;
      continue;
    }

    if (routeSegment != locationSegment) {
      return null;
    }
  }

  return _PathMatch(pathParams: pathParams, isExactPath: false);
}

/// path를 비어 있지 않은 segment 목록으로 나눈다.
List<String> _segmentsOf(String path) {
  return path.split('/').where((segment) => segment.isNotEmpty).toList();
}

/// param segment인지 확인한다.
bool _isParamSegment(String segment) {
  return segment.startsWith(':') && segment.length > 1;
}

/// path segment 개수를 계산한다.
int _segmentCount(String path) {
  return _segmentsOf(path).length;
}

/// static segment 개수를 계산한다.
int _staticSegmentCount(String path) {
  return _segmentsOf(path).where((segment) => !_isParamSegment(segment)).length;
}

/// 내부 path match 결과.
class _PathMatch {
  const _PathMatch({required this.pathParams, required this.isExactPath});

  final Map<String, String> pathParams;
  final bool isExactPath;
}

/// route candidate 정렬용 내부 모델.
class _RouteCandidate {
  const _RouteCandidate({
    required this.route,
    required this.pathParams,
    required this.isExactPath,
    required this.segmentCount,
    required this.staticSegmentCount,
  });

  final RouteDef route;
  final Map<String, String> pathParams;
  final bool isExactPath;
  final int segmentCount;
  final int staticSegmentCount;
}

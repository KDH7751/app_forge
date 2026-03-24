// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Route Matcher
///
/// 역할:
/// - location을 등록된 RouteDef와 매칭한다
///
/// 책임:
/// - query를 제외한 path 기준으로 현재 route를 찾는다
/// - path param을 추출한다
///
/// 경계:
/// - matching 기준은 정확 path, param path, 더 긴 path 우선순위만 가진다
/// - redirect나 navigation side effect는 수행하지 않는다
///
/// 의존성:
/// - route DSL만 참조한다
/// ===================================================================

import 'route_def.dart';

/// location과 매칭된 route 결과다.
class RouteMatchResult {
  const RouteMatchResult({required this.route, required this.pathParams});

  final RouteDef route;
  final Map<String, String> pathParams;
}

/// location에 해당하는 RouteDef를 찾는다.
///
/// 우선순위:
/// 1. 정확 path
/// 2. param path
/// 3. 더 긴 path
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

/// location에서 query와 trailing slash를 제거한 path만 반환한다.
String normalizeLocationPath(String location) {
  final uri = Uri.parse(location);
  final rawPath = uri.path.isEmpty ? '/' : uri.path;

  if (rawPath.length > 1 && rawPath.endsWith('/')) {
    return rawPath.substring(0, rawPath.length - 1);
  }

  return rawPath;
}

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

List<String> _segmentsOf(String path) {
  return path.split('/').where((segment) => segment.isNotEmpty).toList();
}

bool _isParamSegment(String segment) {
  return segment.startsWith(':') && segment.length > 1;
}

int _segmentCount(String path) {
  return _segmentsOf(path).length;
}

int _staticSegmentCount(String path) {
  return _segmentsOf(path).where((segment) => !_isParamSegment(segment)).length;
}

class _PathMatch {
  const _PathMatch({required this.pathParams, required this.isExactPath});

  final Map<String, String> pathParams;
  final bool isExactPath;
}

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

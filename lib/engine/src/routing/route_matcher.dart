// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Route Matcher
///
/// 역할:
/// - location을 등록된 RouteDef와 매칭.
///
/// 경계:
/// - redirect나 navigation side effect는 여기서 다루지 않음.
/// - query는 matching 기준이 아니라 path 정규화 대상으로만 사용함.
/// ===================================================================

import 'route_def.dart';

/// route match 결과 모델.
class RouteMatchResult {
  const RouteMatchResult({required this.route, required this.pathParams});

  final RouteDef route;
  final Map<String, String> pathParams;
}

/// 현재 location에 해당하는 RouteDef 검색.
/// 우선순위: 정확 path, param path, 더 긴 path.
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

/// matching 기준 path 정규화.
String normalizeLocationPath(String location) {
  final uri = Uri.parse(location);
  final rawPath = uri.path.isEmpty ? '/' : uri.path;

  if (rawPath.length > 1 && rawPath.endsWith('/')) {
    return rawPath.substring(0, rawPath.length - 1);
  }

  return rawPath;
}

/// match 우선순위 비교.
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

/// route path와 location path의 segment 단위 매칭.
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

/// path segment 목록 추출.
List<String> _segmentsOf(String path) {
  return path.split('/').where((segment) => segment.isNotEmpty).toList();
}

/// param segment 여부 확인.
bool _isParamSegment(String segment) {
  return segment.startsWith(':') && segment.length > 1;
}

/// path segment 개수 계산.
int _segmentCount(String path) {
  return _segmentsOf(path).length;
}

/// static segment 개수 계산.
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

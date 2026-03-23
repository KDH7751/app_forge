// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Engine Feature Contracts
///
/// 역할:
/// - Engine이 소비하는 최소 Feature 등록 계약을 정의한다
///
/// 책임:
/// - app이 Feature 진입점을 등록하되
///   Engine이 Feature 내부 구현을 몰라도 되게 한다
///
/// 경계:
/// - Engine은 등록된 Feature page를 렌더링할 수 있다
/// - auth policy, Repository 로직, Feature state는 모른다
///
/// 의존성:
/// - Flutter widget type만 참조한다
/// ===================================================================

import 'package:flutter/widgets.dart';

/// 등록된 Feature의 root page를 빌드한다.
typedef EngineFeaturePageBuilder = Widget Function(BuildContext context);

/// Engine placeholder shell이 소비하는 최소 Feature descriptor이다.
///
/// 계약:
/// - 안정적인 key와 path로 Feature를 식별한다
/// - Feature 내부 구현을 노출하지 않고 presentation 진입점을 제공한다
class EngineFeature {
  const EngineFeature({
    required this.key,
    required this.path,
    required this.label,
    required this.builder,
  });

  final String key;
  final String path;
  final String label;
  final EngineFeaturePageBuilder builder;
}

/// app이 먼저 렌더링할 Feature를 결정한다.
///
/// 계약:
/// - 설정된 key와 일치하는 Feature를 반환한다
/// - 일치하는 값이 없으면 첫 번째 등록 Feature로 fallback한다
EngineFeature? findInitialFeature(
  Iterable<EngineFeature> features,
  String initialFeatureKey,
) {
  for (final feature in features) {
    if (feature.key == initialFeatureKey) {
      return feature;
    }
  }

  return features.isEmpty ? null : features.first;
}

// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Engine Placeholder Shell
///
/// 역할:
/// - Phase 1 bootstrap을 위한 임시 Engine shell을 제공한다
///
/// 책임:
/// - 선택된 Feature 진입 page를 일관된 scaffold 안에서 렌더링한다
///
/// 경계:
/// - shell 흐름은 Engine이 소유한다
/// - Router policy, auth state, Feature 비즈니스 로직은 모른다
///
/// 의존성:
/// - Engine Feature 계약과 Flutter UI만 참조한다
/// ===================================================================

import 'package:flutter/material.dart';

import '../routing/engine_feature.dart';

/// Phase 2에서 RouterEngine이 들어오기 전까지 사용하는 임시 shell이다.
///
/// 계약:
/// - 선택된 Feature가 있으면 해당 page를 렌더링한다
/// - 선택할 Feature가 없으면 empty state 메시지를 렌더링한다
class EnginePlaceholderShell extends StatelessWidget {
  const EnginePlaceholderShell({
    super.key,
    required this.title,
    required this.features,
    required this.selectedFeature,
  });

  final String title;
  final List<EngineFeature> features;
  final EngineFeature? selectedFeature;

  @override
  Widget build(BuildContext context) {
    final feature = selectedFeature;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: feature == null
          ? _EmptyFeatureState(features: features)
          : feature.builder(context),
    );
  }
}

class _EmptyFeatureState extends StatelessWidget {
  const _EmptyFeatureState({required this.features});

  final List<EngineFeature> features;

  @override
  Widget build(BuildContext context) {
    final labels = features.map((feature) => feature.label).toList();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          labels.isEmpty
              ? 'No features registered yet.'
              : 'No initial feature matched. Registered: ${labels.join(', ')}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

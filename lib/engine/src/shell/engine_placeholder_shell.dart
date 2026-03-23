import 'package:flutter/material.dart';

import '../routing/engine_feature.dart';

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

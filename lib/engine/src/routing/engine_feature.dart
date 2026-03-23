import 'package:flutter/widgets.dart';

typedef EngineFeaturePageBuilder = Widget Function(BuildContext context);

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

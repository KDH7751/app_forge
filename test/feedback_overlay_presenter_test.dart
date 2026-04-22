// ignore_for_file: avoid_relative_lib_imports

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/modules/feedback/feedback.dart';

void main() {
  testWidgets('snackbar overlay consumes top compact fade options', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildFeedbackHost(container));

    container
        .read(feedbackDispatcherProvider)
        .showRequest(
          FeedbackRequest.snackbar(
            id: 'snackbar-top',
            preset: FeedbackPreset.info,
            variant: FeedbackVariant.info,
            animation: FeedbackAnimation.fade,
            position: FeedbackPosition.top,
            layoutMode: FeedbackLayoutMode.compact,
            slots: const FeedbackSnackbarSlots(message: 'Top snackbar'),
          ),
        );
    await tester.pump();

    final finder = find.byKey(
      const ValueKey<String>('feedback-overlay-snackbar-top-compact-fade'),
    );

    expect(finder, findsOneWidget);
    expect(tester.getTopLeft(finder).dy, lessThan(100));
  });

  testWidgets('banner overlay consumes bottom default slideUp options', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildFeedbackHost(container));

    container
        .read(feedbackDispatcherProvider)
        .showRequest(
          FeedbackRequest.banner(
            id: 'banner-bottom',
            preset: FeedbackPreset.info,
            variant: FeedbackVariant.info,
            animation: FeedbackAnimation.slideUp,
            position: FeedbackPosition.bottom,
            layoutMode: FeedbackLayoutMode.defaultMode,
            slots: const FeedbackBannerSlots(message: 'Bottom banner'),
          ),
        );
    await tester.pump();

    final finder = find.byKey(
      const ValueKey<String>('feedback-overlay-banner-bottom-default-slideUp'),
    );
    final rootHeight = tester.getSize(find.byType(MaterialApp)).height;

    expect(finder, findsOneWidget);
    expect(tester.getTopLeft(finder).dy, greaterThan(rootHeight / 2));
  });
}

Widget _buildFeedbackHost(ProviderContainer container) {
  final navigatorKey = GlobalKey<NavigatorState>();

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      navigatorKey: navigatorKey,
      home: FeedbackHost(
        navigatorKey: navigatorKey,
        child: const Scaffold(body: SizedBox.expand()),
      ),
    ),
  );
}

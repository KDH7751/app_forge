// ignore_for_file: avoid_relative_lib_imports

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/modules/feedback/feedback.dart';

void main() {
  test('dedupe blocks duplicate key across active and queue', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final dispatcher = container.read(feedbackDispatcherProvider);

    dispatcher.showError(message: 'first', dedupeKey: 'same-key');
    dispatcher.showError(message: 'second', dedupeKey: 'same-key');

    final state = container.read(feedbackControllerProvider);

    expect(state.activeByChannel.length, 1);
    expect(
      state.activeFor(FeedbackChannel.snackbar)?.snackbar?.message,
      'first',
    );
    expect(state.queue, isEmpty);
  });

  test(
    'higher priority blocking request replaces lower priority blocking request',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final dispatcher = container.read(feedbackDispatcherProvider);

      dispatcher.showRequest(
        FeedbackRequest.dialog(
          id: 'low-dialog',
          preset: FeedbackPreset.confirm,
          variant: FeedbackVariant.confirm,
          priority: FeedbackPriority.low,
          slots: const FeedbackDialogSlots(body: 'low'),
        ),
      );
      dispatcher.showRequest(
        FeedbackRequest.dialog(
          id: 'high-dialog',
          preset: FeedbackPreset.destructiveConfirm,
          variant: FeedbackVariant.destructiveConfirm,
          priority: FeedbackPriority.high,
          slots: const FeedbackDialogSlots(body: 'high'),
        ),
      );

      final state = container.read(feedbackControllerProvider);

      expect(state.activeFor(FeedbackChannel.dialog)?.id, 'high-dialog');
      expect(state.queue, isEmpty);
    },
  );

  test('snackbar waits until blocking request completes', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final dispatcher = container.read(feedbackDispatcherProvider);
    final controller = container.read(feedbackControllerProvider.notifier);

    dispatcher.showRequest(
      FeedbackRequest.dialog(
        id: 'confirm-dialog',
        preset: FeedbackPreset.confirm,
        variant: FeedbackVariant.confirm,
        slots: const FeedbackDialogSlots(body: 'confirm'),
      ),
    );
    dispatcher.showError(message: 'queued snackbar', dedupeKey: 'queued');

    var state = container.read(feedbackControllerProvider);

    expect(state.activeFor(FeedbackChannel.dialog)?.id, 'confirm-dialog');
    expect(state.activeFor(FeedbackChannel.snackbar), isNull);
    expect(state.queue, hasLength(1));

    controller.complete(FeedbackChannel.dialog, 'confirm-dialog');
    state = container.read(feedbackControllerProvider);

    expect(
      state.activeFor(FeedbackChannel.snackbar)?.snackbar?.message,
      'queued snackbar',
    );
    expect(state.queue, isEmpty);
  });
}

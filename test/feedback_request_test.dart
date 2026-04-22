// ignore_for_file: avoid_relative_lib_imports

import 'package:flutter_test/flutter_test.dart';

import '../lib/modules/feedback/feedback.dart';

void main() {
  group('FeedbackRequest normalization', () {
    test('snackbar normalizes expanded layoutMode to default', () {
      final request = FeedbackRequest.snackbar(
        id: 'snackbar-expanded',
        preset: FeedbackPreset.info,
        variant: FeedbackVariant.info,
        layoutMode: FeedbackLayoutMode.expanded,
        slots: const FeedbackSnackbarSlots(message: 'message'),
      );

      expect(request.layoutMode, FeedbackLayoutMode.defaultMode);
    });

    test('dialog normalizes top position to center', () {
      final request = FeedbackRequest.dialog(
        id: 'dialog-top',
        preset: FeedbackPreset.confirm,
        variant: FeedbackVariant.confirm,
        position: FeedbackPosition.top,
        slots: const FeedbackDialogSlots(body: 'body'),
      );

      expect(request.position, FeedbackPosition.center);
    });

    test('banner normalizes center position to top', () {
      final request = FeedbackRequest.banner(
        id: 'banner-center',
        preset: FeedbackPreset.info,
        variant: FeedbackVariant.info,
        position: FeedbackPosition.center,
        slots: const FeedbackBannerSlots(message: 'message'),
      );

      expect(request.position, FeedbackPosition.top);
    });

    test('modalSheet normalizes top position to bottom', () {
      final request = FeedbackRequest.modalSheet(
        id: 'sheet-top',
        preset: FeedbackPreset.confirm,
        variant: FeedbackVariant.confirm,
        position: FeedbackPosition.top,
        slots: const FeedbackModalSheetSlots(body: 'body'),
      );

      expect(request.position, FeedbackPosition.bottom);
    });

    test('banner normalizes scaleIn animation to slideDown', () {
      final request = FeedbackRequest.banner(
        id: 'banner-scale',
        preset: FeedbackPreset.info,
        variant: FeedbackVariant.info,
        animation: FeedbackAnimation.scaleIn,
        slots: const FeedbackBannerSlots(message: 'message'),
      );

      expect(request.animation, FeedbackAnimation.slideDown);
    });

    test('modalSheet normalizes fade animation to slideUp', () {
      final request = FeedbackRequest.modalSheet(
        id: 'sheet-fade',
        preset: FeedbackPreset.confirm,
        variant: FeedbackVariant.confirm,
        animation: FeedbackAnimation.fade,
        slots: const FeedbackModalSheetSlots(body: 'body'),
      );

      expect(request.animation, FeedbackAnimation.slideUp);
    });
  });
}

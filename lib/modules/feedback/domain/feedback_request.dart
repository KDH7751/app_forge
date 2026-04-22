import 'feedback_preset.dart';
import 'feedback_slots.dart';

/// 중앙 feedback 계층이 표시/운영만 담당할 때 쓰는 low-level request contract.
class FeedbackRequest {
  const FeedbackRequest._({
    required this.id,
    required this.channel,
    required this.preset,
    required this.variant,
    required this.priority,
    required this.animation,
    required this.position,
    required this.layoutMode,
    this.dedupeKey,
    this.snackbar,
    this.dialog,
    this.banner,
    this.modalSheet,
  });

  factory FeedbackRequest.snackbar({
    required String id,
    required FeedbackPreset preset,
    required FeedbackVariant variant,
    required FeedbackSnackbarSlots slots,
    String? dedupeKey,
    FeedbackPriority priority = FeedbackPriority.normal,
    FeedbackAnimation animation = FeedbackAnimation.slideUp,
    FeedbackPosition position = FeedbackPosition.bottom,
    FeedbackLayoutMode layoutMode = FeedbackLayoutMode.defaultMode,
  }) {
    final normalizedPosition = _normalizePosition(
      channel: FeedbackChannel.snackbar,
      position: position,
    );
    final normalizedLayoutMode = _normalizeLayoutMode(
      channel: FeedbackChannel.snackbar,
      layoutMode: layoutMode,
    );
    final normalizedAnimation = _normalizeAnimation(
      channel: FeedbackChannel.snackbar,
      animation: animation,
    );

    return FeedbackRequest._(
      id: id,
      channel: FeedbackChannel.snackbar,
      preset: preset,
      variant: variant,
      priority: priority,
      animation: normalizedAnimation,
      position: normalizedPosition,
      layoutMode: normalizedLayoutMode,
      dedupeKey: dedupeKey,
      snackbar: slots,
    );
  }

  factory FeedbackRequest.dialog({
    required String id,
    required FeedbackPreset preset,
    required FeedbackVariant variant,
    required FeedbackDialogSlots slots,
    String? dedupeKey,
    FeedbackPriority priority = FeedbackPriority.normal,
    FeedbackAnimation animation = FeedbackAnimation.fade,
    FeedbackPosition position = FeedbackPosition.center,
    FeedbackLayoutMode layoutMode = FeedbackLayoutMode.defaultMode,
  }) {
    final normalizedPosition = _normalizePosition(
      channel: FeedbackChannel.dialog,
      position: position,
    );
    final normalizedLayoutMode = _normalizeLayoutMode(
      channel: FeedbackChannel.dialog,
      layoutMode: layoutMode,
    );
    final normalizedAnimation = _normalizeAnimation(
      channel: FeedbackChannel.dialog,
      animation: animation,
    );

    return FeedbackRequest._(
      id: id,
      channel: FeedbackChannel.dialog,
      preset: preset,
      variant: variant,
      priority: priority,
      animation: normalizedAnimation,
      position: normalizedPosition,
      layoutMode: normalizedLayoutMode,
      dedupeKey: dedupeKey,
      dialog: slots,
    );
  }

  factory FeedbackRequest.banner({
    required String id,
    required FeedbackPreset preset,
    required FeedbackVariant variant,
    required FeedbackBannerSlots slots,
    String? dedupeKey,
    FeedbackPriority priority = FeedbackPriority.normal,
    FeedbackAnimation animation = FeedbackAnimation.slideDown,
    FeedbackPosition position = FeedbackPosition.top,
    FeedbackLayoutMode layoutMode = FeedbackLayoutMode.defaultMode,
  }) {
    final normalizedPosition = _normalizePosition(
      channel: FeedbackChannel.banner,
      position: position,
    );
    final normalizedLayoutMode = _normalizeLayoutMode(
      channel: FeedbackChannel.banner,
      layoutMode: layoutMode,
    );
    final normalizedAnimation = _normalizeAnimation(
      channel: FeedbackChannel.banner,
      animation: animation,
    );

    return FeedbackRequest._(
      id: id,
      channel: FeedbackChannel.banner,
      preset: preset,
      variant: variant,
      priority: priority,
      animation: normalizedAnimation,
      position: normalizedPosition,
      layoutMode: normalizedLayoutMode,
      dedupeKey: dedupeKey,
      banner: slots,
    );
  }

  factory FeedbackRequest.modalSheet({
    required String id,
    required FeedbackPreset preset,
    required FeedbackVariant variant,
    required FeedbackModalSheetSlots slots,
    String? dedupeKey,
    FeedbackPriority priority = FeedbackPriority.normal,
    FeedbackAnimation animation = FeedbackAnimation.slideUp,
    FeedbackPosition position = FeedbackPosition.bottom,
    FeedbackLayoutMode layoutMode = FeedbackLayoutMode.defaultMode,
  }) {
    final normalizedPosition = _normalizePosition(
      channel: FeedbackChannel.modalSheet,
      position: position,
    );
    final normalizedLayoutMode = _normalizeLayoutMode(
      channel: FeedbackChannel.modalSheet,
      layoutMode: layoutMode,
    );
    final normalizedAnimation = _normalizeAnimation(
      channel: FeedbackChannel.modalSheet,
      animation: animation,
    );

    return FeedbackRequest._(
      id: id,
      channel: FeedbackChannel.modalSheet,
      preset: preset,
      variant: variant,
      priority: priority,
      animation: normalizedAnimation,
      position: normalizedPosition,
      layoutMode: normalizedLayoutMode,
      dedupeKey: dedupeKey,
      modalSheet: slots,
    );
  }

  final String id;
  final FeedbackChannel channel;
  final FeedbackPreset preset;
  final FeedbackVariant variant;
  final FeedbackPriority priority;
  final FeedbackAnimation animation;
  final FeedbackPosition position;
  final FeedbackLayoutMode layoutMode;
  final String? dedupeKey;
  final FeedbackSnackbarSlots? snackbar;
  final FeedbackDialogSlots? dialog;
  final FeedbackBannerSlots? banner;
  final FeedbackModalSheetSlots? modalSheet;

  bool get isBlocking =>
      channel == FeedbackChannel.dialog ||
      channel == FeedbackChannel.modalSheet;
}

FeedbackPosition _normalizePosition({
  required FeedbackChannel channel,
  required FeedbackPosition position,
}) {
  return switch (channel) {
    FeedbackChannel.snackbar => switch (position) {
      FeedbackPosition.top || FeedbackPosition.bottom => position,
      FeedbackPosition.center => FeedbackPosition.bottom,
    },
    FeedbackChannel.banner => switch (position) {
      FeedbackPosition.top || FeedbackPosition.bottom => position,
      FeedbackPosition.center => FeedbackPosition.top,
    },
    FeedbackChannel.dialog => FeedbackPosition.center,
    FeedbackChannel.modalSheet => FeedbackPosition.bottom,
  };
}

FeedbackLayoutMode _normalizeLayoutMode({
  required FeedbackChannel channel,
  required FeedbackLayoutMode layoutMode,
}) {
  return switch (channel) {
    FeedbackChannel.snackbar || FeedbackChannel.banner => switch (layoutMode) {
      FeedbackLayoutMode.compact ||
      FeedbackLayoutMode.defaultMode => layoutMode,
      FeedbackLayoutMode.expanded => FeedbackLayoutMode.defaultMode,
    },
    FeedbackChannel.dialog ||
    FeedbackChannel.modalSheet => switch (layoutMode) {
      FeedbackLayoutMode.defaultMode ||
      FeedbackLayoutMode.expanded => layoutMode,
      FeedbackLayoutMode.compact => FeedbackLayoutMode.defaultMode,
    },
  };
}

FeedbackAnimation _normalizeAnimation({
  required FeedbackChannel channel,
  required FeedbackAnimation animation,
}) {
  return switch (channel) {
    FeedbackChannel.snackbar => animation,
    FeedbackChannel.banner => switch (animation) {
      FeedbackAnimation.fade ||
      FeedbackAnimation.slideUp ||
      FeedbackAnimation.slideDown => animation,
      FeedbackAnimation.scaleIn => FeedbackAnimation.slideDown,
    },
    FeedbackChannel.dialog => switch (animation) {
      FeedbackAnimation.fade || FeedbackAnimation.scaleIn => animation,
      FeedbackAnimation.slideUp ||
      FeedbackAnimation.slideDown => FeedbackAnimation.fade,
    },
    FeedbackChannel.modalSheet => switch (animation) {
      FeedbackAnimation.slideUp => animation,
      FeedbackAnimation.fade ||
      FeedbackAnimation.slideDown ||
      FeedbackAnimation.scaleIn => FeedbackAnimation.slideUp,
    },
  };
}

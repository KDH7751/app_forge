import 'package:flutter/material.dart';

import '../domain/feedback_preset.dart';
import '../domain/feedback_request.dart';
import '../domain/feedback_slots.dart';
import 'feedback_controller.dart';

/// 3층 API로 feedback request를 조립/전달하는 dispatcher.
class FeedbackDispatcher {
  const FeedbackDispatcher(this._controller);

  final FeedbackController _controller;

  void showRequest(FeedbackRequest request) {
    _controller.dispatch(request);
  }

  void showPreset({
    required FeedbackPreset preset,
    required String message,
    String? title,
    String? dedupeKey,
    FeedbackChannel? channel,
    FeedbackVariant? variant,
    FeedbackAnimation? animation,
    FeedbackPosition? position,
    FeedbackLayoutMode? layoutMode,
    FeedbackPriority? priority,
    IconData? icon,
    FeedbackActionRequest? action,
    List<FeedbackActionRequest> actions = const <FeedbackActionRequest>[],
    FeedbackSupplementarySlot? supplementary,
  }) {
    showRequest(
      _buildPresetRequest(
        preset: preset,
        message: message,
        title: title,
        dedupeKey: dedupeKey,
        channel: channel,
        variant: variant,
        animation: animation,
        position: position,
        layoutMode: layoutMode,
        priority: priority,
        icon: icon,
        action: action,
        actions: actions,
        supplementary: supplementary,
      ),
    );
  }

  void showError({required String message, String? title, String? dedupeKey}) {
    showPreset(
      preset: FeedbackPreset.error,
      message: message,
      title: title,
      dedupeKey: dedupeKey,
    );
  }

  void showSuccess({
    required String message,
    String? title,
    String? dedupeKey,
  }) {
    showPreset(
      preset: FeedbackPreset.success,
      message: message,
      title: title,
      dedupeKey: dedupeKey,
    );
  }

  void showWarning({
    required String message,
    String? title,
    String? dedupeKey,
  }) {
    showPreset(
      preset: FeedbackPreset.warning,
      message: message,
      title: title,
      dedupeKey: dedupeKey,
    );
  }

  void showInfo({required String message, String? title, String? dedupeKey}) {
    showPreset(
      preset: FeedbackPreset.info,
      message: message,
      title: title,
      dedupeKey: dedupeKey,
    );
  }

  void showConfirm({
    required String message,
    String? title,
    String? dedupeKey,
    List<FeedbackActionRequest> actions = const <FeedbackActionRequest>[],
    FeedbackSupplementarySlot? supplementary,
  }) {
    showPreset(
      preset: FeedbackPreset.confirm,
      message: message,
      title: title,
      dedupeKey: dedupeKey,
      actions: actions,
      supplementary: supplementary,
    );
  }

  void showDestructiveConfirm({
    required String message,
    String? title,
    String? dedupeKey,
    List<FeedbackActionRequest> actions = const <FeedbackActionRequest>[],
    FeedbackSupplementarySlot? supplementary,
  }) {
    showPreset(
      preset: FeedbackPreset.destructiveConfirm,
      message: message,
      title: title,
      dedupeKey: dedupeKey,
      actions: actions,
      supplementary: supplementary,
    );
  }

  void showSessionExpired({required String message, String? dedupeKey}) {
    showPreset(
      preset: FeedbackPreset.sessionExpired,
      message: message,
      dedupeKey: dedupeKey,
      action: const FeedbackActionRequest(label: '닫기'),
    );
  }
}

FeedbackRequest _buildPresetRequest({
  required FeedbackPreset preset,
  required String message,
  String? title,
  String? dedupeKey,
  FeedbackChannel? channel,
  FeedbackVariant? variant,
  FeedbackAnimation? animation,
  FeedbackPosition? position,
  FeedbackLayoutMode? layoutMode,
  FeedbackPriority? priority,
  IconData? icon,
  FeedbackActionRequest? action,
  List<FeedbackActionRequest> actions = const <FeedbackActionRequest>[],
  FeedbackSupplementarySlot? supplementary,
}) {
  final resolvedChannel = channel ?? _defaultChannelFor(preset);
  final resolvedVariant = variant ?? _defaultVariantFor(preset);
  final resolvedPriority = priority ?? _defaultPriorityFor(preset);
  final id = '${preset.name}-${DateTime.now().microsecondsSinceEpoch}';

  switch (resolvedChannel) {
    case FeedbackChannel.snackbar:
      return FeedbackRequest.snackbar(
        id: id,
        preset: preset,
        variant: resolvedVariant,
        dedupeKey: dedupeKey,
        priority: resolvedPriority,
        animation: animation ?? FeedbackAnimation.slideUp,
        position: position ?? FeedbackPosition.bottom,
        layoutMode: layoutMode ?? FeedbackLayoutMode.defaultMode,
        slots: FeedbackSnackbarSlots(
          icon: icon,
          title: title,
          message: message,
          action: action,
        ),
      );
    case FeedbackChannel.dialog:
      return FeedbackRequest.dialog(
        id: id,
        preset: preset,
        variant: resolvedVariant,
        dedupeKey: dedupeKey,
        priority: resolvedPriority,
        animation: animation ?? FeedbackAnimation.fade,
        position: position ?? FeedbackPosition.center,
        layoutMode: layoutMode ?? FeedbackLayoutMode.defaultMode,
        slots: FeedbackDialogSlots(
          icon: icon,
          title: title,
          body: message,
          actions: actions,
          supplementary: supplementary,
        ),
      );
    case FeedbackChannel.banner:
      return FeedbackRequest.banner(
        id: id,
        preset: preset,
        variant: resolvedVariant,
        dedupeKey: dedupeKey,
        priority: resolvedPriority,
        animation: animation ?? FeedbackAnimation.slideDown,
        position: position ?? FeedbackPosition.top,
        layoutMode: layoutMode ?? FeedbackLayoutMode.defaultMode,
        slots: FeedbackBannerSlots(
          icon: icon,
          message: message,
          secondaryAction: action,
        ),
      );
    case FeedbackChannel.modalSheet:
      return FeedbackRequest.modalSheet(
        id: id,
        preset: preset,
        variant: resolvedVariant,
        dedupeKey: dedupeKey,
        priority: resolvedPriority,
        animation: animation ?? FeedbackAnimation.slideUp,
        position: position ?? FeedbackPosition.bottom,
        layoutMode: layoutMode ?? FeedbackLayoutMode.defaultMode,
        slots: FeedbackModalSheetSlots(
          header: title,
          body: message,
          actions: actions,
        ),
      );
  }
}

FeedbackChannel _defaultChannelFor(FeedbackPreset preset) {
  return switch (preset) {
    FeedbackPreset.error ||
    FeedbackPreset.success ||
    FeedbackPreset.warning ||
    FeedbackPreset.info => FeedbackChannel.snackbar,
    FeedbackPreset.confirm ||
    FeedbackPreset.destructiveConfirm => FeedbackChannel.dialog,
    FeedbackPreset.sessionExpired => FeedbackChannel.banner,
  };
}

FeedbackVariant _defaultVariantFor(FeedbackPreset preset) {
  return switch (preset) {
    FeedbackPreset.error => FeedbackVariant.error,
    FeedbackPreset.success => FeedbackVariant.success,
    FeedbackPreset.warning => FeedbackVariant.warning,
    FeedbackPreset.info => FeedbackVariant.info,
    FeedbackPreset.confirm => FeedbackVariant.confirm,
    FeedbackPreset.destructiveConfirm => FeedbackVariant.destructiveConfirm,
    FeedbackPreset.sessionExpired => FeedbackVariant.sessionExpired,
  };
}

FeedbackPriority _defaultPriorityFor(FeedbackPreset preset) {
  return switch (preset) {
    FeedbackPreset.sessionExpired => FeedbackPriority.high,
    FeedbackPreset.destructiveConfirm => FeedbackPriority.high,
    FeedbackPreset.confirm => FeedbackPriority.normal,
    FeedbackPreset.error => FeedbackPriority.normal,
    FeedbackPreset.success => FeedbackPriority.normal,
    FeedbackPreset.warning => FeedbackPriority.normal,
    FeedbackPreset.info => FeedbackPriority.low,
  };
}

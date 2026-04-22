import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/feedback_request.dart';
import '../domain/feedback_slots.dart';
import '../state/feedback_controller.dart';
import '../state/feedback_provider.dart';
import 'feedback_overlay_presenter.dart';
import 'feedback_renderers.dart';

/// root에서 feedback active request를 실제 표시 채널로 연결하는 host.
class FeedbackHost extends ConsumerStatefulWidget {
  const FeedbackHost({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  ConsumerState<FeedbackHost> createState() => _FeedbackHostState();
}

class _FeedbackHostState extends ConsumerState<FeedbackHost> {
  ProviderSubscription<FeedbackState>? _subscription;
  String? _activeDialogId;
  String? _activeModalSheetId;

  @override
  void initState() {
    super.initState();
    _subscription = ref.listenManual<FeedbackState>(
      feedbackControllerProvider,
      (_, next) => _syncFeedbackState(next),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  void _syncFeedbackState(FeedbackState state) {
    final dialog = state.activeFor(FeedbackChannel.dialog);
    final modalSheet = state.activeFor(FeedbackChannel.modalSheet);

    if (dialog != null && dialog.id != _activeDialogId) {
      _activeDialogId = dialog.id;
      unawaited(_showDialogRequest(dialog));
    }

    if (modalSheet != null && modalSheet.id != _activeModalSheetId) {
      _activeModalSheetId = modalSheet.id;
      unawaited(_showModalSheetRequest(modalSheet));
    }
  }

  Future<void> _showDialogRequest(FeedbackRequest request) async {
    final dialogContext = widget.navigatorKey.currentContext;

    if (!mounted || dialogContext == null) {
      return;
    }

    final inputControllers = <String, TextEditingController>{};

    try {
      await showGeneralDialog<void>(
        context: dialogContext,
        barrierDismissible: true,
        barrierLabel: 'feedback-dialog',
        transitionBuilder: (context, animation, _, child) {
          return buildFeedbackAnimatedTransition(
            animation: request.animation,
            animationValue: animation,
            child: child,
          );
        },
        pageBuilder: (context, _, __) {
          return buildFeedbackDialog(
            context,
            request,
            inputControllers,
            (action) => _handleDialogAction(context, action, inputControllers),
          );
        },
      );
    } finally {
      for (final controller in inputControllers.values) {
        controller.dispose();
      }

      if (mounted) {
        _activeDialogId = null;
        ref
            .read(feedbackControllerProvider.notifier)
            .complete(FeedbackChannel.dialog, request.id);
      }
    }
  }

  Future<void> _showModalSheetRequest(FeedbackRequest request) async {
    final sheetContext = widget.navigatorKey.currentContext;

    if (!mounted || sheetContext == null) {
      return;
    }

    try {
      await showModalBottomSheet<void>(
        context: sheetContext,
        showDragHandle: request.layoutMode != FeedbackLayoutMode.compact,
        builder: (sheetBuildContext) {
          return buildFeedbackModalSheet(
            sheetBuildContext,
            request,
            (action) => _handleSheetAction(sheetBuildContext, action),
          );
        },
      );
    } finally {
      if (mounted) {
        _activeModalSheetId = null;
        ref
            .read(feedbackControllerProvider.notifier)
            .complete(FeedbackChannel.modalSheet, request.id);
      }
    }
  }

  Future<void> _handleDialogAction(
    BuildContext dialogContext,
    FeedbackActionRequest action,
    Map<String, TextEditingController> inputControllers,
  ) async {
    final inputValues = <String, String>{
      for (final entry in inputControllers.entries) entry.key: entry.value.text,
    };

    if (action.dismissOnAction && Navigator.of(dialogContext).canPop()) {
      Navigator.of(dialogContext).pop();
    }

    await _handleActionTap(action, inputValues);
  }

  Future<void> _handleSheetAction(
    BuildContext sheetContext,
    FeedbackActionRequest action,
  ) async {
    if (action.dismissOnAction && Navigator.of(sheetContext).canPop()) {
      Navigator.of(sheetContext).pop();
    }

    await _handleActionTap(action, const <String, String>{});
  }

  Future<void> _handleActionTap(
    FeedbackActionRequest? action,
    Map<String, String> inputValues,
  ) async {
    if (action?.onSelected == null) {
      return;
    }

    await action!.onSelected!(FeedbackActionContext(inputValues: inputValues));
  }

  @override
  Widget build(BuildContext context) {
    final feedbackState = ref.watch(feedbackControllerProvider);
    final snackbar = feedbackState.activeFor(FeedbackChannel.snackbar);
    final banner = feedbackState.activeFor(FeedbackChannel.banner);

    return FeedbackOverlayPresenter(
      snackbarRequest: snackbar,
      bannerRequest: banner,
      onSnackbarDismissed: snackbar == null
          ? null
          : () {
              ref
                  .read(feedbackControllerProvider.notifier)
                  .complete(FeedbackChannel.snackbar, snackbar.id);
            },
      onBannerDismissed: banner == null
          ? null
          : () {
              ref
                  .read(feedbackControllerProvider.notifier)
                  .complete(FeedbackChannel.banner, banner.id);
            },
      onSnackbarActionPressed: snackbar == null
          ? null
          : () => _handleActionTap(
              snackbar.snackbar?.action,
              const <String, String>{},
            ),
      onBannerActionPressed: banner == null
          ? null
          : () => _handleActionTap(
              banner.banner?.secondaryAction,
              const <String, String>{},
            ),
      child: widget.child,
    );
  }
}

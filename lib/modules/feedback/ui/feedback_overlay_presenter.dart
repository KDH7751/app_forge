import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/feedback_request.dart';
import '../domain/feedback_slots.dart';
import 'feedback_renderers.dart';

/// snackbar와 banner의 root overlay 표시만 담당하는 presenter.
class FeedbackOverlayPresenter extends StatelessWidget {
  const FeedbackOverlayPresenter({
    super.key,
    required this.child,
    this.snackbarRequest,
    this.bannerRequest,
    this.onSnackbarDismissed,
    this.onBannerDismissed,
    this.onSnackbarActionPressed,
    this.onBannerActionPressed,
  });

  final Widget child;
  final FeedbackRequest? snackbarRequest;
  final FeedbackRequest? bannerRequest;
  final VoidCallback? onSnackbarDismissed;
  final VoidCallback? onBannerDismissed;
  final Future<void> Function()? onSnackbarActionPressed;
  final Future<void> Function()? onBannerActionPressed;

  @override
  Widget build(BuildContext context) {
    final topSnackbarOffset =
        bannerRequest?.position == FeedbackPosition.top &&
            snackbarRequest?.position == FeedbackPosition.top
        ? 92.0
        : 0.0;
    final bottomBannerOffset =
        bannerRequest?.position == FeedbackPosition.bottom &&
            snackbarRequest?.position == FeedbackPosition.bottom
        ? 92.0
        : 0.0;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        child,
        if (bannerRequest != null)
          _FeedbackOverlayEntry(
            key: ValueKey<String>('feedback-banner-${bannerRequest!.id}'),
            request: bannerRequest!,
            action: bannerRequest!.banner?.secondaryAction,
            offset: bannerRequest!.position == FeedbackPosition.bottom
                ? bottomBannerOffset
                : 0,
            autoDismiss: false,
            onDismissed: onBannerDismissed,
            onActionPressed: onBannerActionPressed,
            contentBuilder: (context, onPressed) =>
                buildFeedbackBannerContent(context, bannerRequest!, onPressed),
          ),
        if (snackbarRequest != null)
          _FeedbackOverlayEntry(
            key: ValueKey<String>('feedback-snackbar-${snackbarRequest!.id}'),
            request: snackbarRequest!,
            action: snackbarRequest!.snackbar?.action,
            offset: snackbarRequest!.position == FeedbackPosition.top
                ? topSnackbarOffset
                : 0,
            autoDismiss: true,
            onDismissed: onSnackbarDismissed,
            onActionPressed: onSnackbarActionPressed,
            contentBuilder: (context, onPressed) =>
                buildFeedbackSnackbarContent(
                  context,
                  snackbarRequest!,
                  onPressed,
                ),
          ),
      ],
    );
  }
}

class _FeedbackOverlayEntry extends StatefulWidget {
  const _FeedbackOverlayEntry({
    super.key,
    required this.request,
    required this.contentBuilder,
    required this.offset,
    required this.autoDismiss,
    this.action,
    this.onActionPressed,
    this.onDismissed,
  });

  final FeedbackRequest request;
  final FeedbackActionRequest? action;
  final double offset;
  final bool autoDismiss;
  final Future<void> Function()? onActionPressed;
  final Widget Function(
    BuildContext context,
    Future<void> Function()? onPressed,
  )
  contentBuilder;
  final VoidCallback? onDismissed;

  @override
  State<_FeedbackOverlayEntry> createState() => _FeedbackOverlayEntryState();
}

class _FeedbackOverlayEntryState extends State<_FeedbackOverlayEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _dismissTimer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 180),
    )..forward();
    _scheduleDismiss();
  }

  @override
  void didUpdateWidget(covariant _FeedbackOverlayEntry oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.request.id == widget.request.id) {
      return;
    }

    _dismissTimer?.cancel();
    _isDismissing = false;
    _controller
      ..value = 0
      ..forward();
    _scheduleDismiss();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _scheduleDismiss() {
    if (!widget.autoDismiss) {
      return;
    }

    _dismissTimer = Timer(const Duration(seconds: 4), _dismiss);
  }

  Future<void> _handleAction() async {
    await widget.onActionPressed?.call();

    if (widget.action?.dismissOnAction ?? false) {
      await _dismiss();
    }
  }

  Future<void> _dismiss() async {
    if (_isDismissing) {
      return;
    }

    _isDismissing = true;
    _dismissTimer?.cancel();
    await _controller.reverse();

    if (mounted) {
      widget.onDismissed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTop = widget.request.position == FeedbackPosition.top;

    return IgnorePointer(
      ignoring: false,
      child: SafeArea(
        child: Align(
          alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              isTop ? 16 + widget.offset : 16,
              16,
              isTop ? 16 : 16 + widget.offset,
            ),
            child: buildFeedbackAnimatedTransition(
              animation: widget.request.animation,
              animationValue: _controller,
              child: KeyedSubtree(
                key: ValueKey<String>(
                  'feedback-overlay-'
                  '${widget.request.channel.name}-'
                  '${widget.request.position.name}-'
                  '${_layoutModeLabel(widget.request.layoutMode)}-'
                  '${widget.request.animation.name}',
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: widget.contentBuilder(
                    context,
                    widget.action == null ? null : _handleAction,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _layoutModeLabel(FeedbackLayoutMode mode) {
  return switch (mode) {
    FeedbackLayoutMode.compact => 'compact',
    FeedbackLayoutMode.defaultMode => 'default',
    FeedbackLayoutMode.expanded => 'expanded',
  };
}

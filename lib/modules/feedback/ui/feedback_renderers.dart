import 'package:flutter/material.dart';

import '../domain/feedback_preset.dart';
import '../domain/feedback_request.dart';
import '../domain/feedback_slots.dart';

Widget buildFeedbackSnackbarContent(
  BuildContext context,
  FeedbackRequest request,
  Future<void> Function()? onActionPressed,
) {
  final slots = request.snackbar!;
  final compact = request.layoutMode == FeedbackLayoutMode.compact;

  return _FeedbackOverlaySurface(
    variant: request.variant,
    layoutMode: request.layoutMode,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _FeedbackMessageBlock(
            icon: slots.icon,
            title: slots.title,
            message: slots.message,
            variant: request.variant,
            compact: compact,
          ),
        ),
        if (slots.action != null) ...<Widget>[
          const SizedBox(width: 12),
          _FeedbackInlineActionButton(
            action: slots.action!,
            compact: compact,
            onPressed: onActionPressed,
          ),
        ],
      ],
    ),
  );
}

Widget buildFeedbackBannerContent(
  BuildContext context,
  FeedbackRequest request,
  Future<void> Function()? onActionPressed,
) {
  final slots = request.banner!;
  final compact = request.layoutMode == FeedbackLayoutMode.compact;

  return _FeedbackOverlaySurface(
    variant: request.variant,
    layoutMode: request.layoutMode,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _FeedbackMessageBlock(
            icon: slots.icon,
            message: slots.message,
            variant: request.variant,
            compact: compact,
          ),
        ),
        if (slots.secondaryAction != null) ...<Widget>[
          const SizedBox(width: 12),
          _FeedbackInlineActionButton(
            action: slots.secondaryAction!,
            compact: compact,
            onPressed: onActionPressed,
          ),
        ],
      ],
    ),
  );
}

AlertDialog buildFeedbackDialog(
  BuildContext context,
  FeedbackRequest request,
  Map<String, TextEditingController> inputControllers,
  Future<void> Function(FeedbackActionRequest action) onActionPressed,
) {
  final slots = request.dialog!;
  final maxWidth = switch (request.layoutMode) {
    FeedbackLayoutMode.expanded => 560.0,
    _ => 420.0,
  };
  final insetHorizontal = switch (request.layoutMode) {
    FeedbackLayoutMode.expanded => 24.0,
    FeedbackLayoutMode.compact => 32.0,
    FeedbackLayoutMode.defaultMode => 32.0,
  };

  return AlertDialog(
    insetPadding: EdgeInsets.symmetric(
      horizontal: insetHorizontal,
      vertical: 24,
    ),
    icon: slots.icon == null
        ? null
        : Icon(
            slots.icon,
            color: feedbackVariantColor(context, request.variant),
          ),
    title: slots.title == null ? null : Text(slots.title!),
    content: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (slots.body != null) Text(slots.body!),
            if (slots.body != null && slots.supplementary != null)
              const SizedBox(height: 16),
            if (slots.supplementary case final FeedbackTextInputSlot input)
              TextField(
                controller: inputControllers.putIfAbsent(
                  input.fieldKey,
                  () => TextEditingController(text: input.initialValue),
                ),
                obscureText: input.obscureText,
                autofillHints: input.autofillHints,
                decoration: InputDecoration(
                  labelText: input.label,
                  hintText: input.hintText,
                  border: const OutlineInputBorder(),
                ),
              ),
          ],
        ),
      ),
    ),
    actions: <Widget>[
      for (final action in slots.actions)
        _buildDialogActionButton(
          context,
          action: action,
          onPressed: () => onActionPressed(action),
        ),
    ],
  );
}

Widget buildFeedbackModalSheet(
  BuildContext context,
  FeedbackRequest request,
  Future<void> Function(FeedbackActionRequest action) onActionPressed,
) {
  final slots = request.modalSheet!;
  final maxWidth = switch (request.layoutMode) {
    FeedbackLayoutMode.expanded => 640.0,
    FeedbackLayoutMode.compact => 420.0,
    FeedbackLayoutMode.defaultMode => 520.0,
  };
  final verticalPadding = request.layoutMode == FeedbackLayoutMode.compact
      ? 20.0
      : 24.0;

  return SafeArea(
    child: TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 220),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return buildFeedbackAnimatedTransition(
          animation: request.animation,
          animationValue: AlwaysStoppedAnimation<double>(value),
          child: child ?? const SizedBox.shrink(),
        );
      },
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, verticalPadding, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (slots.header != null)
                  Text(
                    slots.header!,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                if (slots.header != null && slots.body != null)
                  const SizedBox(height: 12),
                if (slots.body != null) Text(slots.body!),
                if (slots.body != null && slots.actions.isNotEmpty)
                  const SizedBox(height: 20),
                for (final action in slots.actions)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildSheetActionButton(
                      context,
                      action: action,
                      onPressed: () => onActionPressed(action),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Widget buildFeedbackAnimatedTransition({
  required FeedbackAnimation animation,
  required Animation<double> animationValue,
  required Widget child,
}) {
  final curved = CurvedAnimation(
    parent: animationValue,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  return switch (animation) {
    FeedbackAnimation.fade => FadeTransition(opacity: curved, child: child),
    FeedbackAnimation.slideUp => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.12),
        end: Offset.zero,
      ).animate(curved),
      child: FadeTransition(opacity: curved, child: child),
    ),
    FeedbackAnimation.slideDown => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.12),
        end: Offset.zero,
      ).animate(curved),
      child: FadeTransition(opacity: curved, child: child),
    ),
    FeedbackAnimation.scaleIn => ScaleTransition(
      scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
      child: FadeTransition(opacity: curved, child: child),
    ),
  };
}

class _FeedbackOverlaySurface extends StatelessWidget {
  const _FeedbackOverlaySurface({
    required this.variant,
    required this.layoutMode,
    required this.child,
  });

  final FeedbackVariant variant;
  final FeedbackLayoutMode layoutMode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = feedbackSurfaceColor(context, variant);
    final foregroundColor = feedbackOnSurfaceColor(context, variant);
    final padding = switch (layoutMode) {
      FeedbackLayoutMode.compact => const EdgeInsets.fromLTRB(14, 12, 14, 12),
      _ => const EdgeInsets.fromLTRB(18, 16, 18, 16),
    };

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: DefaultTextStyle(
          style: Theme.of(
            context,
          ).textTheme.bodyMedium!.copyWith(color: foregroundColor),
          child: IconTheme(
            data: IconThemeData(color: foregroundColor),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class _FeedbackInlineActionButton extends StatelessWidget {
  const _FeedbackInlineActionButton({
    required this.action,
    required this.compact,
    this.onPressed,
  });

  final FeedbackActionRequest action;
  final bool compact;
  final Future<void> Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = TextButton.styleFrom(
      minimumSize: compact ? const Size(0, 36) : const Size(0, 40),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return TextButton(
      onPressed: onPressed == null ? null : () => onPressed!(),
      style: style,
      child: Text(action.label),
    );
  }
}

class _FeedbackMessageBlock extends StatelessWidget {
  const _FeedbackMessageBlock({
    required this.variant,
    this.icon,
    this.title,
    this.message,
    this.compact = false,
  });

  final IconData? icon;
  final String? title;
  final String? message;
  final FeedbackVariant variant;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = feedbackVariantColor(context, variant);
    final hasText =
        (title?.isNotEmpty ?? false) || (message?.isNotEmpty ?? false);

    if (!hasText && icon == null) {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Padding(
            padding: EdgeInsets.only(top: compact ? 0 : 2),
            child: Icon(icon, size: compact ? 16 : 18, color: color),
          ),
          if (hasText) const SizedBox(width: 12),
        ],
        if (hasText)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (title?.isNotEmpty == true)
                  Text(
                    title!,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                if (title?.isNotEmpty == true && message?.isNotEmpty == true)
                  SizedBox(height: compact ? 2 : 4),
                if (message?.isNotEmpty == true) Text(message!),
              ],
            ),
          ),
      ],
    );
  }
}

Widget _buildDialogActionButton(
  BuildContext context, {
  required FeedbackActionRequest action,
  required Future<void> Function() onPressed,
}) {
  return switch (action.style) {
    FeedbackActionStyle.filled => FilledButton(
      onPressed: onPressed,
      child: Text(action.label),
    ),
    FeedbackActionStyle.tonal => FilledButton.tonal(
      onPressed: onPressed,
      child: Text(action.label),
    ),
    FeedbackActionStyle.destructive => FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Theme.of(context).colorScheme.onError,
      ),
      child: Text(action.label),
    ),
    FeedbackActionStyle.text => TextButton(
      onPressed: onPressed,
      child: Text(action.label),
    ),
  };
}

Widget _buildSheetActionButton(
  BuildContext context, {
  required FeedbackActionRequest action,
  required Future<void> Function() onPressed,
}) {
  return SizedBox(
    width: double.infinity,
    child: switch (action.style) {
      FeedbackActionStyle.text => OutlinedButton(
        onPressed: onPressed,
        child: Text(action.label),
      ),
      FeedbackActionStyle.tonal => FilledButton.tonal(
        onPressed: onPressed,
        child: Text(action.label),
      ),
      FeedbackActionStyle.filled => FilledButton(
        onPressed: onPressed,
        child: Text(action.label),
      ),
      FeedbackActionStyle.destructive => FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
          foregroundColor: Theme.of(context).colorScheme.onError,
        ),
        child: Text(action.label),
      ),
    },
  );
}

Color feedbackVariantColor(BuildContext context, FeedbackVariant variant) {
  final scheme = Theme.of(context).colorScheme;

  return switch (variant) {
    FeedbackVariant.error => scheme.error,
    FeedbackVariant.success => Colors.green.shade700,
    FeedbackVariant.warning => Colors.orange.shade700,
    FeedbackVariant.info => scheme.primary,
    FeedbackVariant.confirm => scheme.primary,
    FeedbackVariant.destructiveConfirm => scheme.error,
    FeedbackVariant.sessionExpired => scheme.error,
  };
}

Color feedbackSurfaceColor(BuildContext context, FeedbackVariant variant) {
  final scheme = Theme.of(context).colorScheme;

  return switch (variant) {
    FeedbackVariant.error => scheme.errorContainer,
    FeedbackVariant.success => Colors.green.shade50,
    FeedbackVariant.warning => Colors.orange.shade50,
    FeedbackVariant.info => scheme.primaryContainer,
    FeedbackVariant.confirm => scheme.primaryContainer,
    FeedbackVariant.destructiveConfirm => scheme.errorContainer,
    FeedbackVariant.sessionExpired => scheme.errorContainer,
  };
}

Color feedbackOnSurfaceColor(BuildContext context, FeedbackVariant variant) {
  final scheme = Theme.of(context).colorScheme;

  return switch (variant) {
    FeedbackVariant.error => scheme.onErrorContainer,
    FeedbackVariant.success => Colors.green.shade900,
    FeedbackVariant.warning => Colors.orange.shade900,
    FeedbackVariant.info => scheme.onPrimaryContainer,
    FeedbackVariant.confirm => scheme.onPrimaryContainer,
    FeedbackVariant.destructiveConfirm => scheme.onErrorContainer,
    FeedbackVariant.sessionExpired => scheme.onErrorContainer,
  };
}

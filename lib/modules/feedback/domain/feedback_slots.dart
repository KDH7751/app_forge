import 'package:flutter/material.dart';

/// 공식 feedback channel 목록.
enum FeedbackChannel { snackbar, dialog, banner, modalSheet }

/// 등록된 animation 옵션.
enum FeedbackAnimation { fade, slideUp, slideDown, scaleIn }

/// 등록된 position 옵션.
enum FeedbackPosition { top, bottom, center }

/// 등록된 layout mode 옵션.
enum FeedbackLayoutMode { compact, defaultMode, expanded }

/// 중앙 channel 정책에 사용하는 우선순위.
enum FeedbackPriority { low, normal, high, critical }

/// action 시각 역할.
enum FeedbackActionStyle { text, tonal, filled, destructive }

/// 등록형 supplementary content 종류.
sealed class FeedbackSupplementarySlot {
  const FeedbackSupplementarySlot();
}

/// dialog supplementary 영역에서 쓰는 등록형 입력 슬롯.
class FeedbackTextInputSlot extends FeedbackSupplementarySlot {
  const FeedbackTextInputSlot({
    required this.fieldKey,
    required this.label,
    this.initialValue = '',
    this.hintText,
    this.obscureText = false,
    this.autofillHints = const <String>[],
  });

  final String fieldKey;
  final String label;
  final String initialValue;
  final String? hintText;
  final bool obscureText;
  final List<String> autofillHints;
}

/// snackbar 공식 slot 구조.
class FeedbackSnackbarSlots {
  const FeedbackSnackbarSlots({
    this.icon,
    this.title,
    this.message,
    this.action,
  });

  final IconData? icon;
  final String? title;
  final String? message;
  final FeedbackActionRequest? action;
}

/// dialog 공식 slot 구조.
class FeedbackDialogSlots {
  const FeedbackDialogSlots({
    this.icon,
    this.title,
    this.body,
    this.actions = const <FeedbackActionRequest>[],
    this.supplementary,
  });

  final IconData? icon;
  final String? title;
  final String? body;
  final List<FeedbackActionRequest> actions;
  final FeedbackSupplementarySlot? supplementary;
}

/// banner 공식 slot 구조.
class FeedbackBannerSlots {
  const FeedbackBannerSlots({this.icon, this.message, this.secondaryAction});

  final IconData? icon;
  final String? message;
  final FeedbackActionRequest? secondaryAction;
}

/// modal sheet 공식 slot 구조.
class FeedbackModalSheetSlots {
  const FeedbackModalSheetSlots({
    this.header,
    this.body,
    this.actions = const <FeedbackActionRequest>[],
  });

  final String? header;
  final String? body;
  final List<FeedbackActionRequest> actions;
}

/// action callback가 받는 실행 문맥.
class FeedbackActionContext {
  const FeedbackActionContext({this.inputValues = const <String, String>{}});

  final Map<String, String> inputValues;
}

/// 등록형 action contract.
class FeedbackActionRequest {
  const FeedbackActionRequest({
    required this.label,
    this.style = FeedbackActionStyle.text,
    this.dismissOnAction = true,
    this.onSelected,
  });

  final String label;
  final FeedbackActionStyle style;
  final bool dismissOnAction;
  final Future<void> Function(FeedbackActionContext context)? onSelected;
}

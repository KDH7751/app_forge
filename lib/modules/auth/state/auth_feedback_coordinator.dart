import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../foundation/foundation.dart';
import '../../feedback/feedback.dart';
import 'auth_failure_presenter.dart';
import 'controllers/delete_account_controller.dart';

/// auth feature 문맥의 feedback request 조립과 dispatch orchestration을 담당한다.
final authFeedbackCoordinatorProvider = Provider<AuthFeedbackCoordinator>((
  ref,
) {
  return AuthFeedbackCoordinator(ref.read(feedbackDispatcherProvider));
});

/// presenter 출력과 auth action 문맥을 root feedback dispatch로 연결하는 coordinator.
///
/// delete account confirm은 auth feature의 destructive confirm feedback request로 열고,
/// confirm action 이후 실제 delete submit orchestration도 여기서 이어진다.
/// local-only failure는 root feedback으로 승격하지 않고 dialog/local 경로에 남긴다.
final class AuthFeedbackCoordinator {
  const AuthFeedbackCoordinator(this._dispatcher);

  final FeedbackDispatcher _dispatcher;

  void handleAuthFlowFailure(Object? failure) {
    final request = _requestFromPresentation(
      AuthFailurePresenter.presentForAuthFlow(failure),
      dedupePrefix: 'auth-flow',
    );

    if (request != null) {
      _dispatcher.showRequest(request);
    }
  }

  void handleProfileActionFailure(Object? failure) {
    final request = _requestFromPresentation(
      AuthFailurePresenter.presentForProfileAction(failure),
      dedupePrefix: 'profile-action',
    );

    if (request != null) {
      _dispatcher.showRequest(request);
    }
  }

  void handleResetPasswordSuccess() {
    _dispatcher.showSuccess(
      message: '비밀번호 재설정 메일을 전송했습니다',
      dedupeKey: 'reset-password-success',
    );
  }

  /// 현재 비밀번호 입력과 명시적 확인을 포함한 delete confirm request를 연다.
  void showDeleteAccountConfirm({required DeleteAccountController controller}) {
    _dispatcher.showRequest(_buildDeleteAccountConfirmRequest(controller));
  }

  FeedbackRequest? _requestFromPresentation(
    AuthFailurePresentation? presentation, {
    required String dedupePrefix,
  }) {
    if (presentation == null || !presentation.shouldReportToRootFeedback) {
      return null;
    }

    return FeedbackRequest.snackbar(
      id: '$dedupePrefix-${DateTime.now().microsecondsSinceEpoch}',
      preset: FeedbackPreset.error,
      variant: FeedbackVariant.error,
      dedupeKey: '$dedupePrefix-${presentation.message}',
      slots: FeedbackSnackbarSlots(
        icon: Icons.error_outline,
        message: presentation.message,
      ),
    );
  }

  FeedbackRequest _buildDeleteAccountConfirmRequest(
    DeleteAccountController controller, {
    String? localMessage,
  }) {
    return FeedbackRequest.dialog(
      id: 'delete-account-confirm-${DateTime.now().microsecondsSinceEpoch}',
      preset: FeedbackPreset.destructiveConfirm,
      variant: FeedbackVariant.destructiveConfirm,
      priority: FeedbackPriority.high,
      animation: FeedbackAnimation.scaleIn,
      layoutMode: FeedbackLayoutMode.expanded,
      slots: FeedbackDialogSlots(
        icon: Icons.warning_amber_rounded,
        title: 'Delete account',
        body: _deleteAccountBody(localMessage),
        supplementary: const FeedbackTextInputSlot(
          fieldKey: 'currentPassword',
          label: 'Current password',
          obscureText: true,
          autofillHints: <String>[AutofillHints.password],
        ),
        actions: <FeedbackActionRequest>[
          const FeedbackActionRequest(label: 'Cancel'),
          FeedbackActionRequest(
            label: 'Delete',
            style: FeedbackActionStyle.destructive,
            onSelected: (actionContext) async {
              // destructive confirm action이 dialog 입력을 수집한 뒤
              // 실제 delete submit orchestration을 이어서 수행한다.
              controller.updateCurrentPassword(
                actionContext.inputValues['currentPassword'] ?? '',
              );

              final result = await controller.submit();

              if (result case Failure<void>(failure: final failure)) {
                final presentation =
                    AuthFailurePresenter.presentForProfileAction(failure);

                if (presentation == null) {
                  return;
                }

                if (presentation.shouldReportToRootFeedback) {
                  handleProfileActionFailure(failure);
                  return;
                }

                // local-only failure는 root feedback으로 올리지 않고
                // confirm dialog를 다시 열어 같은 local path에 남긴다.
                await Future<void>.delayed(Duration.zero);
                _dispatcher.showRequest(
                  _buildDeleteAccountConfirmRequest(
                    controller,
                    localMessage: presentation.message,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  String _deleteAccountBody(String? localMessage) {
    const baseMessage = '정말 계정을 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.';

    if (localMessage == null || localMessage.isEmpty) {
      return baseMessage;
    }

    return '$baseMessage\n\n$localMessage';
  }
}

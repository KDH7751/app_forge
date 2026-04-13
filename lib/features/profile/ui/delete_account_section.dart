import 'package:app_forge/engine/engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/core/result.dart';
import '../../auth/state/auth_error_mapper.dart';
import '../../auth/state/controllers/delete_account_controller.dart';
import 'delete_account_confirm_dialog.dart';
import 'profile_action_error_report_helper.dart';

/// profile route에서 auth deleteAccount action을 여는 임시 UI 섹션.
class DeleteAccountSection extends ConsumerWidget {
  const DeleteAccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deleteAccountControllerProvider);
    final controller = ref.read(deleteAccountControllerProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Delete Account',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('계정 삭제는 되돌릴 수 없습니다. 현재 비밀번호를 다시 입력해야 합니다.'),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: state.isLoading
                  ? null
                  : () async {
                      final dialogResult =
                          await showDialog<DeleteAccountDialogResult>(
                            context: context,
                            builder: (_) => const DeleteAccountConfirmDialog(),
                          );

                      if (dialogResult == null) {
                        return;
                      }

                      controller.updateCurrentPassword(
                        dialogResult.currentPassword,
                      );

                      final result = await controller.submit();

                      if (!context.mounted) {
                        return;
                      }

                      if (result case Failure<void>(error: final error)) {
                        final message = mapDeleteAccountErrorText(error);

                        if (shouldReportProfileActionError(error)) {
                          reportUiError(context, error, domainError: error);
                        } else if (message != null) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(message)));
                        }

                        return;
                      }
                    },
              style: FilledButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: state.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Delete account'),
            ),
          ],
        ),
      ),
    );
  }
}

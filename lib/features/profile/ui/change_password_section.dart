import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../engine/engine.dart';
import '../../../modules/auth/auth.dart';
import 'profile_action_error_report_helper.dart';

/// profile route에서 auth changePassword action을 소비하는 임시 UI 섹션.
class ChangePasswordSection extends ConsumerWidget {
  const ChangePasswordSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(changePasswordControllerProvider);
    final controller = ref.read(changePasswordControllerProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Change Password',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('현재 비밀번호 확인 후 새 비밀번호로 변경합니다.'),
            const SizedBox(height: 16),
            TextField(
              enabled: !state.isLoading,
              obscureText: true,
              autofillHints: const <String>[AutofillHints.password],
              onChanged: controller.updateCurrentPassword,
              decoration: InputDecoration(
                labelText: 'Current password',
                border: const OutlineInputBorder(),
                errorText: mapChangePasswordErrorText(
                  state.currentPasswordError,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              enabled: !state.isLoading,
              obscureText: true,
              autofillHints: const <String>[AutofillHints.newPassword],
              onChanged: controller.updateNewPassword,
              decoration: InputDecoration(
                labelText: 'New password',
                border: const OutlineInputBorder(),
                errorText: mapChangePasswordErrorText(state.newPasswordError),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              enabled: !state.isLoading,
              obscureText: true,
              onChanged: controller.updateConfirmNewPassword,
              decoration: InputDecoration(
                labelText: 'Confirm new password',
                border: const OutlineInputBorder(),
                errorText: mapChangePasswordErrorText(
                  state.confirmNewPasswordError,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: state.canSubmit
                  ? () async {
                      final result = await controller.submit();

                      if (!context.mounted) {
                        return;
                      }

                      if (result case Failure<void>(
                        error: final error,
                      ) when shouldReportProfileActionError(error)) {
                        reportUiError(context, error, domainError: error);
                      }
                    }
                  : null,
              child: state.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Change password'),
            ),
            if (state.isSuccess) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                '비밀번호를 변경했습니다.',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

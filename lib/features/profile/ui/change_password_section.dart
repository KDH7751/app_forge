import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../engine/engine.dart';
import '../../../modules/auth/auth.dart';
import 'profile_action_failure_report_helper.dart';

/// profile route에서 auth changePassword action을 소비하는 임시 UI 섹션.
class ChangePasswordSection extends ConsumerStatefulWidget {
  const ChangePasswordSection({super.key});

  @override
  ConsumerState<ChangePasswordSection> createState() =>
      _ChangePasswordSectionState();
}

class _ChangePasswordSectionState extends ConsumerState<ChangePasswordSection> {
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmNewPasswordController;
  ProviderSubscription<ChangePasswordControllerState>? _stateSubscription;

  @override
  void initState() {
    super.initState();

    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmNewPasswordController = TextEditingController();
    _syncControllers(ref.read(changePasswordControllerProvider));
    _stateSubscription = ref.listenManual<ChangePasswordControllerState>(
      changePasswordControllerProvider,
      (_, next) => _syncControllers(next),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _stateSubscription?.close();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  void _syncControllers(ChangePasswordControllerState state) {
    _syncController(
      controller: _currentPasswordController,
      value: state.currentPassword,
    );
    _syncController(
      controller: _newPasswordController,
      value: state.newPassword,
    );
    _syncController(
      controller: _confirmNewPasswordController,
      value: state.confirmNewPassword,
    );
  }

  void _syncController({
    required TextEditingController controller,
    required String value,
  }) {
    if (controller.text == value) {
      return;
    }

    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              controller: _currentPasswordController,
              enabled: !state.isLoading,
              obscureText: true,
              autofillHints: const <String>[AutofillHints.password],
              onChanged: controller.updateCurrentPassword,
              decoration: InputDecoration(
                labelText: 'Current password',
                border: const OutlineInputBorder(),
                errorText: mapChangePasswordFailureText(
                  state.currentPasswordFailure,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPasswordController,
              enabled: !state.isLoading,
              obscureText: true,
              autofillHints: const <String>[AutofillHints.newPassword],
              onChanged: controller.updateNewPassword,
              decoration: InputDecoration(
                labelText: 'New password',
                border: const OutlineInputBorder(),
                errorText: mapChangePasswordFailureText(
                  state.newPasswordFailure,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmNewPasswordController,
              enabled: !state.isLoading,
              obscureText: true,
              onChanged: controller.updateConfirmNewPassword,
              decoration: InputDecoration(
                labelText: 'Confirm new password',
                border: const OutlineInputBorder(),
                errorText: mapChangePasswordFailureText(
                  state.confirmNewPasswordFailure,
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
                        failure: final failure,
                      ) when shouldReportProfileActionFailure(failure)) {
                        reportUiError(
                          context,
                          failure,
                          domainError: failure,
                        );
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

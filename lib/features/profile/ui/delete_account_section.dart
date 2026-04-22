import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../modules/auth/auth.dart';

/// profile route에서 auth deleteAccount action을 여는 임시 UI 섹션.
class DeleteAccountSection extends ConsumerWidget {
  const DeleteAccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deleteAccountControllerProvider);
    final controller = ref.read(deleteAccountControllerProvider.notifier);
    final feedbackCoordinator = ref.read(authFeedbackCoordinatorProvider);

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
                  : () {
                      feedbackCoordinator.showDeleteAccountConfirm(
                        controller: controller,
                      );
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

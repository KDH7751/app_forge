import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_action_controller.dart';

/// drawer 노출 route 확인용 profile 페이지.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  /// drawer 노출 profile 본문 렌더링.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionState = ref.watch(authActionControllerProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Profile route inside the Engine shell with drawer enabled.',
              textAlign: TextAlign.center,
            ),
            if (actionState.error != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                actionState.error!.message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: actionState.isLoading
                  ? null
                  : () => ref
                        .read(authActionControllerProvider.notifier)
                        .logout(),
              child: actionState.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}

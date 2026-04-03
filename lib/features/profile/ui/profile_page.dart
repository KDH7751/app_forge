import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_forge/engine/engine.dart';

import '../../auth/domain/result.dart';
import '../../auth/state/auth_error_mapper.dart';
import '../../auth/state/logout_controller.dart';

/// drawer 노출 route 확인용 profile 페이지.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(logoutControllerProvider);
    final controller = ref.read(logoutControllerProvider.notifier);

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
            const SizedBox(height: 24),
            FilledButton(
              onPressed: state.isLoading
                  ? null
                  : () async {
                      final result = await controller.submit();

                      if (!context.mounted) {
                        return;
                      }

                      if (result case Failure<void>(
                        error: final error,
                      ) when shouldReportAuthErrorNotification(error)) {
                        reportUiError(context, error, domainError: error);
                      }
                    },
              child: state.isLoading
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

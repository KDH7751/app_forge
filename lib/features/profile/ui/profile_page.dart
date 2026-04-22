import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../modules/auth/auth.dart';
import 'change_password_section.dart';
import 'delete_account_section.dart';

/// drawer 노출 route 확인용 profile 페이지.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(logoutControllerProvider);
    final controller = ref.read(logoutControllerProvider.notifier);
    final feedbackCoordinator = ref.read(authFeedbackCoordinatorProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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

                        if (result case Failure<void>(failure: final failure)) {
                          feedbackCoordinator.handleProfileActionFailure(
                            failure,
                          );
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
              const SizedBox(height: 32),
              const ChangePasswordSection(),
              const SizedBox(height: 32),
              const DeleteAccountSection(),
            ],
          ),
        ),
      ),
    );
  }
}

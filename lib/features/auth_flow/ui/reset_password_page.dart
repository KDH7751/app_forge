import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../modules/auth/auth.dart';
import '../state/reset_controller.dart';

/// reusable auth module의 recovery 경로를 여는 auth_flow page.
class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  ProviderSubscription<ResetControllerState>? _subscription;

  @override
  void initState() {
    super.initState();

    _subscription = ref.listenManual<ResetControllerState>(
      resetControllerProvider,
      (previous, next) {
        if (previous?.isSuccess == true || !next.isSuccess) {
          return;
        }

        if (!mounted) {
          return;
        }

        ref.read(authFeedbackCoordinatorProvider).handleResetPasswordSuccess();
        context.go('/login');
      },
    );
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetControllerProvider);
    final controller = ref.read(resetControllerProvider.notifier);
    final feedbackCoordinator = ref.read(authFeedbackCoordinatorProvider);
    final emailPresentation = AuthFailurePresenter.presentForAuthFlow(
      state.emailFailure,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  enabled: !state.isLoading,
                  onChanged: controller.updateEmail,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const <String>[AutofillHints.username],
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: const OutlineInputBorder(),
                    errorText: emailPresentation?.message,
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
                          )) {
                            feedbackCoordinator.handleAuthFlowFailure(failure);
                          }
                        }
                      : null,
                  child: state.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send reset email'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          context.push('/login');
                        },
                  child: const Text('Back to login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

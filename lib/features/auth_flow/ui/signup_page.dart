import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../engine/engine.dart';
import '../../../modules/auth/auth.dart';

import '../state/signup_controller.dart';

/// reusable auth module을 실제 프로젝트 sign-up UX로 여는 auth_flow page.
class SignupPage extends ConsumerWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signupControllerProvider);
    final controller = ref.read(signupControllerProvider.notifier);
    final emailPresentation = AuthFailurePresenter.presentForAuthFlow(
      state.emailFailure,
    );
    final passwordPresentation = AuthFailurePresenter.presentForAuthFlow(
      state.passwordFailure,
    );
    final confirmPasswordPresentation = AuthFailurePresenter.presentForAuthFlow(
      state.confirmPasswordFailure,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
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
                  autofillHints: const <String>[AutofillHints.newUsername],
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: const OutlineInputBorder(),
                    errorText: emailPresentation?.message,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  enabled: !state.isLoading,
                  onChanged: controller.updatePassword,
                  obscureText: true,
                  autofillHints: const <String>[AutofillHints.newPassword],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    errorText: passwordPresentation?.message,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  enabled: !state.isLoading,
                  onChanged: controller.updateConfirmPassword,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    border: const OutlineInputBorder(),
                    errorText: confirmPasswordPresentation?.message,
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
                            final presentation =
                                AuthFailurePresenter.presentForAuthFlow(
                                  failure,
                                );

                            if (presentation?.shouldReportToRootFeedback !=
                                true) {
                              return;
                            }

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
                      : const Text('Create account'),
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

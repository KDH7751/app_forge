import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/domain/app_error.dart';
import '../auth_entry_error_mapper.dart';
import '../controllers/signup_controller.dart';

/// auth_entry signup page.
class SignupPage extends ConsumerWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signupControllerProvider);
    final controller = ref.read(signupControllerProvider.notifier);

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
                    errorText: _mapFieldError(state.emailError),
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
                    errorText: _mapFieldError(state.passwordError),
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
                    errorText: _mapFieldError(state.confirmPasswordError),
                  ),
                ),
                if (state.serverError != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    mapAuthEntryError(state.serverError!),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: state.canSubmit
                      ? () {
                          controller.submit();
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

  String? _mapFieldError(AppError? error) {
    if (error == null) {
      return null;
    }

    return mapAuthEntryError(error);
  }
}

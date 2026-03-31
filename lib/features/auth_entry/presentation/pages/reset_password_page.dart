import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/domain/app_error.dart';
import '../auth_entry_error_mapper.dart';
import '../auth_entry_notice.dart';
import '../controllers/reset_controller.dart';

/// auth_entry reset password page.
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

        context.go(
          '/login',
          extra: const AuthEntryNotice.resetPasswordSuccess(),
        );
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
                    errorText: _mapFieldError(state.emailError),
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

  String? _mapFieldError(AppError? error) {
    if (error == null) {
      return null;
    }

    return mapAuthEntryError(error);
  }
}

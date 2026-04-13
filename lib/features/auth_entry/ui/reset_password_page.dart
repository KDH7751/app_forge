import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_forge/engine/engine.dart';

import '../../auth/domain/core/result.dart';
import '../state/auth_entry_error_report_helper.dart';
import '../state/auth_entry_error_mapper.dart';
import '../state/auth_entry_notice.dart';
import '../state/reset_controller.dart';

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
                    errorText: mapAuthEntryErrorText(state.emailError),
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
                          ) when shouldReportAuthEntryError(error)) {
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

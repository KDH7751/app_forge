import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_forge/engine/engine.dart';

import '../../auth/domain/result.dart';
import '../../auth/state/auth_error_mapper.dart';
import '../state/auth_entry_error_mapper.dart';
import '../state/auth_entry_notice.dart';
import '../state/login_controller.dart';

/// auth_entry login page.
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key, this.notice});

  final AuthEntryNotice? notice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loginControllerProvider);
    final controller = ref.read(loginControllerProvider.notifier);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text('Login', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                const Text(
                  'Standalone auth entry route outside the Engine shell.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (notice?.kind ==
                    AuthEntryNoticeKind.resetPasswordSuccess) ...<Widget>[
                  const Text(
                    '비밀번호 재설정 메일을 전송했습니다',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  enabled: !state.isLoading,
                  onChanged: controller.updateEmail,
                  autofillHints: const <String>[AutofillHints.username],
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: const OutlineInputBorder(),
                    errorText: mapAuthEntryErrorText(state.emailError),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  enabled: !state.isLoading,
                  onChanged: controller.updatePassword,
                  obscureText: true,
                  autofillHints: const <String>[AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    errorText: mapAuthEntryErrorText(state.passwordError),
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
                          ) when shouldReportAuthErrorNotification(error)) {
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
                      : const Text('Login'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          context.push('/signup');
                        },
                  child: const Text('Create account'),
                ),
                TextButton(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          context.push('/reset-password');
                        },
                  child: const Text('Reset password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

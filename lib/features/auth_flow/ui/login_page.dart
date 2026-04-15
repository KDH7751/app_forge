import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../engine/engine.dart';
import '../../../modules/auth/auth.dart';

import '../state/auth_flow_error_report_helper.dart';
import '../state/auth_flow_error_mapper.dart';
import '../state/auth_flow_notice.dart';
import '../state/login_controller.dart';

/// reusable auth module을 실제 프로젝트 sign-in UX로 여는 auth_flow 시작 page.
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key, this.notice});

  final AuthFlowNotice? notice;

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
                  'Project auth flow that consumes the reusable auth module outside the Engine shell.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (notice?.kind ==
                    AuthFlowNoticeKind.resetPasswordSuccess) ...<Widget>[
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
                    errorText: mapAuthFlowErrorText(state.emailError),
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
                    errorText: mapAuthFlowErrorText(state.passwordError),
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
                          ) when shouldReportAuthFlowError(error)) {
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// shell 밖 standalone route 예시.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  /// standalone login 화면 렌더링.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Login', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              const Text(
                'Standalone route outside the Engine shell.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go To Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

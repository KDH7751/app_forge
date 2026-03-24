// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Login Page
///
/// 역할:
/// - standalone login route의 검증용 진입점을 제공한다
///
/// 책임:
/// - shell 밖에서 렌더링되는 최소 페이지를 보여준다
///
/// 경계:
/// - auth 비즈니스 로직은 구현하지 않는다
/// - engine shell을 직접 알지 않는다
///
/// 의존성:
/// - Flutter presentation type만 참조한다
/// ===================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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

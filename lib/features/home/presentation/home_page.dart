// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Home Page
///
/// 역할:
/// - home Feature의 placeholder presentation 진입점을 제공한다
///
/// 책임:
/// - Engine이 Feature 내부 구현을 몰라도 page 등록이 가능함을 보여준다
///
/// 경계:
/// - Feature presentation layer에 속한다
/// - app composition이나 Engine policy는 정의하지 않는다
///
/// 의존성:
/// - Flutter presentation type만 참조한다
/// ===================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Phase 1 home slice용 placeholder page이다.
///
/// 계약:
/// - 등록된 Feature의 최소 진입 page를 렌더링한다
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Phase 2 Home Route',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Use the buttons below to verify shell, standalone, and param routes.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: <Widget>[
                FilledButton(
                  onPressed: () => context.go('/profile'),
                  child: const Text('Profile'),
                ),
                FilledButton(
                  onPressed: () => context.go('/posts/42?tab=comments'),
                  child: const Text('Post 42'),
                ),
                OutlinedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Login'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

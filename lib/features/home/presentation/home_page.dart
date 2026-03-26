import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// shell 이동 검증용 home 페이지.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  /// route 이동 검증용 home 본문 렌더링.
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

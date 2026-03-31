import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/app_error.dart';
import '../../auth/domain/result.dart';
import '../../auth/presentation/auth_repository_provider.dart';

/// drawer 노출 route 확인용 profile 페이지.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isLoading = false;
  AppError? _error;

  /// drawer 노출 profile 본문 렌더링.
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Profile route inside the Engine shell with drawer enabled.',
              textAlign: TextAlign.center,
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                _mapLogoutError(_error!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _submitLogout,
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitLogout() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ref.read(authRepositoryProvider).logout();

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      if (result case Failure<void>(error: final error)) {
        _error = error;
      }
    });
  }

  String _mapLogoutError(AppError error) {
    return switch (error.type) {
      AppErrorType.network => '네트워크 문제로 로그아웃할 수 없습니다',
      _ => '로그아웃에 실패했습니다. 다시 시도해주세요',
    };
  }
}

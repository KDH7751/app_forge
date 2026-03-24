// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Feature Shell
///
/// 역할:
/// - Feature 비동기 상태를 감싸는 최소 UI wrapper를 제공한다
///
/// 책임:
/// - AsyncValue의 loading, error, data 분기를 일관되게 처리한다
///
/// 경계:
/// - Result/AppError 정책은 이번 단계에서 다루지 않는다
/// - 세부 refresh 동작 옵션은 최소 수준만 허용한다
///
/// 의존성:
/// - Flutter material과 Riverpod AsyncValue만 참조한다
/// ===================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Feature 화면에서 사용하는 최소 async 상태 wrapper다.
class FeatureShell<T> extends StatelessWidget {
  const FeatureShell({
    super.key,
    required this.value,
    required this.dataBuilder,
    this.onRetry,
    this.loadingMessage,
  });

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) dataBuilder;
  final VoidCallback? onRetry;
  final String? loadingMessage;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => _FeatureLoadingState(message: loadingMessage),
      error: (error, _) => _FeatureErrorState(error: error, onRetry: onRetry),
      data: (data) => dataBuilder(context, data),
    );
  }
}

class _FeatureLoadingState extends StatelessWidget {
  const _FeatureLoadingState({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(),
          if (message != null) ...<Widget>[
            const SizedBox(height: 16),
            Text(message!),
          ],
        ],
      ),
    );
  }
}

class _FeatureErrorState extends StatelessWidget {
  const _FeatureErrorState({required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Something went wrong.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(error.toString(), textAlign: TextAlign.center),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

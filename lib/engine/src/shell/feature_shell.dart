// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// Feature Shell
///
/// 역할:
/// - Feature 화면의 AsyncValue 분기용 공통 UI wrapper 제공.
///
/// 경계:
/// - loading / error / data 분기만 다룸.
/// - 도메인 에러 정책 해석은 이 계층 밖에 둠.
/// ===================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AsyncValue 분기용 Feature 화면 wrapper.
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

  /// AsyncValue 상태별 공통 UI 분기.
  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => _FeatureLoadingState(message: loadingMessage),
      error: (error, _) => _FeatureErrorState(error: error, onRetry: onRetry),
      data: (data) => dataBuilder(context, data),
    );
  }
}

/// loading 상태용 내부 위젯.
class _FeatureLoadingState extends StatelessWidget {
  const _FeatureLoadingState({this.message});

  final String? message;

  /// loading indicator와 message 렌더링.
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

/// error 상태용 내부 위젯.
class _FeatureErrorState extends StatelessWidget {
  const _FeatureErrorState({required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  /// error 메시지와 retry action 렌더링.
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

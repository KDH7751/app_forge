// ignore_for_file: dangling_library_doc_comments

/// ===================================================================
/// FeatureShell
///
/// 역할:
/// - AsyncValue 기반 화면의 loading / error / data 분기를 공통 UI로 감싼다.
///
/// 결정:
/// - AsyncValue 상태별로 어떤 공통 화면을 보여줄지와 retry 노출 여부가 여기서 정해진다.
///
/// 주의:
/// - loading / error / data 분기만 다룬다.
/// - 에러 해석이나 상태 복구 정책은 이 계층 밖에 둔다.
/// ===================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// AsyncValue 상태 분기를 공통 화면 구조로 감싸는 wrapper.
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

  /// AsyncValue 상태에 따라 loading / error / data 화면을 고른다.
  ///
  /// 화면별 개별 분기 코드를 반복하지 않도록
  /// 공통 상태 화면 선택을 이 build에서 수행한다.
  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => _FeatureLoadingState(message: loadingMessage),
      error: (error, _) => _FeatureErrorState(error: error, onRetry: onRetry),
      data: (data) => dataBuilder(context, data),
    );
  }
}

/// loading 상태를 렌더링하는 내부 위젯.
class _FeatureLoadingState extends StatelessWidget {
  const _FeatureLoadingState({this.message});

  final String? message;

  /// loading indicator와 선택적 메시지를 렌더링한다.
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

/// error 상태를 렌더링하는 내부 위젯.
class _FeatureErrorState extends StatelessWidget {
  const _FeatureErrorState({required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  /// error 메시지와 retry action을 렌더링한다.
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

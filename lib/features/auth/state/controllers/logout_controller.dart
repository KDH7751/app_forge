import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/core/result.dart';
import '../providers/auth_facade_provider.dart';

/// profile route가 auth logout 실행을 여는 단일 controller.
///
/// 이 controller는 로딩 상태만 소유하고,
/// 실제 logout 실행은 auth facade를 통해 수행한다.
/// 강제 logout과는 별개로 사용자 의도 기반 logout UI 흐름만 담당한다.
final logoutControllerProvider =
    AutoDisposeNotifierProvider<LogoutController, LogoutControllerState>(
      LogoutController.new,
    );

/// logout action 상태.
class LogoutControllerState {
  const LogoutControllerState({this.isLoading = false});

  final bool isLoading;

  LogoutControllerState copyWith({bool? isLoading}) {
    return LogoutControllerState(isLoading: isLoading ?? this.isLoading);
  }
}

/// logout submit 흐름 controller.
class LogoutController extends AutoDisposeNotifier<LogoutControllerState> {
  @override
  LogoutControllerState build() {
    return const LogoutControllerState();
  }

  Future<Result<void>> submit() async {
    state = state.copyWith(isLoading: true);

    final result = await ref.read(authFacadeProvider).logout();

    if (result case Failure<void>()) {
      state = state.copyWith(isLoading: false);
      return result;
    }

    state = state.copyWith(isLoading: false);
    return result;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/result.dart';
import 'auth_repository_provider.dart';

/// logout controller provider.
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

    final result = await ref.read(authRepositoryProvider).logout();

    if (result case Failure<void>()) {
      state = state.copyWith(isLoading: false);
      return result;
    }

    state = state.copyWith(isLoading: false);
    return result;
  }
}

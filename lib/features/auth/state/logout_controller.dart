import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_error.dart';
import '../domain/result.dart';
import 'auth_repository_provider.dart';

/// logout controller provider.
final logoutControllerProvider =
    AutoDisposeNotifierProvider<LogoutController, LogoutControllerState>(
      LogoutController.new,
    );

/// logout action 상태.
class LogoutControllerState {
  const LogoutControllerState({this.isLoading = false, this.serverError});

  final bool isLoading;
  final AppError? serverError;

  LogoutControllerState copyWith({
    bool? isLoading,
    AppError? serverError,
    bool clearServerError = false,
  }) {
    return LogoutControllerState(
      isLoading: isLoading ?? this.isLoading,
      serverError: clearServerError ? null : (serverError ?? this.serverError),
    );
  }
}

/// logout submit 흐름 controller.
class LogoutController extends AutoDisposeNotifier<LogoutControllerState> {
  @override
  LogoutControllerState build() {
    return const LogoutControllerState();
  }

  Future<Result<void>> submit() async {
    state = state.copyWith(isLoading: true, clearServerError: true);

    final result = await ref.read(authRepositoryProvider).logout();

    if (result case Failure<void>(error: final error)) {
      state = state.copyWith(isLoading: false, serverError: error);
      return result;
    }

    state = state.copyWith(isLoading: false, clearServerError: true);
    return result;
  }
}

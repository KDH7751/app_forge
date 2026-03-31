import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/app_error.dart';
import '../../auth/domain/result.dart';
import '../../auth/state/auth_repository_provider.dart';

/// reset form controller provider.
final resetControllerProvider =
    AutoDisposeNotifierProvider<ResetController, ResetControllerState>(
      ResetController.new,
    );

/// reset form 상태.
class ResetControllerState {
  const ResetControllerState({
    this.email = '',
    this.emailError,
    this.serverError,
    this.isLoading = false,
    this.isSuccess = false,
  });

  final String email;
  final AppError? emailError;
  final AppError? serverError;
  final bool isLoading;
  final bool isSuccess;

  bool get canSubmit => !isLoading && email.trim().isNotEmpty;

  ResetControllerState copyWith({
    String? email,
    AppError? emailError,
    AppError? serverError,
    bool? isLoading,
    bool? isSuccess,
    bool clearEmailError = false,
    bool clearServerError = false,
  }) {
    return ResetControllerState(
      email: email ?? this.email,
      emailError: clearEmailError ? null : (emailError ?? this.emailError),
      serverError: clearServerError ? null : (serverError ?? this.serverError),
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// reset submit 흐름 controller.
class ResetController extends AutoDisposeNotifier<ResetControllerState> {
  @override
  ResetControllerState build() {
    return const ResetControllerState();
  }

  void updateEmail(String email) {
    state = state.copyWith(
      email: email,
      isSuccess: false,
      clearEmailError: true,
      clearServerError: true,
    );
  }

  Future<Result<void>> submit() async {
    final validation = ref
        .read(authRepositoryProvider)
        .validateReset(email: state.email);

    if (validation case Failure<void>(error: final error)) {
      state = state.copyWith(
        emailError: error,
        isSuccess: false,
        clearServerError: true,
      );

      return validation;
    }

    state = state.copyWith(
      isLoading: true,
      isSuccess: false,
      clearEmailError: true,
      clearServerError: true,
    );

    final result = await ref
        .read(authRepositoryProvider)
        .sendPasswordResetEmail(email: state.email.trim());

    if (result case Failure<void>(error: final error)) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        serverError: error,
      );
      return result;
    }

    state = state.copyWith(
      isLoading: false,
      isSuccess: true,
      clearServerError: true,
    );
    return result;
  }
}

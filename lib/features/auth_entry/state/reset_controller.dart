import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/core/app_error.dart';
import '../../auth/domain/core/result.dart';
import '../../auth/state/providers/auth_facade_provider.dart';

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
    this.isLoading = false,
    this.isSuccess = false,
  });

  final String email;
  final AppError? emailError;
  final bool isLoading;
  final bool isSuccess;

  bool get canSubmit => !isLoading && email.trim().isNotEmpty;

  ResetControllerState copyWith({
    String? email,
    AppError? emailError,
    bool? isLoading,
    bool? isSuccess,
    bool clearEmailError = false,
  }) {
    return ResetControllerState(
      email: email ?? this.email,
      emailError: clearEmailError ? null : (emailError ?? this.emailError),
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
    );
  }

  Future<Result<void>> submit() async {
    final validation = ref
        .read(authFacadeProvider)
        .validateReset(email: state.email);

    if (validation case Failure<void>(error: final error)) {
      state = state.copyWith(emailError: error, isSuccess: false);

      return validation;
    }

    state = state.copyWith(
      isLoading: true,
      isSuccess: false,
      clearEmailError: true,
    );

    final result = await ref
        .read(authFacadeProvider)
        .sendPasswordResetEmail(email: state.email.trim());

    if (result case Failure<void>()) {
      state = state.copyWith(isLoading: false, isSuccess: false);
      return result;
    }

    state = state.copyWith(isLoading: false, isSuccess: true);
    return result;
  }
}

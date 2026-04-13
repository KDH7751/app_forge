import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/core/app_error.dart';
import '../../auth/domain/core/result.dart';
import '../../auth/state/providers/auth_facade_provider.dart';
import '../../auth/state/providers/auth_session_provider.dart';

/// signup form controller provider.
final signupControllerProvider =
    AutoDisposeNotifierProvider<SignupController, SignupControllerState>(
      SignupController.new,
    );

/// signup form 상태.
class SignupControllerState {
  const SignupControllerState({
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.emailError,
    this.passwordError,
    this.confirmPasswordError,
    this.isLoading = false,
  });

  final String email;
  final String password;
  final String confirmPassword;
  final AppError? emailError;
  final AppError? passwordError;
  final AppError? confirmPasswordError;
  final bool isLoading;

  bool get canSubmit =>
      !isLoading &&
      email.trim().isNotEmpty &&
      password.isNotEmpty &&
      confirmPassword.isNotEmpty;

  SignupControllerState copyWith({
    String? email,
    String? password,
    String? confirmPassword,
    AppError? emailError,
    AppError? passwordError,
    AppError? confirmPasswordError,
    bool? isLoading,
    bool clearEmailError = false,
    bool clearPasswordError = false,
    bool clearConfirmPasswordError = false,
  }) {
    return SignupControllerState(
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      emailError: clearEmailError ? null : (emailError ?? this.emailError),
      passwordError: clearPasswordError
          ? null
          : (passwordError ?? this.passwordError),
      confirmPasswordError: clearConfirmPasswordError
          ? null
          : (confirmPasswordError ?? this.confirmPasswordError),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// signup submit 흐름 controller.
class SignupController extends AutoDisposeNotifier<SignupControllerState> {
  @override
  SignupControllerState build() {
    return const SignupControllerState();
  }

  void updateEmail(String email) {
    state = state.copyWith(email: email, clearEmailError: true);
  }

  void updatePassword(String password) {
    state = state.copyWith(password: password, clearPasswordError: true);
  }

  void updateConfirmPassword(String confirmPassword) {
    state = state.copyWith(
      confirmPassword: confirmPassword,
      clearConfirmPasswordError: true,
    );
  }

  Future<Result<void>> submit() async {
    final validation = ref
        .read(authFacadeProvider)
        .validateSignup(
          email: state.email,
          password: state.password,
          confirmPassword: state.confirmPassword,
        );

    if (validation case Failure<void>(error: final error)) {
      state = state.copyWith(
        emailError: _emailErrorFor(error),
        passwordError: _passwordErrorFor(error),
        confirmPasswordError: _confirmPasswordErrorFor(error),
      );

      return validation;
    }

    state = state.copyWith(
      isLoading: true,
      clearEmailError: true,
      clearPasswordError: true,
      clearConfirmPasswordError: true,
    );

    final recoveryCount = ref.read(
      authSessionRecoveryInFlightCountProvider.notifier,
    );
    recoveryCount.state += 1;

    try {
      final result = await ref
          .read(authFacadeProvider)
          .signup(email: state.email.trim(), password: state.password);

      if (result case Failure<void>()) {
        state = state.copyWith(isLoading: false);
        return result;
      }

      state = state.copyWith(isLoading: false);
      return result;
    } finally {
      recoveryCount.state -= 1;
    }
  }

  AppError? _emailErrorFor(AppError error) {
    return switch (error.type) {
      AppErrorType.invalidEmail => error,
      _ => null,
    };
  }

  AppError? _passwordErrorFor(AppError error) {
    return switch (error.type) {
      AppErrorType.invalidPassword => error,
      _ => null,
    };
  }

  AppError? _confirmPasswordErrorFor(AppError error) {
    return switch (error.type) {
      AppErrorType.passwordMismatch => error,
      _ => null,
    };
  }
}

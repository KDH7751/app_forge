import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/app_error.dart';
import '../../auth/domain/result.dart';
import '../../auth/state/auth_repository_provider.dart';

/// login form controller provider.
final loginControllerProvider =
    AutoDisposeNotifierProvider<LoginController, LoginControllerState>(
      LoginController.new,
    );

/// login form 상태.
class LoginControllerState {
  const LoginControllerState({
    this.email = '',
    this.password = '',
    this.emailError,
    this.passwordError,
    this.serverError,
    this.isLoading = false,
  });

  final String email;
  final String password;
  final AppError? emailError;
  final AppError? passwordError;
  final AppError? serverError;
  final bool isLoading;

  bool get canSubmit =>
      !isLoading && email.trim().isNotEmpty && password.isNotEmpty;

  LoginControllerState copyWith({
    String? email,
    String? password,
    AppError? emailError,
    AppError? passwordError,
    AppError? serverError,
    bool? isLoading,
    bool clearEmailError = false,
    bool clearPasswordError = false,
    bool clearServerError = false,
  }) {
    return LoginControllerState(
      email: email ?? this.email,
      password: password ?? this.password,
      emailError: clearEmailError ? null : (emailError ?? this.emailError),
      passwordError: clearPasswordError
          ? null
          : (passwordError ?? this.passwordError),
      serverError: clearServerError ? null : (serverError ?? this.serverError),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// login submit 흐름 controller.
class LoginController extends AutoDisposeNotifier<LoginControllerState> {
  @override
  LoginControllerState build() {
    return const LoginControllerState();
  }

  void updateEmail(String email) {
    state = state.copyWith(
      email: email,
      clearEmailError: true,
      clearServerError: true,
    );
  }

  void updatePassword(String password) {
    state = state.copyWith(
      password: password,
      clearPasswordError: true,
      clearServerError: true,
    );
  }

  Future<Result<void>> submit() async {
    final validation = ref
        .read(authRepositoryProvider)
        .validateLogin(email: state.email, password: state.password);

    if (validation case Failure<void>(error: final error)) {
      state = state.copyWith(
        emailError: _emailErrorFor(error),
        passwordError: _passwordErrorFor(error),
        clearServerError: true,
      );

      return validation;
    }

    state = state.copyWith(
      isLoading: true,
      clearEmailError: true,
      clearPasswordError: true,
      clearServerError: true,
    );

    final result = await ref
        .read(authRepositoryProvider)
        .login(email: state.email.trim(), password: state.password);

    if (result case Failure<void>(error: final error)) {
      state = state.copyWith(isLoading: false, serverError: error);
      return result;
    }

    state = state.copyWith(isLoading: false, clearServerError: true);
    return result;
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
}

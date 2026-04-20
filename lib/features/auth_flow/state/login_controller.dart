import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../modules/auth/auth.dart';

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
    this.emailFailure,
    this.passwordFailure,
    this.isLoading = false,
  });

  final String email;
  final String password;
  final AppFailure? emailFailure;
  final AppFailure? passwordFailure;
  final bool isLoading;

  bool get canSubmit =>
      !isLoading && email.trim().isNotEmpty && password.isNotEmpty;

  LoginControllerState copyWith({
    String? email,
    String? password,
    AppFailure? emailFailure,
    AppFailure? passwordFailure,
    bool? isLoading,
    bool clearEmailFailure = false,
    bool clearPasswordFailure = false,
  }) {
    return LoginControllerState(
      email: email ?? this.email,
      password: password ?? this.password,
      emailFailure:
          clearEmailFailure ? null : (emailFailure ?? this.emailFailure),
      passwordFailure: clearPasswordFailure
          ? null
          : (passwordFailure ?? this.passwordFailure),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// auth module 공개 facade를 호출하는 auth_flow sign-in controller.
class LoginController extends AutoDisposeNotifier<LoginControllerState> {
  @override
  LoginControllerState build() {
    return const LoginControllerState();
  }

  void updateEmail(String email) {
    state = state.copyWith(email: email, clearEmailFailure: true);
  }

  void updatePassword(String password) {
    state = state.copyWith(password: password, clearPasswordFailure: true);
  }

  Future<Result<void>> submit() async {
    final validation = ref
        .read(authFacadeProvider)
        .validateLogin(email: state.email, password: state.password);

    if (validation case Failure<void>(failure: final failure)) {
      state = state.copyWith(
        emailFailure: _emailFailureFor(failure),
        passwordFailure: _passwordFailureFor(failure),
      );

      return validation;
    }

    state = state.copyWith(
      isLoading: true,
      clearEmailFailure: true,
      clearPasswordFailure: true,
    );

    final result = await ref
        .read(authFacadeProvider)
        .login(email: state.email.trim(), password: state.password);

    if (result case Failure<void>()) {
      state = state.copyWith(isLoading: false);
      return result;
    }

    state = state.copyWith(isLoading: false);
    return result;
  }

  AppFailure? _emailFailureFor(AppFailure failure) {
    return switch (failure.type) {
      AppFailureType.invalidEmail => failure,
      _ => null,
    };
  }

  AppFailure? _passwordFailureFor(AppFailure failure) {
    return switch (failure.type) {
      AppFailureType.invalidPassword => failure,
      _ => null,
    };
  }
}

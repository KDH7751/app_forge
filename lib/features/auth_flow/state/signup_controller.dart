import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../modules/auth/auth.dart';

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
    this.emailFailure,
    this.passwordFailure,
    this.confirmPasswordFailure,
    this.isLoading = false,
  });

  final String email;
  final String password;
  final String confirmPassword;
  final AppFailure? emailFailure;
  final AppFailure? passwordFailure;
  final AppFailure? confirmPasswordFailure;
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
    AppFailure? emailFailure,
    AppFailure? passwordFailure,
    AppFailure? confirmPasswordFailure,
    bool? isLoading,
    bool clearEmailFailure = false,
    bool clearPasswordFailure = false,
    bool clearConfirmPasswordFailure = false,
  }) {
    return SignupControllerState(
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      emailFailure:
          clearEmailFailure ? null : (emailFailure ?? this.emailFailure),
      passwordFailure: clearPasswordFailure
          ? null
          : (passwordFailure ?? this.passwordFailure),
      confirmPasswordFailure: clearConfirmPasswordFailure
          ? null
          : (confirmPasswordFailure ?? this.confirmPasswordFailure),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// auth module 공개 facade를 호출하는 auth_flow sign-up controller.
class SignupController extends AutoDisposeNotifier<SignupControllerState> {
  @override
  SignupControllerState build() {
    return const SignupControllerState();
  }

  void updateEmail(String email) {
    state = state.copyWith(email: email, clearEmailFailure: true);
  }

  void updatePassword(String password) {
    state = state.copyWith(password: password, clearPasswordFailure: true);
  }

  void updateConfirmPassword(String confirmPassword) {
    state = state.copyWith(
      confirmPassword: confirmPassword,
      clearConfirmPasswordFailure: true,
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

    if (validation case Failure<void>(failure: final failure)) {
      state = state.copyWith(
        emailFailure: _emailFailureFor(failure),
        passwordFailure: _passwordFailureFor(failure),
        confirmPasswordFailure: _confirmPasswordFailureFor(failure),
      );

      return validation;
    }

    state = state.copyWith(
      isLoading: true,
      clearEmailFailure: true,
      clearPasswordFailure: true,
      clearConfirmPasswordFailure: true,
    );

    final result = await ref
        .read(authFacadeProvider)
        .signup(email: state.email.trim(), password: state.password);

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

  AppFailure? _confirmPasswordFailureFor(AppFailure failure) {
    return switch (failure.type) {
      AppFailureType.passwordMismatch => failure,
      _ => null,
    };
  }
}

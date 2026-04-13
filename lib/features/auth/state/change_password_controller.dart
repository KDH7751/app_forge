import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/core/app_error.dart';
import '../domain/core/result.dart';
import '../domain/models/change_password_input.dart';
import 'providers/auth_facade_provider.dart';

/// change password controller provider.
final changePasswordControllerProvider =
    AutoDisposeNotifierProvider<
      ChangePasswordController,
      ChangePasswordControllerState
    >(ChangePasswordController.new);

/// change password form 상태.
class ChangePasswordControllerState {
  const ChangePasswordControllerState({
    this.currentPassword = '',
    this.newPassword = '',
    this.confirmNewPassword = '',
    this.currentPasswordError,
    this.newPasswordError,
    this.confirmNewPasswordError,
    this.isLoading = false,
    this.isSuccess = false,
  });

  final String currentPassword;
  final String newPassword;
  final String confirmNewPassword;
  final AppError? currentPasswordError;
  final AppError? newPasswordError;
  final AppError? confirmNewPasswordError;
  final bool isLoading;
  final bool isSuccess;

  bool get canSubmit =>
      !isLoading &&
      currentPassword.isNotEmpty &&
      newPassword.isNotEmpty &&
      confirmNewPassword.isNotEmpty;

  ChangePasswordControllerState copyWith({
    String? currentPassword,
    String? newPassword,
    String? confirmNewPassword,
    AppError? currentPasswordError,
    AppError? newPasswordError,
    AppError? confirmNewPasswordError,
    bool? isLoading,
    bool? isSuccess,
    bool clearCurrentPasswordError = false,
    bool clearNewPasswordError = false,
    bool clearConfirmNewPasswordError = false,
  }) {
    return ChangePasswordControllerState(
      currentPassword: currentPassword ?? this.currentPassword,
      newPassword: newPassword ?? this.newPassword,
      confirmNewPassword: confirmNewPassword ?? this.confirmNewPassword,
      currentPasswordError: clearCurrentPasswordError
          ? null
          : (currentPasswordError ?? this.currentPasswordError),
      newPasswordError: clearNewPasswordError
          ? null
          : (newPasswordError ?? this.newPasswordError),
      confirmNewPasswordError: clearConfirmNewPasswordError
          ? null
          : (confirmNewPasswordError ?? this.confirmNewPasswordError),
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// change password submit 흐름 controller.
class ChangePasswordController
    extends AutoDisposeNotifier<ChangePasswordControllerState> {
  @override
  ChangePasswordControllerState build() {
    return const ChangePasswordControllerState();
  }

  void updateCurrentPassword(String value) {
    state = state.copyWith(
      currentPassword: value,
      isSuccess: false,
      clearCurrentPasswordError: true,
    );
  }

  void updateNewPassword(String value) {
    state = state.copyWith(
      newPassword: value,
      isSuccess: false,
      clearNewPasswordError: true,
    );
  }

  void updateConfirmNewPassword(String value) {
    state = state.copyWith(
      confirmNewPassword: value,
      isSuccess: false,
      clearConfirmNewPasswordError: true,
    );
  }

  Future<Result<void>> submit() async {
    final input = ChangePasswordInput(
      currentPassword: state.currentPassword,
      newPassword: state.newPassword,
      confirmNewPassword: state.confirmNewPassword,
    );
    final validation = ref
        .read(authFacadeProvider)
        .validateChangePassword(input);

    if (validation case Failure<void>(error: final error)) {
      state = _applyFieldError(error);

      return validation;
    }

    state = state.copyWith(
      isLoading: true,
      isSuccess: false,
      clearCurrentPasswordError: true,
      clearNewPasswordError: true,
      clearConfirmNewPasswordError: true,
    );

    final result = await ref.read(authFacadeProvider).changePassword(input);

    if (result case Failure<void>(error: final error)) {
      state = _applyFieldError(
        error,
      ).copyWith(isLoading: false, isSuccess: false);

      return result;
    }

    state = state.copyWith(
      currentPassword: '',
      newPassword: '',
      confirmNewPassword: '',
      isLoading: false,
      isSuccess: true,
      clearCurrentPasswordError: true,
      clearNewPasswordError: true,
      clearConfirmNewPasswordError: true,
    );

    return result;
  }

  ChangePasswordControllerState _applyFieldError(AppError error) {
    return state.copyWith(
      currentPasswordError: _currentPasswordErrorFor(error),
      newPasswordError: _newPasswordErrorFor(error),
      confirmNewPasswordError: _confirmPasswordErrorFor(error),
    );
  }

  AppError? _currentPasswordErrorFor(AppError error) {
    return switch (error.type) {
      AppErrorType.currentPasswordRequired => error,
      AppErrorType.wrongPassword => error,
      _ => null,
    };
  }

  AppError? _newPasswordErrorFor(AppError error) {
    return switch (error.type) {
      AppErrorType.newPasswordRequired => error,
      AppErrorType.invalidPassword => error,
      AppErrorType.weakPassword => error,
      AppErrorType.samePassword => error,
      _ => null,
    };
  }

  AppError? _confirmPasswordErrorFor(AppError error) {
    return switch (error.type) {
      AppErrorType.confirmPasswordRequired => error,
      AppErrorType.passwordMismatch => error,
      _ => null,
    };
  }
}

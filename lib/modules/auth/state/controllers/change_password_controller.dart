import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/change_password_input.dart';
import '../../../foundation/foundation.dart';
import '../providers/auth_facade_provider.dart';

/// profile 소비 UI가 auth changePassword 실행을 여는 단일 진입 controller.
///
/// 이 controller는 form 상태와 field error만 관리하고,
/// 실제 실행과 validation은 auth facade로 위임한다.
/// 성공 처리 방식이 바뀌면 profile 섹션과 관련 테스트가 함께 영향을 받는다.
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

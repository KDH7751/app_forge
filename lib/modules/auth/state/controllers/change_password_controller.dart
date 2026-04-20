import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/change_password_input.dart';
import '../../../foundation/foundation.dart';
import '../providers/auth_facade_provider.dart';

/// profile 소비 UI가 auth changePassword 실행을 여는 단일 진입 controller.
///
/// 이 controller는 form 상태와 field failure만 관리하고,
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
    this.currentPasswordFailure,
    this.newPasswordFailure,
    this.confirmNewPasswordFailure,
    this.isLoading = false,
    this.isSuccess = false,
  });

  final String currentPassword;
  final String newPassword;
  final String confirmNewPassword;
  final AppFailure? currentPasswordFailure;
  final AppFailure? newPasswordFailure;
  final AppFailure? confirmNewPasswordFailure;
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
    AppFailure? currentPasswordFailure,
    AppFailure? newPasswordFailure,
    AppFailure? confirmNewPasswordFailure,
    bool? isLoading,
    bool? isSuccess,
    bool clearCurrentPasswordFailure = false,
    bool clearNewPasswordFailure = false,
    bool clearConfirmNewPasswordFailure = false,
  }) {
    return ChangePasswordControllerState(
      currentPassword: currentPassword ?? this.currentPassword,
      newPassword: newPassword ?? this.newPassword,
      confirmNewPassword: confirmNewPassword ?? this.confirmNewPassword,
      currentPasswordFailure: clearCurrentPasswordFailure
          ? null
          : (currentPasswordFailure ?? this.currentPasswordFailure),
      newPasswordFailure: clearNewPasswordFailure
          ? null
          : (newPasswordFailure ?? this.newPasswordFailure),
      confirmNewPasswordFailure: clearConfirmNewPasswordFailure
          ? null
          : (confirmNewPasswordFailure ?? this.confirmNewPasswordFailure),
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
      clearCurrentPasswordFailure: true,
    );
  }

  void updateNewPassword(String value) {
    state = state.copyWith(
      newPassword: value,
      isSuccess: false,
      clearNewPasswordFailure: true,
    );
  }

  void updateConfirmNewPassword(String value) {
    state = state.copyWith(
      confirmNewPassword: value,
      isSuccess: false,
      clearConfirmNewPasswordFailure: true,
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

    if (validation case Failure<void>(failure: final failure)) {
      state = _applyFieldFailure(failure);

      return validation;
    }

    state = state.copyWith(
      isLoading: true,
      isSuccess: false,
      clearCurrentPasswordFailure: true,
      clearNewPasswordFailure: true,
      clearConfirmNewPasswordFailure: true,
    );

    final result = await ref.read(authFacadeProvider).changePassword(input);

    if (result case Failure<void>(failure: final failure)) {
      state = _applyFieldFailure(
        failure,
      ).copyWith(isLoading: false, isSuccess: false);

      return result;
    }

    state = state.copyWith(
      currentPassword: '',
      newPassword: '',
      confirmNewPassword: '',
      isLoading: false,
      isSuccess: true,
      clearCurrentPasswordFailure: true,
      clearNewPasswordFailure: true,
      clearConfirmNewPasswordFailure: true,
    );

    return result;
  }

  ChangePasswordControllerState _applyFieldFailure(AppFailure failure) {
    return state.copyWith(
      currentPasswordFailure: _currentPasswordFailureFor(failure),
      newPasswordFailure: _newPasswordFailureFor(failure),
      confirmNewPasswordFailure: _confirmPasswordFailureFor(failure),
    );
  }

  AppFailure? _currentPasswordFailureFor(AppFailure failure) {
    return switch (failure.type) {
      AppFailureType.currentPasswordRequired => failure,
      AppFailureType.wrongPassword => failure,
      _ => null,
    };
  }

  AppFailure? _newPasswordFailureFor(AppFailure failure) {
    return switch (failure.type) {
      AppFailureType.newPasswordRequired => failure,
      AppFailureType.invalidPassword => failure,
      AppFailureType.weakPassword => failure,
      AppFailureType.samePassword => failure,
      _ => null,
    };
  }

  AppFailure? _confirmPasswordFailureFor(AppFailure failure) {
    return switch (failure.type) {
      AppFailureType.confirmPasswordRequired => failure,
      AppFailureType.passwordMismatch => failure,
      _ => null,
    };
  }
}

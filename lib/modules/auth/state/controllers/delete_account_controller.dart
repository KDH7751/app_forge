import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/delete_account_input.dart';
import '../../domain/validation/auth_field_keys.dart';
import '../../../foundation/foundation.dart';
import '../providers/auth_facade_provider.dart';

/// profile 소비 UI가 auth deleteAccount 실행을 여는 단일 진입 controller.
///
/// dialog 바깥에서 실제 submit을 담당하며,
/// currentPassword 입력과 field failure만 유지한다.
/// 삭제 확인 UX가 바뀌면 profile delete 섹션과 함께 수정된다.
final deleteAccountControllerProvider =
    AutoDisposeNotifierProvider<
      DeleteAccountController,
      DeleteAccountControllerState
    >(DeleteAccountController.new);

/// delete account dialog 상태.
class DeleteAccountControllerState {
  const DeleteAccountControllerState({
    this.currentPassword = '',
    this.currentPasswordFailure,
    this.isLoading = false,
  });

  final String currentPassword;
  final AppFailure? currentPasswordFailure;
  final bool isLoading;

  bool get canSubmit => !isLoading && currentPassword.isNotEmpty;

  DeleteAccountControllerState copyWith({
    String? currentPassword,
    AppFailure? currentPasswordFailure,
    bool? isLoading,
    bool clearCurrentPasswordFailure = false,
  }) {
    return DeleteAccountControllerState(
      currentPassword: currentPassword ?? this.currentPassword,
      currentPasswordFailure: clearCurrentPasswordFailure
          ? currentPasswordFailure
          : (currentPasswordFailure ?? this.currentPasswordFailure),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// delete account submit 흐름 controller.
class DeleteAccountController
    extends AutoDisposeNotifier<DeleteAccountControllerState> {
  @override
  DeleteAccountControllerState build() {
    return const DeleteAccountControllerState();
  }

  void updateCurrentPassword(String value) {
    state = state.copyWith(
      currentPassword: value,
      clearCurrentPasswordFailure: true,
    );
  }

  Future<Result<void>> submit() async {
    final input = DeleteAccountInput(currentPassword: state.currentPassword);
    final validation = ref
        .read(authFacadeProvider)
        .validateDeleteAccount(input);

    if (validation case Failure<void>(failure: final failure)) {
      state = state.copyWith(
        currentPasswordFailure: _currentPasswordFailureFor(failure),
        clearCurrentPasswordFailure: true,
      );

      return validation;
    }

    state = state.copyWith(isLoading: true, clearCurrentPasswordFailure: true);

    final result = await ref.read(authFacadeProvider).deleteAccount(input);

    if (result case Failure<void>(failure: final failure)) {
      state = state.copyWith(
        isLoading: false,
        currentPasswordFailure: _currentPasswordFailureFor(failure),
        clearCurrentPasswordFailure: true,
      );

      return result;
    }

    state = state.copyWith(isLoading: false);

    return result;
  }

  AppFailure? _currentPasswordFailureFor(AppFailure failure) {
    return switch (failure.type) {
      AppFailureType.validation => failure.fieldFailure(
        AuthFailureField.currentPassword,
      ),
      AppFailureType.invalidCredentials => failure,
      _ => null,
    };
  }
}

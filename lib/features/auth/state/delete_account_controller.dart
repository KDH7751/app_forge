import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_error.dart';
import '../domain/delete_account_input.dart';
import '../domain/result.dart';
import 'auth_repository_provider.dart';

/// delete account controller provider.
final deleteAccountControllerProvider =
    AutoDisposeNotifierProvider<
      DeleteAccountController,
      DeleteAccountControllerState
    >(DeleteAccountController.new);

/// delete account dialog 상태.
class DeleteAccountControllerState {
  const DeleteAccountControllerState({
    this.currentPassword = '',
    this.currentPasswordError,
    this.isLoading = false,
  });

  final String currentPassword;
  final AppError? currentPasswordError;
  final bool isLoading;

  bool get canSubmit => !isLoading && currentPassword.isNotEmpty;

  DeleteAccountControllerState copyWith({
    String? currentPassword,
    AppError? currentPasswordError,
    bool? isLoading,
    bool clearCurrentPasswordError = false,
  }) {
    return DeleteAccountControllerState(
      currentPassword: currentPassword ?? this.currentPassword,
      currentPasswordError: clearCurrentPasswordError
          ? null
          : (currentPasswordError ?? this.currentPasswordError),
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
      clearCurrentPasswordError: true,
    );
  }

  Future<Result<void>> submit() async {
    final input = DeleteAccountInput(currentPassword: state.currentPassword);
    final validation = ref
        .read(authRepositoryProvider)
        .validateDeleteAccount(input);

    if (validation case Failure<void>(error: final error)) {
      state = state.copyWith(
        currentPasswordError: _currentPasswordErrorFor(error),
      );

      return validation;
    }

    state = state.copyWith(isLoading: true, clearCurrentPasswordError: true);

    final result = await ref.read(authRepositoryProvider).deleteAccount(input);

    if (result case Failure<void>(error: final error)) {
      state = state.copyWith(
        isLoading: false,
        currentPasswordError: _currentPasswordErrorFor(error),
      );

      return result;
    }

    state = state.copyWith(isLoading: false);

    return result;
  }

  AppError? _currentPasswordErrorFor(AppError error) {
    return switch (error.type) {
      AppErrorType.currentPasswordRequired => error,
      AppErrorType.wrongPassword => error,
      _ => null,
    };
  }
}

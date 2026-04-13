import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_forge/features/auth/domain/core/app_error.dart';
import 'package:app_forge/features/auth/domain/auth_facade.dart';
import 'package:app_forge/features/auth/domain/core/result.dart';
import 'package:app_forge/features/auth/domain/models/change_password_input.dart';
import 'package:app_forge/features/auth/domain/models/delete_account_input.dart';
import 'package:app_forge/features/auth/state/providers/auth_facade_provider.dart';
import 'package:app_forge/features/auth/state/change_password_controller.dart';

void main() {
  test(
    'changePassword controller maps wrongPassword failure to current field',
    () async {
      final container = ProviderContainer(
        overrides: <Override>[
          authFacadeProvider.overrideWithValue(
            _ControllerFakeAuthFacade(
              changePasswordResult: const Result<void>.failure(
                AppError.wrongPassword,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        changePasswordControllerProvider.notifier,
      );
      controller.updateCurrentPassword('password123');
      controller.updateNewPassword('newpassword123');
      controller.updateConfirmNewPassword('newpassword123');

      final result = await controller.submit();
      final state = container.read(changePasswordControllerProvider);

      expect(result, isA<Failure<void>>());
      expect(state.currentPasswordError?.type, AppErrorType.wrongPassword);
      expect(state.newPasswordError, isNull);
      expect(state.confirmNewPasswordError, isNull);
    },
  );

  test(
    'changePassword controller clears password fields after success',
    () async {
      final container = ProviderContainer(
        overrides: <Override>[
          authFacadeProvider.overrideWithValue(
            _ControllerFakeAuthFacade(
              changePasswordResult: const Result<void>.success(null),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(
        changePasswordControllerProvider.notifier,
      );
      controller.updateCurrentPassword('password123');
      controller.updateNewPassword('newpassword123');
      controller.updateConfirmNewPassword('newpassword123');

      final result = await controller.submit();
      final state = container.read(changePasswordControllerProvider);

      expect(result, isA<Success<void>>());
      expect(state.currentPassword, isEmpty);
      expect(state.newPassword, isEmpty);
      expect(state.confirmNewPassword, isEmpty);
      expect(state.currentPasswordError, isNull);
      expect(state.newPasswordError, isNull);
      expect(state.confirmNewPasswordError, isNull);
      expect(state.isSuccess, isTrue);
    },
  );
}

class _ControllerFakeAuthFacade implements AuthFacade {
  _ControllerFakeAuthFacade({required this.changePasswordResult});

  final Result<void> changePasswordResult;

  @override
  Future<Result<void>> changePassword(ChangePasswordInput input) async {
    return changePasswordResult;
  }

  @override
  Future<Result<void>> deleteAccount(DeleteAccountInput input) async {
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> login({
    required String email,
    required String password,
  }) async {
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> logout() async {
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> sendPasswordResetEmail({required String email}) async {
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> signup({
    required String email,
    required String password,
  }) async {
    return const Result<void>.success(null);
  }

  @override
  Result<void> validateChangePassword(ChangePasswordInput input) {
    return const Result<void>.success(null);
  }

  @override
  Result<void> validateDeleteAccount(DeleteAccountInput input) {
    return const Result<void>.success(null);
  }

  @override
  Result<void> validateLogin({
    required String email,
    required String password,
  }) {
    return const Result<void>.success(null);
  }

  @override
  Result<void> validateReset({required String email}) {
    return const Result<void>.success(null);
  }

  @override
  Result<void> validateSignup({
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    return const Result<void>.success(null);
  }
}

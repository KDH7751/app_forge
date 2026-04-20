// ignore_for_file: avoid_relative_lib_imports

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/modules/auth/auth.dart';

void main() {
  test(
    'changePassword controller maps invalidCredentials failure to current field',
    () async {
      final container = ProviderContainer(
        overrides: <Override>[
          authFacadeProvider.overrideWithValue(
            _ControllerFakeAuthFacade(
              changePasswordResult: const Result<void>.failure(
                AppFailure.invalidCredentials,
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
      expect(
        state.currentPasswordFailure?.type,
        AppFailureType.invalidCredentials,
      );
      expect(state.newPasswordFailure, isNull);
      expect(state.confirmNewPasswordFailure, isNull);
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
      expect(state.currentPasswordFailure, isNull);
      expect(state.newPasswordFailure, isNull);
      expect(state.confirmNewPasswordFailure, isNull);
      expect(state.isSuccess, isTrue);
    },
  );

  test(
    'changePassword controller maps validation fieldErrors to new password field',
    () async {
      final container = ProviderContainer(
        overrides: <Override>[
          authFacadeProvider.overrideWithValue(
            _ControllerFakeAuthFacade(
              changePasswordResult: const Result<void>.failure(
                AppFailure.validation(
                  fieldErrors: <String, ValidationFieldError>{
                    AuthFailureField.newPassword: ValidationFieldError.tooWeak,
                  },
                ),
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
      controller.updateNewPassword('short');
      controller.updateConfirmNewPassword('short');

      final result = await controller.submit();
      final state = container.read(changePasswordControllerProvider);

      expect(result, isA<Failure<void>>());
      expect(state.currentPasswordFailure, isNull);
      expect(state.newPasswordFailure?.type, AppFailureType.validation);
      expect(
        state.newPasswordFailure
            ?.fieldError(AuthFailureField.newPassword)
            ?.type,
        ValidationFieldErrorType.tooWeak,
      );
      expect(state.confirmNewPasswordFailure, isNull);
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

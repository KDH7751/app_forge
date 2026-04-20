// ignore_for_file: avoid_relative_lib_imports

import 'package:flutter_test/flutter_test.dart';

import '../lib/modules/auth/auth.dart';

void main() {
  group('validateChangePasswordInput', () {
    test('rejects same password reuse', () {
      final result = validateChangePasswordInput(
        const ChangePasswordInput(
          currentPassword: 'password123',
          newPassword: 'password123',
          confirmNewPassword: 'password123',
        ),
      );

      expect(result, isA<Failure<void>>());
      final failure = (result as Failure<void>).failure;

      expect(failure.type, AppFailureType.validation);
      expect(
        failure.fieldError(AuthFailureField.newPassword)?.type,
        ValidationFieldErrorType.sameValue,
      );
    });

    test('rejects missing confirm password separately', () {
      final result = validateChangePasswordInput(
        const ChangePasswordInput(
          currentPassword: 'password123',
          newPassword: 'newpassword123',
          confirmNewPassword: '',
        ),
      );

      expect(result, isA<Failure<void>>());
      final failure = (result as Failure<void>).failure;

      expect(failure.type, AppFailureType.validation);
      expect(
        failure.fieldError(AuthFailureField.confirmNewPassword)?.type,
        ValidationFieldErrorType.required,
      );
    });
  });

  group('validateDeleteAccountInput', () {
    test('requires reauth password input', () {
      final result = validateDeleteAccountInput(
        const DeleteAccountInput(currentPassword: ''),
      );

      expect(result, isA<Failure<void>>());
      final failure = (result as Failure<void>).failure;

      expect(failure.type, AppFailureType.validation);
      expect(
        failure.fieldError(AuthFailureField.currentPassword)?.type,
        ValidationFieldErrorType.required,
      );
    });
  });
}

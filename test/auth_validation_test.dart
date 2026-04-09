import 'package:flutter_test/flutter_test.dart';

import 'package:app_forge/features/auth/domain/app_error.dart';
import 'package:app_forge/features/auth/domain/auth_validation.dart';
import 'package:app_forge/features/auth/domain/change_password_input.dart';
import 'package:app_forge/features/auth/domain/delete_account_input.dart';
import 'package:app_forge/features/auth/domain/result.dart';

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
      expect((result as Failure<void>).error.type, AppErrorType.samePassword);
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
      expect(
        (result as Failure<void>).error.type,
        AppErrorType.confirmPasswordRequired,
      );
    });
  });

  group('validateDeleteAccountInput', () {
    test('requires reauth password input', () {
      final result = validateDeleteAccountInput(
        const DeleteAccountInput(currentPassword: ''),
      );

      expect(result, isA<Failure<void>>());
      expect(
        (result as Failure<void>).error.type,
        AppErrorType.currentPasswordRequired,
      );
    });
  });
}

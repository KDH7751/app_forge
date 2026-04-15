// ignore_for_file: avoid_relative_lib_imports

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/features/profile/ui/change_password_section.dart';
import '../lib/modules/auth/auth.dart';

void main() {
  testWidgets(
    'change password section clears controller state and input UI after success',
    (tester) async {
      final container = ProviderContainer(
        overrides: <Override>[
          authFacadeProvider.overrideWithValue(
            _FakeAuthFacade(
              changePasswordResult: const Result<void>.success(null),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: ChangePasswordSection()),
          ),
        ),
      );

      final fields = find.byType(TextField);

      await tester.enterText(fields.at(0), 'current-password');
      await tester.enterText(fields.at(1), 'new-password-123');
      await tester.enterText(fields.at(2), 'new-password-123');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Change password'));
      await tester.pumpAndSettle();

      final state = container.read(changePasswordControllerProvider);
      final currentField = tester.widget<TextField>(fields.at(0));
      final newField = tester.widget<TextField>(fields.at(1));
      final confirmField = tester.widget<TextField>(fields.at(2));

      expect(state.currentPassword, isEmpty);
      expect(state.newPassword, isEmpty);
      expect(state.confirmNewPassword, isEmpty);
      expect(state.isSuccess, isTrue);
      expect(currentField.controller?.text, isEmpty);
      expect(newField.controller?.text, isEmpty);
      expect(confirmField.controller?.text, isEmpty);
      expect(find.text('비밀번호를 변경했습니다.'), findsOneWidget);
    },
  );
}

class _FakeAuthFacade implements AuthFacade {
  _FakeAuthFacade({required this.changePasswordResult});

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

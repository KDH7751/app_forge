// ignore_for_file: avoid_relative_lib_imports

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/features/profile/ui/delete_account_section.dart';
import '../lib/modules/auth/auth.dart';
import '../lib/modules/feedback/feedback.dart';

void main() {
  testWidgets(
    'delete account local-only failure stays on confirm dialog path without root snackbar fallback',
    (tester) async {
      final container = ProviderContainer(
        overrides: <Override>[
          authFacadeProvider.overrideWithValue(
            _DeleteFailureAuthFacade(
              deleteAccountResult: const Result<void>.failure(
                AppFailure.invalidCredentials,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(_buildDeleteSection(container));

      await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Current password'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      expect(
        container
            .read(feedbackControllerProvider)
            .activeFor(FeedbackChannel.snackbar),
        isNull,
      );
    },
  );
}

Widget _buildDeleteSection(ProviderContainer container) {
  final navigatorKey = GlobalKey<NavigatorState>();

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      navigatorKey: navigatorKey,
      home: FeedbackHost(
        navigatorKey: navigatorKey,
        child: const Scaffold(body: DeleteAccountSection()),
      ),
    ),
  );
}

class _DeleteFailureAuthFacade implements AuthFacade {
  _DeleteFailureAuthFacade({required this.deleteAccountResult});

  final Result<void> deleteAccountResult;

  @override
  Future<Result<void>> changePassword(ChangePasswordInput input) async {
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> deleteAccount(DeleteAccountInput input) async {
    return deleteAccountResult;
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
    if (input.currentPassword.isEmpty) {
      return const Result<void>.failure(
        AppFailure.validation(
          fieldErrors: <String, ValidationFieldError>{
            AuthFailureField.currentPassword: ValidationFieldError.required,
          },
        ),
      );
    }

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

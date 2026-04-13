import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/actions/firebase_change_password_action.dart';
import '../../data/actions/firebase_delete_account_action.dart';
import '../../data/actions/firebase_login_action.dart';
import '../../data/actions/firebase_logout_action.dart';
import '../../data/actions/firebase_reset_password_action.dart';
import '../../data/actions/firebase_signup_action.dart';
import '../../domain/actions/change_password_action.dart';
import '../../domain/actions/delete_account_action.dart';
import '../../domain/actions/login_action.dart';
import '../../domain/actions/logout_action.dart';
import '../../domain/actions/reset_password_action.dart';
import '../../domain/actions/signup_action.dart';
import 'auth_app_input_provider.dart';
import 'auth_runtime_provider.dart';

/// login action assembly provider.
final loginActionProvider = Provider<LoginAction?>((ref) {
  final authInput = ref.watch(authAppInputProvider);

  if (!authInput.capabilities.loginConnected) {
    return null;
  }

  switch (authInput.backendFamily) {
    case AuthBackendFamily.firebase:
      return FirebaseLoginAction(
        firebaseAuth: ref.watch(firebaseAuthProvider),
        usersDataSource: ref.watch(usersDocumentDataSourceProvider),
        logger: ref.watch(authLoggerProvider),
      );
  }
});

/// signup action assembly provider.
final signupActionProvider = Provider<SignupAction?>((ref) {
  final authInput = ref.watch(authAppInputProvider);

  if (!authInput.capabilities.signupConnected) {
    return null;
  }

  switch (authInput.backendFamily) {
    case AuthBackendFamily.firebase:
      return FirebaseSignupAction(
        firebaseAuth: ref.watch(firebaseAuthProvider),
        usersDataSource: ref.watch(usersDocumentDataSourceProvider),
        logger: ref.watch(authLoggerProvider),
      );
  }
});

/// reset password action assembly provider.
final resetPasswordActionProvider = Provider<ResetPasswordAction?>((ref) {
  final authInput = ref.watch(authAppInputProvider);

  if (!authInput.capabilities.resetPasswordConnected) {
    return null;
  }

  switch (authInput.backendFamily) {
    case AuthBackendFamily.firebase:
      return FirebaseResetPasswordAction(
        firebaseAuth: ref.watch(firebaseAuthProvider),
        logger: ref.watch(authLoggerProvider),
      );
  }
});

/// change password action assembly provider.
final changePasswordActionProvider = Provider<ChangePasswordAction?>((ref) {
  final authInput = ref.watch(authAppInputProvider);

  if (!authInput.capabilities.changePasswordConnected) {
    return null;
  }

  switch (authInput.backendFamily) {
    case AuthBackendFamily.firebase:
      return FirebaseChangePasswordAction(
        firebaseAuth: ref.watch(firebaseAuthProvider),
        logger: ref.watch(authLoggerProvider),
      );
  }
});

/// delete account action assembly provider.
final deleteAccountActionProvider = Provider<DeleteAccountAction?>((ref) {
  final authInput = ref.watch(authAppInputProvider);

  if (!authInput.capabilities.deleteAccountConnected) {
    return null;
  }

  switch (authInput.backendFamily) {
    case AuthBackendFamily.firebase:
      return FirebaseDeleteAccountAction(
        firebaseAuth: ref.watch(firebaseAuthProvider),
        usersDataSource: ref.watch(usersDocumentDataSourceProvider),
        logger: ref.watch(authLoggerProvider),
      );
  }
});

/// logout action assembly provider.
final logoutActionProvider = Provider<LogoutAction>((ref) {
  final authInput = ref.watch(authAppInputProvider);

  switch (authInput.backendFamily) {
    case AuthBackendFamily.firebase:
      return FirebaseLogoutAction(
        firebaseAuth: ref.watch(firebaseAuthProvider),
        logger: ref.watch(authLoggerProvider),
      );
  }
});

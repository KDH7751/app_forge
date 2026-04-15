import '../../../foundation/foundation.dart';
import '../models/change_password_input.dart';
import '../models/delete_account_input.dart';

/// login submit validation.
Result<void> validateLoginInput({
  required String email,
  required String password,
}) {
  final normalizedEmail = email.trim();

  if (!_isValidEmail(normalizedEmail)) {
    return const Result<void>.failure(AppError.invalidEmail);
  }

  if (!_isValidPassword(password)) {
    return const Result<void>.failure(AppError.invalidPassword);
  }

  return const Result<void>.success(null);
}

/// signup submit validation.
Result<void> validateSignupInput({
  required String email,
  required String password,
  required String confirmPassword,
}) {
  final emailValidation = validateResetInput(email: email);

  if (emailValidation is Failure<void>) {
    return emailValidation;
  }

  if (!_isValidPassword(password)) {
    return const Result<void>.failure(AppError.invalidPassword);
  }

  if (password != confirmPassword) {
    return const Result<void>.failure(AppError.passwordMismatch);
  }

  return const Result<void>.success(null);
}

/// reset submit validation.
Result<void> validateResetInput({required String email}) {
  if (!_isValidEmail(email.trim())) {
    return const Result<void>.failure(AppError.invalidEmail);
  }

  return const Result<void>.success(null);
}

/// change password submit validation.
Result<void> validateChangePasswordInput(ChangePasswordInput input) {
  if (input.currentPassword.trim().isEmpty) {
    return const Result<void>.failure(AppError.currentPasswordRequired);
  }

  if (input.newPassword.trim().isEmpty) {
    return const Result<void>.failure(AppError.newPasswordRequired);
  }

  if (!_isValidPassword(input.newPassword)) {
    return const Result<void>.failure(AppError.invalidPassword);
  }

  if (input.confirmNewPassword.trim().isEmpty) {
    return const Result<void>.failure(AppError.confirmPasswordRequired);
  }

  if (input.newPassword != input.confirmNewPassword) {
    return const Result<void>.failure(AppError.passwordMismatch);
  }

  if (input.currentPassword == input.newPassword) {
    return const Result<void>.failure(AppError.samePassword);
  }

  return const Result<void>.success(null);
}

/// delete account submit validation.
Result<void> validateDeleteAccountInput(DeleteAccountInput input) {
  if (input.currentPassword.trim().isEmpty) {
    return const Result<void>.failure(AppError.currentPasswordRequired);
  }

  return const Result<void>.success(null);
}

bool _isValidEmail(String email) {
  return RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  ).hasMatch(email);
}

bool _isValidPassword(String password) {
  return password.length >= 8;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/actions/change_password_action.dart';
import '../../domain/actions/delete_account_action.dart';
import '../../domain/actions/login_action.dart';
import '../../domain/actions/logout_action.dart';
import '../../domain/actions/reset_password_action.dart';
import '../../domain/actions/signup_action.dart';
import 'auth_assembly_provider.dart';
import 'auth_setup_provider.dart';

/// login action assembly provider.
final loginActionProvider = Provider<LoginAction?>((ref) {
  final setup = ref.watch(authSetupProvider);
  final assembly = ref.watch(authAssemblyProvider);

  if (!_isCapabilityEnabled(
    assembly: assembly,
    policy: setup.policy,
    capability: AuthCapability.login,
  )) {
    return null;
  }

  return assembly.loginAction;
});

/// signup action assembly provider.
final signupActionProvider = Provider<SignupAction?>((ref) {
  final setup = ref.watch(authSetupProvider);
  final assembly = ref.watch(authAssemblyProvider);

  if (!_isCapabilityEnabled(
    assembly: assembly,
    policy: setup.policy,
    capability: AuthCapability.signup,
  )) {
    return null;
  }

  return assembly.signupAction;
});

/// reset password action assembly provider.
final resetPasswordActionProvider = Provider<ResetPasswordAction?>((ref) {
  final setup = ref.watch(authSetupProvider);
  final assembly = ref.watch(authAssemblyProvider);

  if (!_isCapabilityEnabled(
    assembly: assembly,
    policy: setup.policy,
    capability: AuthCapability.sendPasswordResetEmail,
  )) {
    return null;
  }

  return assembly.resetPasswordAction;
});

/// change password action assembly provider.
final changePasswordActionProvider = Provider<ChangePasswordAction?>((ref) {
  final setup = ref.watch(authSetupProvider);
  final assembly = ref.watch(authAssemblyProvider);

  if (!_isCapabilityEnabled(
    assembly: assembly,
    policy: setup.policy,
    capability: AuthCapability.changePassword,
  )) {
    return null;
  }

  return assembly.changePasswordAction;
});

/// delete account action assembly provider.
final deleteAccountActionProvider = Provider<DeleteAccountAction?>((ref) {
  final setup = ref.watch(authSetupProvider);
  final assembly = ref.watch(authAssemblyProvider);

  if (!_isCapabilityEnabled(
    assembly: assembly,
    policy: setup.policy,
    capability: AuthCapability.deleteAccount,
  )) {
    return null;
  }

  return assembly.deleteAccountAction;
});

/// logout action assembly provider.
final logoutActionProvider = Provider<LogoutAction>((ref) {
  return ref.watch(authAssemblyProvider).logoutAction;
});

bool _isCapabilityEnabled({
  required AuthSetAssembly assembly,
  required AuthActivationPolicy policy,
  required AuthCapability capability,
}) {
  return assembly.supportedCapabilities.contains(capability) &&
      !policy.disables(capability);
}

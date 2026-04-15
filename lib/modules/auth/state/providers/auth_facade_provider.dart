import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/auth_facade.dart';
import '../../domain/models/change_password_input.dart';
import '../../domain/models/delete_account_input.dart';
import '../../../foundation/foundation.dart';
import 'auth_action_provider.dart';
import 'auth_recovery_provider.dart';

/// auth facade 조립 provider.
final authFacadeProvider = Provider<AuthFacade>((ref) {
  return _RecoveryAwareAuthFacade(
    inner: DefaultAuthFacade(
      loginAction: ref.watch(loginActionProvider),
      signupAction: ref.watch(signupActionProvider),
      resetPasswordAction: ref.watch(resetPasswordActionProvider),
      changePasswordAction: ref.watch(changePasswordActionProvider),
      deleteAccountAction: ref.watch(deleteAccountActionProvider),
      logoutAction: ref.watch(logoutActionProvider),
    ),
    recoveryCount: ref.watch(authRecoveryCountProvider.notifier),
  );
});

/// login/signup 이후 session recovery hold를 module 내부에서만 감싼다.
class _RecoveryAwareAuthFacade implements AuthFacade {
  const _RecoveryAwareAuthFacade({
    required AuthFacade inner,
    required StateController<int> recoveryCount,
  }) : _inner = inner,
       _recoveryCount = recoveryCount;

  final AuthFacade _inner;
  final StateController<int> _recoveryCount;

  @override
  Future<Result<void>> login({
    required String email,
    required String password,
  }) async {
    _recoveryCount.state += 1;

    try {
      return await _inner.login(email: email, password: password);
    } finally {
      _recoveryCount.state -= 1;
    }
  }

  @override
  Future<Result<void>> signup({
    required String email,
    required String password,
  }) async {
    _recoveryCount.state += 1;

    try {
      return await _inner.signup(email: email, password: password);
    } finally {
      _recoveryCount.state -= 1;
    }
  }

  @override
  Future<Result<void>> logout() {
    return _inner.logout();
  }

  @override
  Future<Result<void>> sendPasswordResetEmail({required String email}) {
    return _inner.sendPasswordResetEmail(email: email);
  }

  @override
  Future<Result<void>> changePassword(ChangePasswordInput input) {
    return _inner.changePassword(input);
  }

  @override
  Future<Result<void>> deleteAccount(DeleteAccountInput input) {
    return _inner.deleteAccount(input);
  }

  @override
  Result<void> validateLogin({
    required String email,
    required String password,
  }) {
    return _inner.validateLogin(email: email, password: password);
  }

  @override
  Result<void> validateSignup({
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    return _inner.validateSignup(
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
  }

  @override
  Result<void> validateReset({required String email}) {
    return _inner.validateReset(email: email);
  }

  @override
  Result<void> validateChangePassword(ChangePasswordInput input) {
    return _inner.validateChangePassword(input);
  }

  @override
  Result<void> validateDeleteAccount(DeleteAccountInput input) {
    return _inner.validateDeleteAccount(input);
  }
}

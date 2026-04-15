import 'actions/change_password_action.dart';
import 'actions/delete_account_action.dart';
import 'actions/login_action.dart';
import 'actions/logout_action.dart';
import 'actions/reset_password_action.dart';
import 'actions/signup_action.dart';
import 'models/change_password_input.dart';
import 'models/delete_account_input.dart';
import 'validation/auth_validation.dart';
import '../../foundation/foundation.dart';

/// auth 공통 표면.
abstract interface class AuthFacade {
  /// 이메일/비밀번호 login 수행.
  Future<Result<void>> login({required String email, required String password});

  /// 이메일/비밀번호 signup 수행.
  Future<Result<void>> signup({
    required String email,
    required String password,
  });

  /// 현재 세션 logout 수행.
  Future<Result<void>> logout();

  /// 비밀번호 재설정 이메일 발송.
  Future<Result<void>> sendPasswordResetEmail({required String email});

  /// 인증된 사용자 비밀번호 변경 수행.
  Future<Result<void>> changePassword(ChangePasswordInput input);

  /// 인증된 사용자 계정 삭제 수행.
  Future<Result<void>> deleteAccount(DeleteAccountInput input);

  /// login submit validation.
  Result<void> validateLogin({required String email, required String password});

  /// signup submit validation.
  Result<void> validateSignup({
    required String email,
    required String password,
    required String confirmPassword,
  });

  /// reset submit validation.
  Result<void> validateReset({required String email});

  /// change password submit validation.
  Result<void> validateChangePassword(ChangePasswordInput input);

  /// delete account submit validation.
  Result<void> validateDeleteAccount(DeleteAccountInput input);
}

/// action 조립 결과를 감싸는 기본 facade 구현.
class DefaultAuthFacade implements AuthFacade {
  const DefaultAuthFacade({
    required LoginAction? loginAction,
    required SignupAction? signupAction,
    required ResetPasswordAction? resetPasswordAction,
    required ChangePasswordAction? changePasswordAction,
    required DeleteAccountAction? deleteAccountAction,
    required LogoutAction logoutAction,
  }) : _loginAction = loginAction,
       _signupAction = signupAction,
       _resetPasswordAction = resetPasswordAction,
       _changePasswordAction = changePasswordAction,
       _deleteAccountAction = deleteAccountAction,
       _logoutAction = logoutAction;

  final LoginAction? _loginAction;
  final SignupAction? _signupAction;
  final ResetPasswordAction? _resetPasswordAction;
  final ChangePasswordAction? _changePasswordAction;
  final DeleteAccountAction? _deleteAccountAction;
  final LogoutAction _logoutAction;

  @override
  Future<Result<void>> login({
    required String email,
    required String password,
  }) {
    final action = _requireConnectedAction(_loginAction, 'login');

    return action.execute(email: email, password: password);
  }

  @override
  Future<Result<void>> signup({
    required String email,
    required String password,
  }) {
    final action = _requireConnectedAction(_signupAction, 'signup');

    return action.execute(email: email, password: password);
  }

  @override
  Future<Result<void>> logout() {
    return _logoutAction.execute();
  }

  @override
  Future<Result<void>> sendPasswordResetEmail({required String email}) {
    final action = _requireConnectedAction(
      _resetPasswordAction,
      'sendPasswordResetEmail',
    );

    return action.execute(email: email);
  }

  @override
  Future<Result<void>> changePassword(ChangePasswordInput input) {
    final action = _requireConnectedAction(
      _changePasswordAction,
      'changePassword',
    );

    return action.execute(input);
  }

  @override
  Future<Result<void>> deleteAccount(DeleteAccountInput input) {
    final action = _requireConnectedAction(
      _deleteAccountAction,
      'deleteAccount',
    );

    return action.execute(input);
  }

  @override
  Result<void> validateLogin({
    required String email,
    required String password,
  }) {
    return validateLoginInput(email: email, password: password);
  }

  @override
  Result<void> validateSignup({
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    return validateSignupInput(
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
  }

  @override
  Result<void> validateReset({required String email}) {
    return validateResetInput(email: email);
  }

  @override
  Result<void> validateChangePassword(ChangePasswordInput input) {
    return validateChangePasswordInput(input);
  }

  @override
  Result<void> validateDeleteAccount(DeleteAccountInput input) {
    return validateDeleteAccountInput(input);
  }

  T _requireConnectedAction<T>(T? action, String actionName) {
    if (action == null) {
      throw StateError(
        'Auth capability `$actionName` is not connected in the current app '
        'configuration.',
      );
    }

    return action;
  }
}

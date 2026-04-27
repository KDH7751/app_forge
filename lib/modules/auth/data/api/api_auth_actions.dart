import '../../../foundation/foundation.dart';
import '../../domain/actions/change_password_action.dart';
import '../../domain/actions/delete_account_action.dart';
import '../../domain/actions/login_action.dart';
import '../../domain/actions/logout_action.dart';
import '../../domain/actions/reset_password_action.dart';
import '../../domain/actions/signup_action.dart';
import '../../domain/auth_logger.dart';
import '../../domain/models/change_password_input.dart';
import '../../domain/models/delete_account_input.dart';
import 'api_auth_client.dart';
import 'api_auth_failure_mapper.dart';
import 'api_auth_models.dart';

/// API-style login action.
class ApiLoginAction implements LoginAction {
  const ApiLoginAction({
    required ApiAuthClient client,
    required AuthLogger logger,
  }) : _client = client,
       _logger = logger;

  final ApiAuthClient _client;
  final AuthLogger _logger;

  @override
  Future<Result<void>> execute({
    required String email,
    required String password,
  }) async {
    _logger.info('auth.api.login.start');

    try {
      final response = await _client.login(
        ApiAuthLoginRequest(email: email, password: password),
      );

      final result = _resultFromResponse(
        response,
        context: ApiAuthActionContext.login,
      );
      if (result.isSuccess) {
        _logger.info('auth.api.login.success');
      }

      return result;
    } catch (error, stackTrace) {
      _logger.error(
        'auth.api.login.failed.unknown',
        error: error,
        stackTrace: stackTrace,
      );

      return const Result<void>.failure(AppFailure.unknown);
    }
  }
}

/// API-style signup action.
class ApiSignupAction implements SignupAction {
  const ApiSignupAction({
    required ApiAuthClient client,
    required AuthLogger logger,
  }) : _client = client,
       _logger = logger;

  final ApiAuthClient _client;
  final AuthLogger _logger;

  @override
  Future<Result<void>> execute({
    required String email,
    required String password,
  }) async {
    _logger.info('auth.api.signup.start');

    try {
      final response = await _client.signup(
        ApiAuthSignupRequest(email: email, password: password),
      );

      final result = _resultFromResponse(
        response,
        context: ApiAuthActionContext.signup,
      );
      if (result.isSuccess) {
        _logger.info('auth.api.signup.success');
      }

      return result;
    } catch (error, stackTrace) {
      _logger.error(
        'auth.api.signup.failed.unknown',
        error: error,
        stackTrace: stackTrace,
      );

      return const Result<void>.failure(AppFailure.unknown);
    }
  }
}

/// API-style password reset action.
class ApiResetPasswordAction implements ResetPasswordAction {
  const ApiResetPasswordAction({
    required ApiAuthClient client,
    required AuthLogger logger,
  }) : _client = client,
       _logger = logger;

  final ApiAuthClient _client;
  final AuthLogger _logger;

  @override
  Future<Result<void>> execute({required String email}) async {
    _logger.info('auth.api.reset-password.start');

    try {
      final response = await _client.sendPasswordResetEmail(
        ApiAuthResetPasswordRequest(email: email),
      );

      final result = _resultFromResponse(
        response,
        context: ApiAuthActionContext.resetPassword,
      );
      if (result.isSuccess) {
        _logger.info('auth.api.reset-password.success');
      }

      return result;
    } catch (error, stackTrace) {
      _logger.error(
        'auth.api.reset-password.failed.unknown',
        error: error,
        stackTrace: stackTrace,
      );

      return const Result<void>.failure(AppFailure.unknown);
    }
  }
}

/// API-style change password action.
class ApiChangePasswordAction implements ChangePasswordAction {
  const ApiChangePasswordAction({
    required ApiAuthClient client,
    required AuthLogger logger,
  }) : _client = client,
       _logger = logger;

  final ApiAuthClient _client;
  final AuthLogger _logger;

  @override
  Future<Result<void>> execute(ChangePasswordInput input) async {
    _logger.info('auth.api.change-password.start');

    try {
      final response = await _client.changePassword(
        ApiAuthChangePasswordRequest(
          currentPassword: input.currentPassword,
          newPassword: input.newPassword,
        ),
      );

      final result = _resultFromResponse(
        response,
        context: ApiAuthActionContext.changePassword,
      );
      if (result.isSuccess) {
        _logger.info('auth.api.change-password.success');
      }

      return result;
    } catch (error, stackTrace) {
      _logger.error(
        'auth.api.change-password.failed.unknown',
        error: error,
        stackTrace: stackTrace,
      );

      return const Result<void>.failure(AppFailure.unknown);
    }
  }
}

/// API-style delete account action.
class ApiDeleteAccountAction implements DeleteAccountAction {
  const ApiDeleteAccountAction({
    required ApiAuthClient client,
    required AuthLogger logger,
  }) : _client = client,
       _logger = logger;

  final ApiAuthClient _client;
  final AuthLogger _logger;

  @override
  Future<Result<void>> execute(DeleteAccountInput input) async {
    _logger.info('auth.api.delete-account.start');

    try {
      final response = await _client.deleteAccount(
        ApiAuthDeleteAccountRequest(currentPassword: input.currentPassword),
      );

      final result = _resultFromResponse(
        response,
        context: ApiAuthActionContext.deleteAccount,
      );
      if (result.isSuccess) {
        _logger.info('auth.api.delete-account.success');
      }

      return result;
    } catch (error, stackTrace) {
      _logger.error(
        'auth.api.delete-account.failed.unknown',
        error: error,
        stackTrace: stackTrace,
      );

      return const Result<void>.failure(AppFailure.unknown);
    }
  }
}

/// API-style logout action.
class ApiLogoutAction implements LogoutAction {
  const ApiLogoutAction({
    required ApiAuthClient client,
    required AuthLogger logger,
  }) : _client = client,
       _logger = logger;

  final ApiAuthClient _client;
  final AuthLogger _logger;

  @override
  Future<Result<void>> execute() async {
    _logger.info('auth.api.logout.start');

    try {
      final response = await _client.logout();

      final result = _resultFromResponse(
        response,
        context: ApiAuthActionContext.logout,
      );
      if (result.isSuccess) {
        _logger.info('auth.api.logout.success');
      }

      return result;
    } catch (error, stackTrace) {
      _logger.error(
        'auth.api.logout.failed.unknown',
        error: error,
        stackTrace: stackTrace,
      );

      return const Result<void>.failure(AppFailure.unknown);
    }
  }
}

Result<void> _resultFromResponse<T>(
  ApiAuthResponse<T> response, {
  required ApiAuthActionContext context,
}) {
  if (response.isSuccess) {
    return const Result<void>.success(null);
  }

  return Result<void>.failure(mapApiAuthFailure(response, context: context));
}

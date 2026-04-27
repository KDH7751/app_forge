import '../../../foundation/foundation.dart';
import '../../domain/session/auth_session.dart';
import '../../domain/validation/auth_field_keys.dart';
import '../../state/providers/auth_session_models.dart';
import '../datasources/users_document_datasource.dart';
import 'api_auth_models.dart';

/// API auth action context.
enum ApiAuthActionContext {
  login,
  signup,
  resetPassword,
  changePassword,
  deleteAccount,
  logout,
}

/// Maps an API-style auth response into the public AppFailure contract.
AppFailure mapApiAuthFailure<T>(
  ApiAuthResponse<T> response, {
  required ApiAuthActionContext context,
}) {
  final code = response.error?.code;

  if (response.status == 0 || code == 'network_error') {
    return AppFailure.network;
  }

  if (response.status == 503 || code == 'service_unavailable') {
    return AppFailure.unavailable;
  }

  if (response.status == 429 || code == 'rate_limited') {
    return AppFailure.rateLimited;
  }

  return switch (code) {
    'invalid_credentials' => AppFailure.invalidCredentials,
    'missing_account' => _missingAccountFailure(context),
    'blocked_user' || 'disabled_user' => AppFailure.unauthorized,
    'email_already_exists' => AppFailure.conflict,
    'permission_denied' => AppFailure.permissionDenied,
    'weak_password' => const AppFailure.validation(
      fieldErrors: <String, ValidationFieldError>{
        AuthFailureField.password: ValidationFieldError.tooWeak,
      },
    ),
    'invalid_email' => const AppFailure.validation(
      fieldErrors: <String, ValidationFieldError>{
        AuthFailureField.email: ValidationFieldError.invalid,
      },
    ),
    _ => _statusFailure(response.status, context),
  };
}

/// Maps a successful API session body into the public Authenticated payload.
Authenticated? mapApiSessionResponse(
  ApiAuthResponse<ApiAuthUserBody> response,
) {
  final body = response.body;

  if (!response.isSuccess || body == null) {
    return null;
  }

  return Authenticated(uid: body.uid, email: body.email);
}

/// Maps API account-state responses into the existing raw server-state fact.
UserDocumentServerState mapApiAccountStateResponse(
  ApiAuthResponse<ApiAuthAccountStateBody> response,
) {
  final body = response.body;

  if (response.isSuccess && body != null) {
    return UserDocumentServerState(
      exists: body.exists,
      isBlocked: body.isBlocked,
      isDisabled: body.isDisabled,
    );
  }

  return switch (response.error?.code) {
    'missing_account' => const UserDocumentServerState(
      exists: false,
      isBlocked: false,
      isDisabled: false,
    ),
    'blocked_user' => const UserDocumentServerState(
      exists: true,
      isBlocked: true,
      isDisabled: false,
    ),
    'disabled_user' => const UserDocumentServerState(
      exists: true,
      isBlocked: false,
      isDisabled: true,
    ),
    _ => const UserDocumentServerState(
      exists: true,
      isBlocked: false,
      isDisabled: false,
    ),
  };
}

/// Maps API provider-side invalidation responses into internal session facts.
AuthSessionInvalidation? mapApiProviderInvalidationResponse({
  required String uid,
  required ApiAuthResponse<ApiAuthInvalidationBody> response,
}) {
  if (response.isSuccess || response.status == 204) {
    return null;
  }

  return switch (response.error?.code ?? response.body?.code) {
    'missing_account' => AuthSessionInvalidation(
      uid: uid,
      reason: AuthSessionInvalidationReason.missingAuthProviderUser,
    ),
    'disabled_user' => AuthSessionInvalidation(
      uid: uid,
      reason: AuthSessionInvalidationReason.disabledAuthProviderUser,
    ),
    _ => null,
  };
}

AppFailure _missingAccountFailure(ApiAuthActionContext context) {
  return switch (context) {
    ApiAuthActionContext.login => AppFailure.invalidCredentials,
    ApiAuthActionContext.resetPassword => AppFailure.notFound,
    _ => AppFailure.unauthorized,
  };
}

AppFailure _statusFailure(int status, ApiAuthActionContext context) {
  return switch (status) {
    400 => AppFailure.unknown,
    401 => AppFailure.unauthorized,
    403 => AppFailure.unauthorized,
    404 => _missingAccountFailure(context),
    409 => AppFailure.conflict,
    _ => AppFailure.unknown,
  };
}

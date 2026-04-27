/// API-style auth response envelope.
///
/// The auth API provider set consumes this shape instead of provider-specific
/// exceptions so raw status/code/body details are normalized inside data layer.
class ApiAuthResponse<T> {
  const ApiAuthResponse({required this.status, this.body, this.error});

  final int status;
  final T? body;
  final ApiAuthErrorBody? error;

  bool get isSuccess => status >= 200 && status < 300;
}

/// API-style error body.
class ApiAuthErrorBody {
  const ApiAuthErrorBody({required this.code});

  final String code;
}

/// API auth user body returned by successful session endpoints.
class ApiAuthUserBody {
  const ApiAuthUserBody({
    required this.uid,
    required this.email,
    required this.accessToken,
  });

  final String uid;
  final String email;
  final String accessToken;
}

/// API account-state body used for session integrity checks.
class ApiAuthAccountStateBody {
  const ApiAuthAccountStateBody({
    required this.exists,
    required this.isBlocked,
    required this.isDisabled,
  });

  final bool exists;
  final bool isBlocked;
  final bool isDisabled;
}

/// API provider-side invalidation body.
class ApiAuthInvalidationBody {
  const ApiAuthInvalidationBody({required this.code});

  final String code;
}

/// Login request body.
class ApiAuthLoginRequest {
  const ApiAuthLoginRequest({required this.email, required this.password});

  final String email;
  final String password;
}

/// Signup request body.
class ApiAuthSignupRequest {
  const ApiAuthSignupRequest({required this.email, required this.password});

  final String email;
  final String password;
}

/// Password reset request body.
class ApiAuthResetPasswordRequest {
  const ApiAuthResetPasswordRequest({required this.email});

  final String email;
}

/// Change password request body.
class ApiAuthChangePasswordRequest {
  const ApiAuthChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;
}

/// Delete account request body.
class ApiAuthDeleteAccountRequest {
  const ApiAuthDeleteAccountRequest({required this.currentPassword});

  final String currentPassword;
}

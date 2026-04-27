import 'api_auth_models.dart';

/// API auth client boundary consumed by the API-style auth provider set.
///
/// A future HTTP implementation should implement this contract without
/// changing auth actions, session normalization, or app composition input.
abstract interface class ApiAuthClient {
  Future<ApiAuthResponse<ApiAuthUserBody>> login(ApiAuthLoginRequest request);

  Future<ApiAuthResponse<ApiAuthUserBody>> signup(ApiAuthSignupRequest request);

  Future<ApiAuthResponse<void>> logout();

  Future<ApiAuthResponse<void>> sendPasswordResetEmail(
    ApiAuthResetPasswordRequest request,
  );

  Future<ApiAuthResponse<void>> changePassword(
    ApiAuthChangePasswordRequest request,
  );

  Future<ApiAuthResponse<void>> deleteAccount(
    ApiAuthDeleteAccountRequest request,
  );

  Stream<ApiAuthResponse<ApiAuthUserBody>> watchCurrentSession();

  Stream<ApiAuthResponse<ApiAuthAccountStateBody>> watchAccountState({
    required String uid,
  });

  Stream<ApiAuthResponse<ApiAuthInvalidationBody>> watchProviderInvalidation({
    required String uid,
  });
}

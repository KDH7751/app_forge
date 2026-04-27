import '../api_auth_client.dart';
import '../api_auth_models.dart';
import 'in_memory_api_server.dart';

/// ApiAuthClient implementation backed by the Phase 3.6 follow-up in-memory API
/// server.
class InMemoryApiAuthClient implements ApiAuthClient {
  const InMemoryApiAuthClient({required InMemoryApiServer server})
    : _server = server;

  final InMemoryApiServer _server;

  @override
  Future<ApiAuthResponse<ApiAuthUserBody>> login(ApiAuthLoginRequest request) {
    return _server.login(email: request.email, password: request.password);
  }

  @override
  Future<ApiAuthResponse<ApiAuthUserBody>> signup(
    ApiAuthSignupRequest request,
  ) {
    return _server.signup(email: request.email, password: request.password);
  }

  @override
  Future<ApiAuthResponse<void>> logout() {
    return _server.logout();
  }

  @override
  Future<ApiAuthResponse<void>> sendPasswordResetEmail(
    ApiAuthResetPasswordRequest request,
  ) {
    return _server.sendPasswordResetEmail(email: request.email);
  }

  @override
  Future<ApiAuthResponse<void>> changePassword(
    ApiAuthChangePasswordRequest request,
  ) {
    return _server.changePassword(
      currentPassword: request.currentPassword,
      newPassword: request.newPassword,
    );
  }

  @override
  Future<ApiAuthResponse<void>> deleteAccount(
    ApiAuthDeleteAccountRequest request,
  ) {
    return _server.deleteAccount(currentPassword: request.currentPassword);
  }

  @override
  Stream<ApiAuthResponse<ApiAuthUserBody>> watchCurrentSession() {
    return _server.watchCurrentSession();
  }

  @override
  Stream<ApiAuthResponse<ApiAuthAccountStateBody>> watchAccountState({
    required String uid,
  }) {
    return _server.watchAccountState(uid: uid);
  }

  @override
  Stream<ApiAuthResponse<ApiAuthInvalidationBody>> watchProviderInvalidation({
    required String uid,
  }) {
    return _server.watchProviderInvalidation(uid: uid);
  }
}

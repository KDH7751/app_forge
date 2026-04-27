import '../api_auth_models.dart';

/// Builds API-style error responses for the in-memory auth harness.
ApiAuthResponse<T> fakeApiError<T>({
  required int status,
  required String code,
}) {
  return ApiAuthResponse<T>(
    status: status,
    error: ApiAuthErrorBody(code: code),
  );
}

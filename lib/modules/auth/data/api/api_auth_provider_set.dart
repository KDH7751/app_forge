import '../../domain/actions/change_password_action.dart';
import '../../domain/actions/delete_account_action.dart';
import '../../domain/actions/login_action.dart';
import '../../domain/actions/logout_action.dart';
import '../../domain/actions/reset_password_action.dart';
import '../../domain/actions/signup_action.dart';
import '../../domain/auth_logger.dart';
import '../../domain/session/auth_session.dart';
import '../../state/providers/auth_assembly_provider.dart';
import '../../state/providers/auth_session_models.dart';
import '../../state/providers/auth_setup_provider.dart';
import '../datasources/users_document_datasource.dart';
import 'api_auth_actions.dart';
import 'api_auth_client.dart';
import 'api_auth_failure_mapper.dart';

/// API-style auth provider set assembly.
///
/// This assembly consumes only ApiAuthClient. It does not know whether the
/// client is backed by the Phase 3.6 follow-up in-memory harness or a future
/// HTTP client.
class ApiAuthAssembly implements AuthSetAssembly {
  const ApiAuthAssembly({
    required ApiAuthClient client,
    required AuthLogger logger,
  }) : _client = client,
       _logger = logger;

  final ApiAuthClient _client;
  final AuthLogger _logger;

  @override
  AuthProviderSet get provider => AuthProviderSet.apiTestHarness;

  @override
  Set<AuthCapability> get supportedCapabilities => const <AuthCapability>{
    AuthCapability.login,
    AuthCapability.signup,
    AuthCapability.sendPasswordResetEmail,
    AuthCapability.changePassword,
    AuthCapability.deleteAccount,
  };

  @override
  LoginAction get loginAction =>
      ApiLoginAction(client: _client, logger: _logger);

  @override
  SignupAction get signupAction =>
      ApiSignupAction(client: _client, logger: _logger);

  @override
  ResetPasswordAction get resetPasswordAction =>
      ApiResetPasswordAction(client: _client, logger: _logger);

  @override
  ChangePasswordAction get changePasswordAction =>
      ApiChangePasswordAction(client: _client, logger: _logger);

  @override
  DeleteAccountAction get deleteAccountAction =>
      ApiDeleteAccountAction(client: _client, logger: _logger);

  @override
  LogoutAction get logoutAction =>
      ApiLogoutAction(client: _client, logger: _logger);

  @override
  Stream<Authenticated?> watchSessions() {
    return _client.watchCurrentSession().map(mapApiSessionResponse);
  }

  @override
  Stream<UserDocumentServerState> watchUserServerState({required String uid}) {
    return _client.watchAccountState(uid: uid).map(mapApiAccountStateResponse);
  }

  @override
  AuthProviderInvalidationWatcher createInvalidationWatcher({
    required Duration probeInterval,
  }) {
    return (uid) => _client
        .watchProviderInvalidation(uid: uid)
        .map(
          (response) =>
              mapApiProviderInvalidationResponse(uid: uid, response: response),
        );
  }
}

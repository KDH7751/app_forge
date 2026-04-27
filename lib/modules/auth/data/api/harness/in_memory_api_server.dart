import 'dart:async';

import '../api_auth_models.dart';
import 'fake_api_error.dart';
import 'fake_api_models.dart';

/// In-memory API-style auth harness server.
///
/// The server intentionally exposes status/body/code responses instead of
/// AuthSession or AppFailure so the provider boundary proves normalization.
class InMemoryApiServer {
  InMemoryApiServer.seeded() {
    _seed(
      uid: 'user_001',
      email: 'normal@example.com',
      password: 'password123',
    );
    _seed(
      uid: 'user_002',
      email: 'blocked@example.com',
      password: 'password123',
      blocked: true,
    );
    _seed(
      uid: 'user_003',
      email: 'disabled@example.com',
      password: 'password123',
      disabled: true,
    );
  }

  final Map<String, FakeApiAuthAccount> _accountsByEmail =
      <String, FakeApiAuthAccount>{};
  final Map<String, FakeApiAuthAccount> _accountsByUid =
      <String, FakeApiAuthAccount>{};
  final StreamController<String?> _sessionController =
      StreamController<String?>.broadcast();
  final StreamController<String> _accountStateController =
      StreamController<String>.broadcast();
  final StreamController<String> _providerInvalidationController =
      StreamController<String>.broadcast();

  String? _currentUid;
  var _nextUserNumber = 100;

  String? get currentUid => _currentUid;

  Future<ApiAuthResponse<ApiAuthUserBody>> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    final specialFailure = _specialFailure<ApiAuthUserBody>(normalizedEmail);

    if (specialFailure != null) {
      return specialFailure;
    }

    final account = _accountsByEmail[normalizedEmail];

    if (account == null || account.authProviderDeleted) {
      return fakeApiError<ApiAuthUserBody>(
        status: 401,
        code: 'invalid_credentials',
      );
    }

    if (account.password != password) {
      return fakeApiError<ApiAuthUserBody>(
        status: 401,
        code: 'invalid_credentials',
      );
    }

    if (account.userDocumentDeleted) {
      return fakeApiError<ApiAuthUserBody>(
        status: 404,
        code: 'missing_account',
      );
    }

    if (account.blocked) {
      return fakeApiError<ApiAuthUserBody>(status: 403, code: 'blocked_user');
    }

    if (account.disabled) {
      return fakeApiError<ApiAuthUserBody>(status: 403, code: 'disabled_user');
    }

    _currentUid = account.uid;
    _sessionController.add(_currentUid);
    _accountStateController.add(account.uid);

    return ApiAuthResponse<ApiAuthUserBody>(
      status: 200,
      body: _userBody(account),
    );
  }

  Future<ApiAuthResponse<ApiAuthUserBody>> signup({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    final specialFailure = _specialFailure<ApiAuthUserBody>(normalizedEmail);

    if (specialFailure != null) {
      return specialFailure;
    }

    if (_accountsByEmail.containsKey(normalizedEmail)) {
      return fakeApiError<ApiAuthUserBody>(
        status: 409,
        code: 'email_already_exists',
      );
    }

    if (password.length < 8) {
      return fakeApiError<ApiAuthUserBody>(status: 400, code: 'weak_password');
    }

    final uid = 'user_${_nextUserNumber++}';
    final account = _seed(uid: uid, email: normalizedEmail, password: password);

    _currentUid = account.uid;
    _sessionController.add(_currentUid);
    _accountStateController.add(account.uid);

    return ApiAuthResponse<ApiAuthUserBody>(
      status: 200,
      body: _userBody(account),
    );
  }

  Future<ApiAuthResponse<void>> logout() async {
    _currentUid = null;
    _sessionController.add(null);

    return const ApiAuthResponse<void>(status: 204);
  }

  Future<ApiAuthResponse<void>> sendPasswordResetEmail({
    required String email,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    final specialFailure = _specialFailure<void>(normalizedEmail);

    if (specialFailure != null) {
      return specialFailure;
    }

    final account = _accountsByEmail[normalizedEmail];

    if (account == null || account.authProviderDeleted) {
      return fakeApiError<void>(status: 404, code: 'missing_account');
    }

    return const ApiAuthResponse<void>(status: 204);
  }

  Future<ApiAuthResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final account = _currentAccount;

    if (account == null) {
      return fakeApiError<void>(status: 401, code: 'missing_account');
    }

    if (account.password != currentPassword) {
      return fakeApiError<void>(status: 401, code: 'invalid_credentials');
    }

    if (newPassword.length < 8) {
      return fakeApiError<void>(status: 400, code: 'weak_password');
    }

    account.password = newPassword;

    return const ApiAuthResponse<void>(status: 204);
  }

  Future<ApiAuthResponse<void>> deleteAccount({
    required String currentPassword,
  }) async {
    final account = _currentAccount;

    if (account == null) {
      return fakeApiError<void>(status: 401, code: 'missing_account');
    }

    if (account.password != currentPassword) {
      return fakeApiError<void>(status: 401, code: 'invalid_credentials');
    }

    account.authProviderDeleted = true;
    account.userDocumentDeleted = true;
    _currentUid = null;
    _sessionController.add(null);
    _providerInvalidationController.add(account.uid);
    _accountStateController.add(account.uid);

    return const ApiAuthResponse<void>(status: 204);
  }

  Stream<ApiAuthResponse<ApiAuthUserBody>> watchCurrentSession() async* {
    yield _sessionResponse(_currentUid);
    yield* _sessionController.stream.map(_sessionResponse);
  }

  Stream<ApiAuthResponse<ApiAuthAccountStateBody>> watchAccountState({
    required String uid,
  }) async* {
    yield _accountStateResponse(uid);
    yield* _accountStateController.stream
        .where((changedUid) => changedUid == uid)
        .map(_accountStateResponse);
  }

  Stream<ApiAuthResponse<ApiAuthInvalidationBody>> watchProviderInvalidation({
    required String uid,
  }) async* {
    yield _providerInvalidationResponse(uid);
    yield* _providerInvalidationController.stream
        .where((changedUid) => changedUid == uid)
        .map(_providerInvalidationResponse);
  }

  void removeUserDocument(String uid) {
    final account = _accountsByUid[uid];

    if (account == null) {
      return;
    }

    account.userDocumentDeleted = true;
    _accountStateController.add(uid);
  }

  void blockUser(String uid) {
    final account = _accountsByUid[uid];

    if (account == null) {
      return;
    }

    account.blocked = true;
    _accountStateController.add(uid);
  }

  void disableUser(String uid) {
    final account = _accountsByUid[uid];

    if (account == null) {
      return;
    }

    account.disabled = true;
    _accountStateController.add(uid);
    _providerInvalidationController.add(uid);
  }

  void deleteAuthProviderAccount(String uid) {
    final account = _accountsByUid[uid];

    if (account == null) {
      return;
    }

    account.authProviderDeleted = true;
    _providerInvalidationController.add(uid);
  }

  Future<void> dispose() async {
    await _sessionController.close();
    await _accountStateController.close();
    await _providerInvalidationController.close();
  }

  FakeApiAuthAccount _seed({
    required String uid,
    required String email,
    required String password,
    bool blocked = false,
    bool disabled = false,
  }) {
    final normalizedEmail = _normalizeEmail(email);
    final account = FakeApiAuthAccount(
      uid: uid,
      email: normalizedEmail,
      password: password,
      blocked: blocked,
      disabled: disabled,
    );

    _accountsByEmail[normalizedEmail] = account;
    _accountsByUid[uid] = account;

    return account;
  }

  FakeApiAuthAccount? get _currentAccount {
    final uid = _currentUid;

    if (uid == null) {
      return null;
    }

    final account = _accountsByUid[uid];

    if (account == null ||
        account.authProviderDeleted ||
        account.userDocumentDeleted ||
        account.blocked ||
        account.disabled) {
      return null;
    }

    return account;
  }

  ApiAuthResponse<ApiAuthUserBody> _sessionResponse(String? uid) {
    if (uid == null) {
      return fakeApiError<ApiAuthUserBody>(
        status: 401,
        code: 'missing_account',
      );
    }

    final account = _accountsByUid[uid];

    if (account == null || account.authProviderDeleted) {
      return fakeApiError<ApiAuthUserBody>(
        status: 404,
        code: 'missing_account',
      );
    }

    return ApiAuthResponse<ApiAuthUserBody>(
      status: 200,
      body: _userBody(account),
    );
  }

  ApiAuthResponse<ApiAuthAccountStateBody> _accountStateResponse(String uid) {
    final account = _accountsByUid[uid];

    if (account == null || account.userDocumentDeleted) {
      return fakeApiError<ApiAuthAccountStateBody>(
        status: 404,
        code: 'missing_account',
      );
    }

    if (account.blocked) {
      return fakeApiError<ApiAuthAccountStateBody>(
        status: 403,
        code: 'blocked_user',
      );
    }

    if (account.disabled) {
      return fakeApiError<ApiAuthAccountStateBody>(
        status: 403,
        code: 'disabled_user',
      );
    }

    return const ApiAuthResponse<ApiAuthAccountStateBody>(
      status: 200,
      body: ApiAuthAccountStateBody(
        exists: true,
        isBlocked: false,
        isDisabled: false,
      ),
    );
  }

  ApiAuthResponse<ApiAuthInvalidationBody> _providerInvalidationResponse(
    String uid,
  ) {
    final account = _accountsByUid[uid];

    if (account == null || account.authProviderDeleted) {
      return fakeApiError<ApiAuthInvalidationBody>(
        status: 404,
        code: 'missing_account',
      );
    }

    if (account.disabled) {
      return fakeApiError<ApiAuthInvalidationBody>(
        status: 403,
        code: 'disabled_user',
      );
    }

    return const ApiAuthResponse<ApiAuthInvalidationBody>(status: 204);
  }

  ApiAuthUserBody _userBody(FakeApiAuthAccount account) {
    return ApiAuthUserBody(
      uid: account.uid,
      email: account.email,
      accessToken: 'fake-token-${account.uid}',
    );
  }

  ApiAuthResponse<T>? _specialFailure<T>(String normalizedEmail) {
    return switch (normalizedEmail) {
      'network@example.com' => fakeApiError<T>(
        status: 0,
        code: 'network_error',
      ),
      'unavailable@example.com' => fakeApiError<T>(
        status: 503,
        code: 'service_unavailable',
      ),
      'missing@example.com' => fakeApiError<T>(
        status: 404,
        code: 'missing_account',
      ),
      _ => null,
    };
  }

  String _normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }
}

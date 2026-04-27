// ignore_for_file: avoid_relative_lib_imports

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/features/auth_flow/auth_flow.dart';
import '../lib/modules/auth/auth.dart';
import '../lib/modules/auth/data/api/api_auth_models.dart';
import '../lib/modules/auth/data/api/harness/in_memory_api_auth_client.dart';
import '../lib/modules/auth/data/api/harness/in_memory_api_server.dart';
import '../lib/modules/auth/state/providers/auth_runtime_provider.dart';

void main() {
  group('API auth provider set', () {
    test(
      'logs in through ApiAuthClient and exposes AuthSession only',
      () async {
        final server = InMemoryApiServer.seeded();
        final container = _apiAuthContainer(server);
        addTearDown(container.dispose);
        addTearDown(server.dispose);

        expect(
          container.read(authProviderMetadataProvider).label,
          'API test harness',
        );

        final result = await container
            .read(authFacadeProvider)
            .login(email: 'normal@example.com', password: 'password123');

        expect(result.isSuccess, isTrue);

        final session = await _waitForAuthSession(
          container,
          (session) => session is Authenticated,
        );

        expect(
          session,
          const Authenticated(uid: 'user_001', email: 'normal@example.com'),
        );
      },
    );

    test('normalizes API raw failures into AppFailure', () async {
      final server = InMemoryApiServer.seeded();
      final client = InMemoryApiAuthClient(server: server);
      final container = _apiAuthContainer(server, client: client);
      addTearDown(container.dispose);
      addTearDown(server.dispose);

      final rawBlocked = await client.login(
        const ApiAuthLoginRequest(
          email: 'blocked@example.com',
          password: 'password123',
        ),
      );
      expect(rawBlocked.status, 403);
      expect(rawBlocked.error?.code, 'blocked_user');

      final blocked = await container
          .read(authFacadeProvider)
          .login(email: 'blocked@example.com', password: 'password123');
      expect(
        (blocked as Failure<void>).failure.type,
        AppFailureType.unauthorized,
      );

      final invalidCredentials = await container
          .read(authFacadeProvider)
          .login(email: 'normal@example.com', password: 'wrong-password');
      expect(
        (invalidCredentials as Failure<void>).failure.type,
        AppFailureType.invalidCredentials,
      );

      final network = await container
          .read(authFacadeProvider)
          .login(email: 'network@example.com', password: 'password123');
      expect((network as Failure<void>).failure.type, AppFailureType.network);

      final unavailable = await container
          .read(authFacadeProvider)
          .login(email: 'unavailable@example.com', password: 'password123');
      expect(
        (unavailable as Failure<void>).failure.type,
        AppFailureType.unavailable,
      );

      final missingReset = await container
          .read(authFacadeProvider)
          .sendPasswordResetEmail(email: 'missing@example.com');
      expect(
        (missingReset as Failure<void>).failure.type,
        AppFailureType.notFound,
      );
    });

    test('maps API account status to Invalid session reasons', () async {
      final server = InMemoryApiServer.seeded();
      final container = _apiAuthContainer(server);
      addTearDown(container.dispose);
      addTearDown(server.dispose);

      await container
          .read(authFacadeProvider)
          .login(email: 'normal@example.com', password: 'password123');
      await _waitForAuthSession(
        container,
        (session) => session is Authenticated,
      );

      server.blockUser('user_001');
      final blocked = await _waitForAuthSession(
        container,
        (session) =>
            session is Invalid && session.reason == InvalidReason.blocked,
      );
      expect(blocked, const Invalid(reason: InvalidReason.blocked));
    });

    test('supports logout, changePassword, and deleteAccount', () async {
      final server = InMemoryApiServer.seeded();
      final container = _apiAuthContainer(server);
      addTearDown(container.dispose);
      addTearDown(server.dispose);

      final facade = container.read(authFacadeProvider);

      await facade.login(email: 'normal@example.com', password: 'password123');
      await _waitForAuthSession(
        container,
        (session) => session is Authenticated,
      );

      final changePassword = await facade.changePassword(
        const ChangePasswordInput(
          currentPassword: 'password123',
          newPassword: 'password456',
          confirmNewPassword: 'password456',
        ),
      );
      expect(changePassword.isSuccess, isTrue);

      await facade.logout();
      await _waitForAuthSession(
        container,
        (session) => session is Unauthenticated,
      );

      final oldPassword = await facade.login(
        email: 'normal@example.com',
        password: 'password123',
      );
      expect(
        (oldPassword as Failure<void>).failure.type,
        AppFailureType.invalidCredentials,
      );

      final newPassword = await facade.login(
        email: 'normal@example.com',
        password: 'password456',
      );
      expect(newPassword.isSuccess, isTrue);
      await _waitForAuthSession(
        container,
        (session) => session is Authenticated,
      );

      final deleteAccount = await facade.deleteAccount(
        const DeleteAccountInput(currentPassword: 'password456'),
      );
      expect(deleteAccount.isSuccess, isTrue);
      await _waitForAuthSession(
        container,
        (session) => session is Unauthenticated,
      );

      final resetDeleted = await facade.sendPasswordResetEmail(
        email: 'normal@example.com',
      );
      expect(
        (resetDeleted as Failure<void>).failure.type,
        AppFailureType.notFound,
      );
    });

    testWidgets('login page displays selected provider metadata', (
      tester,
    ) async {
      final server = InMemoryApiServer.seeded();
      addTearDown(server.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: _apiOverrides(server),
          child: const MaterialApp(home: LoginPage()),
        ),
      );

      expect(find.text('Auth provider: API test harness'), findsOneWidget);
    });
  });
}

ProviderContainer _apiAuthContainer(
  InMemoryApiServer server, {
  InMemoryApiAuthClient? client,
}) {
  return ProviderContainer(overrides: _apiOverrides(server, client: client));
}

List<Override> _apiOverrides(
  InMemoryApiServer server, {
  InMemoryApiAuthClient? client,
}) {
  return <Override>[
    authSetupProvider.overrideWithValue(
      const AuthSetup(
        provider: AuthProviderSet.apiTestHarness,
        config: ApiTestHarnessAuthConfig(),
        policy: AuthActivationPolicy(),
      ),
    ),
    apiAuthClientProvider.overrideWithValue(
      client ?? InMemoryApiAuthClient(server: server),
    ),
  ];
}

Future<AuthSession> _waitForAuthSession(
  ProviderContainer container,
  bool Function(AuthSession session) predicate,
) async {
  final completer = Completer<AuthSession>();
  late final ProviderSubscription<AuthSession> subscription;
  subscription = container.listen<AuthSession>(authSessionProvider, (_, next) {
    if (!completer.isCompleted && predicate(next)) {
      completer.complete(next);
    }
  }, fireImmediately: true);

  try {
    return await completer.future.timeout(const Duration(seconds: 1));
  } finally {
    subscription.close();
  }
}

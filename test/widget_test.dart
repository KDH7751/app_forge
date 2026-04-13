import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_forge/bootstrap/bootstrap.dart';
import 'package:app_forge/engine/engine.dart';
import 'package:app_forge/app/app_config.dart';
import 'package:app_forge/features/auth/domain/core/app_error.dart';
import 'package:app_forge/features/auth/domain/auth_facade.dart';
import 'package:app_forge/features/auth/domain/core/result.dart';
import 'package:app_forge/features/auth/domain/models/change_password_input.dart';
import 'package:app_forge/features/auth/domain/models/delete_account_input.dart';
import 'package:app_forge/features/auth/domain/session/auth_session.dart';
import 'package:app_forge/features/auth/domain/validation/auth_validation.dart';
import 'package:app_forge/features/auth/data/datasources/users_document_datasource.dart';
import 'package:app_forge/features/auth/state/providers/auth_facade_provider.dart';
import 'package:app_forge/features/auth/state/providers/auth_runtime_provider.dart';
import 'package:app_forge/features/auth/state/providers/auth_session_provider.dart';

/// router shell / auth_entry 흐름 검증용 widget test 묶음.
void main() {
  testWidgets('unauthenticated app redirects to login route', (tester) async {
    final sessionSource = _FakeAuthSessionSource();
    final repository = _FakeAuthRepository(sessionSource: sessionSource);
    addTearDown(sessionSource.dispose);

    await tester.pumpWidget(_buildBootstrap(repository, sessionSource));
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsOneWidget);
    expect(
      find.text('Standalone auth entry route outside the Engine shell.'),
      findsOneWidget,
    );
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('login page pushes to signup route and back works', (
    tester,
  ) async {
    final sessionSource = _FakeAuthSessionSource();
    final repository = _FakeAuthRepository(sessionSource: sessionSource);
    addTearDown(sessionSource.dispose);

    await tester.pumpWidget(_buildBootstrap(repository, sessionSource));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Login'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('authenticated app renders shell home route', (tester) async {
    final sessionSource = _FakeAuthSessionSource(
      initialSession: const Authenticated(
        uid: 'uid-1',
        email: 'user@example.com',
      ),
    );
    final repository = _FakeAuthRepository(sessionSource: sessionSource);
    addTearDown(sessionSource.dispose);

    await tester.pumpWidget(_buildBootstrap(repository, sessionSource));
    await tester.pumpAndSettle();

    expect(find.text('Phase 2 Home Route'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('authenticated bottom nav moves from home to profile route', (
    tester,
  ) async {
    final sessionSource = _FakeAuthSessionSource(
      initialSession: const Authenticated(
        uid: 'uid-1',
        email: 'user@example.com',
      ),
    );
    final repository = _FakeAuthRepository(sessionSource: sessionSource);
    addTearDown(sessionSource.dispose);

    await tester.pumpWidget(_buildBootstrap(repository, sessionSource));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    expect(
      find.text('Profile route inside the Engine shell with drawer enabled.'),
      findsOneWidget,
    );
    expect(find.text('Change Password'), findsOneWidget);
    expect(find.text('Delete Account'), findsOneWidget);
    expect(find.byTooltip('Open navigation menu'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('profile delete account flow requires confirmation dialog', (
    tester,
  ) async {
    final sessionSource = _FakeAuthSessionSource(
      initialSession: const Authenticated(
        uid: 'uid-1',
        email: 'user@example.com',
      ),
    );
    final repository = _FakeAuthRepository(sessionSource: sessionSource);
    addTearDown(sessionSource.dispose);

    await tester.pumpWidget(_buildBootstrap(repository, sessionSource));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    final deleteButton = find.widgetWithText(FilledButton, 'Delete account');
    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);
    expect(
      find.descendant(of: dialog, matching: find.text('Current password')),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Delete'), findsOneWidget);
  });

  testWidgets('login page submits and redirect moves to home route', (
    tester,
  ) async {
    final sessionSource = _FakeAuthSessionSource();
    final repository = _FakeAuthRepository(sessionSource: sessionSource);
    addTearDown(sessionSource.dispose);

    await tester.pumpWidget(_buildBootstrap(repository, sessionSource));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('Phase 2 Home Route'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets(
    'missing users document for an existing auth account recovers and enters on the first login attempt',
    (tester) async {
      final sessionSource = _FakeAuthSessionSource();
      final userStateSource = _FakeUserDocumentStateSource(
        initialState: const UserDocumentServerState(
          exists: false,
          isBlocked: false,
          isDisabled: false,
        ),
      );
      final repository = _FakeAuthRepository(
        sessionSource: sessionSource,
        persistedAuthEmails: <String>{'user@example.com'},
        linkedUserStateSource: userStateSource,
        recreateUserDocumentOnLogin: true,
      );
      addTearDown(sessionSource.dispose);
      addTearDown(userStateSource.dispose);

      await tester.pumpWidget(
        _buildBootstrapWithUserState(
          repository,
          sessionSource,
          userStateSource,
          null,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Login'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(repository.loginCalls, 1);
      expect(find.text('Phase 2 Home Route'), findsOneWidget);
      expect(find.text('Email'), findsNothing);
    },
  );

  testWidgets('signup page submits and redirect moves to home route', (
    tester,
  ) async {
    final sessionSource = _FakeAuthSessionSource();
    final repository = _FakeAuthRepository(sessionSource: sessionSource);
    addTearDown(sessionSource.dispose);

    await tester.pumpWidget(_buildBootstrap(repository, sessionSource));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'new@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.enterText(find.byType(TextField).at(2), 'password123');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Phase 2 Home Route'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets(
    'authenticated home page button navigates to param detail route',
    (tester) async {
      final sessionSource = _FakeAuthSessionSource(
        initialSession: const Authenticated(
          uid: 'uid-1',
          email: 'user@example.com',
        ),
      );
      final repository = _FakeAuthRepository(sessionSource: sessionSource);
      addTearDown(sessionSource.dispose);

      await tester.pumpWidget(_buildBootstrap(repository, sessionSource));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Post 42'));
      await tester.pumpAndSettle();

      expect(find.text('Resolved path param id: 42'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byTooltip('Open navigation menu'), findsNothing);
    },
  );

  testWidgets('profile logout redirects back to login route', (tester) async {
    final sessionSource = _FakeAuthSessionSource(
      initialSession: const Authenticated(
        uid: 'uid-1',
        email: 'user@example.com',
      ),
    );
    final repository = _FakeAuthRepository(sessionSource: sessionSource);
    addTearDown(sessionSource.dispose);

    await tester.pumpWidget(_buildBootstrap(repository, sessionSource));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('reset password success returns to login route', (tester) async {
    final sessionSource = _FakeAuthSessionSource();
    final repository = _FakeAuthRepository(sessionSource: sessionSource);
    addTearDown(sessionSource.dispose);

    await tester.pumpWidget(_buildBootstrap(repository, sessionSource));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reset password'));
    await tester.pumpAndSettle();

    expect(find.text('Reset Password'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'user@example.com');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Send reset email'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Login'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    expect(find.text('비밀번호 재설정 메일을 전송했습니다'), findsOneWidget);
  });

  testWidgets('login failure shows global snackbar once at app root', (
    tester,
  ) async {
    final sessionSource = _FakeAuthSessionSource();
    final repository = _FakeAuthRepository(
      sessionSource: sessionSource,
      loginResult: const Result<void>.failure(AppError.network),
    );
    addTearDown(sessionSource.dispose);

    await tester.pumpWidget(_buildBootstrap(repository, sessionSource));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('네트워크 문제로 요청을 처리할 수 없습니다'), findsOneWidget);
  });

  testWidgets('login validation failure stays local and does not notify root', (
    tester,
  ) async {
    final sessionSource = _FakeAuthSessionSource();
    final repository = _FakeAuthRepository(sessionSource: sessionSource);
    addTearDown(sessionSource.dispose);

    await tester.pumpWidget(_buildBootstrap(repository, sessionSource));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'invalid-email');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('올바른 이메일 형식을 입력해주세요'), findsOneWidget);
    expect(find.text('네트워크 문제로 요청을 처리할 수 없습니다'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  test(
    'authSessionProvider exposes Unauthenticated without a session',
    () async {
      final sessionSource = _FakeAuthSessionSource();
      final container = _buildAuthContainer(sessionSource: sessionSource);
      addTearDown(sessionSource.dispose);
      addTearDown(container.dispose);

      expect(
        await _waitForAuthSession(
          container,
          (session) => session is Unauthenticated,
        ),
        const Unauthenticated(),
      );
    },
  );

  test(
    'authSessionProvider exposes Pending while session integrity is still resolving',
    () async {
      final sessionSource = _FakeAuthSessionSource(
        initialSession: const Authenticated(
          uid: 'uid-1',
          email: 'user@example.com',
        ),
      );
      final userStateSource = _FakeUserDocumentStateSource();
      final container = _buildAuthContainer(
        sessionSource: sessionSource,
        userStateSource: userStateSource,
      );
      addTearDown(sessionSource.dispose);
      addTearDown(userStateSource.dispose);
      addTearDown(container.dispose);

      expect(
        await _waitForAuthSession(container, (session) => session is Pending),
        const Pending(),
      );
    },
  );

  test(
    'authSessionProvider exposes Authenticated for a valid session',
    () async {
      final sessionSource = _FakeAuthSessionSource(
        initialSession: const Authenticated(
          uid: 'uid-1',
          email: 'user@example.com',
        ),
      );
      final userStateSource = _FakeUserDocumentStateSource(
        initialState: const UserDocumentServerState(
          exists: true,
          isBlocked: false,
          isDisabled: false,
        ),
      );
      final container = _buildAuthContainer(
        sessionSource: sessionSource,
        userStateSource: userStateSource,
      );
      addTearDown(sessionSource.dispose);
      addTearDown(userStateSource.dispose);
      addTearDown(container.dispose);

      expect(
        await _waitForAuthSession(
          container,
          (session) => session is Authenticated,
        ),
        const Authenticated(uid: 'uid-1', email: 'user@example.com'),
      );
    },
  );

  test(
    'authSessionProvider maps raw invalidation to public InvalidReason',
    () async {
      final missingAccountSessionSource = _FakeAuthSessionSource(
        initialSession: const Authenticated(
          uid: 'uid-1',
          email: 'user@example.com',
        ),
      );
      final missingAccountUserStateSource = _FakeUserDocumentStateSource(
        initialState: const UserDocumentServerState(
          exists: false,
          isBlocked: false,
          isDisabled: false,
        ),
      );
      final missingAccountContainer = _buildAuthContainer(
        sessionSource: missingAccountSessionSource,
        userStateSource: missingAccountUserStateSource,
      );
      final blockedSessionSource = _FakeAuthSessionSource(
        initialSession: const Authenticated(
          uid: 'uid-2',
          email: 'blocked@example.com',
        ),
      );
      final blockedUserStateSource = _FakeUserDocumentStateSource(
        initialState: const UserDocumentServerState(
          exists: true,
          isBlocked: true,
          isDisabled: false,
        ),
      );
      final blockedContainer = _buildAuthContainer(
        sessionSource: blockedSessionSource,
        userStateSource: blockedUserStateSource,
      );
      final disabledSessionSource = _FakeAuthSessionSource(
        initialSession: const Authenticated(
          uid: 'uid-3',
          email: 'disabled@example.com',
        ),
      );
      final disabledUserStateSource = _FakeUserDocumentStateSource(
        initialState: const UserDocumentServerState(
          exists: true,
          isBlocked: false,
          isDisabled: false,
        ),
      );
      final disabledAuthProviderInvalidationSource =
          _FakeAuthProviderInvalidationSource(
            initialState: const AuthSessionInvalidation(
              uid: 'uid-3',
              reason: AuthSessionInvalidationReason.disabledAuthProviderUser,
            ),
          );
      final disabledContainer = _buildAuthContainer(
        sessionSource: disabledSessionSource,
        userStateSource: disabledUserStateSource,
        authProviderInvalidationSource: disabledAuthProviderInvalidationSource,
      );
      addTearDown(missingAccountSessionSource.dispose);
      addTearDown(missingAccountUserStateSource.dispose);
      addTearDown(blockedSessionSource.dispose);
      addTearDown(blockedUserStateSource.dispose);
      addTearDown(disabledSessionSource.dispose);
      addTearDown(disabledUserStateSource.dispose);
      addTearDown(disabledAuthProviderInvalidationSource.dispose);
      addTearDown(missingAccountContainer.dispose);
      addTearDown(blockedContainer.dispose);
      addTearDown(disabledContainer.dispose);

      expect(
        await _waitForAuthSession(
          missingAccountContainer,
          (session) => session is Invalid,
        ),
        const Invalid(reason: InvalidReason.missingAccount),
      );
      expect(
        await _waitForAuthSession(
          blockedContainer,
          (session) => session is Invalid,
        ),
        const Invalid(reason: InvalidReason.blocked),
      );
      expect(
        await _waitForAuthSession(
          disabledContainer,
          (session) => session is Invalid,
        ),
        const Invalid(reason: InvalidReason.disabled),
      );
    },
  );

  test(
    'authSessionProvider keeps observation errors in Pending instead of downgrading to Unauthenticated',
    () async {
      final container = ProviderContainer(
        overrides: <Override>[
          authSessionObservationStreamProvider.overrideWithValue(
            Stream<AuthSessionObservation>.error(
              StateError('observation error'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        await _waitForAuthSession(container, (session) => session is Pending),
        const Pending(),
      );
    },
  );

  testWidgets(
    'authenticated session waits for first user document state before rendering protected route',
    (tester) async {
      final sessionSource = _FakeAuthSessionSource(
        initialSession: const Authenticated(
          uid: 'uid-1',
          email: 'user@example.com',
        ),
      );
      final userStateSource = _FakeUserDocumentStateSource();
      final repository = _FakeAuthRepository(sessionSource: sessionSource);
      addTearDown(sessionSource.dispose);
      addTearDown(userStateSource.dispose);

      await tester.pumpWidget(
        _buildBootstrapWithUserState(
          repository,
          sessionSource,
          userStateSource,
          null,
        ),
      );
      await tester.pump();

      expect(find.text('Phase 2 Home Route'), findsNothing);
      expect(find.text('Email'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      userStateSource.setState(
        const UserDocumentServerState(
          exists: true,
          isBlocked: false,
          isDisabled: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Phase 2 Home Route'), findsOneWidget);
    },
  );

  testWidgets(
    'login keeps a loading placeholder instead of a blank screen until first user document state',
    (tester) async {
      final sessionSource = _FakeAuthSessionSource();
      final userStateSource = _FakeUserDocumentStateSource();
      final repository = _FakeAuthRepository(sessionSource: sessionSource);
      addTearDown(sessionSource.dispose);
      addTearDown(userStateSource.dispose);

      await tester.pumpWidget(
        _buildBootstrapWithUserState(
          repository,
          sessionSource,
          userStateSource,
          null,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Login'));
      await tester.pump();

      expect(find.text('Phase 2 Home Route'), findsNothing);
      expect(find.text('Email'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      userStateSource.setState(
        const UserDocumentServerState(
          exists: true,
          isBlocked: false,
          isDisabled: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Phase 2 Home Route'), findsOneWidget);
    },
  );

  testWidgets(
    'signup keeps a loading placeholder instead of a blank screen until first user document state',
    (tester) async {
      final sessionSource = _FakeAuthSessionSource();
      final userStateSource = _FakeUserDocumentStateSource();
      final repository = _FakeAuthRepository(sessionSource: sessionSource);
      addTearDown(sessionSource.dispose);
      addTearDown(userStateSource.dispose);

      await tester.pumpWidget(
        _buildBootstrapWithUserState(
          repository,
          sessionSource,
          userStateSource,
          null,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create account'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'new@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');
      await tester.enterText(find.byType(TextField).at(2), 'password123');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pump();

      expect(find.text('Phase 2 Home Route'), findsNothing);
      expect(find.text('Email'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      userStateSource.setState(
        const UserDocumentServerState(
          exists: true,
          isBlocked: false,
          isDisabled: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Phase 2 Home Route'), findsOneWidget);
    },
  );

  testWidgets(
    'invalid session redirects to login before forced logout completes',
    (tester) async {
      final sessionSource = _FakeAuthSessionSource(
        initialSession: const Authenticated(
          uid: 'uid-1',
          email: 'user@example.com',
        ),
      );
      final userStateSource = _FakeUserDocumentStateSource(
        initialState: const UserDocumentServerState(
          exists: true,
          isBlocked: false,
          isDisabled: false,
        ),
      );
      final logoutCompleter = Completer<void>();
      final repository = _FakeAuthRepository(
        sessionSource: sessionSource,
        logoutCompleter: logoutCompleter,
      );
      addTearDown(sessionSource.dispose);
      addTearDown(userStateSource.dispose);

      await tester.pumpWidget(
        _buildBootstrapWithUserState(
          repository,
          sessionSource,
          userStateSource,
          null,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Phase 2 Home Route'), findsOneWidget);

      userStateSource.setState(
        const UserDocumentServerState(
          exists: false,
          isBlocked: false,
          isDisabled: false,
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsOneWidget);
      expect(repository.logoutCalls, 1);
      expect(repository.deleteAccountCalls, 0);
      expect(sessionSource.currentSession, isNotNull);

      logoutCompleter.complete();
      await tester.pumpAndSettle();

      expect(sessionSource.currentSession, isNull);
    },
  );

  testWidgets(
    'blocked server account is treated as invalid and redirects to login',
    (tester) async {
      final sessionSource = _FakeAuthSessionSource(
        initialSession: const Authenticated(
          uid: 'uid-1',
          email: 'user@example.com',
        ),
      );
      final userStateSource = _FakeUserDocumentStateSource(
        initialState: const UserDocumentServerState(
          exists: true,
          isBlocked: true,
          isDisabled: false,
        ),
      );
      final repository = _FakeAuthRepository(sessionSource: sessionSource);
      addTearDown(sessionSource.dispose);
      addTearDown(userStateSource.dispose);

      await tester.pumpWidget(
        _buildBootstrapWithUserState(
          repository,
          sessionSource,
          userStateSource,
          null,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsOneWidget);
      expect(repository.logoutCalls, 1);
      expect(repository.deleteAccountCalls, 0);
    },
  );

  testWidgets(
    'forced logout runs once even if invalid reason changes before logout completes',
    (tester) async {
      final sessionSource = _FakeAuthSessionSource(
        initialSession: const Authenticated(
          uid: 'uid-1',
          email: 'user@example.com',
        ),
      );
      final userStateSource = _FakeUserDocumentStateSource(
        initialState: const UserDocumentServerState(
          exists: true,
          isBlocked: false,
          isDisabled: false,
        ),
      );
      final logoutCompleter = Completer<void>();
      final repository = _FakeAuthRepository(
        sessionSource: sessionSource,
        logoutCompleter: logoutCompleter,
      );
      addTearDown(sessionSource.dispose);
      addTearDown(userStateSource.dispose);

      await tester.pumpWidget(
        _buildBootstrapWithUserState(
          repository,
          sessionSource,
          userStateSource,
          null,
        ),
      );
      await tester.pumpAndSettle();

      userStateSource.setState(
        const UserDocumentServerState(
          exists: false,
          isBlocked: false,
          isDisabled: false,
        ),
      );
      await tester.pumpAndSettle();

      userStateSource.setState(
        const UserDocumentServerState(
          exists: true,
          isBlocked: true,
          isDisabled: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(repository.logoutCalls, 1);

      logoutCompleter.complete();
      await tester.pumpAndSettle();

      expect(sessionSource.currentSession, isNull);
    },
  );

  testWidgets(
    'manual users document deletion invalidates the session but does not delete the auth account',
    (tester) async {
      final sessionSource = _FakeAuthSessionSource(
        initialSession: const Authenticated(
          uid: 'uid-1',
          email: 'user@example.com',
        ),
      );
      final userStateSource = _FakeUserDocumentStateSource(
        initialState: const UserDocumentServerState(
          exists: true,
          isBlocked: false,
          isDisabled: false,
        ),
      );
      final repository = _FakeAuthRepository(
        sessionSource: sessionSource,
        persistedAuthEmails: <String>{'user@example.com'},
      );
      addTearDown(sessionSource.dispose);
      addTearDown(userStateSource.dispose);

      await tester.pumpWidget(
        _buildBootstrapWithUserState(
          repository,
          sessionSource,
          userStateSource,
          null,
        ),
      );
      await tester.pumpAndSettle();

      userStateSource.setState(
        const UserDocumentServerState(
          exists: false,
          isBlocked: false,
          isDisabled: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsOneWidget);
      expect(repository.logoutCalls, 1);
      expect(repository.deleteAccountCalls, 0);

      final signupResult = await repository.signup(
        email: 'user@example.com',
        password: 'password123',
      );

      expect(signupResult, isA<Failure<void>>());
      expect(
        (signupResult as Failure<void>).error.type,
        AppErrorType.emailAlreadyInUse,
      );
    },
  );

  testWidgets(
    'auth provider disabled account is treated as invalid and redirects to login',
    (tester) async {
      final sessionSource = _FakeAuthSessionSource(
        initialSession: const Authenticated(
          uid: 'uid-1',
          email: 'user@example.com',
        ),
      );
      final userStateSource = _FakeUserDocumentStateSource(
        initialState: const UserDocumentServerState(
          exists: true,
          isBlocked: false,
          isDisabled: false,
        ),
      );
      final authProviderInvalidationSource =
          _FakeAuthProviderInvalidationSource(
            initialState: const AuthSessionInvalidation(
              uid: 'uid-1',
              reason: AuthSessionInvalidationReason.disabledAuthProviderUser,
            ),
          );
      final repository = _FakeAuthRepository(sessionSource: sessionSource);
      addTearDown(sessionSource.dispose);
      addTearDown(userStateSource.dispose);
      addTearDown(authProviderInvalidationSource.dispose);

      await tester.pumpWidget(
        _buildBootstrapWithUserState(
          repository,
          sessionSource,
          userStateSource,
          authProviderInvalidationSource,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsOneWidget);
      expect(repository.logoutCalls, 1);
      expect(repository.deleteAccountCalls, 0);
    },
  );

  testWidgets(
    'auth provider deleted account is treated as invalid and redirects to login',
    (tester) async {
      final sessionSource = _FakeAuthSessionSource(
        initialSession: const Authenticated(
          uid: 'uid-1',
          email: 'user@example.com',
        ),
      );
      final userStateSource = _FakeUserDocumentStateSource(
        initialState: const UserDocumentServerState(
          exists: true,
          isBlocked: false,
          isDisabled: false,
        ),
      );
      final authProviderInvalidationSource =
          _FakeAuthProviderInvalidationSource(
            initialState: const AuthSessionInvalidation(
              uid: 'uid-1',
              reason: AuthSessionInvalidationReason.missingAuthProviderUser,
            ),
          );
      final repository = _FakeAuthRepository(sessionSource: sessionSource);
      addTearDown(sessionSource.dispose);
      addTearDown(userStateSource.dispose);
      addTearDown(authProviderInvalidationSource.dispose);

      await tester.pumpWidget(
        _buildBootstrapWithUserState(
          repository,
          sessionSource,
          userStateSource,
          authProviderInvalidationSource,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsOneWidget);
      expect(repository.logoutCalls, 1);
      expect(repository.deleteAccountCalls, 0);
    },
  );
}

Bootstrap _buildBootstrap(
  _FakeAuthRepository repository,
  _FakeAuthSessionSource sessionSource,
) {
  return _buildBootstrapWithUserState(repository, sessionSource, null, null);
}

ProviderContainer _buildAuthContainer({
  required _FakeAuthSessionSource sessionSource,
  _FakeUserDocumentStateSource? userStateSource,
  _FakeAuthProviderInvalidationSource? authProviderInvalidationSource,
}) {
  return ProviderContainer(
    overrides: <Override>[
      authSessionStreamProvider.overrideWithValue(sessionSource.stream),
      usersDocumentDataSourceProvider.overrideWithValue(
        _FakeUsersDocumentDataSource(userStateSource),
      ),
      authProviderInvalidationWatcherProvider.overrideWithValue(
        (uid) =>
            authProviderInvalidationSource?.stream ??
            Stream<AuthSessionInvalidation?>.value(null),
      ),
    ],
  );
}

Bootstrap _buildBootstrapWithUserState(
  _FakeAuthRepository repository,
  _FakeAuthSessionSource sessionSource,
  _FakeUserDocumentStateSource? userStateSource,
  _FakeAuthProviderInvalidationSource? authProviderInvalidationSource,
) {
  return Bootstrap(
    errorHub: ErrorHub(
      policy: appConfig.errorPolicy,
      logger: const _NoopLogger(),
    ),
    overrides: <Override>[
      authFacadeProvider.overrideWithValue(repository),
      authSessionStreamProvider.overrideWithValue(sessionSource.stream),
      usersDocumentDataSourceProvider.overrideWithValue(
        _FakeUsersDocumentDataSource(userStateSource),
      ),
      authProviderInvalidationWatcherProvider.overrideWithValue(
        (uid) =>
            authProviderInvalidationSource?.stream ??
            Stream<AuthSessionInvalidation?>.value(null),
      ),
    ],
  );
}

class _FakeAuthSessionSource {
  _FakeAuthSessionSource({Authenticated? initialSession})
    : _currentSession = initialSession;

  final StreamController<Authenticated?> _controller =
      StreamController<Authenticated?>.broadcast();
  Authenticated? _currentSession;

  Authenticated? get currentSession => _currentSession;

  Stream<Authenticated?> get stream async* {
    yield _currentSession;
    yield* _controller.stream;
  }

  void setSession(Authenticated? session) {
    _currentSession = session;
    _controller.add(session);
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

class _FakeUserDocumentStateSource {
  _FakeUserDocumentStateSource({UserDocumentServerState? initialState})
    : _currentState = initialState;

  final StreamController<UserDocumentServerState> _controller =
      StreamController<UserDocumentServerState>.broadcast();
  UserDocumentServerState? _currentState;

  Stream<UserDocumentServerState> get stream async* {
    final currentState = _currentState;

    if (currentState != null) {
      yield currentState;
    }

    yield* _controller.stream;
  }

  void setState(UserDocumentServerState state) {
    _currentState = state;
    _controller.add(state);
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

class _FakeUsersDocumentDataSource extends UsersDocumentDataSource {
  _FakeUsersDocumentDataSource(this._source) : super();

  final _FakeUserDocumentStateSource? _source;

  @override
  Stream<UserDocumentServerState> watchUserServerState({required String uid}) {
    return _source?.stream ??
        Stream<UserDocumentServerState>.value(
          const UserDocumentServerState(
            exists: true,
            isBlocked: false,
            isDisabled: false,
          ),
        );
  }
}

class _FakeAuthProviderInvalidationSource {
  _FakeAuthProviderInvalidationSource({AuthSessionInvalidation? initialState})
    : _currentState = initialState;

  final StreamController<AuthSessionInvalidation?> _controller =
      StreamController<AuthSessionInvalidation?>.broadcast();
  AuthSessionInvalidation? _currentState;

  Stream<AuthSessionInvalidation?> get stream async* {
    yield _currentState;
    yield* _controller.stream;
  }

  void setState(AuthSessionInvalidation? state) {
    _currentState = state;
    _controller.add(state);
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

class _FakeAuthRepository implements AuthFacade {
  _FakeAuthRepository({
    required _FakeAuthSessionSource sessionSource,
    this.loginResult,
    this.logoutCompleter,
    Set<String>? persistedAuthEmails,
    this.linkedUserStateSource,
    this.recreateUserDocumentOnLogin = false,
  }) : _sessionSource = sessionSource,
       _persistedAuthEmails = persistedAuthEmails ?? <String>{};

  final _FakeAuthSessionSource _sessionSource;
  final Result<void>? loginResult;
  final Completer<void>? logoutCompleter;
  final Set<String> _persistedAuthEmails;
  final _FakeUserDocumentStateSource? linkedUserStateSource;
  final bool recreateUserDocumentOnLogin;
  int loginCalls = 0;
  int logoutCalls = 0;
  int deleteAccountCalls = 0;

  @override
  Future<Result<void>> login({
    required String email,
    required String password,
  }) async {
    loginCalls += 1;
    if (loginResult != null) {
      return loginResult!;
    }

    _persistedAuthEmails.add(email);
    _sessionSource.setSession(Authenticated(uid: 'uid-1', email: email));

    if (recreateUserDocumentOnLogin) {
      unawaited(
        Future<void>.microtask(() {
          linkedUserStateSource?.setState(
            const UserDocumentServerState(
              exists: true,
              isBlocked: false,
              isDisabled: false,
            ),
          );
        }),
      );
    }

    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> signup({
    required String email,
    required String password,
  }) async {
    if (_persistedAuthEmails.contains(email)) {
      return const Result<void>.failure(AppError.emailAlreadyInUse);
    }

    _persistedAuthEmails.add(email);
    _sessionSource.setSession(Authenticated(uid: 'uid-2', email: email));

    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> logout() async {
    logoutCalls += 1;
    if (logoutCompleter != null) {
      await logoutCompleter!.future;
    }

    _sessionSource.setSession(null);

    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> sendPasswordResetEmail({required String email}) async {
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> changePassword(ChangePasswordInput input) async {
    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> deleteAccount(DeleteAccountInput input) async {
    deleteAccountCalls += 1;
    final currentEmail = _sessionSource.currentSession?.email;

    if (currentEmail != null) {
      _persistedAuthEmails.remove(currentEmail);
    }

    _sessionSource.setSession(null);

    return const Result<void>.success(null);
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
}

class _NoopLogger implements Logger {
  const _NoopLogger();

  @override
  void log(ErrorEnvelope error, ErrorSeverity severity) {}
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_forge/bootstrap/bootstrap.dart';
import 'package:app_forge/engine/engine.dart';
import 'package:app_forge/app/app_config.dart';
import 'package:app_forge/features/auth/domain/app_error.dart';
import 'package:app_forge/features/auth/domain/auth_repository.dart';
import 'package:app_forge/features/auth/domain/auth_session.dart';
import 'package:app_forge/features/auth/domain/result.dart';
import 'package:app_forge/features/auth/state/auth_repository_provider.dart';
import 'package:app_forge/features/auth/state/auth_session_provider.dart';

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
      initialSession: const AuthSession(
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
      initialSession: const AuthSession(
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
    expect(find.byTooltip('Open navigation menu'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
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
        initialSession: const AuthSession(
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
      initialSession: const AuthSession(
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
}

Bootstrap _buildBootstrap(
  _FakeAuthRepository repository,
  _FakeAuthSessionSource sessionSource,
) {
  return Bootstrap(
    errorHub: ErrorHub(
      policy: appConfig.errorPolicy,
      logger: const _NoopLogger(),
    ),
    overrides: <Override>[
      authRepositoryProvider.overrideWithValue(repository),
      authSessionStreamProvider.overrideWithValue(sessionSource.stream),
    ],
  );
}

class _FakeAuthSessionSource {
  _FakeAuthSessionSource({AuthSession? initialSession})
    : _currentSession = initialSession;

  final StreamController<AuthSession?> _controller =
      StreamController<AuthSession?>.broadcast();
  AuthSession? _currentSession;

  Stream<AuthSession?> get stream async* {
    yield _currentSession;
    yield* _controller.stream;
  }

  void setSession(AuthSession? session) {
    _currentSession = session;
    _controller.add(session);
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    required _FakeAuthSessionSource sessionSource,
    this.loginResult,
  }) : _sessionSource = sessionSource;

  final _FakeAuthSessionSource _sessionSource;
  final Result<void>? loginResult;

  @override
  Future<Result<void>> login({
    required String email,
    required String password,
  }) async {
    if (loginResult != null) {
      return loginResult!;
    }

    _sessionSource.setSession(AuthSession(uid: 'uid-1', email: email));

    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> signup({
    required String email,
    required String password,
  }) async {
    _sessionSource.setSession(AuthSession(uid: 'uid-2', email: email));

    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> logout() async {
    _sessionSource.setSession(null);

    return const Result<void>.success(null);
  }

  @override
  Future<Result<void>> sendPasswordResetEmail({required String email}) async {
    return const Result<void>.success(null);
  }

  @override
  Result<void> validateLogin({
    required String email,
    required String password,
  }) {
    if (!_isValidEmail(email)) {
      return const Result<void>.failure(AppError.invalidEmail);
    }

    if (!_isValidPassword(password)) {
      return const Result<void>.failure(AppError.invalidPassword);
    }

    return const Result<void>.success(null);
  }

  @override
  Result<void> validateSignup({
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    if (!_isValidEmail(email)) {
      return const Result<void>.failure(AppError.invalidEmail);
    }

    if (!_isValidPassword(password)) {
      return const Result<void>.failure(AppError.invalidPassword);
    }

    if (password != confirmPassword) {
      return const Result<void>.failure(AppError.passwordMismatch);
    }

    return const Result<void>.success(null);
  }

  @override
  Result<void> validateReset({required String email}) {
    if (!_isValidEmail(email)) {
      return const Result<void>.failure(AppError.invalidEmail);
    }

    return const Result<void>.success(null);
  }

  bool _isValidEmail(String email) {
    return email.contains('@');
  }

  bool _isValidPassword(String password) {
    return password.length >= 8;
  }
}

class _NoopLogger implements Logger {
  const _NoopLogger();

  @override
  void log(ErrorEnvelope error, ErrorSeverity severity) {}
}

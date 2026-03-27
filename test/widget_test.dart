import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app_forge/bootstrap/bootstrap.dart';
import 'package:app_forge/features/auth/domain/auth_repository.dart';
import 'package:app_forge/features/auth/domain/auth_session.dart';
import 'package:app_forge/features/auth/domain/result.dart';
import 'package:app_forge/features/auth/presentation/auth_repository_provider.dart';

/// router shell 동작 검증용 widget test 묶음.
void main() {
  testWidgets('unauthenticated app redirects to login route', (tester) async {
    final repository = _FakeAuthRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      Bootstrap(
        overrides: <Override>[
          authRepositoryProvider.overrideWithValue(repository),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsOneWidget);
    expect(
      find.text('Standalone route outside the Engine shell.'),
      findsOneWidget,
    );
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('authenticated app renders shell home route', (tester) async {
    final repository = _FakeAuthRepository(
      initialSession: const AuthSession(
        uid: 'uid-1',
        email: 'user@example.com',
      ),
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      Bootstrap(
        overrides: <Override>[
          authRepositoryProvider.overrideWithValue(repository),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Phase 2 Home Route'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('authenticated bottom nav moves from home to profile route', (
    tester,
  ) async {
    final repository = _FakeAuthRepository(
      initialSession: const AuthSession(
        uid: 'uid-1',
        email: 'user@example.com',
      ),
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      Bootstrap(
        overrides: <Override>[
          authRepositoryProvider.overrideWithValue(repository),
        ],
      ),
    );
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
    final repository = _FakeAuthRepository();
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      Bootstrap(
        overrides: <Override>[
          authRepositoryProvider.overrideWithValue(repository),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('Phase 2 Home Route'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets(
    'authenticated home page button navigates to param detail route',
    (tester) async {
      final repository = _FakeAuthRepository(
        initialSession: const AuthSession(
          uid: 'uid-1',
          email: 'user@example.com',
        ),
      );
      addTearDown(repository.dispose);

      await tester.pumpWidget(
        Bootstrap(
          overrides: <Override>[
            authRepositoryProvider.overrideWithValue(repository),
          ],
        ),
      );
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
    final repository = _FakeAuthRepository(
      initialSession: const AuthSession(
        uid: 'uid-1',
        email: 'user@example.com',
      ),
    );
    addTearDown(repository.dispose);

    await tester.pumpWidget(
      Bootstrap(
        overrides: <Override>[
          authRepositoryProvider.overrideWithValue(repository),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({AuthSession? initialSession})
    : _currentSession = initialSession,
      _controller = StreamController<AuthSession?>.broadcast();

  final StreamController<AuthSession?> _controller;
  AuthSession? _currentSession;

  @override
  AuthSession? currentSession() {
    return _currentSession;
  }

  @override
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    final session = AuthSession(uid: 'uid-1', email: email);
    _currentSession = session;
    _controller.add(session);

    return Result<AuthSession>.success(session);
  }

  @override
  Future<Result<void>> logout() async {
    _currentSession = null;
    _controller.add(null);

    return const Result<void>.success(null);
  }

  @override
  Stream<AuthSession?> watchSession() async* {
    yield _currentSession;
    yield* _controller.stream;
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

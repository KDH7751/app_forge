import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_forge/main.dart';

/// router shell 동작 검증용 widget test 묶음.
void main() {
  testWidgets('Phase 2 router app renders shell home route', (tester) async {
    await tester.pumpWidget(const MainApp());
    await tester.pumpAndSettle();

    expect(find.text('Phase 2 Home Route'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('bottom nav moves from home to profile route', (tester) async {
    await tester.pumpWidget(const MainApp());
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

  testWidgets('home page button navigates to standalone login route', (
    tester,
  ) async {
    await tester.pumpWidget(const MainApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
    expect(
      find.text('Standalone route outside the Engine shell.'),
      findsOneWidget,
    );
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('home page button navigates to param detail route', (
    tester,
  ) async {
    await tester.pumpWidget(const MainApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Post 42'));
    await tester.pumpAndSettle();

    expect(find.text('Resolved path param id: 42'), findsOneWidget);
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byTooltip('Open navigation menu'), findsNothing);
  });
}

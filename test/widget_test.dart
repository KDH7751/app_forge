import 'package:flutter_test/flutter_test.dart';

import 'package:app_forge/main.dart';

void main() {
  testWidgets('Phase 1 placeholder app renders home page', (tester) async {
    await tester.pumpWidget(const MainApp());

    expect(find.text('App Forge'), findsOneWidget);
    expect(find.text('Phase 1 Home Placeholder'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:ryvo/main.dart' as app;

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder, {int max = 30}) async {
  for (var i = 0; i < max; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (finder.evaluate().isNotEmpty) return;
  }
}

Future<void> _signIn(WidgetTester tester, String email, String password) async {
  await _pumpUntilFound(tester, find.text('Sign in'));
  await tester.tap(find.text('Sign in').last);
  await tester.pumpAndSettle();
  await _pumpUntilFound(tester, find.textContaining('Driver and client accounts only'));
  final fields = find.byType(EditableText);
  await tester.enterText(fields.at(0), email);
  await tester.enterText(fields.at(1), password);
  await tester.tap(find.text('Sign in').last);
  await tester.pumpAndSettle(const Duration(seconds: 8));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('client bottom nav matches spec', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 4));
    await _signIn(tester, 'client@ryvo-line.com', 'Client@123');

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Orders'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    expect(find.text('Go to'), findsOneWidget);
    expect(find.text('Requesting'), findsOneWidget);

    await tester.tap(find.text('Orders'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.textContaining('Trip history'), findsWidgets);

    await tester.tap(find.text('Support'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await tester.tap(find.text('Analytics'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle(const Duration(seconds: 4));
    expect(find.text('Request a ride').evaluate().isNotEmpty || find.text('Go to').evaluate().isNotEmpty, isTrue);
  });
}

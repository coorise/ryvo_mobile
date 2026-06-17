import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo/i18n/app_i18n.dart';
import 'package:ryvo/main.dart';
import 'package:ryvo/stores/auth_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('RyvoApp smoke test', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await AppI18n.instance.load('en');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const RyvoApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ShadApp), findsOneWidget);
  });

  test('AuthState defaults', () {
    const state = AuthState();
    expect(state.isReady, isFalse);
    expect(state.user, isNull);
  });
}

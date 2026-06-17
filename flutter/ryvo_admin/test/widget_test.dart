import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo_admin/app/landing/landing_page.dart';
import 'package:ryvo_admin/stores/auth_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Landing page renders brand', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: ShadApp(
          home: const LandingPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('Ryvo-Line'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  test('AuthState defaults', () {
    const state = AuthState();
    expect(state.isReady, isFalse);
    expect(state.user, isNull);
  });
}

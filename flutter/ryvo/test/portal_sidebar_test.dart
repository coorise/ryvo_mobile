import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:ryvo/app/driver/home_page.dart';
import 'package:ryvo/components/layout/portal_shell.dart';
import 'package:ryvo/configs/portal_nav.dart';
import 'package:ryvo/i18n/app_i18n.dart';
import 'package:ryvo/lib/api_client.dart';
import 'package:ryvo/stores/auth_store.dart';
import 'package:ryvo/types/interfaces/schemas/auth_schema.dart';
import 'package:ryvo/types/interfaces/schemas/session_user.dart';

void main() {
  setUpAll(() async {
    apiClientTestMode = true;
    SharedPreferences.setMockInitialValues({});
    TestWidgetsFlutterBinding.ensureInitialized();
    await AppI18n.instance.load('en');
  });

  tearDownAll(() {
    apiClientTestMode = false;
  });

  testWidgets('driver sidebar uses collapsible groups like admin', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final user = SessionUser(
      id: 'test-user',
      email: 'driver@test.com',
      roles: const ['driver'],
      emailVerified: true,
      fullName: 'Test Driver',
    );
    final session = AuthSession(user: user, accessToken: 'test-token');

    final router = GoRouter(
      initialLocation: '/driver',
      routes: [
        GoRoute(
          path: '/driver',
          builder: (context, state) => PortalShell(
            area: PortalArea.driver,
            child: const DriverHomePage(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authProvider.overrideWith(
            (ref) => AuthNotifier(null, initial: AuthState(session: session, isReady: true)),
          ),
        ],
        child: ShadApp.router(
          theme: ShadThemeData(brightness: Brightness.light, colorScheme: const ShadGreenColorScheme.light()),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('en')],
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    await tester.tap(find.byIcon(LucideIcons.menu));
    await tester.pumpAndSettle();

    expect(find.text('OVERVIEW'), findsOneWidget);
    expect(find.text('Main'), findsOneWidget);
    expect(find.text('Communication'), findsOneWidget);
    expect(find.text('Notifications'), findsNothing);

    await tester.tap(find.text('Communication'));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
  });
}

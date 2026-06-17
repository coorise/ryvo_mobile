import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo/app/router.dart';
import 'package:ryvo/configs/const.dart';
import 'package:ryvo/i18n/app_i18n.dart';
import 'package:ryvo/lib/api_client.dart';
import 'package:ryvo/stores/auth_store.dart';
import 'package:ryvo/types/interfaces/schemas/auth_schema.dart';
import 'package:ryvo/types/interfaces/schemas/session_user.dart';

AuthState _portalSession({required List<String> roles}) {
  final user = SessionUser(
    id: 'test-user',
    email: 'user@test.com',
    roles: roles,
    emailVerified: true,
    fullName: 'Test User',
  );
  return AuthState(
    session: AuthSession(user: user, accessToken: 'test-token'),
    isReady: true,
  );
}

Widget _testApp(GoRouter router) {
  return ShadApp.router(
    theme: ShadThemeData(brightness: Brightness.light, colorScheme: const ShadGreenColorScheme.light()),
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('en')],
    routerConfig: router,
  );
}

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

  testWidgets('splash redirects logged-in client to client live map', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    late GoRouter router;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authProvider.overrideWith(
            (ref) => AuthNotifier(null, initial: _portalSession(roles: const ['client'])),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            router = ref.read(routerProvider);
            return _testApp(router);
          },
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    expect(router.routeInformationProvider.value.uri.path, Routes.clientLiveMap);
  });

  testWidgets('logged-in client can open landing without redirect', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    late GoRouter router;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authProvider.overrideWith(
            (ref) => AuthNotifier(null, initial: _portalSession(roles: const ['client'])),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            router = ref.read(routerProvider);
            return _testApp(router);
          },
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    router.go(Routes.landing);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    expect(router.routeInformationProvider.value.uri.path, Routes.landing);
    expect(find.textContaining('Ryvo-Line'), findsWidgets);
  });

  testWidgets('landing mobile header shows brand, sign in, and menu', (tester) async {
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authProvider.overrideWith(
            (ref) => AuthNotifier(null, initial: const AuthState(isReady: true)),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.read(routerProvider);
            return _testApp(router);
          },
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('MOBILITY'), findsOneWidget);
    expect(find.byType(IconButton), findsNWidgets(2));
  });
}

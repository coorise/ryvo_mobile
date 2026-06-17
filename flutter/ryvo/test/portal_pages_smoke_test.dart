import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo/app/client/audits/activity_logs_page.dart';
import 'package:ryvo/app/client/audits/analytics_page.dart';
import 'package:ryvo/app/client/audits/security_logs_page.dart';
import 'package:ryvo/app/client/communication/chat_page.dart';
import 'package:ryvo/app/client/communication/chat_support_page.dart';
import 'package:ryvo/app/client/communication/notifications_page.dart';
import 'package:ryvo/app/client/finances/payments_page.dart';
import 'package:ryvo/app/client/home_page.dart';
import 'package:ryvo/app/client/hr/feedbacks_page.dart';
import 'package:ryvo/app/client/main/drivers_page.dart';
import 'package:ryvo/app/client/main/live_map_page.dart';
import 'package:ryvo/app/client/main/rides_page.dart';
import 'package:ryvo/app/client/settings/configurations_page.dart';
import 'package:ryvo/app/client/settings/profile_page.dart';
import 'package:ryvo/app/driver/audits/activity_logs_page.dart';
import 'package:ryvo/app/driver/audits/analytics_page.dart';
import 'package:ryvo/app/driver/audits/security_logs_page.dart';
import 'package:ryvo/app/driver/communication/chat_page.dart';
import 'package:ryvo/app/driver/communication/chat_support_page.dart';
import 'package:ryvo/app/driver/communication/messages_page.dart';
import 'package:ryvo/app/driver/communication/notifications_page.dart';
import 'package:ryvo/app/driver/finances/payments_page.dart';
import 'package:ryvo/app/driver/home_page.dart';
import 'package:ryvo/app/driver/hr/feedbacks_page.dart';
import 'package:ryvo/app/driver/main/clients_page.dart';
import 'package:ryvo/app/driver/main/kyc_page.dart';
import 'package:ryvo/app/driver/main/live_map_page.dart';
import 'package:ryvo/app/driver/main/rides_page.dart';
import 'package:ryvo/app/driver/settings/configurations_page.dart';
import 'package:ryvo/app/driver/settings/profile_page.dart';
import 'package:ryvo/app/landing/landing_page.dart';
import 'package:ryvo/app/auth/login_page.dart';
import 'package:ryvo/app/auth/register_page.dart';
import 'package:ryvo/i18n/app_i18n.dart';
import 'package:ryvo/lib/api_client.dart';
import 'package:ryvo/stores/auth_store.dart';
import 'package:ryvo/types/interfaces/schemas/session_user.dart';

Future<void> _pumpPortalPage(WidgetTester tester, Widget page, {required List<String> roles}) async {
  final prefs = await SharedPreferences.getInstance();

  final user = SessionUser(
    id: 'test-user',
    email: 'user@test.com',
    roles: roles,
    emailVerified: true,
    fullName: 'Test User',
  );
  final session = AuthSession(user: user, accessToken: 'test-token');

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authProvider.overrideWith(
          (ref) => AuthNotifier(
            null,
            initial: AuthState(session: session, isReady: true),
          ),
        ),
      ],
      child: ShadApp(
        theme: ShadThemeData(brightness: Brightness.light, colorScheme: const ShadGreenColorScheme.light()),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('en')],
        home: Material(child: page),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _disposePage(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
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

  final driverPages = <Widget>[
    const DriverHomePage(),
    const DriverLiveMapPage(),
    const DriverRidesPage(),
    const DriverClientsPage(),
    const DriverKycPage(),
    const DriverNotificationsPage(),
    const DriverChatPage(),
    const DriverMessagesPage(),
    const DriverChatSupportPage(),
    const DriverFeedbacksPage(),
    const DriverPaymentsPage(),
    const DriverAnalyticsPage(),
    const DriverActivityLogsPage(),
    const DriverSecurityLogsPage(),
    const DriverProfilePage(),
    const DriverConfigurationsPage(),
  ];

  final clientPages = <Widget>[
    const ClientHomePage(),
    const ClientLiveMapPage(),
    const ClientRidesPage(),
    const ClientDriversPage(),
    const ClientNotificationsPage(),
    const ClientChatPage(),
    const ClientChatSupportPage(),
    const ClientFeedbacksPage(),
    const ClientPaymentsPage(),
    const ClientAnalyticsPage(),
    const ClientActivityLogsPage(),
    const ClientSecurityLogsPage(),
    const ClientProfilePage(),
    const ClientConfigurationsPage(),
  ];

  group('public pages render', () {
    testWidgets('landing page', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: ShadApp(
            theme: ShadThemeData(brightness: Brightness.light, colorScheme: const ShadGreenColorScheme.light()),
            home: const Material(child: LandingPage()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Register'), findsWidgets);
      expect(find.text('Sign in'), findsWidgets);
      await _disposePage(tester);
    });

    testWidgets('login page', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: ShadApp(
            theme: ShadThemeData(brightness: Brightness.light, colorScheme: const ShadGreenColorScheme.light()),
            home: const Material(child: LoginPage()),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Sign in'), findsWidgets);
      await _disposePage(tester);
    });

    testWidgets('register page', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: ShadApp(
            theme: ShadThemeData(brightness: Brightness.light, colorScheme: const ShadGreenColorScheme.light()),
            home: const Material(child: RegisterPage()),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Create account'), findsWidgets);
      expect(find.text('Rider'), findsOneWidget);
      expect(find.text('Driver'), findsOneWidget);
      await _disposePage(tester);
    });
  });

  for (var i = 0; i < driverPages.length; i++) {
    testWidgets('driver page $i renders without exception', (tester) async {
      await _pumpPortalPage(tester, driverPages[i], roles: const ['driver']);
      await _disposePage(tester);
    });
  }

  for (var i = 0; i < clientPages.length; i++) {
    testWidgets('client page $i renders without exception', (tester) async {
      await _pumpPortalPage(tester, clientPages[i], roles: const ['client']);
      await _disposePage(tester);
    });
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ryvo/app/auth/forgot_password_page.dart';
import 'package:ryvo/app/auth/login_page.dart';
import 'package:ryvo/app/auth/register_page.dart';
import 'package:ryvo/app/auth/verify_email_page.dart';
import 'package:ryvo/app/auth/otp_page.dart';
import 'package:ryvo/app/auth/reset_password_page.dart';
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
import 'package:ryvo/app/client/drive/ride_detail_page.dart';
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
import 'package:ryvo/app/driver/main/kyc/cars/car_detail_page.dart';
import 'package:ryvo/app/driver/main/kyc/cars/edit_car_page.dart';
import 'package:ryvo/app/driver/main/kyc/cars/new_car_page.dart';
import 'package:ryvo/app/driver/main/kyc_page.dart';
import 'package:ryvo/app/driver/main/live_map_page.dart';
import 'package:ryvo/app/driver/main/rides_page.dart';
import 'package:ryvo/app/driver/drive/ride_detail_page.dart';
import 'package:ryvo/app/driver/settings/configurations_page.dart';
import 'package:ryvo/app/driver/settings/profile_page.dart';
import 'package:ryvo/app/landing/landing_page.dart';
import 'package:ryvo/app/legal/legal_scaffold_page.dart';
import 'package:ryvo/app/splash.dart';
import 'package:ryvo/components/layout/portal_shell.dart';
import 'package:ryvo/configs/const.dart';
import 'package:ryvo/configs/portal_nav.dart';
import 'package:ryvo/guards/abac.dart';
import 'package:ryvo/guards/internal_user.dart';
import 'package:ryvo/guards/portal_access.dart';
import 'package:ryvo/stores/auth_store.dart';
import 'package:ryvo/types/interfaces/schemas/session_user.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

class RouterRefreshNotifier extends ChangeNotifier {
  void notifyRouter() => notifyListeners();
}

final routerRefreshProvider = Provider<RouterRefreshNotifier>((ref) {
  final notifier = RouterRefreshNotifier();
  ref.listen(authProvider, (_, _) => notifier.notifyRouter());
  ref.onDispose(notifier.dispose);
  return notifier;
});

PortalArea? _areaForPath(String path) {
  if (path.startsWith('/driver')) return PortalArea.driver;
  if (path.startsWith('/client')) return PortalArea.client;
  return null;
}

String _firstPortalPath(SessionUser? user) {
  if (Abac.hasStrictRole(user, const ['driver'])) {
    return firstAllowedPortalPath(user, PortalArea.driver);
  }
  if (Abac.hasStrictRole(user, const ['client'])) {
    return firstAllowedPortalPath(user, PortalArea.client);
  }
  return Routes.authLogin;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.read(routerRefreshProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final path = state.uri.path;
      final ready = auth.isReady;
      final user = auth.user;
      final hasSession = auth.session != null && user != null;
      final isPortal = hasSession && Abac.isPortalUser(user);
      final isInternal = hasSession && isInternalPortalUser(user);
      final isAuthRoute = path.startsWith('/auth');
      final isPublic = path == Routes.splash ||
          path == Routes.landing ||
          isAuthRoute ||
          path.startsWith('/legal');

      if (!ready) return Routes.splash;

      if (path == Routes.splash) {
        if (!hasSession) return Routes.landing;
        if (isInternal) return Routes.authLogin;
        if (isPortal && !user.emailVerified) return Routes.authVerifyEmail;
        if (isPortal) return Abac.portalDashboardPathForUser(user);
        return Routes.authLogin;
      }

      if (hasSession && isPortal && !user.emailVerified) {
        if (path != Routes.authVerifyEmail && !isAuthRoute && path != Routes.landing) {
          return Routes.authVerifyEmail;
        }
      }

      if (isPortal && (path == Routes.authLogin || path == Routes.authRegister)) {
        if (!user.emailVerified) return Routes.authVerifyEmail;
        return Abac.portalDashboardPathForUser(user);
      }

      if (!hasSession && !isPublic) return Routes.authLogin;
      if (isInternal && !isPublic) return Routes.authLogin;

      if (hasSession && isPortal) {
        if (path.startsWith('/driver') && !Abac.hasStrictRole(user, const ['driver'])) {
          return Routes.clientHome;
        }
        if (path.startsWith('/client') && !Abac.hasStrictRole(user, const ['client'])) {
          return Routes.driverHome;
        }
      }

      final area = _areaForPath(path);
      if (isPortal && area != null && !canAccessPortalPath(user, area, path)) {
        return _firstPortalPath(user);
      }

      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: Routes.landing,
        builder: (context, state) => const LandingPage(),
      ),
      GoRoute(
        path: Routes.authLogin,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: Routes.authRegister,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: Routes.authVerifyEmail,
        builder: (context, state) => const VerifyEmailPage(),
      ),
      GoRoute(
        path: Routes.authForgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: Routes.authOtp,
        builder: (context, state) => const OtpPage(),
      ),
      GoRoute(
        path: Routes.authResetPassword,
        builder: (context, state) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: Routes.legalTos,
        builder: (context, state) => const LegalScaffoldPage(title: 'Terms of Service'),
      ),
      GoRoute(
        path: Routes.legalPrivacy,
        builder: (context, state) => const LegalScaffoldPage(title: 'Privacy Policy'),
      ),
      ShellRoute(
        builder: (context, state, child) => PortalShell(area: PortalArea.driver, child: child),
        routes: [
          GoRoute(
            path: Routes.driverHome,
            pageBuilder: (context, state) => const NoTransitionPage(child: DriverHomePage()),
            routes: [
              GoRoute(
                path: 'main/live-map',
                pageBuilder: (context, state) => const NoTransitionPage(child: DriverLiveMapPage()),
              ),
              GoRoute(
                path: 'main/rides',
                pageBuilder: (context, state) => const NoTransitionPage(child: DriverRidesPage()),
              ),
              GoRoute(
                path: 'drive/:tripId',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: DriverRideDetailPage(tripId: state.pathParameters['tripId']!),
                ),
              ),
              GoRoute(
                path: 'main/clients',
                pageBuilder: (context, state) => const NoTransitionPage(child: DriverClientsPage()),
              ),
              GoRoute(
                path: 'main/kyc',
                pageBuilder: (context, state) => const NoTransitionPage(child: DriverKycPage()),
                routes: [
                  GoRoute(
                    path: 'cars/new',
                    pageBuilder: (context, state) => const NoTransitionPage(child: DriverNewCarPage()),
                  ),
                  GoRoute(
                    path: 'cars/:carId',
                    pageBuilder: (context, state) => NoTransitionPage(
                      child: DriverCarDetailPage(carId: state.pathParameters['carId']!),
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        pageBuilder: (context, state) => NoTransitionPage(
                          child: DriverEditCarPage(carId: state.pathParameters['carId']!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: 'communication/notifications',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: DriverNotificationsPage()),
              ),
              GoRoute(
                path: 'communication/chat',
                pageBuilder: (context, state) => const NoTransitionPage(child: DriverChatPage()),
              ),
              GoRoute(
                path: 'communication/messages',
                pageBuilder: (context, state) => const NoTransitionPage(child: DriverMessagesPage()),
              ),
              GoRoute(
                path: 'communication/chat-support',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: DriverChatSupportPage()),
              ),
              GoRoute(
                path: 'hr/feedbacks',
                pageBuilder: (context, state) => const NoTransitionPage(child: DriverFeedbacksPage()),
              ),
              GoRoute(
                path: 'finances/payments',
                pageBuilder: (context, state) => const NoTransitionPage(child: DriverPaymentsPage()),
              ),
              GoRoute(
                path: 'audits/security-logs',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: DriverSecurityLogsPage()),
              ),
              GoRoute(
                path: 'audits/activity-logs',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: DriverActivityLogsPage()),
              ),
              GoRoute(
                path: 'audits/analytics',
                pageBuilder: (context, state) => const NoTransitionPage(child: DriverAnalyticsPage()),
              ),
              GoRoute(
                path: 'settings/profile',
                pageBuilder: (context, state) => const NoTransitionPage(child: DriverProfilePage()),
              ),
              GoRoute(
                path: 'settings/configurations',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: DriverConfigurationsPage()),
              ),
            ],
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => PortalShell(area: PortalArea.client, child: child),
        routes: [
          GoRoute(
            path: Routes.clientHome,
            pageBuilder: (context, state) => const NoTransitionPage(child: ClientHomePage()),
            routes: [
              GoRoute(
                path: 'main/live-map',
                pageBuilder: (context, state) => const NoTransitionPage(child: ClientLiveMapPage()),
              ),
              GoRoute(
                path: 'main/rides',
                pageBuilder: (context, state) => const NoTransitionPage(child: ClientRidesPage()),
              ),
              GoRoute(
                path: 'drive/:tripId',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: ClientRideDetailPage(tripId: state.pathParameters['tripId']!),
                ),
              ),
              GoRoute(
                path: 'main/drivers',
                pageBuilder: (context, state) => const NoTransitionPage(child: ClientDriversPage()),
              ),
              GoRoute(
                path: 'communication/notifications',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ClientNotificationsPage()),
              ),
              GoRoute(
                path: 'communication/chat',
                pageBuilder: (context, state) => const NoTransitionPage(child: ClientChatPage()),
              ),
              GoRoute(
                path: 'communication/chat-support',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ClientChatSupportPage()),
              ),
              GoRoute(
                path: 'hr/feedbacks',
                pageBuilder: (context, state) => const NoTransitionPage(child: ClientFeedbacksPage()),
              ),
              GoRoute(
                path: 'finances/payments',
                pageBuilder: (context, state) => const NoTransitionPage(child: ClientPaymentsPage()),
              ),
              GoRoute(
                path: 'audits/security-logs',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ClientSecurityLogsPage()),
              ),
              GoRoute(
                path: 'audits/activity-logs',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ClientActivityLogsPage()),
              ),
              GoRoute(
                path: 'audits/analytics',
                pageBuilder: (context, state) => const NoTransitionPage(child: ClientAnalyticsPage()),
              ),
              GoRoute(
                path: 'settings/profile',
                pageBuilder: (context, state) => const NoTransitionPage(child: ClientProfilePage()),
              ),
              GoRoute(
                path: 'settings/configurations',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ClientConfigurationsPage()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

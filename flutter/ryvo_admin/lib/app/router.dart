import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ryvo_admin/app/admin/finance/checkouts_page.dart';
import 'package:ryvo_admin/app/admin/finance/paychecks_page.dart';
import 'package:ryvo_admin/app/admin/finance/referrals_page.dart';
import 'package:ryvo_admin/app/admin/finance/speculative_page.dart';
import 'package:ryvo_admin/app/admin/finance/tariffs_page.dart';
import 'package:ryvo_admin/app/admin/analytics/analytics_page.dart';
import 'package:ryvo_admin/app/admin/audit/audit_page.dart';
import 'package:ryvo_admin/app/admin/communication/chat_support_page.dart';
import 'package:ryvo_admin/app/admin/communication/message_compose_page.dart';
import 'package:ryvo_admin/app/admin/communication/messages_page.dart';
import 'package:ryvo_admin/app/admin/communication/notifications_page.dart';
import 'package:ryvo_admin/app/admin/drivers/driver_profile_page.dart';
import 'package:ryvo_admin/app/admin/drivers/drivers_page.dart';
import 'package:ryvo_admin/app/admin/drivers/new_driver_page.dart';
import 'package:ryvo_admin/app/admin/home_page.dart';
import 'package:ryvo_admin/app/admin/hr/feedbacks_page.dart';
import 'package:ryvo_admin/app/admin/map/map_page.dart';
import 'package:ryvo_admin/app/admin/observability/observability_page.dart';
import 'package:ryvo_admin/app/admin/payments/payments_page.dart';
import 'package:ryvo_admin/app/admin/rides/rides_page.dart';
import 'package:ryvo_admin/app/admin/security/security_page.dart';
import 'package:ryvo_admin/app/admin/staff/assign_role_page.dart';
import 'package:ryvo_admin/app/admin/staff/new_role_page.dart';
import 'package:ryvo_admin/app/admin/staff/new_staff_page.dart';
import 'package:ryvo_admin/app/admin/staff/staff_page.dart';
import 'package:ryvo_admin/app/admin/staff/staff_profile_page.dart';
import 'package:ryvo_admin/app/admin/settings/configurations_page.dart';
import 'package:ryvo_admin/app/admin/settings/profile_page.dart';
import 'package:ryvo_admin/app/admin/settings/tasks_page.dart';
import 'package:ryvo_admin/app/admin/users/new_user_page.dart';
import 'package:ryvo_admin/app/admin/users/user_profile_page.dart';
import 'package:ryvo_admin/app/admin/users/users_page.dart';
import 'package:ryvo_admin/app/auth/forgot_password_page.dart';
import 'package:ryvo_admin/app/auth/login_page.dart';
import 'package:ryvo_admin/app/auth/otp_page.dart';
import 'package:ryvo_admin/app/auth/reset_password_page.dart';
import 'package:ryvo_admin/app/legal/legal_scaffold_page.dart';
import 'package:ryvo_admin/app/landing/landing_page.dart';
import 'package:ryvo_admin/app/splash.dart';
import 'package:ryvo_admin/components/layout/admin_shell.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/guards/abac.dart';
import 'package:ryvo_admin/guards/admin_access.dart';
import 'package:ryvo_admin/stores/auth_store.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: Routes.splash,
    redirect: (context, state) {
      final path = state.uri.path;
      final ready = auth.isReady;
      final user = auth.user;
      final loggedIn = user != null && Abac.canAccessDashboard(user);
      final isAuthRoute = path.startsWith('/auth');
      final isPublic =
          path == Routes.splash || path == Routes.landing || isAuthRoute;
      final isAdmin = path.startsWith('/admin');

      if (!ready) return Routes.splash;
      if (loggedIn && path == Routes.authLogin) {
        return AdminAccess.firstAllowedAdminPath(user);
      }
      if (!loggedIn && !isPublic) return Routes.authLogin;
      if (loggedIn && isAdmin && !AdminAccess.canAccessAdminPath(user, path)) {
        return AdminAccess.firstAllowedAdminPath(user);
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
        redirect: (_, _) => Routes.authLogin,
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
        path: Routes.authVerifyEmail,
        builder: (context, state) => const VerifyEmailPage(),
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
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: Routes.adminHome,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AdminHomePage()),
            routes: [
              GoRoute(
                path: 'map',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: AdminMapPage()),
              ),
              GoRoute(
                path: 'rides',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: AdminRidesPage()),
              ),
              GoRoute(
                path: 'users',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: AdminUsersPage()),
                routes: [
                  GoRoute(
                    path: 'new',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: NewUserPage()),
                  ),
                  GoRoute(
                    path: 'profile',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: UserProfilePage()),
                  ),
                ],
              ),
              GoRoute(
                path: 'drivers',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: AdminDriversPage()),
                routes: [
                  GoRoute(
                    path: 'new',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: NewDriverPage()),
                  ),
                  GoRoute(
                    path: 'profile',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: DriverProfilePage()),
                  ),
                ],
              ),
              GoRoute(
                path: 'tickets',
                redirect: (_, __) => Routes.adminChatSupport,
              ),
              GoRoute(
                path: 'payments',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: AdminPaymentsPage()),
              ),
              GoRoute(
                path: 'security',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: AdminSecurityPage()),
              ),
              GoRoute(
                path: 'audit',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: AdminAuditPage()),
              ),
              GoRoute(
                path: 'analytics',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: AdminAnalyticsPage()),
              ),
              GoRoute(
                path: 'observability',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: AdminObservabilityPage()),
              ),
              GoRoute(
                path: 'communication',
                redirect: (_, _) => Routes.adminCommNotifications,
                routes: [
                  GoRoute(
                    path: 'notifications',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: AdminNotificationsPage()),
                  ),
                  GoRoute(
                    path: 'messages',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: AdminMessagesPage()),
                    routes: [
                      GoRoute(
                        path: 'new',
                        pageBuilder: (context, state) =>
                            const NoTransitionPage(child: MessageComposePage()),
                      ),
                      GoRoute(
                        path: ':id/edit',
                        pageBuilder: (context, state) {
                          final id = state.pathParameters['id'] ?? '';
                          return NoTransitionPage(
                            child: MessageComposePage(campaignId: id),
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'chat-support',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: AdminChatSupportPage()),
                  ),
                ],
              ),
              GoRoute(
                path: 'staff',
                pageBuilder: (context, state) =>
                    NoTransitionPage(child: StaffPage()),
                routes: [
                  GoRoute(
                    path: 'new',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: NewStaffPage()),
                  ),
                  GoRoute(
                    path: 'assign',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: AssignRolePage()),
                  ),
                  GoRoute(
                    path: 'profile',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: StaffProfilePage()),
                  ),
                  GoRoute(
                    path: 'roles',
                    redirect: (_, _) => Routes.adminStaffList,
                    routes: [
                      GoRoute(
                        path: 'new',
                        pageBuilder: (context, state) =>
                            const NoTransitionPage(child: NewRolePage()),
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: 'hr',
                redirect: (_, _) => Routes.adminHrFeedbacks,
                routes: [
                  GoRoute(
                    path: 'feedbacks',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: AdminHrFeedbacksPage()),
                  ),
                ],
              ),
              GoRoute(
                path: 'finance',
                redirect: (_, _) => Routes.adminFinanceReferrals,
                routes: [
                  GoRoute(
                    path: 'referrals',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: FinanceReferralsPage()),
                  ),
                  GoRoute(
                    path: 'tariffs',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: FinanceTariffsPage()),
                  ),
                  GoRoute(
                    path: 'checkouts',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: FinanceCheckoutsPage()),
                  ),
                  GoRoute(
                    path: 'paychecks',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: FinancePaychecksPage()),
                  ),
                  GoRoute(
                    path: 'speculative',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: FinanceSpeculativePage()),
                  ),
                ],
              ),
              GoRoute(
                path: 'settings',
                redirect: (_, _) => Routes.adminSettingsProfile,
                routes: [
                  GoRoute(
                    path: 'profile',
                    pageBuilder: (context, state) => const NoTransitionPage(
                      child: AdminSettingsProfilePage(),
                    ),
                  ),
                  GoRoute(
                    path: 'configurations',
                    pageBuilder: (context, state) => const NoTransitionPage(
                      child: AdminSettingsConfigurationsPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'tasks',
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: AdminSettingsTasksPage()),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

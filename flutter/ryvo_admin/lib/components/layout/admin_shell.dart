import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo_admin/components/layout/admin_drawer.dart';
import 'package:ryvo_admin/components/layout/admin_global_search.dart';
import 'package:ryvo_admin/components/layout/admin_notifications_panel.dart';
import 'package:ryvo_admin/components/layout/language_switcher.dart';
import 'package:ryvo_admin/components/permissions/permissions_check_host.dart';
import 'package:ryvo_admin/components/update/update_check_host.dart';
import 'package:ryvo_admin/configs/admin_nav.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/core/common/view_insets.dart';
import 'package:ryvo_admin/guards/admin_access.dart';
import 'package:ryvo_admin/hooks/use_admin_dashboard.dart';
import 'package:ryvo_admin/hooks/use_auth.dart';
import 'package:ryvo_admin/hooks/use_notifications.dart';
import 'package:ryvo_admin/i18n/t.dart';
import 'package:ryvo_admin/stores/locale_store.dart';
import 'package:ryvo_admin/stores/theme_store.dart';

/// Admin app chrome — drawer (web sidebar) + top bar + bottom nav (mobile-first).
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _notificationsKey = GlobalKey();
  var _notificationsOpen = false;

  @override
  void initState() {
    super.initState();
    scheduleUpdatePrompt(context);
    schedulePermissionsPrompt(context);
  }

  static const _bottomRoutes = [
    Routes.adminHome,
    Routes.adminAnalytics,
    Routes.adminRides,
    Routes.adminChatSupport,
    Routes.adminSettingsProfile,
  ];

  int _bottomIndexForPath(String path) {
    for (var i = 0; i < _bottomRoutes.length; i++) {
      if (path == _bottomRoutes[i]) return i;
    }
    return 0;
  }

  String _titleForPath(String path) {
    for (final item in AdminNav.allItems) {
      if (AdminAccess.isNavActive(path, item.href)) {
        return T.nav(item.labelKey);
      }
    }
    return T.nav('nav.overview');
  }

  Future<void> _confirmSignOut() async {
    final ok = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: const Text('Sign out?'),
        description: const Text('You will return to the landing page.'),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await useAuth(ref).signOut();
    if (!mounted) return;
    context.go(Routes.landing);
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final auth = useAuth(ref);
    final notificationsAsync = ref.watch(notificationsProvider);
    final dashboardAsync = ref.watch(adminDashboardProvider);
    final unreadInbox =
        (notificationsAsync.valueOrNull?.unread ?? 0) +
        ((dashboardAsync.valueOrNull?.badges['tickets'] as num?)?.toInt() ?? 0);

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        width: 288,
        child: AdminDrawer(
          onClose: () => Navigator.pop(context),
          onSignOut: () {
            Navigator.pop(context);
            _confirmSignOut();
          },
        ),
      ),
      appBar: AppBar(
        title: Text(_titleForPath(path)),
        centerTitle: false,
        leading: IconButton(
          tooltip: T.nav('nav.openMenu'),
          icon: const Icon(LucideIcons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          SizedBox(
            width: MediaQuery.sizeOf(context).width >= 640 ? 220 : 44,
            child: MediaQuery.sizeOf(context).width >= 640
                ? const AdminGlobalSearch()
                : IconButton(
                    tooltip: T.nav('common.search'),
                    onPressed: () => context.go(Routes.search),
                    icon: const Icon(LucideIcons.search, size: 20),
                  ),
          ),
          const LanguageSwitcher(compact: true),
          IconButton(
            tooltip: isDark ? 'Light mode' : 'Dark mode',
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(isDark ? LucideIcons.sun : LucideIcons.moon, size: 20),
          ),
          IconButton(
            tooltip: T.nav('nav.notifications'),
            onPressed: () => setState(() => _notificationsOpen = !_notificationsOpen),
            icon: Badge(
              isLabelVisible: unreadInbox > 0,
              child: const Icon(LucideIcons.bell, size: 20),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: auth.user?.email ?? 'Account',
            icon: const Icon(LucideIcons.user, size: 20),
            onSelected: (value) {
              if (value == 'profile') context.go(Routes.adminSettingsProfile);
              if (value == 'settings') context.go(Routes.adminSettingsConfigurations);
              if (value == 'signout') _confirmSignOut();
            },
            itemBuilder: (context) => [
              PopupMenuItem(enabled: false, child: Text(auth.user?.email ?? '—')),
              const PopupMenuDivider(),
              PopupMenuItem(value: 'profile', child: Text(T.nav('nav.profile'))),
              PopupMenuItem(value: 'settings', child: Text(T.nav('nav.configurations'))),
              PopupMenuItem(value: 'signout', child: Text(T.nav('common.signOut'))),
            ],
          ),
          SizedBox(width: ViewInsets.topOf(context) > 0 ? 4 : 8),
        ],
      ),
      body: Stack(
        children: [
          widget.child,
          if (_notificationsOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _notificationsOpen = false),
                child: Container(color: Colors.black26),
              ),
            ),
          if (_notificationsOpen)
            Positioned(
              key: _notificationsKey,
              top: 8,
              right: 8,
              left: 8,
              child: Align(
                alignment: Alignment.topRight,
                child: AdminNotificationsPanel(
                  onClose: () => setState(() => _notificationsOpen = false),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomIndexForPath(path),
        onDestinationSelected: (index) => context.go(_bottomRoutes[index]),
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.layoutDashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.barChart3),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.history),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.messagesSquare),
            label: 'Support',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.user),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

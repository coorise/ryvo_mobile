import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo/components/layout/language_switcher.dart';
import 'package:ryvo/components/layout/portal_drawer.dart';
import 'package:ryvo/components/update/update_check_host.dart';
import 'package:ryvo/configs/const.dart';
import 'package:ryvo/configs/portal_bottom_nav.dart';
import 'package:ryvo/configs/portal_nav.dart';
import 'package:ryvo/guards/portal_access.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';
import 'package:ryvo/stores/theme_store.dart';

class PortalShell extends ConsumerStatefulWidget {
  const PortalShell({super.key, required this.area, required this.child});

  final PortalArea area;
  final Widget child;

  @override
  ConsumerState<PortalShell> createState() => _PortalShellState();
}

class _PortalShellState extends ConsumerState<PortalShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    scheduleUpdatePrompt(context);
  }

  List<PortalBottomNavItem> get _bottomItems => portalBottomNavItems(widget.area);

  String _titleForPath(String path) {
    final config = portalNavForArea(widget.area);
    if (path.contains('/drive/')) return T.portal('portal.rides.detailTitle');
    if (isNavActive(path, config.overview.href)) return T.portal(config.overview.labelKey);
    for (final group in config.groups) {
      for (final item in group.items) {
        if (isNavActive(path, item.href)) return T.portal(item.labelKey);
      }
    }
    for (final item in _bottomItems) {
      if (item.matchPrefixes.any((prefix) => isNavActive(path, prefix))) {
        return T.portal(item.labelKey);
      }
    }
    return T.portal('portal.nav.overview');
  }

  Future<void> _confirmSignOut() async {
    final ok = await showShadDialog<bool>(
      context: context,
      builder: (context) => ShadDialog.alert(
        title: Text(T.portal('portal.shell.signOutTitle')),
        description: Text(T.portal('portal.shell.signOutDescription')),
        actions: [
          ShadButton.outline(
            onPressed: () => Navigator.pop(context, false),
            child: Text(T.portal('common.cancel')),
          ),
          ShadButton.destructive(
            onPressed: () => Navigator.pop(context, true),
            child: Text(T.portal('common.signOut')),
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
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final auth = useAuth(ref);
    final roleLabel = widget.area == PortalArea.driver
        ? T.portal('portal.shell.driver')
        : T.portal('portal.shell.client');
    final bottomItems = _bottomItems;

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        width: 288,
        child: PortalDrawer(
          area: widget.area,
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
          icon: const Icon(LucideIcons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          const LanguageSwitcher(compact: true),
          IconButton(
            tooltip: isDark ? 'Light mode' : 'Dark mode',
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(isDark ? LucideIcons.sun : LucideIcons.moon, size: 20),
          ),
          PopupMenuButton<String>(
            tooltip: auth.user?.email ?? 'Account',
            icon: const Icon(LucideIcons.user, size: 20),
            onSelected: (value) {
              final profileRoute = bottomItems.last.route;
              final settings = widget.area == PortalArea.driver
                  ? '/driver/settings/configurations'
                  : '/client/settings/configurations';
              if (value == 'profile') context.go(profileRoute);
              if (value == 'settings') context.go(settings);
              if (value == 'signout') _confirmSignOut();
            },
            itemBuilder: (context) => [
              PopupMenuItem(enabled: false, child: Text('$roleLabel · ${auth.user?.email ?? '—'}')),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'profile',
                child: Text(T.portal('portal.nav.profile')),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Text(T.portal('portal.nav.configurations')),
              ),
              PopupMenuItem(
                value: 'signout',
                child: Text(T.portal('common.signOut')),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: portalBottomNavIndexForPath(widget.area, path),
        onDestinationSelected: (index) => context.go(bottomItems[index].route),
        destinations: [
          for (final item in bottomItems)
            NavigationDestination(
              icon: Icon(item.icon),
              label: T.portal(item.labelKey),
            ),
        ],
      ),
    );
  }
}

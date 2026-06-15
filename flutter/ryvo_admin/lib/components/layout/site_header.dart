import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo_admin/components/ryvo/brand_logo.dart';
import 'package:ryvo_admin/components/ryvo/ryvo_button.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/configs/landing_const.dart';
import 'package:ryvo_admin/core/common/view_insets.dart';
import 'package:ryvo_admin/guards/abac.dart';
import 'package:ryvo_admin/hooks/use_auth.dart';
import 'package:ryvo_admin/i18n/t.dart';
import 'package:ryvo_admin/stores/theme_store.dart';

class SiteHeader extends ConsumerWidget {
  const SiteHeader({super.key, required this.onNavTap});

  final void Function(String sectionId) onNavTap;

  void _openMobileMenu(BuildContext context, WidgetRef ref) {
    final auth = useAuth(ref);
    final loggedIn = auth.isReady && auth.user != null;
    final dashboardPath = Abac.dashboardPathForUser(auth.user);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final link in LandingConst.navLinks)
                ListTile(
                  title: Text(T.nav('landing.nav.${link.sectionId}'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    onNavTap(link.sectionId);
                  },
                ),
              const Divider(),
              RyvoButton(
                fullWidth: true,
                onPressed: () {
                  Navigator.pop(context);
                  context.go(loggedIn ? dashboardPath : Routes.authLogin);
                },
                child: Text(loggedIn ? 'Go to dashboard' : 'Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = useAuth(ref);
    final loggedIn = auth.isReady && auth.user != null;
    final dashboardPath = Abac.dashboardPathForUser(auth.user);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final wide = MediaQuery.sizeOf(context).width >= 1024;

    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: ViewInsets.toolbarHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  BrandLogo(href: Routes.landing),
                  const Spacer(),
                  if (wide) _DesktopNav(onNavTap: onNavTap),
                  IconButton(
                    tooltip: isDark ? 'Light mode' : 'Dark mode',
                    onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
                    icon: Icon(isDark ? LucideIcons.sun : LucideIcons.moon, size: 18),
                  ),
                  if (loggedIn)
                    RyvoButton(
                      onPressed: () => context.go(dashboardPath),
                      child: const Text('Go to dashboard'),
                    )
                  else
                    RyvoButton(
                      onPressed: () => context.go(Routes.authLogin),
                      child: const Text('Sign in'),
                    ),
                  if (!wide)
                    IconButton(
                      tooltip: T.nav('nav.menu'),
                      onPressed: () => _openMobileMenu(context, ref),
                      icon: const Icon(LucideIcons.menu, size: 18),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _DesktopNav extends StatelessWidget {
  const _DesktopNav({required this.onNavTap});

  final void Function(String sectionId) onNavTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.6)),
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              for (final link in LandingConst.navLinks)
                TextButton(
                  onPressed: () => onNavTap(link.sectionId),
                  child: Text(T.nav('landing.nav.${link.sectionId}')),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

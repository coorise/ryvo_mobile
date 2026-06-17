import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo/components/layout/language_switcher.dart';
import 'package:ryvo/components/update/about_app_dialog.dart';
import 'package:ryvo/components/ryvo/brand_logo.dart';
import 'package:ryvo/components/ryvo/ryvo_button.dart';
import 'package:ryvo/configs/const.dart';
import 'package:ryvo/configs/landing_const.dart';
import 'package:ryvo/core/common/view_insets.dart';
import 'package:ryvo/guards/abac.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';
import 'package:ryvo/stores/locale_store.dart';
import 'package:ryvo/stores/theme_store.dart';

class SiteHeader extends ConsumerWidget {
  const SiteHeader({super.key, required this.onNavTap});

  final void Function(String sectionId) onNavTap;

  void _openMobileMenu(BuildContext context, WidgetRef ref) {
    final auth = useAuth(ref);
    final loggedIn = auth.isReady && Abac.isPortalUser(auth.user);
    final dashboardPath = Abac.portalDashboardPathForUser(auth.user);

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
                  title: Text(
                    T.nav('landing.nav.${link.sectionId}'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onNavTap(link.sectionId);
                  },
                ),
              ListTile(
                title: Text(T.nav('common.about'), style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  showAboutAppDialog(context);
                },
              ),
              if (!loggedIn)
                ListTile(
                  title: Text(T.nav('common.register'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    context.go(Routes.authRegister);
                  },
                ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: LanguageSwitcher(compact: false),
              ),
              const Divider(),
              RyvoButton(
                fullWidth: true,
                onPressed: () {
                  Navigator.pop(context);
                  if (loggedIn) {
                    context.go(dashboardPath);
                  } else {
                    context.go(Routes.authLogin);
                  }
                },
                child: Text(loggedIn ? T.nav('landing.goToDashboard') : T.nav('common.signIn')),
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
    final loggedIn = auth.isReady && Abac.isPortalUser(auth.user);
    final dashboardPath = Abac.portalDashboardPathForUser(auth.user);
    final themeMode = ref.watch(themeModeProvider);
    ref.watch(localeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final wide = MediaQuery.sizeOf(context).width >= 1024;
    final compact = !wide;

    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: ViewInsets.toolbarHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
              child: Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: BrandLogo(href: Routes.landing),
                    ),
                  ),
                  if (wide) _DesktopNav(onNavTap: onNavTap),
                  if (wide) const LanguageSwitcher(compact: true),
                  IconButton(
                    visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
                    padding: compact ? EdgeInsets.zero : null,
                    constraints: compact ? const BoxConstraints(minWidth: 40, minHeight: 40) : null,
                    tooltip: isDark ? 'Light mode' : 'Dark mode',
                    onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
                    icon: Icon(isDark ? LucideIcons.sun : LucideIcons.moon, size: 18),
                  ),
                  if (loggedIn)
                    RyvoButton(
                      onPressed: () => context.go(dashboardPath),
                      child: Text(T.nav('landing.goToDashboard')),
                    )
                  else if (wide) ...[
                    RyvoButton(
                      intent: RyvoButtonIntent.outline,
                      onPressed: () => context.go(Routes.authLogin),
                      child: Text(T.nav('common.signIn')),
                    ),
                    const SizedBox(width: 8),
                    RyvoButton(
                      onPressed: () => context.go(Routes.authRegister),
                      child: Text(T.nav('common.register')),
                    ),
                  ]
                  else
                    RyvoButton(
                      onPressed: () => context.go(Routes.authLogin),
                      child: Text(T.nav('common.signIn')),
                    ),
                  if (!wide)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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
              TextButton(
                onPressed: () => showAboutAppDialog(context),
                child: Text(T.nav('common.about')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

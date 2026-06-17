import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo/components/ryvo/brand_logo.dart';
import 'package:ryvo/components/update/about_app_dialog.dart';
import 'package:ryvo/configs/portal_nav.dart';
import 'package:ryvo/guards/portal_access.dart';
import 'package:ryvo/i18n/t.dart';

class PortalDrawer extends ConsumerWidget {
  const PortalDrawer({
    super.key,
    required this.area,
    required this.onClose,
    required this.onSignOut,
  });

  final PortalArea area;
  final VoidCallback onClose;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = portalNavForArea(area);
    final path = GoRouterState.of(context).uri.path;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            child: Row(
              children: [
                Expanded(child: BrandLogo(subtitle: area == PortalArea.driver ? 'DRIVER' : 'CLIENT')),
                IconButton(onPressed: onClose, icon: const Icon(LucideIcons.x)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _NavTile(
                  item: config.overview,
                  active: isNavActive(path, config.overview.href),
                  onTap: () {
                    onClose();
                    context.go(config.overview.href);
                  },
                ),
                for (final group in config.groups) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      T.portal(group.labelKey),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                    ),
                  ),
                  for (final item in group.items)
                    _NavTile(
                      item: item,
                      active: isNavActive(path, item.href),
                      onTap: () {
                        onClose();
                        context.go(item.href);
                      },
                    ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: ShadButton.outline(
              onPressed: () {
                onClose();
                showAboutAppDialog(context);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.info, size: 16),
                  const SizedBox(width: 8),
                  Text(T.portal('common.about')),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: ShadButton.outline(
              onPressed: onSignOut,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.logOut, size: 16),
                  const SizedBox(width: 8),
                  Text(T.portal('common.signOut')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, required this.active, required this.onTap});

  final PortalNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? Theme.of(context).colorScheme.primary : null;
    return ListTile(
      leading: Icon(item.icon, size: 20, color: color),
      title: Text(
        T.portal(item.labelKey),
        style: TextStyle(fontWeight: active ? FontWeight.w600 : FontWeight.normal, color: color),
      ),
      selected: active,
      onTap: onTap,
    );
  }
}

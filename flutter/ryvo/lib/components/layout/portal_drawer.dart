import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo/components/layout/portal_sidebar_brand.dart';
import 'package:ryvo/components/layout/portal_sidebar_nav.dart';
import 'package:ryvo/components/update/about_app_dialog.dart';
import 'package:ryvo/configs/portal_nav.dart';
import 'package:ryvo/i18n/t.dart';

/// Left drawer body — mirrors admin [AdminDrawer] / web portal sidebar.
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
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            child: PortalSidebarBrand(area: area, onNavigate: onClose),
          ),
          const Divider(height: 1),
          Expanded(
            child: PortalSidebarNav(area: area, onNavigate: onClose),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
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

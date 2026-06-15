import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo_admin/components/ryvo/brand_logo.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/i18n/t.dart';

class AdminSidebarBrand extends StatelessWidget {
  const AdminSidebarBrand({super.key, this.onNavigate});

  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: BrandLogo(
            subtitle: 'Admin console',
            href: Routes.landing,
          ),
        ),
        IconButton(
          tooltip: T.nav('nav.dashboard'),
          onPressed: () {
            onNavigate?.call();
            context.go(Routes.adminHome);
          },
          icon: const Icon(LucideIcons.house, size: 18),
        ),
      ],
    );
  }
}

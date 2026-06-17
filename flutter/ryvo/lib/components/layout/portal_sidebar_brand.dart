import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo/components/ryvo/brand_logo.dart';
import 'package:ryvo/configs/const.dart';
import 'package:ryvo/configs/portal_nav.dart';
import 'package:ryvo/i18n/t.dart';

class PortalSidebarBrand extends StatelessWidget {
  const PortalSidebarBrand({super.key, required this.area, this.onNavigate});

  final PortalArea area;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final config = portalNavForArea(area);
    return Row(
      children: [
        Expanded(
          child: BrandLogo(
            subtitle: area == PortalArea.driver ? 'DRIVER' : 'CLIENT',
            href: Routes.landing,
          ),
        ),
        IconButton(
          tooltip: T.portal('portal.nav.overview'),
          onPressed: () {
            onNavigate?.call();
            context.go(config.overview.href);
          },
          icon: const Icon(LucideIcons.house, size: 18),
        ),
      ],
    );
  }
}

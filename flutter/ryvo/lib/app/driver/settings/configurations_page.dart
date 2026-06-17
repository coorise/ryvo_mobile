import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo/components/portal/portal_page_shell.dart';
import 'package:ryvo/components/portal/panels/portal_configurations_panel.dart';
import 'package:ryvo/configs/portal_nav.dart';

class DriverConfigurationsPage extends ConsumerWidget {
  const DriverConfigurationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortalPageShell(
      titleKey: 'portal.nav.configurations',
      subtitleKey: null,
      expand: true,
      child: PortalConfigurationsPanel(area: PortalArea.driver),
    );
  }
}

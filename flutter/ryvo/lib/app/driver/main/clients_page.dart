import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo/components/portal/portal_page_shell.dart';
import 'package:ryvo/components/portal/panels/portal_counterparties_panel.dart';
import 'package:ryvo/configs/portal_nav.dart';

class DriverClientsPage extends ConsumerWidget {
  const DriverClientsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortalPageShell(
      titleKey: 'portal.nav.clients',
      subtitleKey: 'portal.clients.subtitle',
      expand: false,
      child: PortalCounterpartiesPanel(area: PortalArea.driver),
    );
  }
}

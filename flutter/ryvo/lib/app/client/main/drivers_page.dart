import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo/components/portal/portal_page_shell.dart';
import 'package:ryvo/components/portal/panels/portal_counterparties_panel.dart';
import 'package:ryvo/configs/portal_nav.dart';

class ClientDriversPage extends ConsumerWidget {
  const ClientDriversPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortalPageShell(
      titleKey: 'portal.nav.drivers',
      subtitleKey: 'portal.drivers.subtitle',
      expand: false,
      child: PortalCounterpartiesPanel(area: PortalArea.client),
    );
  }
}

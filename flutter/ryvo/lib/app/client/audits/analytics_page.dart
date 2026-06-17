import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo/components/portal/portal_page_shell.dart';
import 'package:ryvo/components/portal/panels/portal_analytics_panel.dart';
import 'package:ryvo/configs/portal_nav.dart';

class ClientAnalyticsPage extends ConsumerWidget {
  const ClientAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortalPageShell(
      titleKey: 'portal.nav.analytics',
      subtitleKey: null,
      expand: false,
      child: PortalAnalyticsPanel(area: PortalArea.client),
    );
  }
}

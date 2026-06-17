import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo/components/portal/portal_page_shell.dart';
import 'package:ryvo/components/portal/panels/portal_notifications_panel.dart';

class DriverNotificationsPage extends ConsumerWidget {
  const DriverNotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortalPageShell(
      titleKey: 'portal.nav.notifications',
      subtitleKey: null,
      expand: false,
      child: const PortalNotificationsPanel(),
    );
  }
}

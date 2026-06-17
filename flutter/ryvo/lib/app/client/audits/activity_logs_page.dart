import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo/components/portal/portal_page_shell.dart';
import 'package:ryvo/components/portal/panels/portal_activity_logs_panel.dart';

class ClientActivityLogsPage extends ConsumerWidget {
  const ClientActivityLogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortalPageShell(
      titleKey: 'portal.nav.activityLogs',
      subtitleKey: null,
      expand: false,
      child: const PortalActivityLogsPanel(),
    );
  }
}

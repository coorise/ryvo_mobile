import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo/components/portal/portal_page_shell.dart';
import 'package:ryvo/components/portal/panels/portal_messages_panel.dart';

class DriverMessagesPage extends ConsumerWidget {
  const DriverMessagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortalPageShell(
      titleKey: 'portal.nav.messages',
      subtitleKey: null,
      expand: false,
      child: const PortalMessagesPanel(),
    );
  }
}

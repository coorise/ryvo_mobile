import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo/components/portal/portal_page_shell.dart';
import 'package:ryvo/components/portal/panels/portal_chat_panel.dart';

class DriverChatPage extends ConsumerWidget {
  const DriverChatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortalPageShell(
      titleKey: 'portal.nav.chat',
      subtitleKey: null,
      expand: false,
      child: const PortalEphemeralChatPanel(),
    );
  }
}

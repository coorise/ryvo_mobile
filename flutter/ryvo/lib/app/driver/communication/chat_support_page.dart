import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo/components/portal/portal_page_shell.dart';
import 'package:ryvo/components/portal/panels/portal_chat_support_panel.dart';

class DriverChatSupportPage extends ConsumerWidget {
  const DriverChatSupportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortalPageShell(
      titleKey: 'portal.nav.chatSupport',
      subtitleKey: null,
      expand: false,
      child: const PortalChatSupportPanel(),
    );
  }
}

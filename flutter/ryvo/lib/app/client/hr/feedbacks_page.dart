import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo/components/portal/portal_page_shell.dart';
import 'package:ryvo/components/portal/panels/portal_feedbacks_panel.dart';
import 'package:ryvo/configs/portal_nav.dart';

class ClientFeedbacksPage extends ConsumerWidget {
  const ClientFeedbacksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortalPageShell(
      titleKey: 'portal.nav.feedbacks',
      subtitleKey: null,
      expand: false,
      child: PortalFeedbacksPanel(area: PortalArea.client),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo/components/portal/portal_page_shell.dart';
import 'package:ryvo/components/portal/panels/portal_payments_panel.dart';

class ClientPaymentsPage extends ConsumerWidget {
  const ClientPaymentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortalPageShell(
      titleKey: 'portal.nav.payments',
      subtitleKey: 'portal.payments.subtitle',
      expand: false,
      child: const PortalPaymentsPanel(),
    );
  }
}

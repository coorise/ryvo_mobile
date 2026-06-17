import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo/components/portal/portal_page_shell.dart';
import 'package:ryvo/components/portal/panels/portal_kyc_panel.dart';

class DriverCarDetailPage extends ConsumerWidget {
  const DriverCarDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortalPageShell(
      titleKey: 'portal.nav.driverKyc',
      subtitleKey: 'portal.kyc.subtitle',
      expand: true,
      child: const PortalKycPanel(),
    );
  }
}

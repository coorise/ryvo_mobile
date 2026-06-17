import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ryvo/components/portal/portal_page_shell.dart';
import 'package:ryvo/components/portal/panels/portal_kyc_panel.dart';

class DriverKycPage extends ConsumerWidget {
  const DriverKycPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = GoRouter.maybeOf(context)?.state.uri.queryParameters['tab'];
    return PortalPageShell(
      titleKey: 'portal.nav.driverKyc',
      subtitleKey: 'portal.kyc.subtitle',
      expand: true,
      child: PortalKycPanel(initialTab: tab == 'cars' ? 1 : 0),
    );
  }
}

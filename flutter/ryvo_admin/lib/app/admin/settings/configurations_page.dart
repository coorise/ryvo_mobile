import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/components/admin/settings/settings_hub_tabs.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';

class AdminSettingsConfigurationsPage extends ConsumerWidget {
  const AdminSettingsConfigurationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabHeight = MediaQuery.sizeOf(context).height * 0.62;

    return PermissionGate(
      permissions: const ['settings:read'],
      fallback: const Center(child: Text('No access to settings hub.')),
      child: DefaultTabController(
        length: 4,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: AdminListStack(
            children: [
              const AdminPageHeader(
                title: 'Configurations',
                subtitle: 'General, payment, mail and notifications settings.',
              ),
              const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'General'),
                  Tab(text: 'Payment'),
                  Tab(text: 'Mail'),
                  Tab(text: 'Notifications'),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: tabHeight,
                child: const TabBarView(
                  children: [
                    SingleChildScrollView(child: SettingsGeneralTab()),
                    SingleChildScrollView(child: SettingsPaymentTab()),
                    SingleChildScrollView(child: SettingsMailTab()),
                    SingleChildScrollView(child: SettingsNotificationsTab()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

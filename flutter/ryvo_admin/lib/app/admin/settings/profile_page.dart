import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/components/admin/settings/settings_hub_tabs.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';

class AdminSettingsProfilePage extends ConsumerWidget {
  const AdminSettingsProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PermissionGate(
      permissions: const ['settings:read'],
      fallback: const Center(child: Text('No access to profile settings.')),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 672),
            child: const AdminListStack(
              children: [
                AdminPageHeader(
                  title: 'Profile',
                  subtitle: 'Your profile and platform configuration.',
                ),
                SizedBox(height: 8),
                SettingsProfileForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

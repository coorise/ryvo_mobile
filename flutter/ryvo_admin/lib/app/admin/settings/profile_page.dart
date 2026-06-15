import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_auth.dart';
import 'package:ryvo_admin/services/index.dart';

class AdminSettingsProfilePage extends ConsumerStatefulWidget {
  const AdminSettingsProfilePage({super.key});

  @override
  ConsumerState<AdminSettingsProfilePage> createState() =>
      _AdminSettingsProfilePageState();
}

class _AdminSettingsProfilePageState
    extends ConsumerState<AdminSettingsProfilePage> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = settingsService.getMyProfile(useAuth(ref).accessToken);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = settingsService.getMyProfile(useAuth(ref).accessToken);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permissions: const ['settings:read'],
      fallback: const Center(child: Text('No access to profile settings.')),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AdminListStack(
          children: [
            AdminPageHeader(
              title: 'Profile',
              subtitle: 'Admin account profile information.',
              action: OutlinedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
            ),
            FutureBuilder<Map<String, dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return AdminTableCard(
                    isEmpty: true,
                    empty: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text('Failed to load profile: ${snapshot.error}'),
                    ),
                    child: const SizedBox.shrink(),
                  );
                }

                final profile = snapshot.data?['profile'] is Map
                    ? Map<String, dynamic>.from(
                        snapshot.data!['profile'] as Map,
                      )
                    : <String, dynamic>{};

                Widget row(String label, String value) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text(
                          label,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(child: Text(value.isEmpty ? '—' : value)),
                    ],
                  ),
                );

                return AdminTableCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        row('Email', profile['email']?.toString() ?? ''),
                        row('Username', profile['username']?.toString() ?? ''),
                        row(
                          'Display Name',
                          profile['display_name']?.toString() ?? '',
                        ),
                        row(
                          'Full Name',
                          profile['full_name']?.toString() ?? '',
                        ),
                        row('Phone', profile['phone']?.toString() ?? ''),
                        row('Locale', profile['locale']?.toString() ?? ''),
                        row('Country', profile['country']?.toString() ?? ''),
                        row('Bio', profile['bio']?.toString() ?? ''),
                        row(
                          'Roles',
                          (profile['roles'] is List)
                              ? (profile['roles'] as List)
                                    .map((e) => e.toString())
                                    .join(', ')
                              : '',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

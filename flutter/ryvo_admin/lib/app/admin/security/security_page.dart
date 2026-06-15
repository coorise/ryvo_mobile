import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_auth.dart';
import 'package:ryvo_admin/services/index.dart';

class AdminSecurityPage extends ConsumerStatefulWidget {
  const AdminSecurityPage({super.key});

  @override
  ConsumerState<AdminSecurityPage> createState() => _AdminSecurityPageState();
}

class _AdminSecurityPageState extends ConsumerState<AdminSecurityPage> {
  Future<Map<String, dynamic>>? _eventsFuture;
  Future<Map<String, dynamic>>? _devicesFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = auditService.listSecurityAuthEvents(
      useAuth(ref).accessToken,
    );
    _devicesFuture = auditService.listDevices(useAuth(ref).accessToken);
  }

  Future<void> _refresh() async {
    setState(() {
      _eventsFuture = auditService.listSecurityAuthEvents(
        useAuth(ref).accessToken,
      );
      _devicesFuture = auditService.listDevices(useAuth(ref).accessToken);
    });
    await Future.wait([_eventsFuture!, _devicesFuture!]);
  }

  Future<void> _revokeDevice(String id) async {
    await auditService.revokeDevice(useAuth(ref).accessToken, id);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permissions: const ['audit:read'],
      fallback: const Center(child: Text('No access to security data.')),
      child: DefaultTabController(
        length: 2,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: AdminListStack(
            children: [
              AdminPageHeader(
                title: 'Security',
                subtitle: 'Auth events and known devices.',
                action: OutlinedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                ),
              ),
              const TabBar(
                tabs: [
                  Tab(text: 'Auth Events'),
                  Tab(text: 'Devices'),
                ],
              ),
              SizedBox(
                height: 420,
                child: TabBarView(
                  children: [
                    FutureBuilder<Map<String, dynamic>>(
                      future: _eventsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Failed to load events: ${snapshot.error}',
                            ),
                          );
                        }
                        final raw = snapshot.data?['events'];
                        final events = raw is List
                            ? raw
                                  .whereType<Map>()
                                  .map((e) => Map<String, dynamic>.from(e))
                                  .toList()
                            : <Map<String, dynamic>>[];
                        return AdminTableCard(
                          isEmpty: events.isEmpty,
                          empty: const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('No auth events found.'),
                          ),
                          child: ListView.separated(
                            itemCount: events.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final e = events[index];
                              final severity =
                                  e['severity']?.toString() ?? 'info';
                              return ListTile(
                                title: Text(
                                  e['event_type']?.toString() ?? 'event',
                                ),
                                subtitle: Text(
                                  '${e['details'] ?? ''}\n${e['created_at'] ?? ''}',
                                ),
                                isThreeLine: true,
                                trailing: StatusBadge(
                                  label: severity,
                                  variant: severity == 'critical'
                                      ? StatusBadgeVariant.danger
                                      : severity == 'warning'
                                      ? StatusBadgeVariant.warning
                                      : StatusBadgeVariant.info,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _devicesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Failed to load devices: ${snapshot.error}',
                            ),
                          );
                        }
                        final raw = snapshot.data?['devices'];
                        final devices = raw is List
                            ? raw
                                  .whereType<Map>()
                                  .map((e) => Map<String, dynamic>.from(e))
                                  .toList()
                            : <Map<String, dynamic>>[];
                        return AdminTableCard(
                          isEmpty: devices.isEmpty,
                          empty: const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('No devices found.'),
                          ),
                          child: ListView.separated(
                            itemCount: devices.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final d = devices[index];
                              final revoked =
                                  (d['revoked_at']?.toString() ?? '')
                                      .isNotEmpty;
                              return ListTile(
                                title: Text(
                                  '${d['user_email'] ?? 'user'} · ${d['platform'] ?? 'platform'}',
                                ),
                                subtitle: Text(
                                  '${d['device_name'] ?? 'unknown device'} · Last seen: ${d['last_seen_at'] ?? '—'}',
                                ),
                                trailing: revoked
                                    ? const StatusBadge(
                                        label: 'Revoked',
                                        variant: StatusBadgeVariant.danger,
                                      )
                                    : OutlinedButton(
                                        onPressed: () => _revokeDevice(
                                          d['id']?.toString() ?? '',
                                        ),
                                        child: const Text('Revoke'),
                                      ),
                              );
                            },
                          ),
                        );
                      },
                    ),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_auth.dart';
import 'package:ryvo_admin/services/index.dart';

class AdminObservabilityPage extends ConsumerStatefulWidget {
  const AdminObservabilityPage({super.key});

  @override
  ConsumerState<AdminObservabilityPage> createState() =>
      _AdminObservabilityPageState();
}

class _AdminObservabilityPageState
    extends ConsumerState<AdminObservabilityPage> {
  Future<Map<String, dynamic>>? _generalFuture;
  Future<Map<String, dynamic>>? _paymentFuture;

  @override
  void initState() {
    super.initState();
    final token = useAuth(ref).accessToken;
    _generalFuture = adminService.getSettings(token);
    _paymentFuture = settingsService.getPayment(token);
  }

  Future<void> _refresh() async {
    final token = useAuth(ref).accessToken;
    setState(() {
      _generalFuture = adminService.getSettings(token);
      _paymentFuture = settingsService.getPayment(token);
    });
    await Future.wait([_generalFuture!, _paymentFuture!]);
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permissions: const ['observability:read', 'settings:read'],
      fallback: const Center(child: Text('No access to observability.')),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AdminListStack(
          children: [
            AdminPageHeader(
              title: 'Observability',
              subtitle: 'Platform metrics and runtime health snapshot.',
              action: OutlinedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
            ),
            const AdminStatGrid(
              children: [
                AdminStatCard(
                  label: 'Database',
                  value: '2.4 GB / 8 GB',
                  icon: Icons.storage,
                  tone: AdminStatTone.info,
                ),
                AdminStatCard(
                  label: 'Storage',
                  value: '12.1 GB / 50 GB',
                  icon: Icons.folder_open,
                  tone: AdminStatTone.neutral,
                ),
                AdminStatCard(
                  label: 'API Traffic',
                  value: '1.2M / 5M',
                  icon: Icons.network_check,
                  tone: AdminStatTone.success,
                ),
                AdminStatCard(
                  label: 'MAU',
                  value: '8,420 / 25,000',
                  icon: Icons.people_alt_outlined,
                  tone: AdminStatTone.warning,
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AdminTableCard(
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Runtime',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 8),
                          Text('CPU: 42% (4 cores)'),
                          Text('RAM: 3.1 / 8 GB'),
                          Text('Functions: ryvo-functions - healthy'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AdminTableCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: Future.wait([_generalFuture!, _paymentFuture!]),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return Text(
                              'Failed to load platform details: ${snapshot.error}',
                            );
                          }
                          final general = snapshot.data![0];
                          final payment = snapshot.data![1];
                          final prefs = general['preferences'] is Map
                              ? Map<String, dynamic>.from(
                                  general['preferences'] as Map,
                                )
                              : <String, dynamic>{};
                          final config = payment['config'] is Map
                              ? Map<String, dynamic>.from(
                                  payment['config'] as Map,
                                )
                              : <String, dynamic>{};

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Platform',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text('App Name: ${prefs['appName'] ?? '—'}'),
                              Text(
                                'Default Language: ${prefs['defaultLanguage'] ?? '—'}',
                              ),
                              Text('Currency: ${config['currency'] ?? '—'}'),
                              const SizedBox(height: 8),
                              const Text(
                                'Static metrics are shown until admin/platform endpoint is available.',
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

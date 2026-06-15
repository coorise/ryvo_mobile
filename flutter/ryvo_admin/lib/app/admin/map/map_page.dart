import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_auth.dart';
import 'package:ryvo_admin/services/index.dart';

class AdminMapPage extends ConsumerStatefulWidget {
  const AdminMapPage({super.key});

  @override
  ConsumerState<AdminMapPage> createState() => _AdminMapPageState();
}

class _AdminMapPageState extends ConsumerState<AdminMapPage> {
  Future<Map<String, dynamic>>? _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() {
    return mapService.listOnlineDrivers(
      useAuth(ref).accessToken,
      query: _query,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permissions: const ['map:read', 'rides:read'],
      fallback: const Center(child: Text('No access to map data.')),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AdminListStack(
          children: [
            AdminPageHeader(
              title: 'Live Map',
              subtitle:
                  'Online drivers list and live stats (map view omitted).',
              action: OutlinedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
            ),
            AdminSearchToolbar(
              value: _query,
              onChanged: (v) => setState(() => _query = v),
              placeholder: 'Search driver by name or id',
              filters: [
                FilledButton(onPressed: _refresh, child: const Text('Apply')),
              ],
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
                      child: Text(
                        'Failed to load online drivers: ${snapshot.error}',
                      ),
                    ),
                    child: const SizedBox.shrink(),
                  );
                }
                final raw = snapshot.data?['drivers'];
                final drivers = raw is List
                    ? raw
                          .whereType<Map>()
                          .map((e) => Map<String, dynamic>.from(e))
                          .toList()
                    : <Map<String, dynamic>>[];
                final online = drivers
                    .where((d) => d['is_online'] == true)
                    .length;
                final onTrip = drivers
                    .where((d) => d['status']?.toString() == 'on_trip')
                    .length;

                return AdminListStack(
                  children: [
                    AdminStatGrid(
                      children: [
                        AdminStatCard(
                          label: 'Visible Drivers',
                          value: '${drivers.length}',
                          icon: Icons.directions_car_filled,
                        ),
                        AdminStatCard(
                          label: 'Online',
                          value: '$online',
                          icon: Icons.wifi_tethering,
                          tone: AdminStatTone.success,
                        ),
                        AdminStatCard(
                          label: 'On Trip',
                          value: '$onTrip',
                          icon: Icons.alt_route,
                          tone: AdminStatTone.info,
                        ),
                        AdminStatCard(
                          label: 'Idle',
                          value: '${online - onTrip}',
                          icon: Icons.pause_circle_outline,
                          tone: AdminStatTone.warning,
                        ),
                      ],
                    ),
                    AdminTableCard(
                      isEmpty: drivers.isEmpty,
                      empty: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No online drivers found.'),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: drivers.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final d = drivers[index];
                          return ListTile(
                            title: Text(
                              d['name']?.toString() ??
                                  d['driver_id']?.toString() ??
                                  'Driver',
                            ),
                            subtitle: Text(
                              'Status: ${d['status'] ?? '—'} · Lat/Lng: ${d['lat'] ?? '—'}, ${d['lng'] ?? '—'} · Updated: ${d['updated_at'] ?? '—'}',
                            ),
                            trailing: StatusBadge(
                              label: d['is_online'] == true
                                  ? 'Online'
                                  : 'Offline',
                              variant: d['is_online'] == true
                                  ? StatusBadgeVariant.success
                                  : StatusBadgeVariant.defaultVariant,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

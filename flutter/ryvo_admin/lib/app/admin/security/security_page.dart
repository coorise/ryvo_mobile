import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/components/admin/admin_list_layout.dart';
import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/components/admin/admin_managed_list.dart';
import 'package:ryvo_admin/components/admin/admin_selectable_list.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_bulk_selection.dart';
import 'package:ryvo_admin/hooks/use_list_controls.dart';
import 'package:ryvo_admin/hooks/use_paginated_slice.dart';
import 'package:ryvo_admin/stores/auth_store.dart';
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
      ref.read(authProvider).accessToken,
    );
    _devicesFuture = auditService.listDevices(ref.read(authProvider).accessToken);
  }

  Future<void> _refresh() async {
    setState(() {
      _eventsFuture = auditService.listSecurityAuthEvents(
        ref.read(authProvider).accessToken,
      );
      _devicesFuture = auditService.listDevices(ref.read(authProvider).accessToken);
    });
    await Future.wait([_eventsFuture!, _devicesFuture!]);
  }

  Future<void> _revokeDevice(String id) async {
    await auditService.revokeDevice(ref.read(authProvider).accessToken, id);
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
                height: 520,
                child: TabBarView(
                  children: [
                    _AuthEventsTab(eventsFuture: _eventsFuture),
                    _DevicesTab(
                      devicesFuture: _devicesFuture,
                      onRevoke: _revokeDevice,
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

class _AuthEventsTab extends ConsumerStatefulWidget {
  const _AuthEventsTab({required this.eventsFuture});

  final Future<Map<String, dynamic>>? eventsFuture;

  @override
  ConsumerState<_AuthEventsTab> createState() => _AuthEventsTabState();
}

class _AuthEventsTabState extends ConsumerState<_AuthEventsTab> {
  final PaginatedSliceHook<Map<String, dynamic>> _slice =
      PaginatedSliceHook<Map<String, dynamic>>();
  final BulkSelection _selection = BulkSelection();

  void _refreshSelection() => setState(() {});

  StatusBadgeVariant _severityVariant(String severity) {
    if (severity == 'critical') return StatusBadgeVariant.danger;
    if (severity == 'warning') return StatusBadgeVariant.warning;
    return StatusBadgeVariant.info;
  }

  List<Map<String, dynamic>> _sortRows(
    List<Map<String, dynamic>> events,
    ListControlsState controls,
  ) {
    final sort = controls.activeSort;
    if (sort == null) return events;
    final rows = [...events];
    rows.sort((a, b) => compareSortable(a['created_at'], b['created_at'], sort.dir));
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    const controlsKey = 'security_events';
    final controls = ref.watch(listControlsProvider(controlsKey));
    final controlsNotifier = ref.read(listControlsProvider(controlsKey).notifier);

    return FutureBuilder<Map<String, dynamic>>(
      future: widget.eventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load events: ${snapshot.error}'));
        }
        final raw = snapshot.data?['events'];
        final events = raw is List
            ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
            : <Map<String, dynamic>>[];
        final rows = _sortRows(events, controls);
        final pagination = _slice.call(
          rows,
          adminPaginatedOptions(
            controls: controls,
            notifier: controlsNotifier,
            resetDeps: [controls.layout.name],
          ),
        );
        final sliceOptions = adminPaginatedOptions(
          controls: controls,
          notifier: controlsNotifier,
        );

        return AdminListStack(
          children: [
            AdminManagedListToolbarSection(
              controls: controls,
              notifier: controlsNotifier,
              selection: _selection,
              onSelectionChanged: _refreshSelection,
              sortOptions: const [
                AdminFilterOption(value: 'created_at:desc', label: 'Newest first'),
                AdminFilterOption(value: 'created_at:asc', label: 'Oldest first'),
              ],
            ),
            const SizedBox(height: 12),
            AdminLayoutSwitch(
              layout: controls.layout,
              isEmpty: pagination.visibleItems.isEmpty,
              empty: const Padding(
                padding: EdgeInsets.all(20),
                child: Text('No auth events found.'),
              ),
              table: AdminTableCard(
                child: ListView.separated(
                  itemCount: pagination.visibleItems.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final e = pagination.visibleItems[index];
                    final id = rowId(e);
                    final severity = e['severity']?.toString() ?? 'info';
                    return AdminSelectableListTile(
                      id: id,
                      selected: _selection.isSelected(id),
                      onToggleSelected: () {
                        _selection.toggle(id);
                        _refreshSelection();
                      },
                      title: Text(e['event_type']?.toString() ?? 'event'),
                      subtitle: Text(
                        '${e['details'] ?? ''}\n${e['created_at'] ?? ''}',
                      ),
                      trailing: StatusBadge(
                        label: severity,
                        variant: _severityVariant(severity),
                      ),
                    );
                  },
                ),
              ),
              grid: AdminEntityGrid(
                children: [
                  for (final e in pagination.visibleItems)
                    AdminEntityGridCard(
                      selected: _selection.isSelected(rowId(e)),
                      onTap: () {
                        _selection.toggle(rowId(e));
                        _refreshSelection();
                      },
                      selection: AdminListSelectCheckbox(compact: true, 
                        checked: _selection.isSelected(rowId(e)),
                        onChanged: () {
                          _selection.toggle(rowId(e));
                          _refreshSelection();
                        },
                      ),
                      child: Text(e['event_type']?.toString() ?? 'event'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AdminManagedListFooterSection(
              pagination: pagination,
              notifier: controlsNotifier,
              slice: _slice,
              sliceOptions: sliceOptions,
            ),
          ],
        );
      },
    );
  }
}

class _DevicesTab extends ConsumerStatefulWidget {
  const _DevicesTab({
    required this.devicesFuture,
    required this.onRevoke,
  });

  final Future<Map<String, dynamic>>? devicesFuture;
  final Future<void> Function(String id) onRevoke;

  @override
  ConsumerState<_DevicesTab> createState() => _DevicesTabState();
}

class _DevicesTabState extends ConsumerState<_DevicesTab> {
  final PaginatedSliceHook<Map<String, dynamic>> _slice =
      PaginatedSliceHook<Map<String, dynamic>>();
  final BulkSelection _selection = BulkSelection();

  void _refreshSelection() => setState(() {});

  @override
  Widget build(BuildContext context) {
    const controlsKey = 'security_devices';
    final controls = ref.watch(listControlsProvider(controlsKey));
    final controlsNotifier = ref.read(listControlsProvider(controlsKey).notifier);

    return FutureBuilder<Map<String, dynamic>>(
      future: widget.devicesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load devices: ${snapshot.error}'));
        }
        final raw = snapshot.data?['devices'];
        final devices = raw is List
            ? raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
            : <Map<String, dynamic>>[];
        final pagination = _slice.call(
          devices,
          adminPaginatedOptions(
            controls: controls,
            notifier: controlsNotifier,
            resetDeps: [controls.layout.name],
          ),
        );
        final sliceOptions = adminPaginatedOptions(
          controls: controls,
          notifier: controlsNotifier,
        );

        return AdminListStack(
          children: [
            AdminManagedListToolbarSection(
              controls: controls,
              notifier: controlsNotifier,
              selection: _selection,
              onSelectionChanged: _refreshSelection,
              sortOptions: adminEntityGridSortOptions(),
            ),
            const SizedBox(height: 12),
            AdminLayoutSwitch(
              layout: controls.layout,
              isEmpty: pagination.visibleItems.isEmpty,
              empty: const Padding(
                padding: EdgeInsets.all(20),
                child: Text('No devices found.'),
              ),
              table: AdminTableCard(
                child: ListView.separated(
                  itemCount: pagination.visibleItems.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final d = pagination.visibleItems[index];
                    final id = rowId(d);
                    final revoked = (d['revoked_at']?.toString() ?? '').isNotEmpty;
                    final actions = InlineRowActions(
                      onToggle: !revoked && id.isNotEmpty ? () => widget.onRevoke(id) : null,
                      profileLabel: 'Revoke',
                    );

                    return AdminSelectableListTile(
                      id: id,
                      selected: _selection.isSelected(id),
                      onToggleSelected: () {
                        _selection.toggle(id);
                        _refreshSelection();
                      },
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
                          : null,
                      actions: actions,
                    );
                  },
                ),
              ),
              grid: AdminEntityGrid(
                children: [
                  for (final d in pagination.visibleItems)
                    AdminEntityGridCard(
                      selected: _selection.isSelected(rowId(d)),
                      onTap: () {
                        _selection.toggle(rowId(d));
                        _refreshSelection();
                      },
                      selection: AdminListSelectCheckbox(compact: true, 
                        checked: _selection.isSelected(rowId(d)),
                        onChanged: () {
                          _selection.toggle(rowId(d));
                          _refreshSelection();
                        },
                      ),
                      child: Text(d['device_name']?.toString() ?? 'Device'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AdminManagedListFooterSection(
              pagination: pagination,
              notifier: controlsNotifier,
              slice: _slice,
              sliceOptions: sliceOptions,
            ),
          ],
        );
      },
    );
  }
}

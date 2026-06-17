import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ryvo_admin/components/admin/admin_list_layout.dart';
import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/components/admin/admin_managed_list.dart';
import 'package:ryvo_admin/components/admin/admin_selectable_list.dart';
import 'package:ryvo_admin/components/admin/staff/role_editor_sheet.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_bulk_selection.dart';
import 'package:ryvo_admin/hooks/use_list_controls.dart';
import 'package:ryvo_admin/hooks/use_paginated_slice.dart';
import 'package:ryvo_admin/lib/finance_list_helpers.dart';
import 'package:ryvo_admin/stores/auth_store.dart';
import 'package:ryvo_admin/services/rbac_service.dart';

class StaffPage extends ConsumerStatefulWidget {
  const StaffPage({super.key});

  @override
  ConsumerState<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends ConsumerState<StaffPage> {
  Future<_StaffPayload>? _future;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_StaffPayload> _load() async {
    final token = ref.read(authProvider).accessToken;
    final matrix = await rbacService.getMatrix(token);
    final users = await rbacService.listUsers(token, kind: 'staff');
    return _StaffPayload(matrix: matrix, users: users);
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  List<Map<String, dynamic>> _filterStaff(List<Map<String, dynamic>> rows) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows.where((row) {
      return (row['full_name']?.toString().toLowerCase().contains(q) ?? false) ||
          (row['email']?.toString().toLowerCase().contains(q) ?? false) ||
          (row['username']?.toString().toLowerCase().contains(q) ?? false);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = _tabIndexFromQuery(
      GoRouterState.of(context).uri.queryParameters['tab'],
    );

    return PermissionGate(
      permissions: const ['staff:read', 'roles:read'],
      fallback: const Center(child: Text('You do not have access to staff data.')),
      child: DefaultTabController(
        length: 3,
        initialIndex: tabIndex,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<_StaffPayload>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError || snapshot.data == null) {
                return _LoadError(onRetry: _refresh, message: snapshot.error?.toString());
              }

              final payload = snapshot.data!;
              final roles = _asMapList(payload.matrix['roles']);
              final permissions = _asMapList(payload.matrix['permissions']);
              final staffs = _filterStaff(_asMapList(payload.users['users']));

              return AdminListStack(
                children: [
                  AdminPageHeader(
                    title: 'Staff',
                    subtitle: 'Manage staff members, roles, and permission matrix.',
                    action: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => context.go(Routes.adminStaffAssign),
                          child: const Text('Assign role'),
                        ),
                        FilledButton(
                          onPressed: () => context.go(Routes.adminStaffNew),
                          child: const Text('New staff'),
                        ),
                      ],
                    ),
                  ),
                  AdminCollapsibleOverview(
                    summary: '${staffs.length} staff · ${roles.length} roles · ${permissions.length} permissions',
                    child: AdminStatGrid(
                      children: [
                        AdminStatCard(
                          label: 'Staffs',
                          value: '${staffs.length}',
                          icon: Icons.groups_outlined,
                        ),
                        AdminStatCard(
                          label: 'Roles',
                          value: '${roles.length}',
                          icon: Icons.admin_panel_settings_outlined,
                        ),
                        AdminStatCard(
                          label: 'Permissions',
                          value: '${permissions.length}',
                          icon: Icons.key_outlined,
                        ),
                      ],
                    ),
                  ),
                  AdminSearchToolbar(
                    value: _search,
                    onChanged: (v) => setState(() => _search = v),
                    placeholder: 'Search staff',
                  ),
                  const TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: [
                      Tab(text: 'Staffs'),
                      Tab(text: 'Roles'),
                      Tab(text: 'Permissions'),
                    ],
                  ),
                  SizedBox(
                    height: 520,
                    child: TabBarView(
                      children: [
                        _StaffsTab(staffs: staffs, onRefresh: _refresh),
                        _RolesTab(roles: roles, permissions: permissions, onRefresh: _refresh),
                        _PermissionsTab(roles: roles, permissions: permissions, onRefresh: _refresh),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StaffsTab extends ConsumerStatefulWidget {
  const _StaffsTab({required this.staffs, required this.onRefresh});

  final List<Map<String, dynamic>> staffs;
  final VoidCallback onRefresh;

  @override
  ConsumerState<_StaffsTab> createState() => _StaffsTabState();
}

class _StaffsTabState extends ConsumerState<_StaffsTab> {
  final PaginatedSliceHook<Map<String, dynamic>> _slice =
      PaginatedSliceHook<Map<String, dynamic>>();
  final BulkSelection _selection = BulkSelection();

  void _refreshSelection() => setState(() {});

  List<Map<String, dynamic>> _sortRows(ListControlsState controls) {
    final sort = controls.activeSort;
    if (sort == null) return widget.staffs;
    final rows = [...widget.staffs];
    rows.sort((a, b) {
      if (sort.key == 'name') {
        return compareSortable(
          a['full_name'] ?? a['username'],
          b['full_name'] ?? b['username'],
          sort.dir,
        );
      }
      return compareSortable(a['updated_at'], b['updated_at'], sort.dir);
    });
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    const controlsKey = 'staff_users';
    final controls = ref.watch(listControlsProvider(controlsKey));
    final controlsNotifier = ref.read(listControlsProvider(controlsKey).notifier);
    final rows = _sortRows(controls);
    final pagination = _slice.call(
      rows,
      adminPaginatedOptions(
        controls: controls,
        notifier: controlsNotifier,
        resetDeps: [controls.activeSort?.key, controls.activeSort?.dir.name, controls.layout.name],
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
          empty: const Padding(padding: EdgeInsets.all(20), child: Text('No staff users found.')),
          table: AdminTableCard(
            child: ListView.separated(
              itemCount: pagination.visibleItems.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final row = pagination.visibleItems[index];
                final id = rowId(row);
                final roles = _asStringList(row['roles']).join(', ');
                final actions = InlineRowActions(
                  onEdit: id.isEmpty
                      ? null
                      : () => context.go('${Routes.adminStaffProfile}?id=$id'),
                  onDelete: id.isEmpty
                      ? null
                      : () async {
                          final ok = await confirmDelete(
                            context,
                            title: 'Delete staff user?',
                          );
                          if (!ok) return;
                          await rbacService.deleteUser(
                            ref.read(authProvider).accessToken,
                            id,
                            'hard',
                          );
                          widget.onRefresh();
                        },
                );

                return AdminSelectableListTile(
                  id: id,
                  selected: _selection.isSelected(id),
                  onToggleSelected: () {
                    _selection.toggle(id);
                    _refreshSelection();
                  },
                  onTap: id.isEmpty
                      ? null
                      : () => context.go('${Routes.adminStaffProfile}?id=$id'),
                  leading: StatusBadge(
                    label: row['is_banned'] == true ? 'Banned' : 'Active',
                    variant: row['is_banned'] == true
                        ? StatusBadgeVariant.danger
                        : StatusBadgeVariant.success,
                  ),
                  title: Text((row['full_name'] ?? row['username'] ?? 'Unknown').toString()),
                  subtitle: Text('${row['email'] ?? '—'} · ${roles.isEmpty ? 'No roles' : roles}'),
                  actions: actions,
                );
              },
            ),
          ),
          grid: AdminEntityGrid(
            children: [
              for (final row in pagination.visibleItems)
                _StaffGridCard(
                  row: row,
                  selected: _selection.isSelected(rowId(row)),
                  onToggleSelected: () {
                    _selection.toggle(rowId(row));
                    _refreshSelection();
                  },
                  onOpen: (id) => context.go('${Routes.adminStaffProfile}?id=$id'),
                  onDelete: (id) async {
                    final ok = await confirmDelete(context, title: 'Delete staff user?');
                    if (!ok) return;
                    await rbacService.deleteUser(ref.read(authProvider).accessToken, id, 'hard');
                    widget.onRefresh();
                  },
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
  }
}

class _StaffGridCard extends StatelessWidget {
  const _StaffGridCard({
    required this.row,
    required this.selected,
    required this.onToggleSelected,
    required this.onOpen,
    required this.onDelete,
  });

  final Map<String, dynamic> row;
  final bool selected;
  final VoidCallback onToggleSelected;
  final void Function(String id) onOpen;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    final id = rowId(row);
    final actions = InlineRowActions(
      onEdit: id.isEmpty ? null : () => onOpen(id),
      onDelete: id.isEmpty ? null : () => onDelete(id),
    );

    return AdminEntityGridCard(
      selected: selected,
      onTap: onToggleSelected,
      actions: InlineRowActionsSpeedDial(actions: actions),
      selection: AdminListSelectCheckbox(compact: true, checked: selected, onChanged: onToggleSelected),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text((row['full_name'] ?? row['username'] ?? 'Unknown').toString()),
          const SizedBox(height: 6),
          Text(row['email']?.toString() ?? '—', style: Theme.of(context).textTheme.bodySmall),
                  ],
      ),
    );
  }
}

class _RolesTab extends ConsumerStatefulWidget {
  const _RolesTab({
    required this.roles,
    required this.permissions,
    required this.onRefresh,
  });

  final List<Map<String, dynamic>> roles;
  final List<Map<String, dynamic>> permissions;
  final VoidCallback onRefresh;

  @override
  ConsumerState<_RolesTab> createState() => _RolesTabState();
}

class _RolesTabState extends ConsumerState<_RolesTab> {
  final PaginatedSliceHook<Map<String, dynamic>> _slice =
      PaginatedSliceHook<Map<String, dynamic>>();
  final BulkSelection _selection = BulkSelection();

  void _refreshSelection() => setState(() {});

  List<Map<String, dynamic>> _sortRows(ListControlsState controls) {
    final sort = controls.activeSort;
    if (sort == null) return widget.roles;
    final rows = [...widget.roles];
    rows.sort((a, b) => compareSortable(a['name'], b['name'], sort.dir));
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    const controlsKey = 'staff_roles';
    final controls = ref.watch(listControlsProvider(controlsKey));
    final controlsNotifier = ref.read(listControlsProvider(controlsKey).notifier);
    final rows = _sortRows(controls);
    final pagination = _slice.call(
      rows,
      adminPaginatedOptions(
        controls: controls,
        notifier: controlsNotifier,
        resetDeps: [controls.activeSort?.key, controls.activeSort?.dir.name, controls.layout.name],
      ),
    );
    final sliceOptions = adminPaginatedOptions(
      controls: controls,
      notifier: controlsNotifier,
    );

    return AdminListStack(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () => context.go('${Routes.adminStaffList}/roles/new'),
            child: const Text('Create role'),
          ),
        ),
        AdminManagedListToolbarSection(
          controls: controls,
          notifier: controlsNotifier,
          selection: _selection,
          onSelectionChanged: _refreshSelection,
          sortOptions: adminEntityGridSortOptions(defaultKey: 'name'),
        ),
        const SizedBox(height: 12),
        AdminLayoutSwitch(
          layout: controls.layout,
          isEmpty: pagination.visibleItems.isEmpty,
          empty: const Padding(padding: EdgeInsets.all(20), child: Text('No roles available.')),
          table: AdminTableCard(
            child: ListView.separated(
              itemCount: pagination.visibleItems.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final role = pagination.visibleItems[index];
                final id = rowId(role);
                final perms = _asStringList(role['permissions']);
                final actions = InlineRowActions(
                  onEdit: () async {
                    final ok = await showRoleEditorSheet(
                      context,
                      ref,
                      role: role,
                      allPermissions: widget.permissions,
                    );
                    if (ok == true) widget.onRefresh();
                  },
                  onDelete: () async {
                    final ok = await confirmDelete(context, title: 'Delete role?');
                    if (!ok) return;
                    await rbacService.deleteRole(
                      ref.read(authProvider).accessToken,
                      id,
                    );
                    widget.onRefresh();
                  },
                );

                return AdminSelectableListTile(
                  id: id,
                  selected: _selection.isSelected(id),
                  onToggleSelected: () {
                    _selection.toggle(id);
                    _refreshSelection();
                  },
                  title: Text(role['name']?.toString() ?? 'Role'),
                  subtitle: Text('${role['description'] ?? '—'} · ${perms.length} permissions'),
                  actions: actions,
                );
              },
            ),
          ),
          grid: AdminEntityGrid(
            children: [
              for (final role in pagination.visibleItems)
                _RoleGridCard(
                  role: role,
                  selected: _selection.isSelected(rowId(role)),
                  onToggleSelected: () {
                    _selection.toggle(rowId(role));
                    _refreshSelection();
                  },
                  onEdit: () async {
                    final ok = await showRoleEditorSheet(
                      context,
                      ref,
                      role: role,
                      allPermissions: widget.permissions,
                    );
                    if (ok == true) widget.onRefresh();
                  },
                  onDelete: () async {
                    final ok = await confirmDelete(context, title: 'Delete role?');
                    if (!ok) return;
                    await rbacService.deleteRole(
                      ref.read(authProvider).accessToken,
                      role['id']?.toString() ?? '',
                    );
                    widget.onRefresh();
                  },
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
  }
}

class _RoleGridCard extends StatelessWidget {
  const _RoleGridCard({
    required this.role,
    required this.selected,
    required this.onToggleSelected,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> role;
  final bool selected;
  final VoidCallback onToggleSelected;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final actions = InlineRowActions(onEdit: onEdit, onDelete: onDelete);
    return AdminEntityGridCard(
      selected: selected,
      onTap: onToggleSelected,
      actions: InlineRowActionsSpeedDial(actions: actions),
      selection: AdminListSelectCheckbox(compact: true, checked: selected, onChanged: onToggleSelected),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(role['name']?.toString() ?? 'Role', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(role['description']?.toString() ?? '—', style: Theme.of(context).textTheme.bodySmall),
                  ],
      ),
    );
  }
}

class _PermissionsTab extends ConsumerStatefulWidget {
  const _PermissionsTab({
    required this.roles,
    required this.permissions,
    required this.onRefresh,
  });

  final List<Map<String, dynamic>> roles;
  final List<Map<String, dynamic>> permissions;
  final VoidCallback onRefresh;

  @override
  ConsumerState<_PermissionsTab> createState() => _PermissionsTabState();
}

class _PermissionsTabState extends ConsumerState<_PermissionsTab> {
  String? _roleId;

  Map<String, dynamic>? get _selectedRole {
    if (_roleId == null) return widget.roles.isNotEmpty ? widget.roles.first : null;
    return widget.roles.cast<Map<String, dynamic>?>().firstWhere(
          (r) => r?['id']?.toString() == _roleId,
          orElse: () => widget.roles.first,
        );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.roles.isEmpty) {
      return const AdminTableCard(
        isEmpty: true,
        empty: Padding(padding: EdgeInsets.all(20), child: Text('No roles to edit.')),
        child: SizedBox.shrink(),
      );
    }
    final role = _selectedRole!;
    final rolePerms = _asStringList(role['permissions']).toSet();

    return AdminListStack(
      children: [
        DropdownButtonFormField<String>(
          initialValue: role['id']?.toString(),
          decoration: const InputDecoration(
            labelText: 'Role',
            border: OutlineInputBorder(),
          ),
          items: widget.roles
              .map(
                (r) => DropdownMenuItem(
                  value: r['id']?.toString(),
                  child: Text(r['name']?.toString() ?? 'Role'),
                ),
              )
              .toList(growable: false),
          onChanged: (v) => setState(() => _roleId = v),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final ok = await showRoleEditorSheet(
              context,
              ref,
              role: role,
              allPermissions: widget.permissions,
            );
            if (ok == true) widget.onRefresh();
          },
          icon: const Icon(Icons.edit, size: 16),
          label: Text('Edit ${role['name']} permissions'),
        ),
        AdminTableCard(
          isEmpty: widget.permissions.isEmpty,
          empty: const Padding(padding: EdgeInsets.all(20), child: Text('No permissions defined.')),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.permissions.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final perm = widget.permissions[index];
              final name = perm['name']?.toString() ?? '';
              final assigned = rolePerms.contains(name);
              return ListTile(
                dense: true,
                title: Text(name),
                subtitle: Text(perm['description']?.toString() ?? ''),
                trailing: Icon(
                  assigned ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: assigned ? Theme.of(context).colorScheme.primary : null,
                  size: 18,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message ?? 'Failed to load data.'),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _StaffPayload {
  const _StaffPayload({required this.matrix, required this.users});

  final Map<String, dynamic> matrix;
  final Map<String, dynamic> users;
}

int _tabIndexFromQuery(String? raw) {
  switch (raw) {
    case 'roles':
      return 1;
    case 'permissions':
      return 2;
    default:
      return 0;
  }
}

List<Map<String, dynamic>> _asMapList(dynamic raw) {
  if (raw is! List) return const [];
  return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(growable: false);
}

List<String> _asStringList(dynamic raw) {
  if (raw is! List) return const [];
  return raw.map((e) => e.toString()).toList(growable: false);
}

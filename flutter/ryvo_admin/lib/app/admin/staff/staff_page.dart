import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_auth.dart';
import 'package:ryvo_admin/services/rbac_service.dart';

class StaffPage extends ConsumerStatefulWidget {
  const StaffPage({super.key});

  @override
  ConsumerState<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends ConsumerState<StaffPage> {
  late Future<_StaffPayload> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_StaffPayload> _load() async {
    final token = useAuth(ref).accessToken;
    final matrix = await rbacService.getMatrix(token);
    final users = await rbacService.listUsers(token, kind: 'staff');
    return _StaffPayload(matrix: matrix, users: users);
  }

  void _refresh() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = _tabIndexFromQuery(
      GoRouterState.of(context).uri.queryParameters['tab'],
    );

    return PermissionGate(
      permissions: const ['staff:read', 'roles:read'],
      fallback: const Center(
        child: Text('You do not have access to staff data.'),
      ),
      child: DefaultTabController(
        length: 3,
        initialIndex: tabIndex,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<_StaffPayload>(
            future: _future,
            builder: (context, snapshot) {
              final loading =
                  snapshot.connectionState == ConnectionState.waiting;
              final error = snapshot.error;
              final payload = snapshot.data;

              if (loading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (error != null || payload == null) {
                return _LoadError(
                  onRetry: _refresh,
                  message: error?.toString(),
                );
              }

              final roles = _asMapList(payload.matrix['roles']);
              final permissions = _asMapList(payload.matrix['permissions']);
              final staffs = _asMapList(payload.users['users']);

              return AdminListStack(
                children: [
                  AdminPageHeader(
                    title: 'Staff',
                    subtitle:
                        'Manage staff members, roles, and permission matrix.',
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
                  AdminStatGrid(
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
                        _StaffsTab(staffs: staffs),
                        _RolesTab(roles: roles),
                        _PermissionsTab(permissions: permissions),
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

class _StaffsTab extends StatelessWidget {
  const _StaffsTab({required this.staffs});

  final List<Map<String, dynamic>> staffs;

  @override
  Widget build(BuildContext context) {
    return AdminTableCard(
      isEmpty: staffs.isEmpty,
      empty: const Padding(
        padding: EdgeInsets.all(20),
        child: Text('No staff users found.'),
      ),
      child: AdminTable(
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Roles')),
            DataColumn(label: Text('Status')),
          ],
          rows: staffs
              .map((row) {
                final id = row['id']?.toString() ?? '';
                final roles = _asStringList(row['roles']).join(', ');
                return DataRow(
                  cells: [
                    DataCell(
                      InkWell(
                        onTap: id.isEmpty
                            ? null
                            : () => context.go(
                                '${Routes.adminStaffProfile}?id=$id',
                              ),
                        child: Text(
                          (row['full_name'] ?? row['username'] ?? 'Unknown')
                              .toString(),
                        ),
                      ),
                    ),
                    DataCell(Text((row['email'] ?? '—').toString())),
                    DataCell(Text(roles.isEmpty ? '—' : roles)),
                    DataCell(
                      StatusBadge(
                        label: (row['is_banned'] == true) ? 'Banned' : 'Active',
                        variant: row['is_banned'] == true
                            ? StatusBadgeVariant.danger
                            : StatusBadgeVariant.success,
                      ),
                    ),
                  ],
                );
              })
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _RolesTab extends StatelessWidget {
  const _RolesTab({required this.roles});

  final List<Map<String, dynamic>> roles;

  @override
  Widget build(BuildContext context) {
    return AdminListStack(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: () => context.go('${Routes.adminStaffList}/roles/new'),
            child: const Text('Create role'),
          ),
        ),
        AdminTableCard(
          isEmpty: roles.isEmpty,
          empty: const Padding(
            padding: EdgeInsets.all(20),
            child: Text('No roles available.'),
          ),
          child: AdminTable(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Role')),
                DataColumn(label: Text('Description')),
                DataColumn(label: Text('Permissions')),
              ],
              rows: roles
                  .map((role) {
                    final perms = _asStringList(role['permissions']);
                    return DataRow(
                      cells: [
                        DataCell(Text((role['name'] ?? '—').toString())),
                        DataCell(Text((role['description'] ?? '—').toString())),
                        DataCell(Text('${perms.length}')),
                      ],
                    );
                  })
                  .toList(growable: false),
            ),
          ),
        ),
      ],
    );
  }
}

class _PermissionsTab extends StatelessWidget {
  const _PermissionsTab({required this.permissions});

  final List<Map<String, dynamic>> permissions;

  @override
  Widget build(BuildContext context) {
    return AdminTableCard(
      isEmpty: permissions.isEmpty,
      empty: const Padding(
        padding: EdgeInsets.all(20),
        child: Text('No permissions available.'),
      ),
      child: ListView.separated(
        itemCount: permissions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final row = permissions[index];
          return ListTile(
            dense: true,
            title: Text((row['name'] ?? '—').toString()),
            subtitle: Text((row['description'] ?? '').toString()),
          );
        },
      ),
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
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);
}

List<String> _asStringList(dynamic raw) {
  if (raw is! List) return const [];
  return raw.map((e) => e.toString()).toList(growable: false);
}

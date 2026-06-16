import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_auth.dart';
import 'package:ryvo_admin/services/index.dart';

class AdminMessagesPage extends ConsumerStatefulWidget {
  const AdminMessagesPage({super.key});

  @override
  ConsumerState<AdminMessagesPage> createState() => _AdminMessagesPageState();
}

class _AdminMessagesPageState extends ConsumerState<AdminMessagesPage> {
  Future<Map<String, dynamic>>? _future;
  String _statusFilter = 'all';
  String _audienceFilter = 'all_audiences';
  String _search = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<Map<String, dynamic>> _load() {
    final token = useAuth(ref).accessToken;
    return messagesService.list(token);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> source) {
    return source
        .where((row) {
          final status = row['status']?.toString() ?? '';
          final audience = row['audience']?.toString() ?? '';
          final body = row['body_template']?.toString() ?? '';
          final id = row['id']?.toString() ?? '';
          if (_statusFilter != 'all' && status != _statusFilter) {
            return false;
          }
          if (_audienceFilter == 'clients' && audience != 'clients') {
            return false;
          }
          if (_audienceFilter == 'drivers' && audience != 'drivers') {
            return false;
          }
          if (_audienceFilter == 'everyone' && audience != 'all') {
            return false;
          }
          if (_search.trim().isEmpty) return true;
          final q = _search.toLowerCase().trim();
          return body.toLowerCase().contains(q) ||
              id.toLowerCase().contains(q) ||
              status.toLowerCase().contains(q);
        })
        .toList(growable: false);
  }

  int _countByStatus(List<Map<String, dynamic>> rows, String status) {
    return rows.where((r) => r['status']?.toString() == status).length;
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permissions: const ['communication:messages:read', 'support:reply'],
      fallback: const Center(child: Text('No access to campaigns.')),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AdminListStack(
          children: [
            AdminPageHeader(
              title: 'Messages',
              subtitle: 'Message campaigns list.',
              action: Wrap(
                spacing: 8,
                children: [
                  ShadButton(
                    onPressed: () => context.go(Routes.adminCommMessagesNew),
                    child: const Text('Compose'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Refresh'),
                  ),
                ],
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
                      child: Text(
                        'Failed to load campaigns: ${snapshot.error}',
                      ),
                    ),
                    child: const SizedBox.shrink(),
                  );
                }

                final campaignsRaw = snapshot.data?['campaigns'];
                final campaigns = campaignsRaw is List
                    ? campaignsRaw
                          .whereType<Map>()
                          .map((e) => Map<String, dynamic>.from(e))
                          .toList(growable: false)
                    : <Map<String, dynamic>>[];
                final rows = _filtered(campaigns);

                return AdminListStack(
                  children: [
                    AdminStatGrid(
                      children: [
                        AdminStatCard(
                          label: 'Total',
                          value: '${campaigns.length}',
                          icon: Icons.message_outlined,
                        ),
                        AdminStatCard(
                          label: 'Drafts',
                          value: '${_countByStatus(campaigns, 'draft')}',
                          icon: Icons.edit_note,
                          tone: AdminStatTone.warning,
                        ),
                        AdminStatCard(
                          label: 'Sent',
                          value: '${_countByStatus(campaigns, 'sent')}',
                          icon: Icons.send,
                          tone: AdminStatTone.success,
                        ),
                        AdminStatCard(
                          label: 'Queued',
                          value: '${_countByStatus(campaigns, 'queued')}',
                          icon: Icons.schedule_send,
                          tone: AdminStatTone.info,
                        ),
                      ],
                    ),
                    AdminSearchToolbar(
                      value: _search,
                      onChanged: (v) => setState(() => _search = v),
                      placeholder: 'Search campaigns',
                      filters: [
                        AdminFilterSelect(
                          value: _statusFilter,
                          onChanged: (v) => setState(() => _statusFilter = v),
                          options: const [
                            AdminFilterOption(
                              value: 'all',
                              label: 'All statuses',
                            ),
                            AdminFilterOption(value: 'draft', label: 'Draft'),
                            AdminFilterOption(value: 'queued', label: 'Queued'),
                            AdminFilterOption(value: 'sent', label: 'Sent'),
                            AdminFilterOption(
                              value: 'cancelled',
                              label: 'Cancelled',
                            ),
                          ],
                        ),
                        AdminFilterSelect(
                          value: _audienceFilter,
                          onChanged: (v) => setState(() => _audienceFilter = v),
                          options: const [
                            AdminFilterOption(
                              value: 'all_audiences',
                              label: 'All audiences',
                            ),
                            AdminFilterOption(
                              value: 'clients',
                              label: 'Clients',
                            ),
                            AdminFilterOption(
                              value: 'drivers',
                              label: 'Drivers',
                            ),
                            AdminFilterOption(
                              value: 'everyone',
                              label: 'Everyone',
                            ),
                          ],
                        ),
                      ],
                    ),
                    AdminTableCard(
                      isEmpty: rows.isEmpty,
                      empty: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No campaigns found for the selected filters.',
                        ),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final c = rows[index];
                          final status = c['status']?.toString() ?? 'unknown';
                          final audience =
                              c['audience']?.toString() ?? 'unknown';
                          final createdAt = c['created_at']?.toString() ?? '—';
                          return ListTile(
                            title: Text(
                              c['body_template']?.toString() ?? '—',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'Audience: $audience · Created: $createdAt',
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              final id = c['id']?.toString();
                              if (id == null || id.isEmpty) return;
                              context.go('/admin/communication/messages/$id/edit');
                            },
                            leading: StatusBadge(
                              label: status,
                              variant: status == 'sent'
                                  ? StatusBadgeVariant.success
                                  : status == 'queued'
                                  ? StatusBadgeVariant.info
                                  : status == 'draft'
                                  ? StatusBadgeVariant.warning
                                  : StatusBadgeVariant.danger,
                            ),
                          );
                        },
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemCount: rows.length,
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

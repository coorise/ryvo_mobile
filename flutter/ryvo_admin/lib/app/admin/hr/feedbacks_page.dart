import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_auth.dart';
import 'package:ryvo_admin/services/index.dart';

class AdminHrFeedbacksPage extends ConsumerStatefulWidget {
  const AdminHrFeedbacksPage({super.key});

  @override
  ConsumerState<AdminHrFeedbacksPage> createState() =>
      _AdminHrFeedbacksPageState();
}

class _AdminHrFeedbacksPageState extends ConsumerState<AdminHrFeedbacksPage> {
  final List<String> _categories = const ['product', 'driver', 'staff'];
  final List<String> _granularity = const ['day', 'week', 'month', 'year'];
  String _category = 'product';
  String _bucket = 'week';
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() {
    return feedbacksService.getAnalytics(
      useAuth(ref).accessToken,
      _category,
      _bucket,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permissions: const ['feedbacks:read', 'support:read'],
      fallback: const Center(child: Text('No access to feedback analytics.')),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AdminListStack(
          children: [
            AdminPageHeader(
              title: 'Feedbacks',
              subtitle: 'Feedback analytics by category.',
              action: OutlinedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
            ),
            AdminSearchToolbar(
              value: '',
              onChanged: (_) {},
              placeholder: 'Filters',
              filters: [
                AdminFilterSelect(
                  value: _category,
                  onChanged: (v) => setState(() {
                    _category = v;
                    _future = _load();
                  }),
                  options: _categories
                      .map((e) => AdminFilterOption(value: e, label: e))
                      .toList(),
                ),
                AdminFilterSelect(
                  value: _bucket,
                  onChanged: (v) => setState(() {
                    _bucket = v;
                    _future = _load();
                  }),
                  options: _granularity
                      .map((e) => AdminFilterOption(value: e, label: e))
                      .toList(),
                ),
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
                        'Failed to load feedbacks: ${snapshot.error}',
                      ),
                    ),
                    child: const SizedBox.shrink(),
                  );
                }

                final stats = snapshot.data?['stats'] is Map
                    ? Map<String, dynamic>.from(snapshot.data!['stats'] as Map)
                    : <String, dynamic>{};
                final entriesRaw = snapshot.data?['entries'];
                final entries = entriesRaw is List
                    ? entriesRaw
                          .whereType<Map>()
                          .map((e) => Map<String, dynamic>.from(e))
                          .toList(growable: false)
                    : <Map<String, dynamic>>[];

                return AdminListStack(
                  children: [
                    AdminStatGrid(
                      children: [
                        AdminStatCard(
                          label: 'Total',
                          value: '${stats['total'] ?? 0}',
                          icon: Icons.rate_review,
                        ),
                        AdminStatCard(
                          label: 'Avg Score',
                          value: '${stats['avgScore'] ?? 0}',
                          icon: Icons.star_rate,
                          tone: AdminStatTone.warning,
                        ),
                        AdminStatCard(
                          label: 'Disputes',
                          value: '${stats['litiges'] ?? 0}',
                          icon: Icons.report_problem_outlined,
                          tone: AdminStatTone.danger,
                        ),
                        AdminStatCard(
                          label: 'Low Ratings',
                          value: '${stats['lowRatings'] ?? 0}',
                          icon: Icons.trending_down,
                          tone: AdminStatTone.info,
                        ),
                      ],
                    ),
                    AdminTableCard(
                      isEmpty: entries.isEmpty,
                      empty: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No feedback entries found.'),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: entries.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = entries[index];
                          return ListTile(
                            title: Text(
                              item['comment']?.toString() ?? 'No comment',
                            ),
                            subtitle: Text(
                              'Stars: ${item['stars'] ?? 0} · Source: ${item['source'] ?? '—'} · ${item['created_at'] ?? ''}',
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

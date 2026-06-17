import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ryvo_admin/components/admin/admin_list_layout.dart';
import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/components/admin/admin_managed_list.dart';
import 'package:ryvo_admin/components/admin/admin_selectable_list.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_bulk_selection.dart';
import 'package:ryvo_admin/hooks/use_list_controls.dart';
import 'package:ryvo_admin/hooks/use_paginated_slice.dart';
import 'package:ryvo_admin/services/index.dart';
import 'package:ryvo_admin/stores/auth_store.dart';

class AdminHrFeedbacksPage extends ConsumerStatefulWidget {
  const AdminHrFeedbacksPage({super.key});

  @override
  ConsumerState<AdminHrFeedbacksPage> createState() =>
      _AdminHrFeedbacksPageState();
}

class _AdminHrFeedbacksPageState extends ConsumerState<AdminHrFeedbacksPage> {
  final List<String> _granularity = const ['day', 'week', 'month', 'year'];
  String _bucket = 'week';
  final PaginatedSliceHook<Map<String, dynamic>> _slice =
      PaginatedSliceHook<Map<String, dynamic>>();
  final BulkSelection _selection = BulkSelection();
  Future<Map<String, dynamic>>? _future;

  void _refreshSelection() => setState(() {});

  @override
  void initState() {
    super.initState();
    _future = _load(_categoryFromTab(null));
  }

  String _categoryFromTab(String? tab) {
    if (tab == AdminTabs.feedbacksDrivers) return 'driver';
    if (tab == AdminTabs.feedbacksStaff) return 'staff';
    return 'product';
  }

  int _tabIndexFromQuery(String? tab) {
    if (tab == AdminTabs.feedbacksDrivers) return 1;
    if (tab == AdminTabs.feedbacksStaff) return 2;
    return 0;
  }

  String _tabFromIndex(int index) {
    switch (index) {
      case 1:
        return AdminTabs.feedbacksDrivers;
      case 2:
        return AdminTabs.feedbacksStaff;
      default:
        return AdminTabs.feedbacksProduct;
    }
  }

  String _subtitleForTab(String? tab) {
    if (tab == AdminTabs.feedbacksDrivers) {
      return 'Driver service quality, complaints, and dispute signals.';
    }
    if (tab == AdminTabs.feedbacksStaff) {
      return 'Staff and agent satisfaction, escalations, and litiges.';
    }
    return 'Product and platform experience feedback over time.';
  }

  Future<Map<String, dynamic>> _load(String category) {
    return feedbacksService.getAnalytics(
      ref.read(authProvider).accessToken,
      category,
      _bucket,
    );
  }

  Future<void> _refresh(String category) async {
    setState(() => _future = _load(category));
    await _future;
  }

  List<Map<String, dynamic>> _filterAndSort(
    List<Map<String, dynamic>> allEntries,
    ListControlsState controls,
  ) {
    final q = controls.search.trim().toLowerCase();
    var entries = q.isEmpty
        ? allEntries
        : allEntries.where((item) {
            final comment = item['comment']?.toString().toLowerCase() ?? '';
            final source = item['source']?.toString().toLowerCase() ?? '';
            final stars = item['stars']?.toString() ?? '';
            return comment.contains(q) ||
                source.contains(q) ||
                stars.contains(q);
          }).toList(growable: false);

    final sort = controls.activeSort;
    if (sort != null) {
      entries = [...entries]
        ..sort((a, b) {
          if (sort.key == 'stars') {
            return compareSortable(a['stars'], b['stars'], sort.dir);
          }
          return compareSortable(a['created_at'], b['created_at'], sort.dir);
        });
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    const controlsKey = 'feedbacks';
    final controls = ref.watch(listControlsProvider(controlsKey));
    final controlsNotifier = ref.read(listControlsProvider(controlsKey).notifier);
    final tab = GoRouterState.of(context).uri.queryParameters['tab'];
    final tabIndex = _tabIndexFromQuery(tab);
    final category = _categoryFromTab(tab);

    return PermissionGate(
      permissions: const ['feedbacks:read', 'support:read'],
      fallback: const Center(child: Text('No access to feedback analytics.')),
      child: DefaultTabController(
        key: ValueKey(tab ?? AdminTabs.feedbacksProduct),
        length: 3,
        initialIndex: tabIndex,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: AdminListStack(
            children: [
              AdminPageHeader(
                title: 'Feedbacks',
                subtitle: _subtitleForTab(tab),
                action: OutlinedButton.icon(
                  onPressed: () => _refresh(category),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                ),
              ),
              TabBar(
                onTap: (index) {
                  final nextTab = _tabFromIndex(index);
                  context.go('${Routes.adminHrFeedbacks}?tab=$nextTab');
                  setState(() => _future = _load(_categoryFromTab(nextTab)));
                },
                tabs: const [
                  Tab(text: 'Product-Services'),
                  Tab(text: 'Drivers-Services'),
                  Tab(text: 'Staff-Services'),
                ],
              ),
              const SizedBox(height: 12),
              AdminSearchToolbar(
                value: controls.search,
                onChanged: controlsNotifier.setSearch,
                placeholder: 'Search feedback entries',
              ),
              const SizedBox(height: 10),
              AdminManagedListToolbarSection(
                controls: controls,
                notifier: controlsNotifier,
                selection: _selection,
                onSelectionChanged: _refreshSelection,
                sortOptions: const [
                  AdminFilterOption(value: 'created_at:desc', label: 'Newest first'),
                  AdminFilterOption(value: 'created_at:asc', label: 'Oldest first'),
                  AdminFilterOption(value: 'stars:desc', label: 'Highest rating'),
                  AdminFilterOption(value: 'stars:asc', label: 'Lowest rating'),
                ],
                filters: AdminFilterSelect(
                  value: _bucket,
                  onChanged: (v) => setState(() {
                    _bucket = v;
                    _future = _load(category);
                  }),
                  options: _granularity
                      .map((e) => AdminFilterOption(value: e, label: e))
                      .toList(),
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
                  final allEntries = entriesRaw is List
                      ? entriesRaw
                            .whereType<Map>()
                            .map((e) => Map<String, dynamic>.from(e))
                            .toList(growable: false)
                      : <Map<String, dynamic>>[];
                  final entries = _filterAndSort(allEntries, controls);
                  final pagination = _slice.call(
                    entries,
                    adminPaginatedOptions(
                      controls: controls,
                      notifier: controlsNotifier,
                      resetDeps: [
                        controls.search,
                        controls.activeSort?.key,
                        controls.activeSort?.dir.name,
                        _bucket,
                        category,
                        controls.layout.name,
                      ],
                    ),
                  );
                  final sliceOptions = adminPaginatedOptions(
                    controls: controls,
                    notifier: controlsNotifier,
                  );

                  return AdminListStack(
                    children: [
                      AdminCollapsibleOverview(
                        summary:
                            '${stats['total'] ?? 0} total · avg ${stats['avgScore'] ?? 0} · ${stats['litiges'] ?? 0} disputes',
                        child: AdminStatGrid(
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
                      ),
                      const SizedBox(height: 12),
                      AdminLayoutSwitch(
                        layout: controls.layout,
                        isEmpty: pagination.visibleItems.isEmpty,
                        empty: const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('No feedback entries found.'),
                        ),
                        table: AdminTableCard(
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: pagination.visibleItems.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = pagination.visibleItems[index];
                              final id = rowId(item);
                              return AdminSelectableListTile(
                                id: id,
                                selected: _selection.isSelected(id),
                                onToggleSelected: () {
                                  _selection.toggle(id);
                                  _refreshSelection();
                                },
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
                        grid: AdminEntityGrid(
                          children: [
                            for (final item in pagination.visibleItems)
                              _FeedbackGridCard(
                                item: item,
                                selected: _selection.isSelected(rowId(item)),
                                onToggleSelected: () {
                                  _selection.toggle(rowId(item));
                                  _refreshSelection();
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
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackGridCard extends StatelessWidget {
  const _FeedbackGridCard({
    required this.item,
    required this.selected,
    required this.onToggleSelected,
  });

  final Map<String, dynamic> item;
  final bool selected;
  final VoidCallback onToggleSelected;

  @override
  Widget build(BuildContext context) {
    return AdminEntityGridCard(
      selected: selected,
      onTap: onToggleSelected,
      selection: AdminListSelectCheckbox(compact: true, 
        checked: selected,
        onChanged: onToggleSelected,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item['comment']?.toString() ?? 'No comment',
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            '★ ${item['stars'] ?? 0} · ${item['source'] ?? '—'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

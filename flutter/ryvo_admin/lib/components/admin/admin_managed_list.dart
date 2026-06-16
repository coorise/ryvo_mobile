import 'package:flutter/material.dart';

import 'package:ryvo_admin/components/admin/admin_list_layout.dart';
import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/hooks/use_bulk_selection.dart';
import 'package:ryvo_admin/hooks/use_list_controls.dart';
import 'package:ryvo_admin/hooks/use_paginated_slice.dart';

/// Toolbar + bulk selection bar for managed list pages.
class AdminManagedListToolbarSection extends StatelessWidget {
  const AdminManagedListToolbarSection({
    super.key,
    required this.controls,
    required this.notifier,
    required this.selection,
    required this.onSelectionChanged,
    this.sortOptions,
    this.filters,
  });

  final ListControlsState controls;
  final ListControlsNotifier notifier;
  final BulkSelection selection;
  final VoidCallback onSelectionChanged;
  final List<AdminFilterOption>? sortOptions;
  final Widget? filters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminListLayoutToolbar(
          layout: controls.layout,
          onLayoutChange: notifier.setLayout,
          loadMode: controls.loadMode,
          onLoadModeChange: notifier.setLoadMode,
          pageSize: controls.pageSize,
          onPageSizeChange: notifier.setPageSize,
          gridSortValue: controls.gridSortValue,
          onGridSortValueChange: notifier.setGridSortValue,
          sortOptions: sortOptions,
          filters: filters,
        ),
        const SizedBox(height: 10),
        AdminBulkSelectionBar(
          count: selection.count,
          onClear: () {
            selection.clear();
            onSelectionChanged();
          },
        ),
      ],
    );
  }
}

/// Pagination footer for managed list pages.
class AdminManagedListFooterSection extends StatelessWidget {
  const AdminManagedListFooterSection({
    super.key,
    required this.pagination,
    required this.notifier,
    required this.slice,
    required this.sliceOptions,
  });

  final PaginatedSliceResult<dynamic> pagination;
  final ListControlsNotifier notifier;
  final PaginatedSliceHook<dynamic> slice;
  final PaginatedSliceOptions sliceOptions;

  @override
  Widget build(BuildContext context) {
    return AdminListPaginationFooter(
      loadMode: pagination.loadMode,
      total: pagination.total,
      page: pagination.page,
      totalPages: pagination.totalPages,
      showingFrom: pagination.showingFrom,
      showingTo: pagination.showingTo,
      hasMore: pagination.hasMore,
      onPageChange: notifier.setPage,
      onLoadMore: () => slice.loadMore(pagination, sliceOptions),
    );
  }
}

/// Table or grid wrapper based on [ListLayout].
class AdminLayoutSwitch extends StatelessWidget {
  const AdminLayoutSwitch({
    super.key,
    required this.layout,
    required this.isEmpty,
    required this.empty,
    required this.table,
    required this.grid,
  });

  final ListLayout layout;
  final bool isEmpty;
  final Widget empty;
  final Widget table;
  final Widget grid;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return AdminTableCard(isEmpty: true, empty: empty, child: const SizedBox.shrink());
    }
    return layout == ListLayout.table ? table : grid;
  }
}

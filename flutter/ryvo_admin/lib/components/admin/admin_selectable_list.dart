import 'package:flutter/material.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/hooks/use_list_controls.dart';
import 'package:ryvo_admin/hooks/use_paginated_slice.dart';

/// List/grid row with checkbox selection and long-press actions — for ListView-based pages.
class AdminSelectableListTile extends StatelessWidget {
  const AdminSelectableListTile({
    super.key,
    required this.id,
    required this.selected,
    required this.onToggleSelected,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.actions,
    this.onTap,
  });

  final String id;
  final bool selected;
  final VoidCallback onToggleSelected;
  final Widget title;
  final Widget? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final InlineRowActions? actions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final rowActions = actions;
    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.28)
          : null,
      child: InkWell(
        onTap: onTap ?? onToggleSelected,
        onLongPress: rowActions == null || rowActions.items.isEmpty
            ? null
            : () => showInlineRowActionsMenu(context, rowActions.items),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdminListSelectCheckbox(
                checked: selected,
                onChanged: onToggleSelected,
              ),
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle(
                      style: Theme.of(context).textTheme.bodyLarge!,
                      child: title,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      DefaultTextStyle(
                        style: Theme.of(context).textTheme.bodySmall!,
                        child: subtitle!,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (rowActions != null) rowActions,
            ],
          ),
        ),
      ),
    );
  }
}

/// Standard grid sort options for user/driver entity lists.
List<AdminFilterOption> adminEntityGridSortOptions({String defaultKey = 'updated_at'}) {
  return [
    AdminFilterOption(value: '$defaultKey:desc', label: 'Recently updated'),
    AdminFilterOption(value: '$defaultKey:asc', label: 'Oldest updated'),
    AdminFilterOption(value: 'name:asc', label: 'Name A–Z'),
    AdminFilterOption(value: 'name:desc', label: 'Name Z–A'),
    AdminFilterOption(value: 'email:asc', label: 'Email A–Z'),
    AdminFilterOption(value: 'email:desc', label: 'Email Z–A'),
  ];
}

String rowId(Map<String, dynamic> row) => row['id']?.toString() ?? '';

PaginatedSliceOptions adminPaginatedOptions({
  required ListControlsState controls,
  required ListControlsNotifier notifier,
  List<Object?> resetDeps = const [],
}) {
  return PaginatedSliceOptions(
    pageSize: controls.pageSize,
    loadMode: controls.loadMode,
    page: controls.page,
    setPage: notifier.setPage,
    infinitePages: controls.infinitePages,
    setInfinitePages: notifier.setInfinitePages,
    resetDeps: resetDeps,
  );
}

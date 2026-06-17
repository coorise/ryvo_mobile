import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo/components/portal/portal_list_ui.dart';
import 'package:ryvo/hooks/use_list_controls.dart';

/// Table / grid + auto load / pages + per-page — mirrors web `ListLayoutToolbar`.
class AdminListLayoutToolbar extends StatelessWidget {
  const AdminListLayoutToolbar({
    super.key,
    required this.layout,
    required this.onLayoutChange,
    required this.loadMode,
    required this.onLoadModeChange,
    required this.pageSize,
    required this.onPageSizeChange,
    this.gridSortValue,
    this.onGridSortValueChange,
    this.sortOptions,
    this.filters,
  });

  final ListLayout layout;
  final ValueChanged<ListLayout> onLayoutChange;
  final ListLoadMode loadMode;
  final ValueChanged<ListLoadMode> onLoadModeChange;
  final int pageSize;
  final ValueChanged<int> onPageSizeChange;
  final String? gridSortValue;
  final ValueChanged<String>? onGridSortValueChange;
  final List<AdminFilterOption>? sortOptions;
  final Widget? filters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _ToggleGroup(
              children: [
                _TogglePill(
                  active: layout == ListLayout.table,
                  label: 'Table',
                  icon: LucideIcons.list,
                  onTap: () => onLayoutChange(ListLayout.table),
                ),
                _TogglePill(
                  active: layout == ListLayout.grid,
                  label: 'Grid',
                  icon: LucideIcons.layoutGrid,
                  onTap: () => onLayoutChange(ListLayout.grid),
                ),
              ],
            ),
            _ToggleGroup(
              children: [
                _TogglePill(
                  active: loadMode == ListLoadMode.infinite,
                  label: 'Auto load',
                  icon: LucideIcons.scrollText,
                  onTap: () => onLoadModeChange(ListLoadMode.infinite),
                ),
                _TogglePill(
                  active: loadMode == ListLoadMode.pages,
                  label: 'Pages',
                  icon: LucideIcons.layers2,
                  onTap: () => onLoadModeChange(ListLoadMode.pages),
                ),
              ],
            ),
            _PageSizeField(value: pageSize, onChanged: onPageSizeChange),
          ],
        ),
        if ((layout == ListLayout.grid &&
                sortOptions != null &&
                onGridSortValueChange != null &&
                gridSortValue != null) ||
            filters != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              if (layout == ListLayout.grid &&
                  sortOptions != null &&
                  onGridSortValueChange != null &&
                  gridSortValue != null)
                AdminFilterSelect(
                  width: 200,
                  value: gridSortValue!,
                  onChanged: onGridSortValueChange!,
                  options: sortOptions!,
                ),
              if (filters != null) filters!,
            ],
          ),
        ],
      ],
    );
  }
}

class _ToggleGroup extends StatelessWidget {
  const _ToggleGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.55),
        ),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  const _TogglePill({
    required this.active,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final bool active;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: active ? scheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: active ? scheme.onPrimary : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageSizeField extends StatelessWidget {
  const _PageSizeField({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.55),
        ),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Per page',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 52,
              child: TextFormField(
                initialValue: '$value',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  border: InputBorder.none,
                ),
                onFieldSubmitted: (v) {
                  final parsed = int.tryParse(v) ?? value;
                  onChanged(parsed);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Footer with range label, load-more, and numbered pages — mirrors web.
class AdminListPaginationFooter extends StatelessWidget {
  const AdminListPaginationFooter({
    super.key,
    required this.loadMode,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.showingFrom,
    required this.showingTo,
    required this.hasMore,
    required this.onPageChange,
    required this.onLoadMore,
  });

  final ListLoadMode loadMode;
  final int total;
  final int page;
  final int totalPages;
  final int showingFrom;
  final int showingTo;
  final bool hasMore;
  final ValueChanged<int> onPageChange;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();

    return Column(
      children: [
        Text(
          '$showingFrom–$showingTo of $total',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        if (loadMode == ListLoadMode.infinite)
          OutlinedButton(
            onPressed: hasMore ? onLoadMore : null,
            child: const Text('Load more'),
          )
        else
          Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _PageBtn(
                enabled: page > 1,
                onTap: () => onPageChange(page - 1),
                child: const Icon(LucideIcons.chevronLeft, size: 18),
              ),
              for (final n in _pageNumbers(page, totalPages))
                if (n == '…')
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text('…', style: Theme.of(context).textTheme.bodySmall),
                  )
                else
                  _PageBtn(
                    active: n == page,
                    enabled: true,
                    onTap: () => onPageChange(n as int),
                    child: Text('$n'),
                  ),
              _PageBtn(
                enabled: page < totalPages,
                onTap: () => onPageChange(page + 1),
                child: const Icon(LucideIcons.chevronRight, size: 18),
              ),
            ],
          ),
      ],
    );
  }
}

class _PageBtn extends StatelessWidget {
  const _PageBtn({
    required this.onTap,
    required this.child,
    this.enabled = true,
    this.active = false,
  });

  final VoidCallback onTap;
  final Widget child;
  final bool enabled;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: active ? scheme.primary : scheme.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? scheme.primary : Theme.of(context).dividerColor.withValues(alpha: 0.55),
            ),
          ),
          child: DefaultTextStyle(
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
              color: active ? scheme.onPrimary : scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
            child: Opacity(opacity: enabled ? 1 : 0.4, child: child),
          ),
        ),
      ),
    );
  }
}

List<Object> _pageNumbers(int current, int total) {
  if (total <= 7) return [for (var i = 1; i <= total; i++) i];
  final pages = <Object>[1];
  if (current > 3) pages.add('…');
  for (var p = (current - 1).clamp(2, total - 1); p <= (current + 1).clamp(2, total - 1); p++) {
    pages.add(p);
  }
  if (current < total - 2) pages.add('…');
  pages.add(total);
  return pages;
}

/// Bulk selection action bar — mirrors web `BulkSelectionBar`.
class AdminBulkSelectionBar extends StatelessWidget {
  const AdminBulkSelectionBar({
    super.key,
    required this.count,
    required this.onClear,
    this.onDelete,
    this.canDelete = true,
  });

  final int count;
  final VoidCallback onClear;
  final VoidCallback? onDelete;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    if (count < 1) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)),
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Text('$count selected', style: Theme.of(context).textTheme.titleSmall),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onClear,
                  icon: const Icon(LucideIcons.x, size: 16),
                  label: const Text('Clear selection'),
                ),
                if (canDelete && onDelete != null)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: onDelete,
                    icon: const Icon(LucideIcons.trash2, size: 16),
                    label: const Text('Delete'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Responsive entity card grid — mirrors web `EntityGrid`.
/// Mobile uses 2 columns (web `sm:grid-cols-2`); never a full-width single column.
class AdminEntityGrid extends StatelessWidget {
  const AdminEntityGrid({
    super.key,
    required this.children,
    this.minTileHeight = 210,
  });

  final List<Widget> children;
  final double minTileHeight;

  /// Column count aligned with web: sm:2 → xl:3 → 2xl:4.
  /// Mobile admin always gets at least 2 columns.
  static int crossAxisCountFor(double width) {
    if (width >= 1280) return 4;
    if (width >= 960) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = crossAxisCountFor(width);
        const spacing = 12.0;
        final tileWidth = (width - spacing * (columns - 1)) / columns;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: tileWidth / minTileHeight,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// Grid card shell with optional selection slot — mirrors web `EntityGridCard`.
class AdminEntityGridCard extends StatelessWidget {
  const AdminEntityGridCard({
    super.key,
    required this.child,
    this.onTap,
    this.selection,
    this.actions,
    this.selected = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Widget? selection;
  final Widget? actions;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).dividerColor.withValues(alpha: 0.45);

    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.25)
          : Theme.of(context).colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      clipBehavior: Clip.none,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        top: selection != null ? 4 : 0,
                        right: selection != null ? 28 : 0,
                      ),
                      child: child,
                    ),
                    if (selection != null)
                      Positioned(top: 0, right: 0, child: selection!),
                  ],
                ),
              ),
              if (actions != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {},
                    behavior: HitTestBehavior.opaque,
                    child: actions!,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

enum AdminStatTone { neutral, success, warning, danger, info }

enum StatusBadgeVariant { defaultVariant, success, warning, danger, info }

class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.start,
      runSpacing: 12,
      spacing: 12,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 240, maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        action ?? const SizedBox.shrink(),
      ],
    );
  }
}

class AdminStatGrid extends StatelessWidget {
  const AdminStatGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var columns = 1;
        if (constraints.maxWidth >= 1280) {
          columns = 4;
        } else if (constraints.maxWidth >= 760) {
          columns = 2;
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// Collapsible overview stats — collapsed by default on mobile list pages.
class AdminCollapsibleOverview extends StatefulWidget {
  const AdminCollapsibleOverview({
    super.key,
    this.title = 'Overview',
    this.summary,
    required this.child,
    this.initiallyExpanded = false,
  });

  final String title;
  final String? summary;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<AdminCollapsibleOverview> createState() =>
      _AdminCollapsibleOverviewState();
}

class _AdminCollapsibleOverviewState extends State<AdminCollapsibleOverview> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (!_expanded && widget.summary != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.summary!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}

/// Web two-column panels become tabs on narrow screens.
class AdminMobileColumnTabs extends StatelessWidget {
  const AdminMobileColumnTabs({
    super.key,
    required this.tabs,
    required this.children,
    this.tabHeight = 360,
    this.wideBreakpoint = 760,
    this.spacing = 12,
  });

  final List<String> tabs;
  final List<Widget> children;
  final double tabHeight;
  final double wideBreakpoint;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    assert(tabs.length == children.length);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= wideBreakpoint;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(width: spacing),
                Expanded(child: children[i]),
              ],
            ],
          );
        }
        return DefaultTabController(
          length: tabs.length,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TabBar(
                isScrollable: tabs.length > 2,
                tabAlignment: tabs.length > 2 ? TabAlignment.start : TabAlignment.fill,
                tabs: [for (final tab in tabs) Tab(text: tab)],
              ),
              SizedBox(
                height: tabHeight,
                child: TabBarView(children: children),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.hint,
    this.tone = AdminStatTone.neutral,
  });

  final String label;
  final String value;
  final String? hint;
  final IconData icon;
  final AdminStatTone tone;

  @override
  Widget build(BuildContext context) {
    final (bgColor, fgColor) = _toneColors(context, tone);
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: fgColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  Text(
                    label.toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6),
                  ),
                  if (hint != null && hint!.isNotEmpty)
                    Text(
                      hint!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminSearchToolbar extends StatelessWidget {
  const AdminSearchToolbar({
    super.key,
    required this.value,
    required this.onChanged,
    required this.placeholder,
    this.filters,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String placeholder;
  final List<Widget>? filters;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final filterWidgets = filters ?? const <Widget>[];
        if (isWide) {
          return Row(
            children: [
              Expanded(child: _SearchInput(value: value, onChanged: onChanged, placeholder: placeholder)),
              if (filterWidgets.isNotEmpty) ...[
                const SizedBox(width: 8),
                Wrap(spacing: 8, runSpacing: 8, children: filterWidgets),
              ],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SearchInput(value: value, onChanged: onChanged, placeholder: placeholder),
            if (filterWidgets.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: filterWidgets),
            ],
          ],
        );
      },
    );
  }
}

class _SearchInput extends StatelessWidget {
  const _SearchInput({
    required this.value,
    required this.onChanged,
    required this.placeholder,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return ShadInput(
      initialValue: value,
      onChanged: onChanged,
      placeholder: Text(placeholder),
      leading: const Padding(
        padding: EdgeInsets.only(left: 4),
        child: Icon(LucideIcons.search, size: 16),
      ),
    );
  }
}

class AdminFilterOption {
  const AdminFilterOption({required this.value, required this.label});

  final String value;
  final String label;
}

class AdminFilterSelect extends StatelessWidget {
  const AdminFilterSelect({
    super.key,
    required this.value,
    required this.onChanged,
    required this.options,
    this.width,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final List<AdminFilterOption> options;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final dropdown = DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: value,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      items: options
          .map(
            (o) => DropdownMenuItem<String>(
              value: o.value,
              child: Text(o.label, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(growable: false),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
    if (width != null) {
      return SizedBox(width: width, child: dropdown);
    }
    return dropdown;
  }
}

/// Period filter pills matching web analytics dashboard.
class AdminPeriodPillBar extends StatelessWidget {
  const AdminPeriodPillBar({
    super.key,
    required this.periods,
    required this.selected,
    required this.onSelected,
  });

  final List<String> periods;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: periods.map((period) {
        final active = selected == period;
        return Material(
          color: active ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onSelected(period),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                period.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: active ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

/// Compact KPI tile matching web analytics `KpiCard`.
class AdminKpiCard extends StatelessWidget {
  const AdminKpiCard({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chart container matching web `ChartPanel`.
class AdminChartPanel extends StatelessWidget {
  const AdminChartPanel({
    super.key,
    required this.title,
    this.description,
    required this.child,
    this.actions,
    this.minHeight = 220,
  });

  final String title;
  final String? description;
  final Widget child;
  final Widget? actions;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          description!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (actions != null) actions!,
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class AdminTableCard extends StatelessWidget {
  const AdminTableCard({
    super.key,
    required this.child,
    this.empty,
    this.isEmpty = false,
  });

  final Widget child;
  final Widget? empty;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.35)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: isEmpty ? (empty ?? const SizedBox.shrink()) : child,
      ),
    );
  }
}

class AdminTable extends StatefulWidget {
  const AdminTable({super.key, required this.child});

  final Widget child;

  @override
  State<AdminTable> createState() => _AdminTableState();
}

class _AdminTableState extends State<AdminTable> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      trackVisibility: true,
      interactive: true,
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        child: widget.child,
      ),
    );
  }
}

class AdminTableHead extends StatelessWidget {
  const AdminTableHead({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55);
    return ColoredBox(color: color, child: child);
  }
}

class AdminListStack extends StatelessWidget {
  const AdminListStack({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1) const SizedBox(height: 24),
        ],
      ],
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.variant = StatusBadgeVariant.defaultVariant,
  });

  final String label;
  final StatusBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    final (bgColor, fgColor) = _statusColors(context, variant);
    return DecoratedBox(
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
        ),
      ),
    );
  }
}

class AdminListSelectCheckbox extends StatelessWidget {
  const AdminListSelectCheckbox({
    super.key,
    required this.checked,
    required this.onChanged,
    this.indeterminate = false,
    this.semanticLabel = 'Select row',
    this.compact = false,
  });

  final bool checked;
  final VoidCallback onChanged;
  final bool indeterminate;
  final String semanticLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 32.0 : 48.0;
    return Semantics(
      label: semanticLabel,
      checked: checked,
      child: SizedBox(
        width: size,
        height: size,
        child: Checkbox(
          value: indeterminate ? null : checked,
          tristate: indeterminate,
          onChanged: (_) => onChanged(),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
        ),
      ),
    );
  }
}

class InlineRowActionItem {
  const InlineRowActionItem({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.destructive = false,
    this.toneColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool destructive;
  final Color? toneColor;
}

class InlineRowActions extends StatelessWidget {
  const InlineRowActions({
    super.key,
    this.onView,
    this.onEdit,
    this.onToggle,
    this.onRemind,
    this.onDelete,
    this.toggleSuspended = false,
    this.profileLabel = 'Profile',
    this.remindLabel = 'Remind',
  });

  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onToggle;
  final VoidCallback? onRemind;
  final VoidCallback? onDelete;
  final bool toggleSuspended;
  final String profileLabel;
  final String remindLabel;

  List<InlineRowActionItem> get items {
    return [
      if (onView != null)
        InlineRowActionItem(label: 'View', icon: LucideIcons.eye, onPressed: onView!),
      if (onEdit != null)
        InlineRowActionItem(label: 'Edit', icon: LucideIcons.pencil, onPressed: onEdit!),
      if (onToggle != null)
        InlineRowActionItem(
          label: profileLabel,
          icon: LucideIcons.userRound,
          onPressed: onToggle!,
          destructive: toggleSuspended,
        ),
      if (onRemind != null)
        InlineRowActionItem(
          label: remindLabel,
          icon: LucideIcons.bellRing,
          onPressed: onRemind!,
          toneColor: const Color(0xFFF59E0B),
        ),
      if (onDelete != null)
        InlineRowActionItem(
          label: 'Delete',
          icon: LucideIcons.trash2,
          onPressed: onDelete!,
          destructive: true,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final actionItems = items;
    return GestureDetector(
      onLongPress: actionItems.isEmpty ? null : () => showInlineRowActionsMenu(context, actionItems),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 6,
        children: [
          for (final action in actionItems)
            _ActionIconButton(
              icon: action.icon,
              label: action.label,
              onPressed: action.onPressed,
              isDestructive: action.destructive,
              toneColor: action.toneColor,
            ),
        ],
      ),
    );
  }
}

Future<void> showInlineRowActionsMenu(
  BuildContext context,
  List<InlineRowActionItem> entries,
) async {
  if (entries.isEmpty || !context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in entries)
            ListTile(
              leading: Icon(
                entry.icon,
                color: entry.destructive ? Theme.of(context).colorScheme.error : entry.toneColor,
                size: 20,
              ),
              title: Text(
                entry.label,
                style: entry.destructive
                    ? TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w600,
                      )
                    : const TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.pop(context);
                entry.onPressed();
              },
            ),
        ],
      ),
    ),
  );
}

/// Speed-dial FAB menu for grid cards — expands labeled mini-FABs above the trigger.
class InlineRowActionsSpeedDial extends StatefulWidget {
  const InlineRowActionsSpeedDial({
    super.key,
    required this.actions,
    this.semanticLabel = 'Actions',
  });

  final InlineRowActions actions;
  final String semanticLabel;

  @override
  State<InlineRowActionsSpeedDial> createState() => _InlineRowActionsSpeedDialState();
}

class _InlineRowActionsSpeedDialState extends State<InlineRowActionsSpeedDial>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  late final AnimationController _controller;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_open) {
      _close();
    } else {
      _openOverlay();
    }
  }

  void _openOverlay() {
    _overlayEntry = OverlayEntry(builder: (context) => _buildOverlay());
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _open = true);
    _controller.forward(from: 0);
  }

  void _close() {
    if (!_open) return;
    _controller.reverse().whenComplete(() {
      _removeOverlay();
      if (mounted) setState(() => _open = false);
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _runAction(InlineRowActionItem entry) {
    _close();
    entry.onPressed();
  }

  Widget _buildOverlay() {
    final entries = widget.actions.items;
    final scheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _close,
            behavior: HitTestBehavior.translucent,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Container(
                color: Colors.black.withValues(alpha: 0.08 * _controller.value),
              ),
            ),
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          targetAnchor: Alignment.topRight,
          followerAnchor: Alignment.bottomRight,
          offset: const Offset(0, -6),
          showWhenUnlinked: false,
          child: Material(
            color: Colors.transparent,
            elevation: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < entries.length; i++)
                  _SpeedDialActionRow(
                    entry: entries[i],
                    animation: CurvedAnimation(
                      parent: _controller,
                      curve: Interval(0.08 * i, 0.55 + (0.12 * i), curve: Curves.easeOutBack),
                    ),
                    onTap: () => _runAction(entries[i]),
                  ),
              ],
            ),
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          targetAnchor: Alignment.center,
          followerAnchor: Alignment.center,
          showWhenUnlinked: false,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.35 * _controller.value),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const SizedBox(width: 32, height: 32),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.actions.items;
    if (entries.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return CompositedTransformTarget(
      link: _layerLink,
      child: Semantics(
        button: true,
        label: widget.semanticLabel,
        child: Material(
          color: scheme.primary,
          elevation: _open ? 6 : 2,
          shadowColor: scheme.primary.withValues(alpha: 0.35),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _toggle,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 32,
              height: 32,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) => RotationTransition(
                  turns: Tween<double>(begin: 0.75, end: 1).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(
                  _open ? LucideIcons.x : LucideIcons.ellipsisVertical,
                  key: ValueKey(_open),
                  size: 16,
                  color: scheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeedDialActionRow extends StatelessWidget {
  const _SpeedDialActionRow({
    required this.entry,
    required this.animation,
    required this.onTap,
  });

  final InlineRowActionItem entry;
  final Animation<double> animation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fabColor = entry.destructive
        ? scheme.error
        : entry.toneColor ?? scheme.secondaryContainer;
    final iconColor = entry.destructive
        ? scheme.onError
        : entry.toneColor != null
            ? Colors.white
            : scheme.onSecondaryContainer;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(animation),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Text(
                    entry.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: fabColor,
                elevation: 4,
                shadowColor: fabColor.withValues(alpha: 0.45),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(entry.icon, size: 18, color: iconColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// @deprecated Use [InlineRowActionsSpeedDial] for grid cards.
typedef InlineRowActionsMenuButton = InlineRowActionsSpeedDial;

/// Table/grid row shell with selection highlight and long-press actions menu.
class AdminListRowShell extends StatelessWidget {
  const AdminListRowShell({
    super.key,
    required this.selected,
    required this.onToggleSelected,
    required this.actions,
    required this.child,
  });

  final bool selected;
  final VoidCallback onToggleSelected;
  final InlineRowActions actions;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.28)
          : null,
      child: InkWell(
        onTap: onToggleSelected,
        onLongPress: actions.items.isEmpty
            ? null
            : () => showInlineRowActionsMenu(context, actions.items),
        child: child,
      ),
    );
  }
}

enum SortDirection { asc, desc }

class SortModel {
  const SortModel({required this.key, required this.dir});

  final String key;
  final SortDirection dir;
}

class SortableTableHeader extends StatelessWidget {
  const SortableTableHeader({
    super.key,
    required this.label,
    required this.sortKey,
    required this.activeSort,
    required this.onSort,
    this.alignment = Alignment.centerLeft,
  });

  final String label;
  final String sortKey;
  final SortModel? activeSort;
  final ValueChanged<String> onSort;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final isActive = activeSort?.key == sortKey;
    final icon = !isActive
        ? LucideIcons.arrowUpDown
        : activeSort?.dir == SortDirection.asc
            ? LucideIcons.arrowUp
            : LucideIcons.arrowDown;

    return Align(
      alignment: alignment,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onSort(sortKey),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              Icon(icon, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
    this.toneColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;
  final Color? toneColor;

  @override
  Widget build(BuildContext context) {
    final baseColor = toneColor ?? (isDestructive ? Theme.of(context).colorScheme.error : null);
    final fg = baseColor ?? Theme.of(context).iconTheme.color;
    return Tooltip(
      message: label,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(36, 36),
          maximumSize: const Size(36, 36),
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          side: BorderSide(color: (baseColor ?? Theme.of(context).dividerColor).withValues(alpha: 0.35)),
        ),
        child: Icon(icon, size: 16, color: fg),
      ),
    );
  }
}

(Color, Color) _toneColors(BuildContext context, AdminStatTone tone) {
  final scheme = Theme.of(context).colorScheme;
  return switch (tone) {
    AdminStatTone.neutral => (scheme.surfaceContainerHighest.withValues(alpha: 0.8), scheme.onSurfaceVariant),
    AdminStatTone.success => (scheme.primary.withValues(alpha: 0.16), scheme.primary),
    AdminStatTone.warning => (const Color(0xFFF59E0B).withValues(alpha: 0.16), const Color(0xFFB45309)),
    AdminStatTone.danger => (scheme.error.withValues(alpha: 0.14), scheme.error),
    AdminStatTone.info => (const Color(0xFF0EA5E9).withValues(alpha: 0.14), const Color(0xFF0369A1)),
  };
}

(Color, Color) _statusColors(BuildContext context, StatusBadgeVariant variant) {
  final scheme = Theme.of(context).colorScheme;
  return switch (variant) {
    StatusBadgeVariant.defaultVariant =>
      (scheme.surfaceContainerHighest.withValues(alpha: 0.75), scheme.onSurfaceVariant),
    StatusBadgeVariant.success => (scheme.primary.withValues(alpha: 0.16), scheme.primary),
    StatusBadgeVariant.warning => (const Color(0xFFF59E0B).withValues(alpha: 0.16), const Color(0xFF92400E)),
    StatusBadgeVariant.danger => (scheme.error.withValues(alpha: 0.16), scheme.error),
    StatusBadgeVariant.info => (const Color(0xFF0EA5E9).withValues(alpha: 0.14), const Color(0xFF075985)),
  };
}

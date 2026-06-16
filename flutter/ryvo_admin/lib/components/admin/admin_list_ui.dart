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
    return SizedBox(
      width: width ?? 170,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
        items: options
            .map((o) => DropdownMenuItem<String>(value: o.value, child: Text(o.label, overflow: TextOverflow.ellipsis)))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
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

class AdminTable extends StatelessWidget {
  const AdminTable({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: child);
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

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 6,
      children: [
        if (onView != null) _ActionIconButton(icon: LucideIcons.eye, label: 'View', onPressed: onView!),
        if (onEdit != null) _ActionIconButton(icon: LucideIcons.pencil, label: 'Edit', onPressed: onEdit!),
        if (onToggle != null)
          _ActionIconButton(
            icon: LucideIcons.userRound,
            label: profileLabel,
            onPressed: onToggle!,
            isDestructive: toggleSuspended,
          ),
        if (onRemind != null)
          _ActionIconButton(
            icon: LucideIcons.bellRing,
            label: remindLabel,
            onPressed: onRemind!,
            toneColor: const Color(0xFFF59E0B),
          ),
        if (onDelete != null)
          _ActionIconButton(
            icon: LucideIcons.trash2,
            label: 'Delete',
            onPressed: onDelete!,
            isDestructive: true,
          ),
      ],
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

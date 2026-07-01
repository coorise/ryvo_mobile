import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ryvo_admin/configs/app_permissions.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/i18n/app_i18n.dart';
import 'package:ryvo_admin/services/permission_service.dart';

class PermissionsPrompt {
  PermissionsPrompt._();

  static var _shownThisSession = false;

  static Future<void> maybeShow(BuildContext context) async {
    if (_shownThisSession) return;

    final specs = permissionsForAdmin();
    if (specs.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final dismissedVersion = prefs.getInt(AppConst.storagePermissionsDismissedVersion) ?? 0;
    final statuses = await PermissionService.statusesFor(specs);
    final pending = specs.where((spec) => PermissionService.needsPrompt(statuses[spec.id]!));

    if (pending.isEmpty) {
      await prefs.setInt(AppConst.storagePermissionsDismissedVersion, appPermissionsVersion);
      return;
    }

    if (dismissedVersion >= appPermissionsVersion && !_hasNewDenials(statuses)) return;
    if (!context.mounted) return;

    _shownThisSession = true;
    await _showDialog(context, specs, statuses, prefs);
  }

  static bool _hasNewDenials(Map<String, PermissionStatus> statuses) {
    return statuses.values.any(
      (status) =>
          status == PermissionStatus.denied || status == PermissionStatus.permanentlyDenied,
    );
  }

  static Future<void> _showDialog(
    BuildContext context,
    List<AppPermissionSpec> specs,
    Map<String, PermissionStatus> statuses,
    SharedPreferences prefs,
  ) async {
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogContext) => _PermissionsDialog(
        specs: specs,
        initialStatuses: statuses,
        onContinue: () async {
          await prefs.setInt(AppConst.storagePermissionsDismissedVersion, appPermissionsVersion);
          if (dialogContext.mounted) Navigator.pop(dialogContext);
        },
      ),
    );
  }
}

class _PermissionsDialog extends StatefulWidget {
  const _PermissionsDialog({
    required this.specs,
    required this.initialStatuses,
    required this.onContinue,
  });

  final List<AppPermissionSpec> specs;
  final Map<String, PermissionStatus> initialStatuses;
  final Future<void> Function() onContinue;

  @override
  State<_PermissionsDialog> createState() => _PermissionsDialogState();
}

class _PermissionsDialogState extends State<_PermissionsDialog> {
  late Map<String, PermissionStatus> _statuses;
  String? _requestingId;

  @override
  void initState() {
    super.initState();
    _statuses = Map<String, PermissionStatus>.from(widget.initialStatuses);
  }

  String _tr(String key) => AppI18n.instance.tr(key);

  bool get _allGranted => widget.specs.every(
        (spec) => PermissionService.isGranted(_statuses[spec.id]!),
      );

  Future<void> _requestOne(AppPermissionSpec spec) async {
    setState(() => _requestingId = spec.id);
    final status = await PermissionService.request(spec);
    if (!mounted) return;
    setState(() {
      _statuses[spec.id] = status;
      _requestingId = null;
    });
  }

  Future<void> _requestAll() async {
    for (final spec in widget.specs) {
      final current = _statuses[spec.id]!;
      if (!PermissionService.needsPrompt(current)) continue;
      await _requestOne(spec);
      if (!mounted) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(_tr('permissions.title')),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _tr('permissions.adminSubtitle'),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ...widget.specs.map((spec) => _PermissionRow(
                    spec: spec,
                    status: _statuses[spec.id]!,
                    requesting: _requestingId == spec.id,
                    onRequest: () => _requestOne(spec),
                    onOpenSettings: PermissionService.openSettings,
                  )),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _requestingId == null ? () => widget.onContinue() : null,
          child: Text(_tr('permissions.continueAnyway')),
        ),
        if (!_allGranted)
          FilledButton(
            onPressed: _requestingId == null ? _requestAll : null,
            child: Text(_tr('permissions.enableAll')),
          )
        else
          FilledButton(
            onPressed: _requestingId == null ? () => widget.onContinue() : null,
            child: Text(_tr('permissions.done')),
          ),
      ],
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.spec,
    required this.status,
    required this.requesting,
    required this.onRequest,
    required this.onOpenSettings,
  });

  final AppPermissionSpec spec;
  final PermissionStatus status;
  final bool requesting;
  final VoidCallback onRequest;
  final Future<void> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = AppI18n.instance.tr(spec.titleKey);
    final description = AppI18n.instance.tr(spec.descriptionKey);
    final statusLabel = _statusLabel(status);
    final statusColor = _statusColor(theme, status);
    final granted = PermissionService.isGranted(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_iconFor(spec.id), size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(description, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusLabel,
                      style: theme.textTheme.labelSmall?.copyWith(color: statusColor),
                    ),
                  ),
                  const Spacer(),
                  if (status == PermissionStatus.permanentlyDenied)
                    TextButton(
                      onPressed: onOpenSettings,
                      child: Text(AppI18n.instance.tr('permissions.openSettings')),
                    )
                  else if (!granted)
                    FilledButton.tonal(
                      onPressed: requesting ? null : onRequest,
                      child: requesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(AppI18n.instance.tr('permissions.enable')),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String id) {
    return switch (id) {
      'location' => LucideIcons.mapPin,
      'camera' => LucideIcons.camera,
      'photos' => LucideIcons.image,
      'notifications' => LucideIcons.bell,
      'install' => LucideIcons.download,
      'sms' => LucideIcons.messageSquare,
      _ => LucideIcons.shield,
    };
  }

  String _statusLabel(PermissionStatus status) {
    final key = switch (status) {
      PermissionStatus.granted => 'permissions.status.granted',
      PermissionStatus.limited => 'permissions.status.limited',
      PermissionStatus.denied => 'permissions.status.denied',
      PermissionStatus.permanentlyDenied => 'permissions.status.blocked',
      PermissionStatus.restricted => 'permissions.status.restricted',
      _ => 'permissions.status.unknown',
    };
    return AppI18n.instance.tr(key);
  }

  Color _statusColor(ThemeData theme, PermissionStatus status) {
    return switch (status) {
      PermissionStatus.granted => Colors.green.shade700,
      PermissionStatus.limited => Colors.orange.shade800,
      PermissionStatus.denied => Colors.red.shade700,
      PermissionStatus.permanentlyDenied => theme.colorScheme.error,
      _ => theme.colorScheme.outline,
    };
  }
}

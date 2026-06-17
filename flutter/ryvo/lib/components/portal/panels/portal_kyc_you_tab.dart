import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ryvo/components/portal/panels/portal_panel_utils.dart';
import 'package:ryvo/components/portal/portal_list_ui.dart';
import 'package:ryvo/configs/kyc_const.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';
import 'package:ryvo/lib/storage_keys.dart';
import 'package:ryvo/services/index.dart';

class PortalKycYouTab extends ConsumerStatefulWidget {
  const PortalKycYouTab({super.key});

  @override
  ConsumerState<PortalKycYouTab> createState() => _PortalKycYouTabState();
}

class _PortalKycYouTabState extends ConsumerState<PortalKycYouTab> {
  bool _loading = true;
  bool _uploading = false;
  String? _error;
  String _kycStatus = kycStatusPending;
  Map<String, dynamic> _documents = const {};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = useAuth(ref);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await kycService.getChecklist(auth.accessToken);
      if (!mounted) return;
      final docsRaw = res['documents'];
      setState(() {
        _kycStatus = portalStr(res['kyc_status'], kycStatusPending);
        _documents = docsRaw is Map ? Map<String, dynamic>.from(docsRaw) : const {};
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = T.portal('portal.kyc.unavailable');
        _loading = false;
      });
    }
  }

  Map<String, dynamic> _docForType(String docType) {
    final doc = _documents[docType];
    if (doc is Map) return Map<String, dynamic>.from(doc);
    return {
      'doc_type': docType,
      's3_key': '',
      'status': kycStatusMissing,
      'rejection_reason': null,
    };
  }

  StatusBadgeVariant _statusVariant(String status) {
    switch (status) {
      case kycStatusApproved:
        return StatusBadgeVariant.success;
      case kycStatusRejected:
        return StatusBadgeVariant.danger;
      case kycStatusPending:
        return StatusBadgeVariant.warning;
      default:
        return StatusBadgeVariant.defaultVariant;
    }
  }

  String _statusLabel(String status) {
    if (status == kycStatusMissing) return T.portal('portal.kyc.docMissing');
    return status;
  }

  String _docLabel(String docType) {
    final key = kycDocLabelKeys[docType];
    if (key != null) return T.nav(key);
    return docType;
  }

  Future<void> _pickAndUpload(String docType) async {
    final auth = useAuth(ref);
    final userId = auth.user?.id;
    if (userId == null || userId.isEmpty) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      withData: true,
    );
    final file = result?.files.first;
    if (file == null || file.bytes == null) return;

    setState(() => _uploading = true);
    try {
      final ext = file.extension ?? 'bin';
      final path = 'drivers/$userId/kyc/$docType/${DateTime.now().millisecondsSinceEpoch}.$ext';
      final s3Key = await storageService.uploadFile(
        auth.accessToken,
        file.bytes!,
        path,
        file.name,
      );
      await kycService.submitDocument(auth.accessToken, docType, s3Key);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(T.portal('portal.kyc.uploaded'))),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _openDocument(String docType) async {
    final auth = useAuth(ref);
    final doc = _docForType(docType);
    if (portalStr(doc['status']) == kycStatusMissing || !isRealStorageKey(portalStr(doc['s3_key']))) {
      return;
    }

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _DocumentViewDialog(
        title: _docLabel(docType),
        load: () => kycService.getDocumentViewUrl(auth.accessToken, docType),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return portalLoading();
    if (_error != null) return portalError(_error!);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        T.portal('portal.kyc.statusLabel'),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(T.portal('portal.kyc.subtitle'), style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                StatusBadge(label: _kycStatus.toUpperCase(), variant: _statusVariant(_kycStatus)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  T.nav('drivers.documents'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(T.portal('portal.kyc.uploadHint'), style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                for (final docType in personalKycDocTypes) ...[
                  _documentRow(docType),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _documentRow(String docType) {
    final doc = _docForType(docType);
    final status = portalStr(doc['status'], kycStatusMissing);
    final canView = status != kycStatusMissing && isRealStorageKey(portalStr(doc['s3_key']));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_docLabel(docType), style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          StatusBadge(label: _statusLabel(status).toUpperCase(), variant: _statusVariant(status)),
          if (portalStr(doc['rejection_reason']).isNotEmpty && status == kycStatusRejected) ...[
            const SizedBox(height: 6),
            Text(
              portalStr(doc['rejection_reason']),
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ShadButton.outline(
                size: ShadButtonSize.sm,
                onPressed: canView ? () => _openDocument(docType) : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.eye, size: 14),
                    const SizedBox(width: 6),
                    Text(T.nav('drivers.viewDocument')),
                  ],
                ),
              ),
              ShadButton(
                size: ShadButtonSize.sm,
                onPressed: _uploading ? null : () => _pickAndUpload(docType),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.upload, size: 14),
                    const SizedBox(width: 6),
                    Text(T.portal('portal.kyc.update')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentViewDialog extends StatefulWidget {
  const _DocumentViewDialog({required this.title, required this.load});

  final String title;
  final Future<Map<String, dynamic>> Function() load;

  @override
  State<_DocumentViewDialog> createState() => _DocumentViewDialogState();
}

class _DocumentViewDialogState extends State<_DocumentViewDialog> {
  late Future<Map<String, dynamic>> _future = widget.load();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) return portalLoading();
            if (snapshot.hasError || snapshot.data == null) {
              return Text(T.nav('drivers.viewDocumentError'));
            }
            final url = portalStr(snapshot.data!['url']);
            final mime = portalStr(snapshot.data!['mime_type']);
            if (mime.startsWith('image/') && url.isNotEmpty) {
              return Image.network(url, fit: BoxFit.contain);
            }
            if (mime.contains('pdf') && url.isNotEmpty) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(T.nav('drivers.viewDocumentHint')),
                  const SizedBox(height: 12),
                  ShadButton(
                    onPressed: () {
                      final uri = Uri.tryParse(url);
                      if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: Text(T.portal('portal.kyc.viewDocument')),
                  ),
                ],
              );
            }
            return portalEmpty(T.nav('common.noData'));
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(T.nav('common.cancel'))),
      ],
    );
  }
}

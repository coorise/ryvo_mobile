import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ryvo/components/portal/panels/portal_panel_utils.dart';
import 'package:ryvo/components/portal/portal_list_ui.dart';
import 'package:ryvo/configs/kyc_const.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';
import 'package:ryvo/lib/storage_keys.dart';
import 'package:ryvo/lib/vehicle_profile.dart';
import 'package:ryvo/services/index.dart';

class PortalVehicleForm extends ConsumerStatefulWidget {
  const PortalVehicleForm({super.key, required this.mode, this.vehicleId});

  final String mode;
  final String? vehicleId;

  @override
  ConsumerState<PortalVehicleForm> createState() => _PortalVehicleFormState();
}

class _PortalVehicleFormState extends ConsumerState<PortalVehicleForm> {
  VehicleFormState _form = VehicleFormState();
  Map<String, dynamic>? _vehicle;
  String? _savedId;
  bool _loading = true;
  bool _busy = false;
  bool _formLoaded = false;
  final _otherLabelController = TextEditingController();

  String? get _effectiveId => widget.vehicleId ?? _savedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _otherLabelController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final id = _effectiveId;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    final auth = useAuth(ref);
    setState(() => _loading = true);
    try {
      final res = await vehiclesService.getVehicle(auth.accessToken, id);
      if (!mounted) return;
      final vehicle = res['vehicle'];
      if (vehicle is Map) {
        setState(() {
          _vehicle = Map<String, dynamic>.from(vehicle);
          if (!_formLoaded) {
            _form = vehicleToForm(_vehicle!);
            _formLoaded = true;
          }
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  VehicleProfileChecklist get _checklist => buildVehicleChecklist(_form, _vehicle);

  Future<Map<String, dynamic>> _persistVehicle() async {
    validateProfileForm(_form, T.portal);
    final auth = useAuth(ref);
    final body = formToBody(_form);
    if (_effectiveId != null) {
      final res = await vehiclesService.update(auth.accessToken, _effectiveId!, body);
      final vehicle = res['vehicle'];
      if (vehicle is Map) _vehicle = Map<String, dynamic>.from(vehicle);
      return _vehicle ?? body;
    }
    final res = await vehiclesService.create(auth.accessToken, body);
    final vehicle = res['vehicle'];
    if (vehicle is! Map) throw Exception(T.portal('portal.kyc.unavailable'));
    final id = portalStr(vehicle['id']);
    setState(() {
      _savedId = id;
      _vehicle = Map<String, dynamic>.from(vehicle);
      _formLoaded = true;
    });
    if (mounted) context.go('/driver/main/kyc/cars/$id/edit');
    return _vehicle!;
  }

  Future<void> _withVehicle(Future<void> Function(Map<String, dynamic> vehicle, String id) run) async {
    setState(() => _busy = true);
    try {
      final vehicle = await _persistVehicle();
      final id = portalStr(vehicle['id'], _effectiveId ?? '');
      if (id.isEmpty) throw Exception(T.portal('portal.kyc.unavailable'));
      await run(vehicle, id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(T.portal('portal.kyc.uploaded'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickSingleFile({
    required List<String> extensions,
    required Future<void> Function(PlatformFile file) onPicked,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      withData: true,
    );
    final file = result?.files.first;
    if (file == null || file.bytes == null) return;
    await onPicked(file);
  }

  Future<void> _pickMultipleImages(Future<void> Function(List<PlatformFile> files) onPicked) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
      withData: true,
    );
    final files = result?.files.where((f) => f.bytes != null).toList(growable: false) ?? const [];
    if (files.isEmpty) return;
    await onPicked(files);
  }

  Future<void> _save({required bool strict}) async {
    setState(() => _busy = true);
    try {
      final vehicle = await _persistVehicle();
      if (strict) {
        final checklist = buildVehicleChecklist(_form, vehicle);
        if (!checklist.readyForReview) {
          throw Exception(T.portal('portal.kyc.profileIncomplete'));
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(T.portal('portal.kyc.carSaved'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<Map<String, dynamic>> get _documents {
    final docs = _vehicle?['documents'];
    if (docs is! List) return const [];
    return docs.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(growable: false);
  }

  Map<String, dynamic>? _docForType(String docType) {
    for (final doc in _documents) {
      if (portalStr(doc['doc_type']) == docType && isRealStorageKey(portalStr(doc['s3_key']))) {
        return doc;
      }
    }
    return null;
  }

  List<Map<String, dynamic>> get _otherDocs =>
      _documents.where((d) => portalStr(d['doc_type']) == 'other').toList(growable: false);

  List<String> get _galleryKeys {
    final keys = _vehicle?['image_keys'];
    if (keys is! List) return const [];
    return keys.map((k) => k.toString()).where(isRealStorageKey).toList(growable: false);
  }

  Future<void> _viewMedia(String key) async {
    final auth = useAuth(ref);
    final id = _effectiveId;
    if (id == null) return;
    final res = await vehiclesService.getMediaViewUrl(auth.accessToken, id, key);
    final url = portalStr(res['url']);
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _viewDoc(String docId) async {
    final auth = useAuth(ref);
    final id = _effectiveId;
    if (id == null) return;
    final res = await vehiclesService.getDocumentViewUrl(auth.accessToken, id, docId);
    final url = portalStr(res['url']);
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _checkItem(bool done, String label) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, size: 18, color: done ? Colors.green : null),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
      ],
    );
  }

  Widget _field(String label, String value, ValueChanged<String> onChanged, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label *', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          keyboardType: keyboardType,
          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return portalLoading();
    if (widget.mode == 'edit' && _effectiveId != null && !_formLoaded) return portalLoading();
    final checklist = _checklist;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(T.portal('portal.kyc.profileChecklist'), style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 10),
                _checkItem(checklist.profileComplete, T.portal('portal.kyc.checkProfileFields')),
                _checkItem(checklist.hasBanner, T.portal('portal.kyc.banner')),
                _checkItem(
                  checklist.galleryCount >= minGalleryImages,
                  T.portal('portal.kyc.checkGallery', {'count': '$minGalleryImages'}),
                ),
                _checkItem(checklist.hasRegistration, T.portal('portal.kyc.registration')),
                _checkItem(checklist.hasInsurance, T.portal('portal.kyc.insurance')),
                _checkItem(isRealStorageKey(_vehicle?['video_key']?.toString()), T.portal('portal.kyc.videoOptional')),
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
                Text(T.portal('portal.kyc.carProfileSection'), style: Theme.of(context).textTheme.titleMedium),
                Text(T.portal('portal.kyc.carProfileHint'), style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                _field(T.portal('portal.kyc.fields.brand'), _form.brand, (v) => setState(() {
                  _form = _form.copyWith(brand: v, make: v);
                })),
                const SizedBox(height: 10),
                _field(T.portal('portal.kyc.fields.name'), _form.name, (v) => setState(() {
                  _form = _form.copyWith(name: v, model: v);
                })),
                const SizedBox(height: 10),
                _field(T.portal('portal.kyc.fields.plate'), _form.plate, (v) => setState(() => _form = _form.copyWith(plate: v))),
                const SizedBox(height: 10),
                _field(
                  T.portal('portal.kyc.fields.speed'),
                  _form.maxSpeedKmh,
                  (v) => setState(() => _form = _form.copyWith(maxSpeedKmh: v)),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                _field(
                  T.portal('portal.kyc.fields.age'),
                  _form.ageYears,
                  (v) => setState(() => _form = _form.copyWith(ageYears: v)),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                _field(
                  T.portal('portal.kyc.fields.carbon'),
                  _form.carbonPrint,
                  (v) => setState(() => _form = _form.copyWith(carbonPrint: v)),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 10),
                Text('${T.portal('portal.kyc.fields.tyres')} *', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _form.tyresType.isEmpty ? null : _form.tyresType,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  hint: Text(T.portal('portal.kyc.selectTyres')),
                  items: tyresTypes
                      .map(
                        (tyre) => DropdownMenuItem(
                          value: tyre,
                          child: Text(T.portal('portal.kyc.tyres.$tyre')),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _form = _form.copyWith(tyresType: value));
                  },
                ),
                const SizedBox(height: 10),
                Text('${T.portal('portal.kyc.fields.energy')} *', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _form.energyType,
                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  items: energyTypes
                      .map(
                        (energy) => DropdownMenuItem(
                          value: energy,
                          child: Text(T.portal('portal.kyc.energy.$energy')),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _form = _form.copyWith(energyType: value));
                  },
                ),
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
                Text(T.portal('portal.kyc.mediaSection'), style: Theme.of(context).textTheme.titleSmall),
                Text(T.portal('portal.kyc.mediaHint'), style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                Text('${T.portal('portal.kyc.banner')} *'),
                const SizedBox(height: 6),
                ShadButton.outline(
                  onPressed: _busy
                      ? null
                      : () => _pickSingleFile(
                            extensions: const ['jpg', 'jpeg', 'png', 'webp'],
                            onPicked: (file) => _withVehicle((_, id) async {
                              final auth = useAuth(ref);
                              final userId = auth.user?.id ?? '';
                              final path = 'drivers/$userId/vehicles/$id/banner/${DateTime.now().millisecondsSinceEpoch}.jpg';
                              final key = await storageService.uploadFile(auth.accessToken, file.bytes!, path, file.name);
                              await vehiclesService.update(auth.accessToken, id, {'banner_key': key});
                            }),
                          ),
                  child: Text(T.portal('portal.kyc.uploadBanner')),
                ),
                if (isRealStorageKey(_vehicle?['banner_key']?.toString()))
                  TextButton(
                    onPressed: () => _viewMedia(portalStr(_vehicle?['banner_key'])),
                    child: Text(T.portal('portal.kyc.viewBanner')),
                  ),
                const SizedBox(height: 12),
                Text('${T.portal('portal.kyc.galleryImages')} * (${_galleryKeys.length}/$minGalleryImages+)'),
                const SizedBox(height: 6),
                ShadButton.outline(
                  onPressed: _busy
                      ? null
                      : () => _pickMultipleImages((files) => _withVehicle((vehicle, id) async {
                            final auth = useAuth(ref);
                            final userId = auth.user?.id ?? '';
                            final keys = [..._galleryKeys];
                            for (final file in files) {
                              final path =
                                  'drivers/$userId/vehicles/$id/gallery/${DateTime.now().millisecondsSinceEpoch}-${file.name}';
                              keys.add(await storageService.uploadFile(auth.accessToken, file.bytes!, path, file.name));
                            }
                            await vehiclesService.update(auth.accessToken, id, {'image_keys': keys});
                          })),
                  child: Text(T.portal('portal.kyc.addGalleryImages')),
                ),
                const SizedBox(height: 12),
                Text(T.portal('portal.kyc.videoOptional')),
                const SizedBox(height: 6),
                ShadButton.outline(
                  onPressed: _busy
                      ? null
                      : () => _pickSingleFile(
                            extensions: const ['mp4', 'webm'],
                            onPicked: (file) async {
                              if ((file.bytes?.length ?? 0) > maxVideoBytes) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(T.portal('portal.kyc.videoTooLarge'))),
                                );
                                return;
                              }
                              await _withVehicle((_, id) async {
                                final auth = useAuth(ref);
                                final userId = auth.user?.id ?? '';
                                final path = 'drivers/$userId/vehicles/$id/video/${DateTime.now().millisecondsSinceEpoch}.mp4';
                                final key = await storageService.uploadFile(auth.accessToken, file.bytes!, path, file.name);
                                await vehiclesService.update(auth.accessToken, id, {'video_key': key});
                              });
                            },
                          ),
                  child: Text(T.portal('portal.kyc.uploadVideo')),
                ),
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
                Text(T.portal('portal.kyc.documentsSection'), style: Theme.of(context).textTheme.titleSmall),
                Text(T.portal('portal.kyc.documentsHint'), style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                _vehicleDocRow('registration', T.portal('portal.kyc.registration')),
                const SizedBox(height: 10),
                _vehicleDocRow('insurance', T.portal('portal.kyc.insurance')),
                const SizedBox(height: 12),
                Text(T.portal('portal.kyc.otherDocsTitle'), style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                ShadInput(
                  controller: _otherLabelController,
                  placeholder: Text(T.portal('portal.kyc.otherDocPlaceholder')),
                ),
                const SizedBox(height: 8),
                ShadButton.outline(
                  onPressed: _busy
                      ? null
                      : () => _pickSingleFile(
                            extensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
                            onPicked: (file) => _withVehicle((_, id) async {
                              final auth = useAuth(ref);
                              final userId = auth.user?.id ?? '';
                              final label = _otherLabelController.text.trim();
                              final path =
                                  'drivers/$userId/vehicles/$id/other/${DateTime.now().millisecondsSinceEpoch}.${file.extension ?? 'bin'}';
                              final key = await storageService.uploadFile(auth.accessToken, file.bytes!, path, file.name);
                              await vehiclesService.submitDocument(
                                auth.accessToken,
                                id,
                                docType: 'other',
                                s3Key: key,
                                label: label.isEmpty ? T.portal('portal.kyc.otherDocDefault') : label,
                              );
                              _otherLabelController.clear();
                            }),
                          ),
                  child: Text(T.portal('portal.kyc.addOtherDoc')),
                ),
                if (_otherDocs.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ..._otherDocs.map(
                    (doc) => ListTile(
                      dense: true,
                      title: Text(portalStr(doc['label'], T.portal('portal.kyc.otherDocDefault'))),
                      subtitle: Text(portalStr(doc['status'], kycStatusPending)),
                      trailing: IconButton(
                        icon: const Icon(LucideIcons.eye, size: 16),
                        onPressed: () => _viewDoc(portalStr(doc['id'])),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ShadButton.outline(
              onPressed: _busy ? null : () => _save(strict: false),
              child: Text(T.portal('portal.kyc.saveProfile')),
            ),
            ShadButton(
              onPressed: _busy || !checklist.readyForReview ? null : () => _save(strict: true),
              child: Text(T.portal('portal.kyc.submitForReview')),
            ),
            ShadButton.ghost(
              onPressed: () => context.go('/driver/main/kyc?tab=cars'),
              child: Text(T.portal('portal.kyc.backToCars')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _vehicleDocRow(String docType, String label) {
    final doc = _docForType(docType);
    final status = doc == null ? kycStatusMissing : portalStr(doc['status'], kycStatusPending);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              StatusBadge(
                label: (status == kycStatusMissing ? T.portal('portal.kyc.docMissing') : status).toUpperCase(),
                variant: status == kycStatusApproved
                    ? StatusBadgeVariant.success
                    : status == kycStatusRejected
                        ? StatusBadgeVariant.danger
                        : StatusBadgeVariant.warning,
              ),
            ],
          ),
        ),
        ShadButton.outline(
          size: ShadButtonSize.sm,
          onPressed: _busy
              ? null
              : () => _pickSingleFile(
                    extensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
                    onPicked: (file) => _withVehicle((_, id) async {
                      final auth = useAuth(ref);
                      final userId = auth.user?.id ?? '';
                      final path =
                          'drivers/$userId/vehicles/$id/$docType/${DateTime.now().millisecondsSinceEpoch}.${file.extension ?? 'bin'}';
                      final key = await storageService.uploadFile(auth.accessToken, file.bytes!, path, file.name);
                      await vehiclesService.submitDocument(
                        auth.accessToken,
                        id,
                        docType: docType,
                        s3Key: key,
                      );
                    }),
                  ),
          child: Text(T.portal('portal.kyc.update')),
        ),
        if (doc != null) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(LucideIcons.eye, size: 16),
            onPressed: () => _viewDoc(portalStr(doc['id'])),
          ),
        ],
      ],
    );
  }
}

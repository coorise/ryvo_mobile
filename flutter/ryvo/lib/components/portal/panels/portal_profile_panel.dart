import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo/components/portal/panels/portal_panel_utils.dart';
import 'package:ryvo/components/portal/portal_list_ui.dart';
import 'package:ryvo/configs/portal_nav.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';
import 'package:ryvo/services/index.dart';

class PortalProfilePanel extends ConsumerStatefulWidget {
  const PortalProfilePanel({super.key, required this.area});

  final PortalArea area;

  @override
  ConsumerState<PortalProfilePanel> createState() => _PortalProfilePanelState();
}

class _PortalProfilePanelState extends ConsumerState<PortalProfilePanel> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Map<String, dynamic>> _vehicles = const [];
  String _activeVehicleId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = useAuth(ref);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await settingsService.getMyProfile(auth.accessToken);
      final data = profile['profile'];
      if (data is Map) {
        _nameController.text = portalStr(data['full_name'], '');
        _phoneController.text = portalStr(data['phone'], '');
      }
      if (widget.area == PortalArea.driver) {
        final vehiclesRes = await vehiclesService.listMine(auth.accessToken);
        final vehicles = portalMapList(vehiclesRes, 'vehicles');
        final profileData = profile['profile'];
        final activeId = profileData is Map ? portalStr(profileData['active_vehicle_id'], '') : '';
        _vehicles = vehicles;
        _activeVehicleId = activeId;
      }
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = T.portal('portal.profile.unavailable');
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final auth = useAuth(ref);
    setState(() => _saving = true);
    try {
      await settingsService.updateMyProfile(auth.accessToken, {
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(T.portal('portal.profile.saved'))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(T.portal('portal.profile.saveFailed'))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setActiveVehicle(String id) async {
    final auth = useAuth(ref);
    await vehiclesService.setActiveVehicle(auth.accessToken, id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return portalLoading();
    if (_error != null) return portalError(_error!);

    return AdminListStack(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ShadInput(
                  controller: _nameController,
                  placeholder: Text(T.portal('portal.profile.fullName')),
                ),
                const SizedBox(height: 10),
                ShadInput(
                  controller: _phoneController,
                  placeholder: Text(T.portal('portal.profile.phone')),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ShadButton(
                    onPressed: _saving ? null : _save,
                    child: Text(T.portal('portal.profile.save')),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (widget.area == PortalArea.driver)
          AdminTableCard(
            child: AdminTable(
              child: DataTable(
                columns: [
                  DataColumn(label: Text(T.portal('portal.profile.vehicle'))),
                  DataColumn(label: Text(T.portal('portal.profile.plate'))),
                  const DataColumn(label: SizedBox.shrink()),
                ],
                rows: _vehicles.map((vehicle) {
                  final id = portalStr(vehicle['id']);
                  final isActive = id == _activeVehicleId;
                  return DataRow(
                    selected: isActive,
                    cells: [
                      DataCell(Text('${portalStr(vehicle['brand'])} ${portalStr(vehicle['name'])}'.trim())),
                      DataCell(Text(portalStr(vehicle['plate']))),
                      DataCell(
                        ShadButton.outline(
                          onPressed: isActive ? null : () => _setActiveVehicle(id),
                          size: ShadButtonSize.sm,
                          child: Text(
                            isActive
                                ? T.portal('portal.profile.activeVehicle')
                                : T.portal('portal.profile.setActiveVehicle'),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(growable: false),
              ),
            ),
            isEmpty: _vehicles.isEmpty,
            empty: portalEmpty(T.nav('common.noData')),
          ),
      ],
    );
  }
}

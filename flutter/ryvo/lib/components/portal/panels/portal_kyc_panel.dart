import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo/components/portal/panels/portal_panel_utils.dart';
import 'package:ryvo/components/portal/portal_tab_scaffold.dart';
import 'package:ryvo/configs/const.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';
import 'package:ryvo/services/index.dart';

class PortalKycPanel extends ConsumerStatefulWidget {
  const PortalKycPanel({super.key});

  @override
  ConsumerState<PortalKycPanel> createState() => _PortalKycPanelState();
}

class _PortalKycPanelState extends ConsumerState<PortalKycPanel> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _checklist = const [];
  List<Map<String, dynamic>> _vehicles = const [];

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
      final checklistRes = await kycService.getChecklist(auth.accessToken);
      final vehiclesRes = await vehiclesService.listMine(auth.accessToken);
      if (!mounted) return;
      setState(() {
        _checklist = portalMapList(checklistRes, 'items');
        _vehicles = portalMapList(vehiclesRes, 'vehicles');
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return portalLoading();
    if (_error != null) return portalError(_error!);

    return PortalTabScaffold(
      tabs: [
        T.portal('portal.kyc.tabs.you'),
        T.portal('portal.kyc.tabs.cars'),
      ],
      children: [
        _checklist.isEmpty
            ? portalEmpty(T.nav('common.noData'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _checklist.length,
                itemBuilder: (context, index) {
                  final item = _checklist[index];
                  final done = item['status'] == 'completed' || item['done'] == true;
                  return ListTile(
                    leading: Icon(
                      done ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: done ? Colors.green : null,
                    ),
                    title: Text(portalStr(item['label'], portalStr(item['name']))),
                    subtitle: Text(portalStr(item['status'])),
                  );
                },
              ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: ShadButton(
                  size: ShadButtonSize.sm,
                  onPressed: () => context.go(Routes.driverKycCarsNew),
                  child: Text(T.portal('portal.kyc.addCar')),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _vehicles.isEmpty
                    ? portalEmpty(T.nav('common.noData'))
                    : ListView.builder(
                        itemCount: _vehicles.length,
                        itemBuilder: (context, index) {
                          final vehicle = _vehicles[index];
                          return ListTile(
                            title: Text(
                              '${portalStr(vehicle['brand'])} ${portalStr(vehicle['model'])}'.trim(),
                            ),
                            subtitle: Text(portalStr(vehicle['plate_number'])),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

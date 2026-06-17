import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo/components/portal/panels/portal_panel_utils.dart';
import 'package:ryvo/components/portal/portal_list_ui.dart';
import 'package:ryvo/components/portal/portal_tab_scaffold.dart';
import 'package:ryvo/configs/const.dart';
import 'package:ryvo/configs/portal_nav.dart';
import 'package:ryvo/hooks/use_auth.dart';
import 'package:ryvo/i18n/t.dart';
import 'package:ryvo/services/index.dart';

class PortalConfigurationsPanel extends ConsumerStatefulWidget {
  const PortalConfigurationsPanel({super.key, required this.area});

  final PortalArea area;

  @override
  ConsumerState<PortalConfigurationsPanel> createState() => _PortalConfigurationsPanelState();
}

class _PortalConfigurationsPanelState extends ConsumerState<PortalConfigurationsPanel> {
  bool _loading = true;
  String? _error;
  String _locale = 'en';
  bool _savingLocale = false;

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
      final general = await settingsService.getGeneral(auth.accessToken);
      final locale = portalStr(general['settings']?['locale'], portalStr(general['locale'], 'en'));
      if (!mounted) return;
      setState(() {
        _locale = locale;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = T.portal('portal.configurations.unavailable');
        _loading = false;
      });
    }
  }

  Future<void> _saveLocale() async {
    final auth = useAuth(ref);
    setState(() => _savingLocale = true);
    try {
      await settingsService.updateGeneral(auth.accessToken, {'locale': _locale});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(T.portal('portal.configurations.saved'))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(T.portal('portal.configurations.saveFailed'))),
      );
    } finally {
      if (mounted) setState(() => _savingLocale = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return portalLoading();
    if (_error != null) return portalError(_error!);

    final paymentRoute = widget.area == PortalArea.driver ? Routes.driverPayments : Routes.clientPayments;
    final notificationsRoute = widget.area == PortalArea.driver
        ? Routes.driverNotifications
        : Routes.clientNotifications;

    return PortalTabScaffoldSimple(
      tabs: [
        T.portal('portal.settings.tabs.general'),
        T.portal('portal.settings.tabs.payment'),
        T.portal('portal.settings.tabs.notifications'),
      ],
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminFilterSelect(
                value: _locale,
                onChanged: (value) => setState(() => _locale = value),
                options: [
                  AdminFilterOption(value: 'en', label: 'English'),
                  AdminFilterOption(value: 'fr', label: 'Français'),
                  AdminFilterOption(value: 'es', label: 'Español'),
                  AdminFilterOption(value: 'de', label: 'Deutsch'),
                  AdminFilterOption(value: 'zh', label: '中文'),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ShadButton(
                  onPressed: _savingLocale ? null : _saveLocale,
                  child: Text(T.portal('portal.configurations.saveLocale')),
                ),
              ),
            ],
          ),
        ),
        _LinkCard(
          title: T.portal('portal.nav.payments'),
          description: T.portal('portal.configurations.paymentHint'),
          buttonLabel: T.portal('portal.configurations.openPayments'),
          onTap: () => context.go(paymentRoute),
        ),
        _LinkCard(
          title: T.portal('portal.nav.notifications'),
          description: T.portal('portal.configurations.notificationsHint'),
          buttonLabel: T.portal('portal.configurations.openNotifications'),
          onTap: () => context.go(notificationsRoute),
        ),
      ],
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onTap,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              Text(description, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ShadButton.outline(onPressed: onTap, child: Text(buttonLabel)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_auth.dart';
import 'package:ryvo_admin/services/index.dart';

class AdminSettingsConfigurationsPage extends ConsumerStatefulWidget {
  const AdminSettingsConfigurationsPage({super.key});

  @override
  ConsumerState<AdminSettingsConfigurationsPage> createState() =>
      _AdminSettingsConfigurationsPageState();
}

class _AdminSettingsConfigurationsPageState
    extends ConsumerState<AdminSettingsConfigurationsPage> {
  Future<Map<String, dynamic>>? _generalFuture;
  Future<Map<String, dynamic>>? _paymentFuture;
  Future<Map<String, dynamic>>? _mailFuture;
  Future<Map<String, dynamic>>? _notifFuture;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  void _loadAll() {
    final token = useAuth(ref).accessToken;
    _generalFuture = settingsService.getGeneral(token);
    _paymentFuture = settingsService.getPayment(token);
    _mailFuture = settingsService.listEmailTemplates(token);
    _notifFuture = settingsService.getNotifications(token);
  }

  Future<void> _refresh() async {
    setState(_loadAll);
    await Future.wait([
      _generalFuture!,
      _paymentFuture!,
      _mailFuture!,
      _notifFuture!,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permissions: const ['settings:read'],
      fallback: const Center(child: Text('No access to settings hub.')),
      child: DefaultTabController(
        length: 4,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: AdminListStack(
            children: [
              AdminPageHeader(
                title: 'Configurations',
                subtitle: 'General, payment, mail and notifications settings.',
                action: OutlinedButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                ),
              ),
              const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'General'),
                  Tab(text: 'Payment'),
                  Tab(text: 'Mail'),
                  Tab(text: 'Notifications'),
                ],
              ),
              SizedBox(
                height: 420,
                child: TabBarView(
                  children: [
                    _MapCard(
                      future: _generalFuture!,
                      mapKey: 'preferences',
                      emptyText: 'No general settings.',
                    ),
                    _MapCard(
                      future: _paymentFuture!,
                      mapKey: 'config',
                      emptyText: 'No payment settings.',
                    ),
                    _ListCard(
                      future: _mailFuture!,
                      listKey: 'templates',
                      emptyText: 'No email templates.',
                    ),
                    _MapCard(
                      future: _notifFuture!,
                      mapKey: 'config',
                      emptyText: 'No notifications config.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({
    required this.future,
    required this.mapKey,
    required this.emptyText,
  });

  final Future<Map<String, dynamic>> future;
  final String mapKey;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load: ${snapshot.error}'));
        }
        final map = snapshot.data?[mapKey] is Map
            ? Map<String, dynamic>.from(snapshot.data![mapKey] as Map)
            : <String, dynamic>{};
        if (map.isEmpty) return Center(child: Text(emptyText));
        return AdminTableCard(
          child: ListView(
            children: map.entries
                .map(
                  (e) => ListTile(
                    title: Text(e.key),
                    subtitle: Text(e.value.toString()),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.future,
    required this.listKey,
    required this.emptyText,
  });

  final Future<Map<String, dynamic>> future;
  final String listKey;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load: ${snapshot.error}'));
        }
        final raw = snapshot.data?[listKey];
        final rows = raw is List
            ? raw
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
            : <Map<String, dynamic>>[];
        if (rows.isEmpty) return Center(child: Text(emptyText));
        return AdminTableCard(
          child: ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final row = rows[index];
              return ListTile(
                title: Text(row['template_key']?.toString() ?? 'Template'),
                subtitle: Text(row['subject']?.toString() ?? ''),
              );
            },
          ),
        );
      },
    );
  }
}

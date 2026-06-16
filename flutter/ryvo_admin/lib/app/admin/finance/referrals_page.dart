import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/hooks/use_auth.dart';
import 'package:ryvo_admin/services/finance_service.dart';

class FinanceReferralsPage extends ConsumerStatefulWidget {
  const FinanceReferralsPage({super.key});

  @override
  ConsumerState<FinanceReferralsPage> createState() =>
      _FinanceReferralsPageState();
}

class _FinanceReferralsPageState extends ConsumerState<FinanceReferralsPage> {
  late Future<_ReferralsPayload> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ReferralsPayload> _load() async {
    final token = useAuth(ref).accessToken;
    final referrals = await financeService.getReferrals(token);
    final coupons = await financeService.getCoupons(token);
    final settings = await financeService.getReferralSettings(token);
    return _ReferralsPayload(
      referrals: referrals,
      coupons: coupons,
      settings: settings,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permissions: const ['finances:referrals:read', 'payments:read'],
      fallback: const Center(
        child: Text('You do not have access to referrals finance module.'),
      ),
      child: DefaultTabController(
        length: 4,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: FutureBuilder<_ReferralsPayload>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return Text('Failed to load referrals hub: ${snapshot.error}');
              }
              final data = snapshot.data!;
              return AdminListStack(
                children: [
                  const AdminPageHeader(
                    title: 'Referrals',
                    subtitle:
                        'Bonus, coupons, referral programs, and referral settings.',
                  ),
                  const TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: [
                      Tab(text: 'Bonus'),
                      Tab(text: 'Coupons'),
                      Tab(text: 'Referrals'),
                      Tab(text: 'Settings'),
                    ],
                  ),
                  SizedBox(
                    height: 520,
                    child: TabBarView(
                      children: [
                        _JsonListTab(
                          title: 'Bonuses',
                          value: data.referrals['bonuses'],
                        ),
                        _JsonListTab(
                          title: 'Coupons',
                          value: data.coupons['coupons'],
                        ),
                        _JsonListTab(
                          title: 'Programs',
                          value:
                              data.referrals['campaigns'] ??
                              data.referrals['programs'],
                        ),
                        _KeyValueTab(data: data.settings),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReferralsPayload {
  const _ReferralsPayload({
    required this.referrals,
    required this.coupons,
    required this.settings,
  });

  final Map<String, dynamic> referrals;
  final Map<String, dynamic> coupons;
  final Map<String, dynamic> settings;
}

class _JsonListTab extends StatelessWidget {
  const _JsonListTab({required this.title, required this.value});

  final String title;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final rows = (value is List)
        ? value
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList(growable: false)
        : <Map<String, dynamic>>[];
    return AdminTableCard(
      isEmpty: rows.isEmpty,
      empty: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('No $title found.'),
      ),
      child: ListView.separated(
        itemCount: rows.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final row = rows[index];
          final name =
              row['name'] ??
              row['title'] ??
              row['code'] ??
              row['id'] ??
              'row-${index + 1}';
          final subtitle = row.entries
              .take(3)
              .map((e) => '${e.key}: ${e.value}')
              .join(' • ');
          return ListTile(
            dense: true,
            title: Text(name.toString()),
            subtitle: Text(subtitle),
          );
        },
      ),
    );
  }
}

class _KeyValueTab extends StatelessWidget {
  const _KeyValueTab({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const AdminTableCard(
        isEmpty: true,
        empty: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No settings found.'),
        ),
        child: SizedBox.shrink(),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: data.entries
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          entry.key,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      Expanded(flex: 3, child: Text(entry.value.toString())),
                    ],
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

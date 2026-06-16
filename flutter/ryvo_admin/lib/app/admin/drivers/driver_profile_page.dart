import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';
import 'package:ryvo_admin/components/admin/profile_header.dart';
import 'package:ryvo_admin/components/admin/profile_manage_section.dart';
import 'package:ryvo_admin/configs/const.dart';
import 'package:ryvo_admin/guards/permission_gate.dart';
import 'package:ryvo_admin/stores/auth_store.dart';
import 'package:ryvo_admin/hooks/use_rbac.dart';
import 'package:ryvo_admin/services/drivers_service.dart';
import 'package:ryvo_admin/services/rbac_service.dart';
import 'package:ryvo_admin/services/vehicles_service.dart';

const _tabInfo = 'info';
const _tabVehicles = 'vehicles';
const _tabDocuments = 'documents';

const _personalDocTypes = [
  'national_id',
  'passport',
  'selfie_with_id',
  'driver_license',
  'bank_statement',
];

class DriverProfilePage extends ConsumerStatefulWidget {
  const DriverProfilePage({super.key});

  @override
  ConsumerState<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends ConsumerState<DriverProfilePage>
    with SingleTickerProviderStateMixin {
  Future<_DriverProfilePayload>? _future;
  String? _loadedDriverId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final driverId = GoRouterState.of(context).uri.queryParameters['id'];
    final tab = GoRouterState.of(context).uri.queryParameters['tab'];
    if (driverId != _loadedDriverId) {
      _loadedDriverId = driverId;
      _future = driverId == null || driverId.isEmpty ? null : _load(driverId);
    }
    final tabIndex = _tabIndex(tab);
    if (_tabController.index != tabIndex) {
      _tabController.index = tabIndex;
    }
  }

  int _tabIndex(String? tab) {
    return switch (tab) {
      _tabVehicles => 1,
      _tabDocuments => 2,
      _ => 0,
    };
  }

  String _tabParam(int index) {
    return switch (index) {
      1 => _tabVehicles,
      2 => _tabDocuments,
      _ => _tabInfo,
    };
  }

  Future<_DriverProfilePayload> _load(String driverId) async {
    final token = ref.read(authProvider).accessToken;
    final results = await Future.wait([
      driversService.getDriver(token, driverId),
      rbacService.getUserDetail(token, driverId),
    ]);
    return _DriverProfilePayload(
      driverRes: Map<String, dynamic>.from(results[0]),
      userRes: Map<String, dynamic>.from(results[1]),
    );
  }

  void _refresh() {
    final driverId = _loadedDriverId;
    if (driverId == null || driverId.isEmpty) return;
    setState(() => _future = _load(driverId));
  }

  void _setTab(int index) {
    final driverId = _loadedDriverId;
    if (driverId == null || driverId.isEmpty) return;
    final tab = _tabParam(index);
    context.go('${Routes.adminDriversProfile}?id=$driverId&tab=$tab');
  }

  Map<String, String> _customFields(dynamic raw) {
    if (raw is! Map) return const {};
    return raw.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driverId = GoRouterState.of(context).uri.queryParameters['id'];
    final rbac = ref.watch(rbacProvider);
    final canEditDriver = rbac.maybeWhen(
      data: (vm) =>
          vm.hasPermission('drivers:update') || vm.hasPermission('users:update'),
      orElse: () => false,
    );

    return PermissionGate(
      permissions: const ['drivers:read'],
      fallback: const Center(
        child: Text('You do not have access to view driver profiles.'),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: AdminListStack(
          children: [
            OutlinedButton.icon(
              onPressed: () => context.go(Routes.adminDriversList),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back to drivers'),
            ),
            if (driverId == null || driverId.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No driver id found in query params.'),
                ),
              )
            else
              FutureBuilder<_DriverProfilePayload>(
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
                  if (snapshot.hasError) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Failed to load driver: ${snapshot.error}',
                        ),
                      ),
                    );
                  }

                  final driver = (snapshot.data?.driverRes['driver'] is Map)
                      ? Map<String, dynamic>.from(
                          snapshot.data!.driverRes['driver'] as Map,
                        )
                      : <String, dynamic>{};
                  if (driver.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Driver not found.'),
                      ),
                    );
                  }

                  final user = (snapshot.data?.userRes['user'] is Map)
                      ? Map<String, dynamic>.from(
                          snapshot.data!.userRes['user'] as Map,
                        )
                      : <String, dynamic>{};

                  final documents = _asMapList(driver['documents']);
                  final vehicles = _asMapList(driver['vehicles']);
                  final reviews = _asMapList(driver['reviews']);
                  final pendingDocs = documents
                      .where((d) => d['status']?.toString() == 'pending')
                      .length;
                  final rolesRaw = driver['roles'];
                  final roles = rolesRaw is List
                      ? rolesRaw.map((e) => e.toString()).toList()
                      : <String>[];

                  return AdminListStack(
                    children: [
                      ProfileHeader(
                        variant: ProfileVariant.driver,
                        user: ProfileHeaderData(
                          fullName: driver['full_name']?.toString(),
                          email: driver['email']?.toString() ?? '—',
                          phone: driver['phone']?.toString(),
                          avatarUrl: driver['avatar_url']?.toString(),
                          ratingAvg: (driver['rating_avg'] as num?)?.toDouble(),
                          tripCount: (driver['trip_count'] as num?)?.toInt(),
                          createdAt: driver['created_at']?.toString(),
                          updatedAt: driver['updated_at']?.toString(),
                          emailVerified: driver['email_verified'] == true,
                          profileVerified: driver['profile_verified'] == true,
                          kycStatus: driver['kyc_status']?.toString(),
                          roles: roles,
                        ),
                      ),
                      Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: Text(
                                'Profile sections',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                              ),
                            ),
                            TabBar(
                              controller: _tabController,
                              onTap: _setTab,
                              isScrollable: true,
                              tabs: [
                                const Tab(text: 'Info'),
                                Tab(
                                  text: vehicles.isEmpty
                                      ? 'Vehicles'
                                      : 'Vehicles (${vehicles.length})',
                                ),
                                Tab(
                                  text: pendingDocs == 0
                                      ? 'Documents'
                                      : 'Documents ($pendingDocs)',
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: AnimatedBuilder(
                                animation: _tabController,
                                builder: (context, _) {
                                  switch (_tabController.index) {
                                    case 1:
                                      return _VehiclesTab(
                                        vehicles: vehicles,
                                        onChanged: _refresh,
                                      );
                                    case 2:
                                      return _DocumentsTab(
                                        driverId: driverId,
                                        documents: documents,
                                        onChanged: _refresh,
                                      );
                                    default:
                                      return _InfoTab(
                                        driverId: driverId,
                                        user: user,
                                        reviews: reviews,
                                        canEdit: canEditDriver,
                                        onSaved: _refresh,
                                        customFields: _customFields(
                                          user['custom_fields'],
                                        ),
                                      );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DriverProfilePayload {
  const _DriverProfilePayload({
    required this.driverRes,
    required this.userRes,
  });

  final Map<String, dynamic> driverRes;
  final Map<String, dynamic> userRes;
}

class _InfoTab extends StatelessWidget {
  const _InfoTab({
    required this.driverId,
    required this.user,
    required this.reviews,
    required this.canEdit,
    required this.onSaved,
    required this.customFields,
  });

  final String driverId;
  final Map<String, dynamic> user;
  final List<Map<String, dynamic>> reviews;
  final bool canEdit;
  final VoidCallback onSaved;
  final Map<String, String> customFields;

  @override
  Widget build(BuildContext context) {
    return AdminListStack(
      children: [
        if (user.isNotEmpty)
          ProfileManageSection(
            userId: driverId,
            canEdit: canEdit,
            onSaved: onSaved,
            initial: ProfileManageValues(
              fullName: user['full_name']?.toString(),
              email: user['email']?.toString() ?? '',
              phone: user['phone']?.toString(),
              username: user['username']?.toString(),
              customFields: customFields,
            ),
          ),
        _ReviewsSection(reviews: reviews),
      ],
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.reviews});

  final List<Map<String, dynamic>> reviews;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reviews',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (reviews.isEmpty)
              Text(
                'No reviews yet.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              ...reviews.map((review) {
                final rating = (review['rating'] as num?)?.toInt() ?? 0;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('★' * rating.clamp(0, 5)),
                  subtitle: Text(review['comment']?.toString() ?? '—'),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _VehiclesTab extends ConsumerStatefulWidget {
  const _VehiclesTab({required this.vehicles, required this.onChanged});

  final List<Map<String, dynamic>> vehicles;
  final VoidCallback onChanged;

  @override
  ConsumerState<_VehiclesTab> createState() => _VehiclesTabState();
}

class _VehiclesTabState extends ConsumerState<_VehiclesTab> {
  bool _busy = false;

  Future<void> _reviewVehicle(
    String vehicleId,
    String status, {
    String? reason,
  }) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await vehiclesService.reviewVehicle(
        ref.read(authProvider).accessToken,
        vehicleId,
        status,
        rejectionReason: reason,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Vehicle marked as $status.')),
      );
      widget.onChanged();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to review vehicle: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rejectVehicle(String vehicleId) async {
    final reasonCtrl = TextEditingController(
      text: 'Vehicle does not meet requirements.',
    );
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject vehicle'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(labelText: 'Reason'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, reasonCtrl.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    reasonCtrl.dispose();
    if (reason == null || reason.isEmpty) return;
    await _reviewVehicle(vehicleId, 'rejected', reason: reason);
  }

  Future<void> _reviewVehicleDocument(
    String vehicleId,
    String docId,
    String status, {
    String? reason,
  }) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await vehiclesService.reviewVehicleDocument(
        ref.read(authProvider).accessToken,
        vehicleId,
        docId,
        status,
        rejectionReason: reason,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Document marked as $status.')),
      );
      widget.onChanged();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to review document: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _viewVehicleDocument(String vehicleId, String docId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await vehiclesService.adminGetDocumentViewUrl(
        ref.read(authProvider).accessToken,
        vehicleId,
        docId,
      );
      final url = res['url']?.toString() ?? res['view_url']?.toString();
      if (url == null || url.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No view URL returned.')),
        );
        return;
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Document URL'),
          content: SelectableText(url),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to open document: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.vehicles.isEmpty) {
      return const Text('No vehicles registered for this driver.');
    }

    return PermissionGate(
      permissions: const ['drivers:update', 'kyc:review'],
      fallback: const Text('You do not have permission to review vehicles.'),
      child: Column(
        children: widget.vehicles.map((vehicle) {
          final vehicleId = vehicle['id']?.toString() ?? '';
          final status = vehicle['status']?.toString() ?? 'unknown';
          final docs = _asMapList(vehicle['documents']);
          final canApproveVehicle = status == 'pending';
          final canRejectVehicle = status == 'approved' || status == 'pending';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${vehicle['make'] ?? '—'} ${vehicle['model'] ?? ''}'.trim(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      StatusBadge(
                        label: status,
                        variant: _docVariant(status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Plate: ${vehicle['plate_number'] ?? '—'}'),
                  Text('Color: ${vehicle['color'] ?? '—'}'),
                  if (vehicleId.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (canApproveVehicle)
                          FilledButton(
                            onPressed: _busy
                                ? null
                                : () => _reviewVehicle(vehicleId, 'approved'),
                            child: const Text('Approve vehicle'),
                          ),
                        if (canRejectVehicle)
                          OutlinedButton(
                            onPressed:
                                _busy ? null : () => _rejectVehicle(vehicleId),
                            child: const Text('Reject vehicle'),
                          ),
                      ],
                    ),
                  ],
                  if (docs.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Documents (${docs.length})',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    ...docs.map((doc) {
                      final docId = doc['id']?.toString() ?? '';
                      final docStatus = doc['status']?.toString() ?? 'unknown';
                      final canView = docId.isNotEmpty && docStatus != 'missing';
                      final canApprove = docStatus == 'pending';
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(doc['doc_type']?.toString() ?? 'Document'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StatusBadge(
                              label: docStatus,
                              variant: _docVariant(docStatus),
                            ),
                            if (canView)
                              IconButton(
                                tooltip: 'View',
                                onPressed: _busy
                                    ? null
                                    : () => _viewVehicleDocument(
                                          vehicleId,
                                          docId,
                                        ),
                                icon: const Icon(LucideIcons.eye, size: 18),
                              ),
                            if (canApprove && vehicleId.isNotEmpty && docId.isNotEmpty)
                              IconButton(
                                tooltip: 'Approve',
                                onPressed: _busy
                                    ? null
                                    : () => _reviewVehicleDocument(
                                          vehicleId,
                                          docId,
                                          'approved',
                                        ),
                                icon: const Icon(LucideIcons.check, size: 18),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _DocumentsTab extends ConsumerStatefulWidget {
  const _DocumentsTab({
    required this.driverId,
    required this.documents,
    required this.onChanged,
  });

  final String driverId;
  final List<Map<String, dynamic>> documents;
  final VoidCallback onChanged;

  @override
  ConsumerState<_DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends ConsumerState<_DocumentsTab> {
  bool _busy = false;

  Map<String, dynamic>? _docByType(String docType) {
    for (final doc in widget.documents) {
      if (doc['doc_type']?.toString() == docType) return doc;
    }
    return null;
  }

  Future<void> _viewDocument(String docType) async {
    final token = ref.read(authProvider).accessToken;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await driversService.getDocumentViewUrl(
        token,
        widget.driverId,
        docType,
      );
      final url = res['url']?.toString() ?? res['view_url']?.toString();
      if (url == null || url.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No view URL returned.')),
        );
        return;
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('View $_docLabel(docType)'),
          content: SelectableText(url),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to open document: $e')),
      );
    }
  }

  Future<void> _reviewDocument(
    String docType,
    String status, {
    String? reason,
  }) async {
    setState(() => _busy = true);
    final token = ref.read(authProvider).accessToken;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await driversService.reviewDocument(
        token,
        widget.driverId,
        docType,
        status,
        rejectionReason: reason,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Document marked as $status.')),
      );
      widget.onChanged();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to review document: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rejectDocument(String docType) async {
    final reasonCtrl = TextEditingController(
      text: 'Document does not meet requirements.',
    );
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject document'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(labelText: 'Reason'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, reasonCtrl.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    reasonCtrl.dispose();
    if (reason == null || reason.isEmpty) return;
    await _reviewDocument(docType, 'rejected', reason: reason);
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      permissions: const ['drivers:update', 'kyc:review'],
      fallback: const Text('You do not have permission to review documents.'),
      child: Column(
        children: _personalDocTypes.map((docType) {
          final doc = _docByType(docType);
          final status = doc?['status']?.toString() ?? 'missing';
          final s3Key = doc?['s3_key']?.toString() ?? '';
          final canView = status != 'missing' && s3Key.isNotEmpty;
          final canApprove = status == 'pending' && s3Key.isNotEmpty;
          final canReject = status == 'approved' || status == 'pending';

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(_docLabel(docType)),
              subtitle: Text(status.toUpperCase()),
              trailing: Wrap(
                spacing: 6,
                children: [
                  if (canView)
                    IconButton(
                      tooltip: 'View',
                      onPressed: _busy ? null : () => _viewDocument(docType),
                      icon: const Icon(LucideIcons.eye, size: 18),
                    ),
                  if (canApprove)
                    IconButton(
                      tooltip: 'Approve',
                      onPressed: _busy
                          ? null
                          : () => _reviewDocument(docType, 'approved'),
                      icon: const Icon(LucideIcons.check, size: 18),
                    ),
                  if (canReject)
                    IconButton(
                      tooltip: 'Reject',
                      onPressed: _busy ? null : () => _rejectDocument(docType),
                      icon: const Icon(LucideIcons.x, size: 18),
                    ),
                ],
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

StatusBadgeVariant _docVariant(String? status) {
  return switch (status) {
    'approved' => StatusBadgeVariant.success,
    'pending' => StatusBadgeVariant.warning,
    'rejected' => StatusBadgeVariant.danger,
    _ => StatusBadgeVariant.defaultVariant,
  };
}

String _docLabel(String docType) {
  return switch (docType) {
    'national_id' => 'National ID',
    'passport' => 'Passport',
    'selfie_with_id' => 'Selfie with ID',
    'driver_license' => 'Driver license',
    'bank_statement' => 'Bank statement',
    _ => docType,
  };
}

List<Map<String, dynamic>> _asMapList(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList(growable: false);
}

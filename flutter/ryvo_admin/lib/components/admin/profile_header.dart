import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ryvo_admin/components/admin/admin_list_ui.dart';

enum ProfileVariant { client, driver, staff }

class ProfileHeaderData {
  const ProfileHeaderData({
    required this.fullName,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.ratingAvg,
    this.tripCount,
    this.createdAt,
    this.updatedAt,
    this.emailVerified = false,
    this.profileVerified = false,
    this.kycStatus,
    this.roles = const [],
  });

  final String? fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final double? ratingAvg;
  final int? tripCount;
  final String? createdAt;
  final String? updatedAt;
  final bool emailVerified;
  final bool profileVerified;
  final String? kycStatus;
  final List<String> roles;
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.user,
    this.variant = ProfileVariant.client,
  });

  final ProfileHeaderData user;
  final ProfileVariant variant;

  @override
  Widget build(BuildContext context) {
    final displayName = (user.fullName?.trim().isNotEmpty ?? false)
        ? user.fullName!
        : user.email;
    final isDriver = variant == ProfileVariant.driver;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: const Offset(0, -48),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage:
                        user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                        ? const Icon(LucideIcons.user, size: 36)
                        : null,
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (user.phone != null && user.phone!.isNotEmpty)
                        Text(
                          user.phone!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (user.emailVerified)
                            const StatusBadge(
                              label: 'Email verified',
                              variant: StatusBadgeVariant.success,
                            ),
                          if (isDriver &&
                              (user.profileVerified ||
                                  user.kycStatus == 'approved'))
                            const StatusBadge(
                              label: 'Verified',
                              variant: StatusBadgeVariant.success,
                            ),
                          if (isDriver &&
                              user.kycStatus != null &&
                              user.kycStatus != 'approved')
                            StatusBadge(
                              label: user.kycStatus!.toUpperCase(),
                              variant: user.kycStatus == 'rejected'
                                  ? StatusBadgeVariant.danger
                                  : StatusBadgeVariant.warning,
                            ),
                          if (isDriver && user.ratingAvg != null)
                            StatusBadge(
                              label:
                                  '★ ${user.ratingAvg!.toStringAsFixed(1)} · ${user.tripCount ?? 0} trips',
                              variant: StatusBadgeVariant.info,
                            ),
                          ...user.roles.map(
                            (role) => StatusBadge(
                              label: role,
                              variant: StatusBadgeVariant.defaultVariant,
                            ),
                          ),
                        ],
                      ),
                      if (user.createdAt != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Joined ${_formatDate(user.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(String? iso) {
  final dt = DateTime.tryParse(iso ?? '');
  if (dt == null) return '—';
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

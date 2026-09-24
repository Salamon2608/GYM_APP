import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/features/admin/presentation/theme/admin_theme.dart';
import 'package:gym_management/features/admin/presentation/widgets/admin_widgets.dart';
import 'package:gym_management/features/admin/providers/admin_providers.dart';

class ComplaintsScreen extends ConsumerWidget {
  const ComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AdminTheme.scaffold,
        appBar: AppBar(
          backgroundColor: AdminTheme.scaffold,
          title: Text('Complaints & Feedback', style: AdminTheme.headingMedium),
          iconTheme: const IconThemeData(color: AdminTheme.textPrimary),
          bottom: TabBar(
            indicatorColor: AdminTheme.orange,
            labelColor: AdminTheme.orange,
            unselectedLabelColor: AdminTheme.textSecondary,
            tabs: const [
              Tab(text: 'Complaints'),
              Tab(text: 'Trainer Ratings'),
            ],
          ),
        ),
        body: TabBarView(children: [_ComplaintsTab(), _RatingsTab()]),
      ),
    );
  }
}

class _ComplaintsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaintsAsync = ref.watch(allComplaintsProvider);

    return complaintsAsync.when(
      data: (complaints) {
        if (complaints.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 56,
                  color: AdminTheme.success,
                ),
                const SizedBox(height: 12),
                Text('No complaints', style: AdminTheme.bodySmall),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: complaints.length,
          itemBuilder: (_, i) =>
              _buildComplaintCard(context, ref, complaints[i]),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AdminTheme.orange),
      ),
      error: (e, _) => Center(
        child: Text('Error: $e', style: TextStyle(color: AdminTheme.error)),
      ),
    );
  }

  Widget _buildComplaintCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> complaint,
  ) {
    final user = complaint['users'] as Map<String, dynamic>? ?? {};
    final status = complaint['status'] ?? 'pending';
    final statusColor = status == 'resolved'
        ? AdminTheme.success
        : status == 'in_progress'
        ? AdminTheme.warning
        : AdminTheme.error;
    final nextStatus = status == 'pending'
        ? 'in_progress'
        : status == 'in_progress'
        ? 'resolved'
        : null;

    // Trainer linked to this complaint
    final trainerData = complaint['trainer'] as Map<String, dynamic>?;
    final trainerUser = trainerData?['users'] as Map<String, dynamic>?;
    final trainerName = trainerUser?['full_name'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AdminTheme.card,
        borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
        border: Border.all(color: AdminTheme.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 3, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user['full_name'] ?? 'Unknown',
                                  style: AdminTheme.headingSmall,
                                ),
                                Text(
                                  user['email'] ?? '',
                                  style: AdminTheme.label,
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(
                            text: status.toUpperCase(),
                            color: statusColor,
                          ),
                        ],
                      ),
                      if (trainerName != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.sports_rounded,
                              size: 14,
                              color: AdminTheme.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'About Trainer: $trainerName',
                              style: AdminTheme.label.copyWith(
                                color: AdminTheme.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(
                        complaint['subject'] ?? '',
                        style: AdminTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (complaint['description'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            complaint['description'],
                            style: AdminTheme.bodySmall,
                          ),
                        ),
                      if (nextStatus != null) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AdminTheme.orange,
                              side: const BorderSide(color: AdminTheme.orange),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AdminTheme.radiusMd,
                                ),
                              ),
                            ),
                            onPressed: () async {
                              final repo = ref.read(adminRepositoryProvider);
                              await repo.updateComplaintStatus(
                                complaint['id'],
                                nextStatus,
                              );
                              ref.invalidate(allComplaintsProvider);
                            },
                            child: Text(
                              nextStatus == 'in_progress'
                                  ? 'Mark In Progress'
                                  : 'Mark Resolved',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratingsAsync = ref.watch(trainerFeedbackProvider);

    return ratingsAsync.when(
      data: (ratings) {
        if (ratings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_border, size: 56, color: AdminTheme.textMuted),
                const SizedBox(height: 12),
                Text('No ratings yet', style: AdminTheme.bodySmall),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ratings.length,
          itemBuilder: (_, i) => _buildRatingCard(ratings[i]),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AdminTheme.orange),
      ),
      error: (e, _) => Center(
        child: Text('Error: $e', style: TextStyle(color: AdminTheme.error)),
      ),
    );
  }

  Widget _buildRatingCard(Map<String, dynamic> rating) {
    final member = rating['users'] as Map<String, dynamic>? ?? {};
    final trainer = rating['trainers'] as Map<String, dynamic>? ?? {};
    final trainerUser = trainer['users'] as Map<String, dynamic>? ?? {};
    final stars = (rating['rating'] as num?)?.toInt() ?? 5;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminTheme.card,
        borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['full_name'] ?? 'Unknown',
                      style: AdminTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Trainer: ${trainerUser['full_name'] ?? 'Unknown'}',
                      style: AdminTheme.label,
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 16,
                    color: AdminTheme.warning,
                  );
                }),
              ),
            ],
          ),
          if (rating['comment'] != null &&
              rating['comment'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '"${rating['comment']}"',
                style: AdminTheme.bodySmall.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

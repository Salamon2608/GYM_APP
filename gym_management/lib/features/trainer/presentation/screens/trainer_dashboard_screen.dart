import 'package:flutter/material.dart';
import 'package:gym_management/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_management/core/router/app_router.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';
import 'package:gym_management/features/member/presentation/screens/attendance_screen.dart';
import 'package:gym_management/features/trainer/presentation/theme/trainer_theme.dart';
import 'package:gym_management/features/trainer/providers/trainer_provider.dart';
import 'package:gym_management/features/shared/presentation/connectivity_error_widget.dart';

class TrainerDashboardScreen extends ConsumerStatefulWidget {
  const TrainerDashboardScreen({super.key});

  @override
  ConsumerState<TrainerDashboardScreen> createState() =>
      _TrainerDashboardScreenState();
}

class _TrainerDashboardScreenState
    extends ConsumerState<TrainerDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final trainerId = authState.user?.id;
    final gymName = authState.gymName ?? 'TRACEFIT';

    if (trainerId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in as a trainer.')),
      );
    }

    final statsAsync = ref.watch(trainerStatsProvider(trainerId));
    final membersAsync = ref.watch(assignedMembersProvider(trainerId));

    // Check for network errors in either provider
    final hasError = statsAsync.hasError || membersAsync.hasError;
    final error = statsAsync.error ?? membersAsync.error;
    if (hasError && error != null) {
      final errorStr = error.toString().toLowerCase();
      final isOffline = errorStr.contains('socket') || 
                        errorStr.contains('connection') || 
                        errorStr.contains('network') || 
                        errorStr.contains('timeout') ||
                        errorStr.contains('failed host lookup') ||
                        errorStr.contains('handshake');
      if (isOffline) {
        return Scaffold(
          backgroundColor: TrainerTheme.scaffold,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(gymName, style: TrainerTheme.headingSmall),
            elevation: 0,
          ),
          body: ConnectivityErrorWidget(
            accentColor: TrainerTheme.orange,
            onRetry: () {
              ref.invalidate(trainerStatsProvider(trainerId));
              ref.invalidate(assignedMembersProvider(trainerId));
            },
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: TrainerTheme.scaffold,
      body: SafeArea(
        child: RefreshIndicator(
          color: TrainerTheme.orange,
          onRefresh: () async {
            ref.invalidate(trainerStatsProvider(trainerId));
            ref.invalidate(assignedMembersProvider(trainerId));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const Divider(color: TrainerTheme.border, height: 1),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TrainerTheme.bodyLarge.copyWith(
                          color: TrainerTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        // Display the real name if available, otherwise default
                        authState.user?.userMetadata?['full_name'] ?? 'Trainer',
                        style: TrainerTheme.headingLarge.copyWith(fontSize: 32),
                      ),
                      const SizedBox(height: 16),

                      // Attendance Card
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AttendanceScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: TrainerTheme.success.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.fingerprint_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'My Attendance',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Check in / out via GPS',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white70,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Stats Grid
                      statsAsync.when(
                        data: (stats) => _buildStatsGrid(stats),
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            color: TrainerTheme.orange,
                          ),
                        ),
                        error: (e, _) => Text(
                          'Error loading stats: $e',
                          style: const TextStyle(color: TrainerTheme.error),
                        ),
                      ),

                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Assigned Members',
                            style: TrainerTheme.headingMedium,
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      _AllMembersScreen(trainerId: trainerId),
                                ),
                              );
                            },
                            child: Text(
                              'View All',
                              style: TrainerTheme.bodyMedium.copyWith(
                                color: TrainerTheme.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Members List
                      membersAsync.when(
                        data: (members) {
                          if (members.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32.0),
                              child: Center(
                                child: Text(
                                  'No members assigned yet.',
                                  style: TextStyle(
                                    color: TrainerTheme.textSecondary,
                                  ),
                                ),
                              ),
                            );
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: members.length,
                            itemBuilder: (context, index) {
                              return _buildMemberTile(members[index]);
                            },
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            color: TrainerTheme.orange,
                          ),
                        ),
                        error: (e, _) => Text(
                          'Error loading members: $e',
                          style: const TextStyle(color: TrainerTheme.error),
                        ),
                      ),

                      const SizedBox(height: 80), // Padding for the bottom nav
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final authState = ref.watch(authProvider);
    final gymName = authState.gymName ?? 'Dashboard';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (authState.logoUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    AppConstants.getFullImageUrl(authState.logoUrl),
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: TrainerTheme.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.fitness_center_rounded,
                          color: TrainerTheme.orange,
                          size: 20,
                        ),
                      );
                    },
                  ),
                ),
              ] else ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: TrainerTheme.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.fitness_center_rounded,
                    color: TrainerTheme.orange,
                    size: 20,
                  ),
                ),
              ],
              const SizedBox(width: 12),
              Text(
                gymName,
                style: TrainerTheme.headingSmall.copyWith(fontSize: 20),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: TrainerTheme.textSecondary),
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (mounted) {
                context.go(AppRoutes.login);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [TrainerTheme.orange, TrainerTheme.orangeDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.people_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total\nMembers',
                      style: TrainerTheme.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '${stats['member_count'] ?? 0}',
                  style: TrainerTheme.headingLarge.copyWith(
                    fontSize: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.trending_up_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+5%', // Placeholder for trend
                        style: TrainerTheme.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: TrainerTheme.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: TrainerTheme.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.fitness_center_rounded,
                      color: TrainerTheme.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Active Plans',
                      style: TrainerTheme.bodyMedium.copyWith(
                        color: TrainerTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  '${stats['plan_count'] ?? 0}',
                  style: TrainerTheme.headingLarge.copyWith(fontSize: 36),
                ),
                const SizedBox(height: 12),
                Text(
                  '+12% from last\nweek',
                  style: TrainerTheme.bodySmall.copyWith(
                    color: TrainerTheme.success,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberTile(Map<String, dynamic> assignmentData) {
    IconData statusIcon;
    Color statusColor;

    // Safety fallback for join data
    final memberNode = assignmentData['users'] as Map<String, dynamic>?;
    final String name = memberNode?['full_name'] ?? 'Unknown Member';
    final String memberId = memberNode?['id'] ?? '';

    // Determine plan status based on assigned plans
    final workouts = memberNode?['assigned_workouts'] as List?;
    final diets = memberNode?['assigned_diets'] as List?;
    final bool isActive =
        (workouts != null && workouts.isNotEmpty) ||
        (diets != null && diets.isNotEmpty);

    if (isActive) {
      statusIcon = Icons.check_circle_rounded;
      statusColor = TrainerTheme.success;
    } else {
      statusIcon = Icons.warning_rounded;
      statusColor = TrainerTheme.error;
    }

    return GestureDetector(
      onTap: () {
        context.push('${AppRoutes.trainerMemberDetail}?id=$memberId');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TrainerTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TrainerTheme.border, width: 1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: TrainerTheme.scaffold,
              // You would use backgroundImage here if URLs were provided
              child: const Icon(
                Icons.person,
                color: TrainerTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TrainerTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isActive ? 'Active Plan' : 'No Active Plan',
                    style: TrainerTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(statusIcon, color: statusColor, size: 20),
          ],
        ),
      ),
    );
  }
}

class _AllMembersScreen extends ConsumerWidget {
  final String trainerId;
  const _AllMembersScreen({required this.trainerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(assignedMembersProvider(trainerId));

    return Scaffold(
      backgroundColor: TrainerTheme.scaffold,
      appBar: AppBar(
        backgroundColor: TrainerTheme.scaffold,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: TrainerTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Assigned Members', style: TrainerTheme.headingSmall),
      ),
      body: membersAsync.when(
        data: (members) {
          if (members.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    color: TrainerTheme.textSecondary,
                    size: 56,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No members assigned yet',
                    style: TrainerTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final assignmentData = members[index];
              final memberNode =
                  assignmentData['users'] as Map<String, dynamic>?;
              final String name = memberNode?['full_name'] ?? 'Unknown Member';
              final String memberId = memberNode?['id'] ?? '';

              final workouts = memberNode?['assigned_workouts'] as List?;
              final diets = memberNode?['assigned_diets'] as List?;
              final bool isActive =
                  (workouts != null && workouts.isNotEmpty) ||
                  (diets != null && diets.isNotEmpty);

              return GestureDetector(
                onTap: () {
                  context.push('${AppRoutes.trainerMemberDetail}?id=$memberId');
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TrainerTheme.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: TrainerTheme.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: TrainerTheme.scaffold,
                        child: const Icon(
                          Icons.person,
                          color: TrainerTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TrainerTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isActive ? 'Active Plan' : 'No Active Plan',
                              style: TrainerTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isActive
                            ? Icons.check_circle_rounded
                            : Icons.warning_rounded,
                        color: isActive
                            ? TrainerTheme.success
                            : TrainerTheme.error,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: TrainerTheme.orange),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: TrainerTheme.error),
          ),
        ),
      ),
    );
  }
}

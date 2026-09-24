import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_management/core/router/app_router.dart';
import 'package:gym_management/core/theme/app_theme.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';
import 'package:gym_management/features/member/providers/workout_provider.dart';
import 'package:gym_management/features/shared/video_player_screen.dart';

class WorkoutScreen extends ConsumerWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authProvider).user?.id;
    if (userId == null) return const SizedBox.shrink();

    final workoutsAsync = ref.watch(assignedWorkoutsProvider(userId));
    final todayAsync = ref.watch(todayTrackingProvider(userId));
    final libraryAsync = ref.watch(memberExerciseLibraryProvider);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      appBar: AppBar(
        title: const Text('My Workouts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go(AppRoutes.memberDashboard),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildMuscleFocusCard(context, ref, userId),
            workoutsAsync.when(
              data: (workouts) {
                if (workouts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fitness_center_outlined,
                            color: AppTheme.textSecondary,
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No workout plans assigned yet',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Your trainer will assign one soon!',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    final assigned = workouts[index];
                    final plan = assigned['workout_plans'] as Map<String, dynamic>? ?? {};
                    final items = plan['workout_plan_items'] as List? ?? [];
                    final completedIds = todayAsync.whenOrNull(
                          data: (tracked) => tracked.map((t) => t['plan_item_id'] as String).toSet(),
                        ) ??
                        {};
                    final library = libraryAsync.whenOrNull(data: (d) => d) ?? [];

                    return _buildWorkoutPlanCard(
                      context,
                      ref,
                      userId,
                      plan,
                      items,
                      completedIds,
                      library,
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Error: $e',
                  style: const TextStyle(color: AppTheme.errorColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMuscleFocusCard(BuildContext context, WidgetRef ref, String userId) {
    final distributionAsync = ref.watch(muscleDistributionProvider(userId));

    return distributionAsync.when(
      data: (dist) {
        if (dist.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics_outlined, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Muscle Focus Today',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...dist.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${(entry.value * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: entry.value,
                          backgroundColor: AppTheme.borderDark,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildWorkoutPlanCard(
    BuildContext context,
    WidgetRef ref,
    String userId,
    Map<String, dynamic> plan,
    List items,
    Set completedIds,
    List<Map<String, dynamic>> library,
  ) {
    final planName = plan['name'] ?? 'Workout Plan';
    final totalExercises = items.length;
    final completedCount = items
        .where((i) => completedIds.contains(i['id']))
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planName,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completedCount / $totalExercises completed',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Progress circle
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    value: totalExercises > 0
                        ? completedCount / totalExercises
                        : 0,
                    backgroundColor: AppTheme.borderDark,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                    strokeWidth: 4,
                  ),
                ),
              ],
            ),
          ),

          // Exercise list
          ...items.map((item) {
            final exerciseName = item['exercise_name'] ?? 'Exercise';
            final sets = item['sets'] ?? '-';
            final reps = item['reps'] ?? '-';
            final isCompleted = completedIds.contains(item['id']);

            String? videoUrl;
            try {
              final match = library.firstWhere(
                (lib) =>
                    (lib['name']?.toString().toLowerCase() ?? '') ==
                    exerciseName.toString().toLowerCase(),
              );
              videoUrl = match['video_url'];
            } catch (_) {}

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.borderDark)),
              ),
              child: Row(
                children: [
                  // Checkbox
                  GestureDetector(
                    onTap: () async {
                      final repo = ref.read(workoutRepositoryProvider);
                      if (isCompleted) {
                        await repo.unlogWorkout(
                          userId: userId,
                          workoutPlanItemId: item['id'],
                        );
                      } else {
                        await repo.logWorkout(
                          userId: userId,
                          workoutPlanItemId: item['id'],
                          setsCompleted: sets is int ? sets : null,
                          repsCompleted: reps is int ? reps : null,
                          weightUsed: item['weight']?.toDouble(),
                        );

                        if (completedCount + 1 == totalExercises && context.mounted) {
                          _showWorkoutCompleteDialog(context, planName, items, library);
                        }
                      }
                      ref.invalidate(todayTrackingProvider(userId));
                      ref.invalidate(muscleDistributionProvider(userId));
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppTheme.successColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCompleted
                              ? AppTheme.successColor
                              : AppTheme.textSecondary,
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              exerciseName,
                              style: TextStyle(
                                color: isCompleted
                                    ? AppTheme.textSecondary
                                    : AppTheme.textPrimary,
                                fontWeight: FontWeight.w500,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            if (videoUrl != null && videoUrl.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VideoPlayerScreen(
                                        videoUrl: videoUrl!,
                                        title: exerciseName,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.play_circle_filled_rounded,
                                        color: AppTheme.primaryColor,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Video',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              '$sets sets × $reps reps',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            if (item['weight'] != null && (item['weight'] as num) > 0) ...[
                              const Text(
                                ' \u2022 ',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              ),
                              Text(
                                '${item['weight']} kg',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showWorkoutCompleteDialog(
    BuildContext context,
    String planName,
    List items,
    List<Map<String, dynamic>> library,
  ) {
    final Map<String, int> counts = {};
    int total = 0;

    for (var item in items) {
      final exerciseName = item['exercise_name']?.toString() ?? '';
      String? muscle;
      try {
        final match = library.firstWhere(
          (lib) =>
              (lib['name']?.toString().toLowerCase() ?? '') ==
              exerciseName.toLowerCase(),
        );
        muscle = match['muscle_group']?.toString();
      } catch (_) {}

      if (muscle != null) {
        counts[muscle] = (counts[muscle] ?? 0) + 1;
        total++;
      }
    }

    if (total == 0) return;

    final distribution = counts.map(
      (muscle, count) => MapEntry(muscle, count / total),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.5)),
          ),
          title: Column(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: Colors.amber,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Workout Complete!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                planName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(color: AppTheme.borderDark),
              const SizedBox(height: 12),
              const Text(
                'Muscle Focus Breakdown:',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ...distribution.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${(entry.value * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: entry.value,
                          backgroundColor: AppTheme.borderDark,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor,
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(color: AppTheme.primaryColor)),
            ),
          ],
        );
      },
    );
  }
}

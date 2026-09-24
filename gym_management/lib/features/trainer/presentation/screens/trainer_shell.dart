import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_management/core/router/app_router.dart';
import 'package:gym_management/core/utils/validators.dart';
import 'package:gym_management/features/trainer/presentation/theme/trainer_theme.dart';
import 'package:gym_management/features/trainer/presentation/screens/trainer_dashboard_screen.dart';
import 'package:gym_management/features/trainer/presentation/screens/trainer_profile_screen.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';
import 'package:gym_management/features/trainer/providers/trainer_provider.dart';

// Placeholder screens for other tabs
// Removed TrainerClientsScreen

class TrainerPlansScreen extends ConsumerWidget {
  const TrainerPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 24, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text('My Plans', style: TrainerTheme.headingLarge),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: TrainerTheme.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: TrainerTheme.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: TrainerTheme.textSecondary,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              dividerHeight: 0,
              tabs: const [
                Tab(text: 'Workout Plans'),
                Tab(text: 'Diet Plans'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(children: [_WorkoutPlansTab(), _DietPlansTab()]),
          ),
        ],
      ),
    );
  }
}

class _WorkoutPlansTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final trainerId = authState.user?.id;
    if (trainerId == null) return const SizedBox.shrink();

    final plansAsync = ref.watch(trainerWorkoutPlansProvider(trainerId));

    return plansAsync.when(
      data: (plans) {
        if (plans.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.fitness_center_outlined,
                  color: TrainerTheme.textSecondary,
                  size: 56,
                ),
                const SizedBox(height: 16),
                Text('No workout plans yet', style: TrainerTheme.bodyLarge),
                const SizedBox(height: 8),
                Text('Tap + to create one', style: TrainerTheme.bodySmall),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: plans.length,
          itemBuilder: (context, index) {
            final plan = plans[index];
            return GestureDetector(
              onTap: () => _showWorkoutDetail(context, ref, plan),
              child: _buildPlanCard(
                name: plan['name'] ?? 'Untitled',
                subtitle: plan['goal'] ?? '',
                difficulty: plan['difficulty'] ?? '',
                createdAt: plan['created_at'],
                icon: Icons.fitness_center_rounded,
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
    );
  }

  Widget _buildPlanCard({
    required String name,
    required String subtitle,
    required String difficulty,
    required dynamic createdAt,
    required IconData icon,
  }) {
    String dateStr = '';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt.toString());
        dateStr = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TrainerTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TrainerTheme.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TrainerTheme.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: TrainerTheme.orange),
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
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: TrainerTheme.bodySmall),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (difficulty.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: TrainerTheme.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    difficulty,
                    style: TrainerTheme.bodySmall.copyWith(
                      color: TrainerTheme.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (dateStr.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  dateStr,
                  style: TrainerTheme.bodySmall.copyWith(fontSize: 10),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showWorkoutDetail(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> plan,
  ) {
    final planId = plan['id'] as String;
    final repo = ref.read(trainerRepositoryProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: TrainerTheme.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return FutureBuilder(
              future: Future.wait([
                repo.getWorkoutPlanDetail(planId),
                repo.getMembersUsingWorkoutPlan(planId),
              ]),
              builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: TrainerTheme.orange,
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: TrainerTheme.error),
                      ),
                    ),
                  );
                }

                final detail = snapshot.data![0] as Map<String, dynamic>;
                final members = snapshot.data![1] as List<Map<String, dynamic>>;
                final items = List<dynamic>.from(
                  detail['workout_plan_items'] as List? ?? [],
                );

                return DraggableScrollableSheet(
                  initialChildSize: 0.7,
                  minChildSize: 0.4,
                  maxChildSize: 0.9,
                  expand: false,
                  builder: (context, scrollController) {
                    return SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: TrainerTheme.border,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  detail['name'] ?? 'Plan',
                                  style: TrainerTheme.headingMedium,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_rounded,
                                      color: TrainerTheme.orange,
                                    ),
                                    onPressed: () =>
                                        _editWorkoutPlan(context, ref, detail),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_rounded,
                                      color: TrainerTheme.error,
                                    ),
                                    onPressed: () => _deleteWorkoutPlan(
                                      context,
                                      ref,
                                      planId,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if ((detail['goal'] ?? '').toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Goal: ${detail['goal']}',
                                style: TrainerTheme.bodySmall,
                              ),
                            ),
                          const SizedBox(height: 24),

                          // Exercises
                          Text(
                            'Exercises (${items.length})',
                            style: TrainerTheme.headingSmall,
                          ),
                          const SizedBox(height: 12),
                          if (items.isEmpty)
                            Text(
                              'No exercises added yet.',
                              style: TrainerTheme.bodySmall,
                            )
                          else
                            ...items.map((item) {
                              final dayNum = item['day_number'] ?? 0;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: TrainerTheme.scaffold,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: TrainerTheme.orange.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'D$dayNum',
                                          style: TrainerTheme.bodySmall
                                              .copyWith(
                                                color: TrainerTheme.orange,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['exercise_name'] ?? '',
                                            style: TrainerTheme.bodyLarge
                                                .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          Text(
                                            '${item['sets'] ?? '-'} sets \u00d7 ${item['reps'] ?? '-'} reps',
                                            style: TrainerTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Edit exercise
                                    GestureDetector(
                                      onTap: () {
                                        final nameCtrl = TextEditingController(
                                          text: item['exercise_name'] ?? '',
                                        );
                                        final setsCtrl = TextEditingController(
                                          text: '${item['sets'] ?? 3}',
                                        );
                                        final repsCtrl = TextEditingController(
                                          text: '${item['reps'] ?? 12}',
                                        );
                                        showDialog(
                                          context: sheetCtx,
                                          builder: (dlgCtx) => AlertDialog(
                                            backgroundColor: TrainerTheme.card,
                                            title: Text(
                                              'Edit Exercise',
                                              style: TrainerTheme.headingSmall,
                                            ),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextField(
                                                  controller: nameCtrl,
                                                  style: const TextStyle(
                                                    color: TrainerTheme
                                                        .textPrimary,
                                                  ),
                                                  decoration: InputDecoration(
                                                    labelText: 'Exercise Name',
                                                    labelStyle:
                                                        TrainerTheme.bodySmall,
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide(
                                                                color:
                                                                    TrainerTheme
                                                                        .border,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                          borderSide:
                                                              const BorderSide(
                                                                color:
                                                                    TrainerTheme
                                                                        .orange,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: TextField(
                                                        controller: setsCtrl,
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        style: const TextStyle(
                                                          color: TrainerTheme
                                                              .textPrimary,
                                                        ),
                                                        decoration: InputDecoration(
                                                          labelText: 'Sets',
                                                          labelStyle:
                                                              TrainerTheme
                                                                  .bodySmall,
                                                          enabledBorder: OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                              color:
                                                                  TrainerTheme
                                                                      .border,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderSide:
                                                                const BorderSide(
                                                                  color:
                                                                      TrainerTheme
                                                                          .orange,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: TextField(
                                                        controller: repsCtrl,
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        style: const TextStyle(
                                                          color: TrainerTheme
                                                              .textPrimary,
                                                        ),
                                                        decoration: InputDecoration(
                                                          labelText: 'Reps',
                                                          labelStyle:
                                                              TrainerTheme
                                                                  .bodySmall,
                                                          enabledBorder: OutlineInputBorder(
                                                            borderSide: BorderSide(
                                                              color:
                                                                  TrainerTheme
                                                                      .border,
                                                            ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          focusedBorder: OutlineInputBorder(
                                                            borderSide:
                                                                const BorderSide(
                                                                  color:
                                                                      TrainerTheme
                                                                          .orange,
                                                                ),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(dlgCtx),
                                                child: Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                    color: TrainerTheme
                                                        .textSecondary,
                                                  ),
                                                ),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      TrainerTheme.orange,
                                                ),
                                                onPressed: () async {
                                                  final name = nameCtrl.text.trim();
                                                  final setsStr = setsCtrl.text.trim();
                                                  final repsStr = repsCtrl.text.trim();

                                                  if (name.isEmpty) {
                                                    ScaffoldMessenger.of(dlgCtx).showSnackBar(
                                                      const SnackBar(content: Text('Please enter exercise name')),
                                                    );
                                                    return;
                                                  }

                                                  final setsError = Validators.validatePositiveInteger(setsStr, 'Sets');
                                                  if (setsError != null) {
                                                    ScaffoldMessenger.of(dlgCtx).showSnackBar(
                                                      SnackBar(content: Text(setsError), backgroundColor: TrainerTheme.error),
                                                    );
                                                    return;
                                                  }

                                                  final repsError = Validators.validatePositiveInteger(repsStr, 'Reps');
                                                  if (repsError != null) {
                                                    ScaffoldMessenger.of(dlgCtx).showSnackBar(
                                                      SnackBar(content: Text(repsError), backgroundColor: TrainerTheme.error),
                                                    );
                                                    return;
                                                  }

                                                  await repo
                                                      .updateWorkoutPlanItem(
                                                        itemId: item['id'],
                                                        exerciseName: name,
                                                        sets:
                                                            int.parse(setsStr),
                                                        reps:
                                                            int.parse(repsStr),
                                                      );
                                                  if (dlgCtx.mounted) {
                                                    Navigator.pop(dlgCtx);
                                                  }
                                                  setSheetState(
                                                    () {},
                                                  ); // refresh
                                                },
                                                child: const Text(
                                                  'Save',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                          color: TrainerTheme.orange,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    // Delete exercise
                                    GestureDetector(
                                      onTap: () async {
                                        await repo.deleteWorkoutPlanItem(
                                          item['id'],
                                        );
                                        setSheetState(() {}); // refresh
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 18,
                                          color: TrainerTheme.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                          // Add Exercise button
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              final nameCtrl = TextEditingController();
                              final setsCtrl = TextEditingController(text: '3');
                              final repsCtrl = TextEditingController(
                                text: '12',
                              );
                              final dayCtrl = TextEditingController(text: '1');
                              showDialog(
                                context: sheetCtx,
                                builder: (dlgCtx) => AlertDialog(
                                  backgroundColor: TrainerTheme.card,
                                  title: Text(
                                    'Add Exercise',
                                    style: TrainerTheme.headingSmall,
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: nameCtrl,
                                        style: const TextStyle(
                                          color: TrainerTheme.textPrimary,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: 'Exercise Name',
                                          labelStyle: TrainerTheme.bodySmall,
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: TrainerTheme.border,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: TrainerTheme.orange,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      TextField(
                                        controller: dayCtrl,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(
                                          color: TrainerTheme.textPrimary,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: 'Day Number',
                                          labelStyle: TrainerTheme.bodySmall,
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: TrainerTheme.border,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: TrainerTheme.orange,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: setsCtrl,
                                              keyboardType:
                                                  TextInputType.number,
                                              style: const TextStyle(
                                                color: TrainerTheme.textPrimary,
                                              ),
                                              decoration: InputDecoration(
                                                labelText: 'Sets',
                                                labelStyle:
                                                    TrainerTheme.bodySmall,
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            TrainerTheme.border,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderSide:
                                                          const BorderSide(
                                                            color: TrainerTheme
                                                                .orange,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: TextField(
                                              controller: repsCtrl,
                                              keyboardType:
                                                  TextInputType.number,
                                              style: const TextStyle(
                                                color: TrainerTheme.textPrimary,
                                              ),
                                              decoration: InputDecoration(
                                                labelText: 'Reps',
                                                labelStyle:
                                                    TrainerTheme.bodySmall,
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            TrainerTheme.border,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderSide:
                                                          const BorderSide(
                                                            color: TrainerTheme
                                                                .orange,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dlgCtx),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: TrainerTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: TrainerTheme.orange,
                                      ),
                                      onPressed: () async {
                                        final name = nameCtrl.text.trim();
                                        if (name.isEmpty) {
                                          ScaffoldMessenger.of(dlgCtx).showSnackBar(
                                            const SnackBar(content: Text('Please enter exercise name')),
                                          );
                                          return;
                                        }

                                        final setsStr = setsCtrl.text.trim();
                                        final repsStr = repsCtrl.text.trim();
                                        final dayStr = dayCtrl.text.trim();

                                        final setsError = Validators.validatePositiveInteger(setsStr, 'Sets');
                                        if (setsError != null) {
                                          ScaffoldMessenger.of(dlgCtx).showSnackBar(
                                            SnackBar(content: Text(setsError), backgroundColor: TrainerTheme.error),
                                          );
                                          return;
                                        }

                                        final repsError = Validators.validatePositiveInteger(repsStr, 'Reps');
                                        if (repsError != null) {
                                          ScaffoldMessenger.of(dlgCtx).showSnackBar(
                                            SnackBar(content: Text(repsError), backgroundColor: TrainerTheme.error),
                                          );
                                          return;
                                        }

                                        final dayError = Validators.validatePositiveInteger(dayStr, 'Day');
                                        if (dayError != null) {
                                          ScaffoldMessenger.of(dlgCtx).showSnackBar(
                                            SnackBar(content: Text(dayError), backgroundColor: TrainerTheme.error),
                                          );
                                          return;
                                        }

                                        await repo.addWorkoutPlanItems(planId, [
                                          {
                                            'exercise_name': name,
                                            'day_number': int.parse(dayStr),
                                            'sets': int.parse(setsStr),
                                            'reps': int.parse(repsStr),
                                          },
                                        ]);
                                        if (dlgCtx.mounted) {
                                          Navigator.pop(dlgCtx);
                                        }
                                        setSheetState(() {});
                                      },
                                      child: const Text(
                                        'Add',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: TrainerTheme.orange,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_rounded,
                                    color: TrainerTheme.orange,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Add Exercise',
                                    style: TrainerTheme.bodyMedium.copyWith(
                                      color: TrainerTheme.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          // Assigned members
                          Text(
                            'Assigned Members (${members.length})',
                            style: TrainerTheme.headingSmall,
                          ),
                          const SizedBox(height: 12),
                          if (members.isEmpty)
                            Text(
                              'Not assigned to anyone yet.',
                              style: TrainerTheme.bodySmall,
                            )
                          else
                            ...members.map(
                              (m) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const CircleAvatar(
                                  backgroundColor: TrainerTheme.scaffold,
                                  child: Icon(
                                    Icons.person,
                                    color: TrainerTheme.textSecondary,
                                  ),
                                ),
                                title: Text(
                                  m['full_name'] ?? 'Unknown',
                                  style: TrainerTheme.bodyLarge,
                                ),
                                subtitle: Text(
                                  m['email'] ?? '',
                                  style: TrainerTheme.bodySmall,
                                ),
                                trailing: GestureDetector(
                                  onTap: () async {
                                    await repo.unassignWorkoutPlan(
                                      planId: planId,
                                      userId: m['id'],
                                    );
                                    setSheetState(() {}); // refresh
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: TrainerTheme.error.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Unassign',
                                      style: TrainerTheme.bodySmall.copyWith(
                                        color: TrainerTheme.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // Assign member button
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              final authState = ref.read(authProvider);
                              final trainerId = authState.user?.id;
                              if (trainerId == null) return;
                              final allMembersData = await repo
                                  .getAssignedMembers(trainerId);
                              final allMembers = allMembersData
                                  .map(
                                    (m) => m['users'] as Map<String, dynamic>,
                                  )
                                  .toList();
                              final assignedIds = members
                                  .map((m) => m['id'])
                                  .toSet();
                              final available = allMembers
                                  .where((m) => !assignedIds.contains(m['id']))
                                  .toList();
                              if (!sheetCtx.mounted) return;
                              showDialog(
                                context: sheetCtx,
                                builder: (dlgCtx) => AlertDialog(
                                  backgroundColor: TrainerTheme.card,
                                  title: Text(
                                    'Assign Member',
                                    style: TrainerTheme.headingSmall,
                                  ),
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    child: available.isEmpty
                                        ? Text(
                                            'No available members.',
                                            style: TrainerTheme.bodySmall,
                                          )
                                        : ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: available.length,
                                            itemBuilder: (ctx2, i) {
                                              final member = available[i];
                                              return ListTile(
                                                leading: const CircleAvatar(
                                                  backgroundColor:
                                                      TrainerTheme.scaffold,
                                                  child: Icon(
                                                    Icons.person,
                                                    color: TrainerTheme
                                                        .textSecondary,
                                                  ),
                                                ),
                                                title: Text(
                                                  member['full_name'] ??
                                                      'Unknown',
                                                  style: TrainerTheme.bodyLarge,
                                                ),
                                                subtitle: Text(
                                                  member['email'] ?? '',
                                                  style: TrainerTheme.bodySmall,
                                                ),
                                                onTap: () async {
                                                  await repo.assignWorkoutPlan(
                                                    trainerId: trainerId,
                                                    memberId: member['id'],
                                                    planId: planId,
                                                  );
                                                  if (dlgCtx.mounted) {
                                                    Navigator.pop(dlgCtx);
                                                  }
                                                  setSheetState(() {});
                                                },
                                              );
                                            },
                                          ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dlgCtx),
                                      child: Text(
                                        'Close',
                                        style: TextStyle(
                                          color: TrainerTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: TrainerTheme.orange,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.person_add_rounded,
                                    color: TrainerTheme.orange,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Assign Member',
                                    style: TrainerTheme.bodyMedium.copyWith(
                                      color: TrainerTheme.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _editWorkoutPlan(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> plan,
  ) {
    final nameCtrl = TextEditingController(text: plan['name'] ?? '');
    final goalCtrl = TextEditingController(text: plan['goal'] ?? '');
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TrainerTheme.card,
        title: Text('Edit Plan', style: TrainerTheme.headingSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: TrainerTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Plan Name',
                labelStyle: TrainerTheme.bodySmall,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: TrainerTheme.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: TrainerTheme.orange),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: goalCtrl,
              style: const TextStyle(color: TrainerTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Goal',
                labelStyle: TrainerTheme.bodySmall,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: TrainerTheme.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: TrainerTheme.orange),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: TrainerTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TrainerTheme.orange,
            ),
            onPressed: () async {
              final repo = ref.read(trainerRepositoryProvider);
              await repo.updateWorkoutPlan(
                planId: plan['id'],
                name: nameCtrl.text.trim(),
                goal: goalCtrl.text.trim(),
              );
              final trainerId = ref.read(authProvider).user?.id;
              if (trainerId != null) {
                ref.invalidate(trainerWorkoutPlansProvider(trainerId));
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteWorkoutPlan(BuildContext context, WidgetRef ref, String planId) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TrainerTheme.card,
        title: Text('Delete Plan?', style: TrainerTheme.headingSmall),
        content: Text(
          'This will remove the plan and all assignments. This cannot be undone.',
          style: TrainerTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: TrainerTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TrainerTheme.error,
            ),
            onPressed: () async {
              final repo = ref.read(trainerRepositoryProvider);
              await repo.deleteWorkoutPlan(planId);
              final trainerId = ref.read(authProvider).user?.id;
              if (trainerId != null) {
                ref.invalidate(trainerWorkoutPlansProvider(trainerId));
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _DietPlansTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final trainerId = authState.user?.id;
    if (trainerId == null) return const SizedBox.shrink();

    final plansAsync = ref.watch(trainerDietPlansProvider(trainerId));

    return plansAsync.when(
      data: (plans) {
        if (plans.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.restaurant_menu_outlined,
                  color: TrainerTheme.textSecondary,
                  size: 56,
                ),
                const SizedBox(height: 16),
                Text('No diet plans yet', style: TrainerTheme.bodyLarge),
                const SizedBox(height: 8),
                Text('Tap + to create one', style: TrainerTheme.bodySmall),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: plans.length,
          itemBuilder: (context, index) {
            final plan = plans[index];
            final calories = plan['calories_target'] ?? plan['daily_calories'];
            return GestureDetector(
              onTap: () => _showDietDetail(context, ref, plan),
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: TrainerTheme.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        color: TrainerTheme.success,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan['title'] ?? plan['name'] ?? 'Untitled',
                            style: TrainerTheme.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (calories != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '$calories kcal/day',
                              style: TrainerTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
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
    );
  }

  void _showDietDetail(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> plan,
  ) {
    final planId = plan['id'] as String;
    final repo = ref.read(trainerRepositoryProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: TrainerTheme.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return FutureBuilder(
              future: Future.wait([
                repo.getDietPlanDetail(planId),
                repo.getMembersUsingDietPlan(planId),
              ]),
              builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: TrainerTheme.orange,
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return SizedBox(
                    height: 200,
                    child: Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: TrainerTheme.error),
                      ),
                    ),
                  );
                }

                final detail = snapshot.data![0] as Map<String, dynamic>;
                final members = snapshot.data![1] as List<Map<String, dynamic>>;
                final items = List<dynamic>.from(
                  detail['diet_plan_items'] as List? ?? [],
                );
                final calories =
                    detail['calories_target'] ?? detail['daily_calories'];

                return DraggableScrollableSheet(
                  initialChildSize: 0.7,
                  minChildSize: 0.4,
                  maxChildSize: 0.9,
                  expand: false,
                  builder: (context, scrollController) {
                    return SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: TrainerTheme.border,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  detail['title'] ??
                                      detail['name'] ??
                                      'Diet Plan',
                                  style: TrainerTheme.headingMedium,
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_rounded,
                                      color: TrainerTheme.orange,
                                    ),
                                    onPressed: () =>
                                        _editDietPlan(context, ref, detail),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_rounded,
                                      color: TrainerTheme.error,
                                    ),
                                    onPressed: () =>
                                        _deleteDietPlan(context, ref, planId),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (calories != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '$calories kcal/day',
                                style: TrainerTheme.bodySmall.copyWith(
                                  color: TrainerTheme.orange,
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),

                          Text(
                            'Meals (${items.length})',
                            style: TrainerTheme.headingSmall,
                          ),
                          const SizedBox(height: 12),
                          if (items.isEmpty)
                            Text(
                              'No meals added yet.',
                              style: TrainerTheme.bodySmall,
                            )
                          else
                            ...items.map((item) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: TrainerTheme.scaffold,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: TrainerTheme.success.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.restaurant,
                                        color: TrainerTheme.success,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['food_item'] ?? '',
                                            style: TrainerTheme.bodyLarge
                                                .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          Text(
                                            '${item['meal_time'] ?? 'Meal'} \u00b7 Day ${item['day_number'] ?? '-'}${item['calories'] != null ? ' \u00b7 ${item['calories']} kcal' : ''}',
                                            style: TrainerTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Edit meal
                                    GestureDetector(
                                      onTap: () {
                                        final foodCtrl = TextEditingController(
                                          text: item['food_item'] ?? '',
                                        );
                                        final mealCtrl = TextEditingController(
                                          text: item['meal_time'] ?? '',
                                        );
                                        final calCtrl = TextEditingController(
                                          text: '${item['calories'] ?? ''}',
                                        );
                                        showDialog(
                                          context: sheetCtx,
                                          builder: (dlgCtx) => AlertDialog(
                                            backgroundColor: TrainerTheme.card,
                                            title: Text(
                                              'Edit Meal',
                                              style: TrainerTheme.headingSmall,
                                            ),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextField(
                                                  controller: foodCtrl,
                                                  style: const TextStyle(
                                                    color: TrainerTheme
                                                        .textPrimary,
                                                  ),
                                                  decoration: InputDecoration(
                                                    labelText: 'Food Item',
                                                    labelStyle:
                                                        TrainerTheme.bodySmall,
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide(
                                                                color:
                                                                    TrainerTheme
                                                                        .border,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                          borderSide:
                                                              const BorderSide(
                                                                color:
                                                                    TrainerTheme
                                                                        .orange,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                TextField(
                                                  controller: mealCtrl,
                                                  style: const TextStyle(
                                                    color: TrainerTheme
                                                        .textPrimary,
                                                  ),
                                                  decoration: InputDecoration(
                                                    labelText: 'Meal Time',
                                                    labelStyle:
                                                        TrainerTheme.bodySmall,
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide(
                                                                color:
                                                                    TrainerTheme
                                                                        .border,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                          borderSide:
                                                              const BorderSide(
                                                                color:
                                                                    TrainerTheme
                                                                        .orange,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                TextField(
                                                  controller: calCtrl,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  style: const TextStyle(
                                                    color: TrainerTheme
                                                        .textPrimary,
                                                  ),
                                                  decoration: InputDecoration(
                                                    labelText: 'Calories',
                                                    labelStyle:
                                                        TrainerTheme.bodySmall,
                                                    enabledBorder:
                                                        OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide(
                                                                color:
                                                                    TrainerTheme
                                                                        .border,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                          borderSide:
                                                              const BorderSide(
                                                                color:
                                                                    TrainerTheme
                                                                        .orange,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(dlgCtx),
                                                child: Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                    color: TrainerTheme
                                                        .textSecondary,
                                                  ),
                                                ),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      TrainerTheme.orange,
                                                ),
                                                onPressed: () async {
                                                  final foodItem = foodCtrl.text.trim();
                                                  final mealTime = mealCtrl.text.trim();
                                                  final caloriesStr = calCtrl.text.trim();

                                                  if (foodItem.isEmpty) {
                                                    ScaffoldMessenger.of(dlgCtx).showSnackBar(
                                                      const SnackBar(content: Text('Please enter food item')),
                                                    );
                                                    return;
                                                  }

                                                  final calError = Validators.validatePositiveInteger(caloriesStr, 'Calories');
                                                  if (calError != null) {
                                                    ScaffoldMessenger.of(dlgCtx).showSnackBar(
                                                      SnackBar(content: Text(calError), backgroundColor: TrainerTheme.error),
                                                    );
                                                    return;
                                                  }

                                                  await repo.updateDietPlanItem(
                                                    itemId: item['id'],
                                                    foodItem: foodItem,
                                                    mealTime: mealTime,
                                                    calories: int.parse(caloriesStr),
                                                  );
                                                  if (dlgCtx.mounted) {
                                                    Navigator.pop(dlgCtx);
                                                  }
                                                  setSheetState(() {});
                                                },
                                                child: const Text(
                                                  'Save',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                          color: TrainerTheme.orange,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    // Delete meal
                                    GestureDetector(
                                      onTap: () async {
                                        await repo.deleteDietPlanItem(
                                          item['id'],
                                        );
                                        setSheetState(() {});
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 18,
                                          color: TrainerTheme.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                          // Add Meal button
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              final foodCtrl = TextEditingController();
                              final mealCtrl = TextEditingController();
                              final calCtrl = TextEditingController(text: '0');
                              final dayCtrl = TextEditingController(text: '1');
                              showDialog(
                                context: sheetCtx,
                                builder: (dlgCtx) => AlertDialog(
                                  backgroundColor: TrainerTheme.card,
                                  title: Text(
                                    'Add Meal',
                                    style: TrainerTheme.headingSmall,
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: foodCtrl,
                                        style: const TextStyle(
                                          color: TrainerTheme.textPrimary,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: 'Food Item',
                                          labelStyle: TrainerTheme.bodySmall,
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: TrainerTheme.border,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: TrainerTheme.orange,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      TextField(
                                        controller: mealCtrl,
                                        style: const TextStyle(
                                          color: TrainerTheme.textPrimary,
                                        ),
                                        decoration: InputDecoration(
                                          labelText:
                                              'Meal Time (e.g. Breakfast)',
                                          labelStyle: TrainerTheme.bodySmall,
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: TrainerTheme.border,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: const BorderSide(
                                              color: TrainerTheme.orange,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: dayCtrl,
                                              keyboardType:
                                                  TextInputType.number,
                                              style: const TextStyle(
                                                color: TrainerTheme.textPrimary,
                                              ),
                                              decoration: InputDecoration(
                                                labelText: 'Day',
                                                labelStyle:
                                                    TrainerTheme.bodySmall,
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            TrainerTheme.border,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderSide:
                                                          const BorderSide(
                                                            color: TrainerTheme
                                                                .orange,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: TextField(
                                              controller: calCtrl,
                                              keyboardType:
                                                  TextInputType.number,
                                              style: const TextStyle(
                                                color: TrainerTheme.textPrimary,
                                              ),
                                              decoration: InputDecoration(
                                                labelText: 'Calories',
                                                labelStyle:
                                                    TrainerTheme.bodySmall,
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderSide: BorderSide(
                                                        color:
                                                            TrainerTheme.border,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderSide:
                                                          const BorderSide(
                                                            color: TrainerTheme
                                                                .orange,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dlgCtx),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: TrainerTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: TrainerTheme.orange,
                                      ),
                                      onPressed: () async {
                                        final foodItem = foodCtrl.text.trim();
                                        final mealTime = mealCtrl.text.trim();
                                        final dayStr = dayCtrl.text.trim();
                                        final calStr = calCtrl.text.trim();

                                        if (foodItem.isEmpty) {
                                          ScaffoldMessenger.of(dlgCtx).showSnackBar(
                                            const SnackBar(content: Text('Please enter food item')),
                                          );
                                          return;
                                        }

                                        final dayError = Validators.validatePositiveInteger(dayStr, 'Day');
                                        if (dayError != null) {
                                          ScaffoldMessenger.of(dlgCtx).showSnackBar(
                                            SnackBar(content: Text(dayError), backgroundColor: TrainerTheme.error),
                                          );
                                          return;
                                        }

                                        final calError = Validators.validatePositiveInteger(calStr, 'Calories');
                                        if (calError != null) {
                                          ScaffoldMessenger.of(dlgCtx).showSnackBar(
                                            SnackBar(content: Text(calError), backgroundColor: TrainerTheme.error),
                                          );
                                          return;
                                        }

                                        await repo.addDietPlanItems(planId, [
                                          {
                                            'food_item': foodItem,
                                            'meal_time': mealTime,
                                            'day_number': int.parse(dayStr),
                                            'calories': int.parse(calStr),
                                          },
                                        ]);
                                        if (dlgCtx.mounted) {
                                          Navigator.pop(dlgCtx);
                                        }
                                        setSheetState(() {});
                                      },
                                      child: const Text(
                                        'Add',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: TrainerTheme.orange,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.add_rounded,
                                    color: TrainerTheme.orange,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Add Meal',
                                    style: TrainerTheme.bodyMedium.copyWith(
                                      color: TrainerTheme.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),
                          Text(
                            'Assigned Members (${members.length})',
                            style: TrainerTheme.headingSmall,
                          ),
                          const SizedBox(height: 12),
                          if (members.isEmpty)
                            Text(
                              'Not assigned to anyone yet.',
                              style: TrainerTheme.bodySmall,
                            )
                          else
                            ...members.map(
                              (m) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const CircleAvatar(
                                  backgroundColor: TrainerTheme.scaffold,
                                  child: Icon(
                                    Icons.person,
                                    color: TrainerTheme.textSecondary,
                                  ),
                                ),
                                title: Text(
                                  m['full_name'] ?? 'Unknown',
                                  style: TrainerTheme.bodyLarge,
                                ),
                                subtitle: Text(
                                  m['email'] ?? '',
                                  style: TrainerTheme.bodySmall,
                                ),
                                trailing: GestureDetector(
                                  onTap: () async {
                                    await repo.unassignDietPlan(
                                      planId: planId,
                                      userId: m['id'],
                                    );
                                    setSheetState(() {});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: TrainerTheme.error.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Unassign',
                                      style: TrainerTheme.bodySmall.copyWith(
                                        color: TrainerTheme.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          // Assign member button (diet)
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              final authState = ref.read(authProvider);
                              final trainerId = authState.user?.id;
                              if (trainerId == null) return;
                              final allMembersData = await repo
                                  .getAssignedMembers(trainerId);
                              final allMembers = allMembersData
                                  .map(
                                    (m) => m['users'] as Map<String, dynamic>,
                                  )
                                  .toList();
                              final assignedIds = members
                                  .map((m) => m['id'])
                                  .toSet();
                              final available = allMembers
                                  .where((m) => !assignedIds.contains(m['id']))
                                  .toList();
                              if (!sheetCtx.mounted) return;
                              showDialog(
                                context: sheetCtx,
                                builder: (dlgCtx) => AlertDialog(
                                  backgroundColor: TrainerTheme.card,
                                  title: Text(
                                    'Assign Member',
                                    style: TrainerTheme.headingSmall,
                                  ),
                                  content: SizedBox(
                                    width: double.maxFinite,
                                    child: available.isEmpty
                                        ? Text(
                                            'No available members.',
                                            style: TrainerTheme.bodySmall,
                                          )
                                        : ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: available.length,
                                            itemBuilder: (ctx2, i) {
                                              final member = available[i];
                                              return ListTile(
                                                leading: const CircleAvatar(
                                                  backgroundColor:
                                                      TrainerTheme.scaffold,
                                                  child: Icon(
                                                    Icons.person,
                                                    color: TrainerTheme
                                                        .textSecondary,
                                                  ),
                                                ),
                                                title: Text(
                                                  member['full_name'] ??
                                                      'Unknown',
                                                  style: TrainerTheme.bodyLarge,
                                                ),
                                                subtitle: Text(
                                                  member['email'] ?? '',
                                                  style: TrainerTheme.bodySmall,
                                                ),
                                                onTap: () async {
                                                  await repo.assignDietPlan(
                                                    trainerId: trainerId,
                                                    memberId: member['id'],
                                                    planId: planId,
                                                  );
                                                  if (dlgCtx.mounted) {
                                                    Navigator.pop(dlgCtx);
                                                  }
                                                  setSheetState(() {});
                                                },
                                              );
                                            },
                                          ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dlgCtx),
                                      child: Text(
                                        'Close',
                                        style: TextStyle(
                                          color: TrainerTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: TrainerTheme.orange,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.person_add_rounded,
                                    color: TrainerTheme.orange,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Assign Member',
                                    style: TrainerTheme.bodyMedium.copyWith(
                                      color: TrainerTheme.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _editDietPlan(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> plan,
  ) {
    final titleCtrl = TextEditingController(
      text: plan['title'] ?? plan['name'] ?? '',
    );
    final calCtrl = TextEditingController(
      text: (plan['calories_target'] ?? plan['daily_calories'] ?? '')
          .toString(),
    );
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TrainerTheme.card,
        title: Text('Edit Diet Plan', style: TrainerTheme.headingSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              style: const TextStyle(color: TrainerTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: TrainerTheme.bodySmall,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: TrainerTheme.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: TrainerTheme.orange),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: calCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: TrainerTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Daily Calories',
                labelStyle: TrainerTheme.bodySmall,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: TrainerTheme.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: TrainerTheme.orange),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: TrainerTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TrainerTheme.orange,
            ),
            onPressed: () async {
              final repo = ref.read(trainerRepositoryProvider);
              await repo.updateDietPlan(
                planId: plan['id'],
                title: titleCtrl.text.trim(),
                dailyCalories: int.tryParse(calCtrl.text.trim()) ?? 2000,
              );
              final trainerId = ref.read(authProvider).user?.id;
              if (trainerId != null) {
                ref.invalidate(trainerDietPlansProvider(trainerId));
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteDietPlan(BuildContext context, WidgetRef ref, String planId) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TrainerTheme.card,
        title: Text('Delete Diet Plan?', style: TrainerTheme.headingSmall),
        content: Text(
          'This will remove the plan and all assignments. This cannot be undone.',
          style: TrainerTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: TrainerTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TrainerTheme.error,
            ),
            onPressed: () async {
              final repo = ref.read(trainerRepositoryProvider);
              await repo.deleteDietPlan(planId);
              final trainerId = ref.read(authProvider).user?.id;
              if (trainerId != null) {
                ref.invalidate(trainerDietPlansProvider(trainerId));
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class TrainerShell extends ConsumerStatefulWidget {
  const TrainerShell({super.key});

  @override
  ConsumerState<TrainerShell> createState() => _TrainerShellState();
}

class _TrainerShellState extends ConsumerState<TrainerShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    TrainerDashboardScreen(),
    TrainerProfileScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  void _onFabTapped() {
    // Show Action Sheet for New Plan (Workout / Diet)
    showModalBottomSheet(
      context: context,
      backgroundColor: TrainerTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _buildNewPlanBottomSheet(context),
    );
  }

  Widget _buildNewPlanBottomSheet(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: TrainerTheme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Create New Plan', style: TrainerTheme.headingMedium),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(
              Icons.fitness_center,
              color: TrainerTheme.orange,
            ),
            title: Text('Workout Plan', style: TrainerTheme.bodyLarge),
            subtitle: Text(
              'Create a new workout schedule',
              style: TrainerTheme.bodySmall,
            ),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.trainerCreateWorkout);
            },
          ),
          const Divider(color: TrainerTheme.border),
          ListTile(
            leading: const Icon(
              Icons.restaurant_menu,
              color: TrainerTheme.orange,
            ),
            title: Text('Diet Plan', style: TrainerTheme.bodyLarge),
            subtitle: Text(
              'Create a new nutrition plan',
              style: TrainerTheme.bodySmall,
            ),
            onTap: () {
              Navigator.pop(context);
              context.push(AppRoutes.trainerCreateDiet);
            },
          ),
          const Divider(color: TrainerTheme.border),
          ListTile(
            leading: const Icon(
              Icons.assignment_rounded,
              color: TrainerTheme.orange,
            ),
            title: Text('Manage Plans', style: TrainerTheme.bodyLarge),
            subtitle: Text(
              'View and edit your existing plans',
              style: TrainerTheme.bodySmall,
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const Scaffold(
                  backgroundColor: TrainerTheme.scaffold,
                  body: SafeArea(child: TrainerPlansScreen()),
                )),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TrainerTheme.scaffold,
      extendBody: true, // Needed for floating nav bar to sit over background
      body: IndexedStack(index: _currentIndex, children: _pages),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(top: 40),
        child: FloatingActionButton(
          onPressed: _onFabTapped,
          backgroundColor: TrainerTheme.orange,
          elevation: 6,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildFloatingBottomBar(),
    );
  }

  Widget _buildFloatingBottomBar() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Slightly lighter than scaffold
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: TrainerTheme.border, width: 0.5),
        ),
      child: BottomAppBar(
        color: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard'),
            const SizedBox(width: 48), // Spacer for FAB notch
            _buildNavItem(1, Icons.person_rounded, 'Profile'),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? TrainerTheme.orange : TrainerTheme.textSecondary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTabTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

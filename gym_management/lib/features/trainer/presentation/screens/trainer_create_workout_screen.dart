import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';
import 'package:gym_management/features/trainer/presentation/theme/trainer_theme.dart';
import 'package:gym_management/features/trainer/providers/trainer_provider.dart';
import 'package:gym_management/core/utils/validators.dart';
import 'package:gym_management/features/admin/providers/admin_providers.dart';
import 'package:gym_management/features/shared/video_player_screen.dart';

class TrainerCreateWorkoutScreen extends ConsumerStatefulWidget {
  const TrainerCreateWorkoutScreen({super.key});

  @override
  ConsumerState<TrainerCreateWorkoutScreen> createState() =>
      _TrainerCreateWorkoutScreenState();
}

class _TrainerCreateWorkoutScreenState
    extends ConsumerState<TrainerCreateWorkoutScreen> {
  final _planNameController = TextEditingController();
  String _goal = 'Muscle Gain';
  bool _isSaving = false;

  // Dynamic data representing the structured day-wise plan
  final List<Map<String, dynamic>> _days = [
    {'day': 1, 'title': 'Day 1', 'exercises': <dynamic>[]},
  ];

  void _addDay() {
    setState(() {
      final newDay = _days.length + 1;
      _days.add({
        'day': newDay,
        'title': 'Day $newDay',
        'exercises': <dynamic>[],
      });
    });
  }

  void _addExercise(int dayIndex) {
    showDialog(
      context: context,
      builder: (ctx) {
        final detailsCtrl = TextEditingController();
        final manualNameCtrl = TextEditingController();
        final setsCtrl = TextEditingController(text: '3');
        final repsCtrl = TextEditingController(text: '12');
        final weightCtrl = TextEditingController(text: '0');
        bool isManual = false;
        String? selectedExerciseName;
        String? selectedVideoUrl;

        return Consumer(
          builder: (context, ref, child) {
            final libraryAsync = ref.watch(exerciseLibraryProvider);
            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  backgroundColor: TrainerTheme.card,
                  title: Text('Add Exercise', style: TrainerTheme.headingSmall),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isManual ? 'Exercise Name' : 'Select Exercise', style: TrainerTheme.bodySmall),
                          TextButton(
                            onPressed: () => setDialogState(() => isManual = !isManual),
                            child: Text(
                              isManual ? 'Use Library' : 'Add Manual',
                              style: TextStyle(color: TrainerTheme.orange, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (isManual)
                        TextField(
                          controller: manualNameCtrl,
                          style: TrainerTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: 'Enter exercise name',
                            hintStyle: TrainerTheme.bodyLarge.copyWith(color: TrainerTheme.textSecondary),
                          ),
                        )
                      else
                        libraryAsync.when(
                        data: (library) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: TrainerTheme.scaffold,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: TrainerTheme.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedExerciseName,
                                hint: Text('Choose Exercise', style: TrainerTheme.bodyMedium),
                                isExpanded: true,
                                dropdownColor: TrainerTheme.card,
                                items: library.map((ex) {
                                  return DropdownMenuItem<String>(
                                    value: ex['name'],
                                    child: Text(ex['name'] ?? '', style: TrainerTheme.bodyMedium),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    final ex = library.firstWhere((e) => e['name'] == val);
                                    setDialogState(() {
                                      selectedExerciseName = val;
                                      selectedVideoUrl = ex['video_url'];
                                    });
                                  }
                                },
                              ),
                            ),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Text('Error: $e', style: const TextStyle(color: TrainerTheme.error)),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Sets', style: TrainerTheme.bodySmall),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: setsCtrl,
                                  keyboardType: TextInputType.number,
                                  style: TrainerTheme.bodyLarge,
                                  decoration: const InputDecoration(hintText: '3'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Reps', style: TrainerTheme.bodySmall),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: repsCtrl,
                                  keyboardType: TextInputType.number,
                                  style: TrainerTheme.bodyLarge,
                                  decoration: const InputDecoration(hintText: '12'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Weight (kg)', style: TrainerTheme.bodySmall),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: weightCtrl,
                                  keyboardType: TextInputType.number,
                                  style: TrainerTheme.bodyLarge,
                                  decoration: const InputDecoration(hintText: '0'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Notes (Optional)', style: TrainerTheme.bodySmall),
                      const SizedBox(height: 8),
                      TextField(
                        controller: detailsCtrl,
                        style: TrainerTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'e.g. Focus on form',
                          hintStyle: TrainerTheme.bodyLarge.copyWith(
                            color: TrainerTheme.textSecondary,
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
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        final finalName = isManual ? manualNameCtrl.text.trim() : selectedExerciseName;
                        
                        if (finalName == null || finalName.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Please select or enter an exercise name')),
                          );
                          return;
                        }

                        final setsStr = setsCtrl.text.trim();
                        final repsStr = repsCtrl.text.trim();
                        final weightStr = weightCtrl.text.trim();

                        final setsError = Validators.validatePositiveInteger(setsStr, 'Sets');
                        if (setsError != null) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(setsError), backgroundColor: TrainerTheme.error),
                          );
                          return;
                        }

                        final repsError = Validators.validatePositiveInteger(repsStr, 'Reps');
                        if (repsError != null) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(repsError), backgroundColor: TrainerTheme.error),
                          );
                          return;
                        }

                        final weightError = Validators.validatePositiveDouble(weightStr, 'Weight');
                        if (weightError != null) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(weightError), backgroundColor: TrainerTheme.error),
                          );
                          return;
                        }

                        setState(() {
                          (_days[dayIndex]['exercises'] as List).add({
                            'name': finalName,
                            'sets': int.parse(setsStr),
                            'reps': int.parse(repsStr),
                            'weight': double.parse(weightStr),
                            'notes': detailsCtrl.text.trim(),
                            'video_url': isManual ? null : selectedVideoUrl,
                          });
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Add'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _planNameController.dispose();
    super.dispose();
  }

  Future<void> _savePlan() async {
    final name = _planNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a plan name')));
      return;
    }

    final authState = ref.read(authProvider);
    final trainerId = authState.user?.id;
    if (trainerId == null) return;

    setState(() => _isSaving = true);
    final repo = ref.read(trainerRepositoryProvider);

    try {
      final planId = await repo.createWorkoutPlan(
        trainerId: trainerId,
        name: name,
        goal: _goal,
        difficulty: 'intermediate', // Default or could be added to UI
      );

      // Flatten exercises for saving
      final List<Map<String, dynamic>> planItems = [];
      for (final day in _days) {
        final dayNumber = day['day'] as int;
        final exercises = day['exercises'] as List<dynamic>;

        for (int i = 0; i < exercises.length; i++) {
          final currentEx = exercises[i];
          
          planItems.add({
            'day_number': dayNumber,
            'exercise_name': currentEx['name'],
            'sets': currentEx['sets'],
            'reps': currentEx['reps'],
            'weight': currentEx['weight'],
            'video_url': currentEx['video_url'],
            'notes': currentEx['notes'],
          });
        }
      }

      if (planItems.isNotEmpty) {
        await repo.addWorkoutPlanItems(planId, planItems);
      }

      // Invalidate provider so the created plan appears in the assignment list
      ref.invalidate(trainerWorkoutPlansProvider(trainerId));

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan created successfully!'),
            backgroundColor: TrainerTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving plan: $e'),
            backgroundColor: TrainerTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TrainerTheme.scaffold,
      appBar: AppBar(
        backgroundColor: TrainerTheme.scaffold,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: TrainerTheme.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Create Workout Plan',
          style: TrainerTheme.headingSmall.copyWith(fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: TrainerTheme.orange,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _savePlan,
              child: Text(
                'Save',
                style: TrainerTheme.bodyLarge.copyWith(
                  color: TrainerTheme.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plan Name', style: TrainerTheme.bodySmall),
            const SizedBox(height: 8),
            _buildTextField(
              'e.g. High Intensity Interval',
              _planNameController,
            ),
            const SizedBox(height: 24),
            Text('Goal', style: TrainerTheme.bodySmall),
            const SizedBox(height: 8),
            _buildDropdown(),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Schedule', style: TrainerTheme.headingMedium),
                Text(
                  'Auto-fill',
                  style: TrainerTheme.bodyMedium.copyWith(
                    color: TrainerTheme.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._days.asMap().entries.map(
              (entry) => _buildDayCard(entry.value, entry.key),
            ),
            const SizedBox(height: 16),
            _buildAddDayButton(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: TrainerTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TrainerTheme.border, width: 1),
      ),
      child: TextField(
        controller: controller,
        style: TrainerTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TrainerTheme.bodyLarge.copyWith(
            color: TrainerTheme.textPrimary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: TrainerTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TrainerTheme.border, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _goal,
          isExpanded: true,
          dropdownColor: TrainerTheme.card,
          icon: const Icon(
            Icons.expand_more_rounded,
            color: TrainerTheme.textSecondary,
          ),
          style: TrainerTheme.bodyLarge.copyWith(
            color: TrainerTheme.textPrimary,
          ),
          items: ['Muscle Gain', 'Weight Loss', 'Endurance', 'Flexibility']
              .map((goal) => DropdownMenuItem(value: goal, child: Text(goal)))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _goal = val);
          },
        ),
      ),
    );
  }

  Widget _buildDayCard(Map<String, dynamic> dayData, int dayIndex) {
    final int dayNumber = dayData['day'];
    final String title = dayData['title'];
    final List<dynamic> exercises = dayData['exercises'];
    final bool isEmpty = exercises.isEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: TrainerTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TrainerTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isEmpty
                            ? TrainerTheme.border
                            : TrainerTheme.orange,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        dayNumber.toString(),
                        style: TrainerTheme.bodyMedium.copyWith(
                          color: isEmpty
                              ? TrainerTheme.textSecondary
                              : Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TrainerTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Icon(
                  isEmpty ? Icons.edit_rounded : Icons.more_horiz_rounded,
                  color: TrainerTheme.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
          if (isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  Text(
                    'No exercises added for this day yet.',
                    style: TrainerTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _addExercise(dayIndex),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: TrainerTheme.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add,
                            color: TrainerTheme.orange,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Add Activity',
                            style: TrainerTheme.bodyMedium.copyWith(
                              color: TrainerTheme.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                ...exercises.map((ex) => _buildExerciseTile(ex)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: GestureDetector(
                    onTap: () => _addExercise(dayIndex),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: TrainerTheme.border,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_circle_outline_rounded,
                            color: TrainerTheme.textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Add Exercise',
                            style: TrainerTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildExerciseTile(dynamic exercise) {
    final String? videoUrl = exercise['video_url'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TrainerTheme.scaffold,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: TrainerTheme.card,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: TrainerTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      exercise['name'],
                      style: TrainerTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (videoUrl != null && videoUrl.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.play_circle_fill, color: TrainerTheme.orange),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VideoPlayerScreen(
                                videoUrl: videoUrl,
                                title: exercise['name'] ?? 'Exercise',
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${exercise['sets']} sets × ${exercise['reps']} reps',
                      style: TrainerTheme.bodySmall,
                    ),
                    if ((exercise['weight'] ?? 0) > 0) ...[
                      Text(
                        ' \u2022 ',
                        style: TrainerTheme.bodySmall,
                      ),
                      Text(
                        '${exercise['weight']} kg',
                        style: TrainerTheme.bodySmall.copyWith(
                          color: TrainerTheme.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                if (exercise['notes'] != null && exercise['notes'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      exercise['notes'],
                      style: TrainerTheme.bodySmall.copyWith(
                        fontStyle: FontStyle.italic,
                        color: TrainerTheme.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Icon(
            Icons.drag_handle_rounded,
            color: TrainerTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildAddDayButton() {
    return GestureDetector(
      onTap: _addDay,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(
            color: TrainerTheme.border,
            width: 1,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TrainerTheme.card,
                shape: BoxShape.circle,
                border: Border.all(color: TrainerTheme.border),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: TrainerTheme.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add Day ${_days.length + 1}',
              style: TrainerTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

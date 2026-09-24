import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';
import 'package:gym_management/features/trainer/presentation/theme/trainer_theme.dart';
import 'package:gym_management/features/trainer/providers/trainer_provider.dart';
import 'package:gym_management/core/utils/validators.dart';

class TrainerCreateDietScreen extends ConsumerStatefulWidget {
  const TrainerCreateDietScreen({super.key});

  @override
  ConsumerState<TrainerCreateDietScreen> createState() =>
      _TrainerCreateDietScreenState();
}

class _TrainerCreateDietScreenState
    extends ConsumerState<TrainerCreateDietScreen> {
  final _planTitleController = TextEditingController(
    text: 'Hypertrophy Phase 1',
  );
  final _calorieController = TextEditingController(text: '2800');
  bool _isSaving = false;

  // Editable macro split percentages
  int _proteinPct = 40;
  int _carbsPct = 35;
  int _fatsPct = 25;

  // Dynamic data representing the structured day-wise meal plan
  final List<List<Map<String, dynamic>>> _days = [];
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    _days.add(_generateEmptyDay());
  }

  List<Map<String, dynamic>> _generateEmptyDay() {
    return [
      {
        'type': 'Breakfast',
        'time': '08:00 AM',
        'icon': Icons.wb_twilight_rounded,
        'color': TrainerTheme.orange,
        'items': <dynamic>[],
      },
      {
        'type': 'Lunch',
        'time': '12:30 PM',
        'icon': Icons.restaurant_rounded,
        'color': const Color(0xFF4A6572),
        'items': <dynamic>[],
      },
      {
        'type': 'Dinner',
        'time': '07:00 PM',
        'icon': Icons.nightlight_round,
        'color': const Color(0xFF342C4B),
        'items': <dynamic>[],
      },
    ];
  }

  void _addDay() {
    setState(() {
      _days.add(_generateEmptyDay());
      _selectedDayIndex = _days.length - 1;
    });
  }

  void _addMealSchedule() {
    final mealNameCtrl = TextEditingController();
    String selectedPreset = '';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              backgroundColor: TrainerTheme.card,
              title: Text(
                'Add Meal Schedule',
                style: TrainerTheme.headingSmall,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Pick:', style: TrainerTheme.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                              'Snack',
                              'Pre-Workout',
                              'Post-Workout',
                              'Brunch',
                              'Supper',
                              'Midnight Snack',
                            ]
                            .map(
                              (preset) => GestureDetector(
                                onTap: () {
                                  setStateSB(() {
                                    selectedPreset = preset;
                                    mealNameCtrl.text = preset;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selectedPreset == preset
                                        ? TrainerTheme.orange
                                        : TrainerTheme.scaffold,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    preset,
                                    style: TrainerTheme.bodySmall.copyWith(
                                      color: selectedPreset == preset
                                          ? Colors.white
                                          : TrainerTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: mealNameCtrl,
                    style: const TextStyle(color: TrainerTheme.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Or type a name',
                      labelStyle: TrainerTheme.bodySmall,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: TrainerTheme.border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: TrainerTheme.orange,
                        ),
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
                  onPressed: () {
                    final name = mealNameCtrl.text.trim();
                    if (name.isEmpty) return;
                    setState(() {
                      _days[_selectedDayIndex].add({
                        'type': name,
                        'time': '03:00 PM',
                        'icon': Icons.fastfood_rounded,
                        'color': const Color(0xFF6C5CE7),
                        'items': <dynamic>[],
                      });
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Add',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addFoodItem(int mealIndex) {
    showDialog(
      context: context,
      builder: (ctx) {
        final nameCtrl = TextEditingController();
        final caloriesCtrl = TextEditingController();
        final proteinCtrl = TextEditingController();
        return AlertDialog(
          backgroundColor: TrainerTheme.card,
          title: Text('Add Food Item', style: TrainerTheme.headingSmall),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: TrainerTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Food Name (e.g. Dosa)',
                  hintStyle: TrainerTheme.bodyLarge.copyWith(
                    color: TrainerTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: caloriesCtrl,
                      keyboardType: TextInputType.number,
                      style: TrainerTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Calories',
                        hintStyle: TrainerTheme.bodyLarge.copyWith(
                          color: TrainerTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: proteinCtrl,
                      keyboardType: TextInputType.number,
                      style: TrainerTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Protein (g)',
                        hintStyle: TrainerTheme.bodyLarge.copyWith(
                          color: TrainerTheme.textSecondary,
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
                final name = nameCtrl.text.trim();
                final caloriesStr = caloriesCtrl.text.trim();
                final proteinStr = proteinCtrl.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please enter food name')),
                  );
                  return;
                }

                final calError =
                    Validators.validatePositiveInteger(caloriesStr, 'Calories');
                if (calError != null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(calError),
                      backgroundColor: TrainerTheme.error,
                    ),
                  );
                  return;
                }

                final proteinError =
                    Validators.validatePositiveInteger(proteinStr, 'Protein');
                if (proteinError != null) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text(proteinError),
                      backgroundColor: TrainerTheme.error,
                    ),
                  );
                  return;
                }

                setState(() {
                  (_days[_selectedDayIndex][mealIndex]['items'] as List).add({
                    'name': name,
                    'calories': int.parse(caloriesStr),
                    'protein': int.parse(proteinStr),
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
  }

  @override
  void dispose() {
    _planTitleController.dispose();
    _calorieController.dispose();
    super.dispose();
  }

  Future<void> _savePlan() async {
    final title = _planTitleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a plan title')),
      );
      return;
    }

    final authState = ref.read(authProvider);
    final trainerId = authState.user?.id;
    if (trainerId == null) return;

    setState(() => _isSaving = true);
    final repo = ref.read(trainerRepositoryProvider);

    final calStr = _calorieController.text.trim();
    final calError = Validators.validatePositiveInteger(calStr, 'Daily Calorie Target');
    if (calError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(calError), backgroundColor: TrainerTheme.error),
      );
      return;
    }

    final int calories = int.parse(calStr);

    try {
      final planId = await repo.createDietPlan(
        trainerId: trainerId,
        title: title,
        dailyCalories: calories,
        proteinMax: (calories * _proteinPct / 100 / 4).round(),
        carbsMax: (calories * _carbsPct / 100 / 4).round(),
        fatsMax: (calories * _fatsPct / 100 / 9).round(),
      );

      // Flatten meals for saving
      final List<Map<String, dynamic>> planItems = [];
      for (int dIndex = 0; dIndex < _days.length; dIndex++) {
        final mealsForDay = _days[dIndex];
        for (final meal in mealsForDay) {
          final mealType = meal['type'] as String;
          final mealTime = meal['time'] as String;
          final items = meal['items'] as List<dynamic>;

          for (int i = 0; i < items.length; i++) {
            final currentItem = items[i];
            planItems.add({
              'day_number': dIndex + 1,
              'meal_time': mealTime.isNotEmpty ? mealTime : mealType,
              'food_item': currentItem['name'] ?? '',
              'calories': currentItem['calories'] ?? 0,
            });
          }
        }
      }

      if (planItems.isNotEmpty) {
        await repo.addDietPlanItems(planId, planItems);
      }

      // Invalidate provider so the created plan appears in the assignment list
      ref.invalidate(trainerDietPlansProvider(trainerId));

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Diet plan created successfully!'),
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
          'Create Diet Plan',
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
                'SAVE',
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
            Text('Plan Details', style: TrainerTheme.headingMedium),
            const SizedBox(height: 4),
            Text(
              'Set the basics for this nutrition strategy.',
              style: TrainerTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text('Plan Title', style: TrainerTheme.bodySmall),
            const SizedBox(height: 8),
            _buildTextField(
              _planTitleController,
              suffixIcon: Icons.edit_rounded,
            ),
            const SizedBox(height: 24),
            Text('Daily Calorie Target', style: TrainerTheme.bodySmall),
            const SizedBox(height: 8),
            _buildTextField(
              _calorieController,
              suffixText: 'kcal',
              inputType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Text('Macro Split Target', style: TrainerTheme.bodySmall),
            const SizedBox(height: 12),
            _buildMacroSplitBar(),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Meal Schedule', style: TrainerTheme.headingMedium),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _addMealSchedule,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.restaurant_menu_rounded,
                            color: TrainerTheme.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
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
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: _addDay,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.add_circle_outline_rounded,
                            color: TrainerTheme.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Add Day',
                            style: TrainerTheme.bodyMedium.copyWith(
                              color: TrainerTheme.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDaysScroller(),
            const SizedBox(height: 24),
            ..._days[_selectedDayIndex].asMap().entries.map(
              (entry) => _buildMealCard(entry.value, entry.key),
            ),
            const SizedBox(height: 80), // Padding for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSaving ? null : _savePlan,
        backgroundColor: TrainerTheme.orange,
        elevation: 4,
        shape: const CircleBorder(),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.check_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    IconData? suffixIcon,
    String? suffixText,
    TextInputType? inputType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: TrainerTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TrainerTheme.border, width: 1),
      ),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        style: TrainerTheme.bodyLarge,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          suffixIcon: suffixIcon != null
              ? Icon(suffixIcon, color: TrainerTheme.orange, size: 20)
              : null,
          suffixText: suffixText,
          suffixStyle: TrainerTheme.bodyMedium.copyWith(
            color: TrainerTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _editMacroSplit() {
    showDialog(
      context: context,
      builder: (ctx) {
        int tempProtein = _proteinPct;
        int tempCarbs = _carbsPct;
        int tempFats = _fatsPct;

        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              backgroundColor: TrainerTheme.card,
              title: Text('Edit Macro Split', style: TrainerTheme.headingSmall),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total: ${tempProtein + tempCarbs + tempFats}%',
                    style: TrainerTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  _buildMacroSlider(
                    'Protein',
                    tempProtein,
                    (value) => setStateSB(() => tempProtein = value.round()),
                    TrainerTheme.orange,
                  ),
                  _buildMacroSlider(
                    'Carbs',
                    tempCarbs,
                    (value) => setStateSB(() => tempCarbs = value.round()),
                    TrainerTheme.orange.withValues(alpha: 0.6),
                  ),
                  _buildMacroSlider(
                    'Fats',
                    tempFats,
                    (value) => setStateSB(() => tempFats = value.round()),
                    TrainerTheme.orange.withValues(alpha: 0.3),
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
                    if (tempProtein + tempCarbs + tempFats == 100) {
                      setState(() {
                        _proteinPct = tempProtein;
                        _carbsPct = tempCarbs;
                        _fatsPct = tempFats;
                      });
                      Navigator.pop(ctx);
                    } else {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Macro percentages must sum to 100%'),
                          backgroundColor: TrainerTheme.error,
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMacroSlider(
    String label,
    int value,
    ValueChanged<double> onChanged,
    Color color,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text('$label:', style: TrainerTheme.bodyMedium),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 100,
            divisions: 100,
            activeColor: color,
            inactiveColor: color.withValues(alpha: 0.3),
            label: '$value%',
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text('$value%', style: TrainerTheme.bodyMedium),
        ),
      ],
    );
  }

  Widget _buildMacroSplitBar() {
    return GestureDetector(
      onTap: _editMacroSplit,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: _proteinPct,
                    child: Container(color: TrainerTheme.orange),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: _carbsPct,
                    child: Container(
                      color: TrainerTheme.orange.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: _fatsPct,
                    child: Container(
                      color: TrainerTheme.orange.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMacroLegend('Protein $_proteinPct%', TrainerTheme.orange),
              _buildMacroLegend(
                'Carbs $_carbsPct%',
                TrainerTheme.orange.withValues(alpha: 0.6),
              ),
              _buildMacroLegend(
                'Fats $_fatsPct%',
                TrainerTheme.orange.withValues(alpha: 0.3),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tap to edit',
            style: TrainerTheme.bodySmall.copyWith(
              fontSize: 10,
              color: TrainerTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TrainerTheme.bodySmall.copyWith(
            color: TrainerTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDaysScroller() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_days.length, (index) {
          final isSelected = _selectedDayIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = index),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? TrainerTheme.orange : TrainerTheme.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? TrainerTheme.orange : TrainerTheme.border,
                ),
              ),
              child: Text(
                'Day ${index + 1}',
                style: TrainerTheme.bodyMedium.copyWith(
                  color: isSelected ? Colors.white : TrainerTheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> mealData, int mealIndex) {
    final String type = mealData['type'];
    final String time = mealData['time'];
    final IconData icon = mealData['icon'];
    final Color color = mealData['color'];
    final List<dynamic> items = mealData['items'];
    final bool isEmpty = items.isEmpty;

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
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(type, style: TrainerTheme.headingSmall),
                  ],
                ),
                GestureDetector(
                  onTap: () async {
                    // Parse the current time string to get initial values
                    final parts = time.split(':');
                    int hour = int.tryParse(parts[0]) ?? 8;
                    int minute = 0;
                    if (parts.length > 1) {
                      final minParts = parts[1].split(' ');
                      minute = int.tryParse(minParts[0]) ?? 0;
                      if (minParts.length > 1 &&
                          minParts[1].toUpperCase() == 'PM' &&
                          hour != 12) {
                        hour += 12;
                      } else if (minParts.length > 1 &&
                          minParts[1].toUpperCase() == 'AM' &&
                          hour == 12) {
                        hour = 0;
                      }
                    }
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: hour, minute: minute),
                      builder: (ctx, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: TrainerTheme.orange,
                              surface: TrainerTheme.card,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() {
                        mealData['time'] = picked.format(context);
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: TrainerTheme.scaffold,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: TrainerTheme.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: TrainerTheme.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: TrainerTheme.border,
                        width: 1,
                        style: BorderStyle.none,
                      ), // Should be dashed
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.lunch_dining_rounded,
                          color: TrainerTheme.border,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text('No meal added', style: TrainerTheme.bodyMedium),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAddItemButton('Add Meal', mealIndex),
                ],
              ),
            )
          else
            Column(
              children: [
                ...items.map((item) => _buildFoodItemTile(item)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: _buildAddItemButton('Add Item', mealIndex),
                ),
                const SizedBox(height: 16),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFoodItemTile(dynamic item) {
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: TrainerTheme.card,
              borderRadius: BorderRadius.circular(8),
              // Use DecorationImage here with real assets
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: TrainerTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'],
                  style: TrainerTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['calories'] ?? 0} cals ${item['protein'] ?? 0} Protein',
                  style: TrainerTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.more_vert_rounded,
            color: TrainerTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildAddItemButton(String label, int mealIndex) {
    return GestureDetector(
      onTap: () => _addFoodItem(mealIndex),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: TrainerTheme.border, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: TrainerTheme.orange, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TrainerTheme.bodyMedium.copyWith(
                color: TrainerTheme.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

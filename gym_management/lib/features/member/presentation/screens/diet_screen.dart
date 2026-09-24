import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_management/core/router/app_router.dart';
import 'package:gym_management/core/theme/app_theme.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';
import 'package:gym_management/features/member/providers/workout_provider.dart';

class DietScreen extends ConsumerWidget {
  const DietScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authProvider).user?.id;
    if (userId == null) return const SizedBox.shrink();

    final dietsAsync = ref.watch(assignedDietsProvider(userId));

    return Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      appBar: AppBar(
        title: const Text('My Diet Plan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go(AppRoutes.memberDashboard),
        ),
      ),
      body: dietsAsync.when(
        data: (diets) {
          if (diets.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.restaurant_menu_outlined,
                    color: AppTheme.textSecondary,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No diet plans assigned yet',
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
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: diets.length,
            itemBuilder: (context, index) {
              final assigned = diets[index];
              final plan =
                  assigned['diet_plans'] as Map<String, dynamic>? ?? {};
              final items = plan['diet_plan_items'] as List? ?? [];

              return _buildDietPlanCard(context, plan, items);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: const TextStyle(color: AppTheme.errorColor),
          ),
        ),
      ),
    );
  }

  Widget _buildDietPlanCard(
    BuildContext context,
    Map<String, dynamic> plan,
    List items,
  ) {
    final planName = plan['name'] ?? 'Diet Plan';
    final calories = plan['calories_target'] ?? '-';

    // Group by meal type
    final Map<String, List> meals = {};
    for (final item in items) {
      final mealType = (item['meal_time'] ?? 'Other').toString();
      meals.putIfAbsent(mealType, () => []).add(item);
    }

    final mealIcons = {
      'Breakfast': Icons.wb_sunny_outlined,
      'Lunch': Icons.wb_cloudy_outlined,
      'Dinner': Icons.nightlight_outlined,
      'Snack': Icons.apple,
      'Pre-Workout': Icons.flash_on_outlined,
      'Post-Workout': Icons.battery_charging_full_outlined,
    };

    final mealColors = {
      'Breakfast': const Color(0xFFFFA726),
      'Lunch': const Color(0xFF42A5F5),
      'Dinner': const Color(0xFF7E57C2),
      'Snack': const Color(0xFF66BB6A),
      'Pre-Workout': const Color(0xFFEF5350),
      'Post-Workout': const Color(0xFF26C6DA),
    };

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
                  AppTheme.secondaryColor.withValues(alpha: 0.2),
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
                Text(
                  planName,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$calories kcal',
                    style: const TextStyle(
                      color: AppTheme.secondaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Meals
          ...meals.entries.map((entry) {
            final mealType = entry.key;
            final mealItems = entry.value;
            final icon = mealIcons[mealType] ?? Icons.restaurant;
            final color = mealColors[mealType] ?? AppTheme.textSecondary;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        mealType,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...mealItems.map((item) {
                    final foodName = item['food_item'] ?? 'Food';
                    final quantity = item['quantity'] ?? '';
                    final cals = item['calories'] ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(left: 26, bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '• $foodName ${quantity.toString().isNotEmpty ? "($quantity)" : ""}',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (cals.toString().isNotEmpty)
                            Text(
                              '$cals kcal',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

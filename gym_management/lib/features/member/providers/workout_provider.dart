import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/features/member/data/workout_repository.dart';
import 'package:gym_management/features/admin/providers/admin_providers.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final authState = ref.watch(authProvider);
  return WorkoutRepository(gymId: authState.gymId);
});

final dietRepositoryProvider = Provider<DietRepository>((ref) {
  final authState = ref.watch(authProvider);
  return DietRepository(gymId: authState.gymId);
});

/// Expose admin's exercise library to the member facing code
final memberExerciseLibraryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // We can just reuse the admin one or fetch it directly. For this, we'll just read the admin one:
  return ref.watch(exerciseLibraryProvider.future);
});

/// Assigned workouts
final assignedWorkoutsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      userId,
    ) async {
      final repo = ref.read(workoutRepositoryProvider);
      return repo.getAssignedWorkouts(userId);
    });

/// Today's workout tracking
final todayTrackingProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      userId,
    ) async {
      final repo = ref.read(workoutRepositoryProvider);
      return repo.getTodayTracking(userId);
    });

/// Muscle distribution for today
final muscleDistributionProvider =
    FutureProvider.family<Map<String, double>, String>((
      ref,
      userId,
    ) async {
      final repo = ref.read(workoutRepositoryProvider);
      return repo.getMuscleDistribution(userId);
    });

/// Assigned diets
final assignedDietsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      userId,
    ) async {
      final repo = ref.read(dietRepositoryProvider);
      return repo.getAssignedDiets(userId);
    });

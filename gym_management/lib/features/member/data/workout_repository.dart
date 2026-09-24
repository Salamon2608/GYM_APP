import 'package:gym_management/core/services/api_service.dart';

class WorkoutRepository {
  final String? gymId;
  WorkoutRepository({this.gymId});

  /// Get assigned workouts for a user
  Future<List<Map<String, dynamic>>> getAssignedWorkouts(String userId) async {
    final response = await ApiService.get('/member/workouts');
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Get workout tracking for today
  Future<List<Map<String, dynamic>>> getTodayTracking(String userId) async {
    final response = await ApiService.get('/member/workouts/tracking');
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Log workout completion
  Future<void> logWorkout({
    required String userId,
    required String workoutPlanItemId,
    int? setsCompleted,
    int? repsCompleted,
    double? weightUsed,
    int? durationMinutes,
    String? notes,
  }) async {
    await ApiService.post('/member/workouts/tracking', data: {
      'plan_item_id': workoutPlanItemId,
      'weight_used': weightUsed,
    });
  }

  /// Unlog workout completion (delete today's record)
  Future<void> unlogWorkout({
    required String userId,
    required String workoutPlanItemId,
  }) async {
    await ApiService.delete('/member/workouts/tracking', data: {
      'plan_item_id': workoutPlanItemId,
    });
  }

  /// Get muscle group distribution for work done today
  Future<Map<String, double>> getMuscleDistribution(String userId) async {
    final response = await ApiService.get('/member/workouts/muscle-distribution');
    final Map<String, dynamic> raw = response.data;
    return raw.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }
}

class DietRepository {
  final String? gymId;
  DietRepository({this.gymId});

  /// Get assigned diets for a user
  Future<List<Map<String, dynamic>>> getAssignedDiets(String userId) async {
    final response = await ApiService.get('/member/diets');
    return List<Map<String, dynamic>>.from(response.data);
  }
}

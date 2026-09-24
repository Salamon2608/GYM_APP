import 'package:gym_management/core/services/api_service.dart';

class TrainerRepository {
  final String? gymId;
  TrainerRepository({this.gymId});

  /// Get trainer's own profile
  Future<Map<String, dynamic>> getTrainerProfile(String trainerId) async {
    final response = await ApiService.get('/trainer/profile');
    return Map<String, dynamic>.from(response.data);
  }

  /// Update trainer's profile details
  Future<void> updateTrainerProfile({
    required String trainerId,
    required String fullName,
    String? email,
    required String specialization,
    required int experienceYears,
    required String bio,
  }) async {
    await ApiService.put('/trainer/profile', data: {
      'full_name': fullName,
      'email': email,
      'specialization': specialization,
      'experience_years': experienceYears,
      'bio': bio,
    });
  }

  /// Get trainer's dashboard stats
  Future<Map<String, dynamic>> getTrainerStats(String trainerId) async {
    final response = await ApiService.get('/trainer/stats');
    return Map<String, dynamic>.from(response.data);
  }

  /// Get feedback for this trainer
  Future<List<Map<String, dynamic>>> getTrainerFeedback(String trainerId) async {
    final response = await ApiService.get('/trainer/feedback');
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Get a single member's detailed profile
  Future<Map<String, dynamic>> getMemberDetailedProfile(String memberId) async {
    final response = await ApiService.get('/trainer/members/$memberId');
    return Map<String, dynamic>.from(response.data);
  }

  /// Get members assigned to this trainer
  Future<List<Map<String, dynamic>>> getAssignedMembers(String trainerId) async {
    final response = await ApiService.get('/trainer/members');
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Create a new workout plan template
  Future<String> createWorkoutPlan({
    required String trainerId,
    required String name,
    required String goal,
    required String difficulty,
  }) async {
    final response = await ApiService.post('/trainer/workout-plans', data: {
      'name': name,
      'goal': goal,
      'difficulty': difficulty,
    });
    return response.data['id'] as String;
  }

  /// Add items to a workout plan
  Future<void> addWorkoutPlanItems(String planId, List<Map<String, dynamic>> items) async {
    await ApiService.post('/trainer/workout-plans/$planId/items', data: {
      'items': items,
    });
  }

  /// Assign plan to a member
  Future<String> assignWorkoutPlan({
    required String trainerId,
    required String memberId,
    required String planId,
  }) async {
    final response = await ApiService.post('/trainer/workout-plans/$planId/assign', data: {
      'member_id': memberId,
    });
    return response.data['status'] as String;
  }

  /// Get workout plans created by this trainer
  Future<List<Map<String, dynamic>>> getWorkoutPlans(String trainerId) async {
    final response = await ApiService.get('/trainer/workout-plans');
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Create a new diet plan template
  Future<String> createDietPlan({
    required String trainerId,
    required String title,
    required int dailyCalories,
    int? proteinMax,
    int? carbsMax,
    int? fatsMax,
  }) async {
    final response = await ApiService.post('/trainer/diet-plans', data: {
      'title': title,
      'daily_calories': dailyCalories,
    });
    return response.data['id'] as String;
  }

  /// Add items to a diet plan
  Future<void> addDietPlanItems(String planId, List<Map<String, dynamic>> items) async {
    await ApiService.post('/trainer/diet-plans/$planId/items', data: {
      'items': items,
    });
  }

  /// Assign diet plan to a member
  Future<String> assignDietPlan({
    required String trainerId,
    required String memberId,
    required String planId,
  }) async {
    final response = await ApiService.post('/trainer/diet-plans/$planId/assign', data: {
      'member_id': memberId,
    });
    return response.data['status'] as String;
  }

  /// Get diet plans created by this trainer
  Future<List<Map<String, dynamic>>> getDietPlans(String trainerId) async {
    final response = await ApiService.get('/trainer/diet-plans');
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Get workout plan with its items
  Future<Map<String, dynamic>> getWorkoutPlanDetail(String planId) async {
    final response = await ApiService.get('/trainer/workout-plans/$planId');
    return Map<String, dynamic>.from(response.data);
  }

  /// Get diet plan with its items
  Future<Map<String, dynamic>> getDietPlanDetail(String planId) async {
    final response = await ApiService.get('/trainer/diet-plans/$planId');
    return Map<String, dynamic>.from(response.data);
  }

  /// Get members assigned to a specific workout plan
  Future<List<Map<String, dynamic>>> getMembersUsingWorkoutPlan(String planId) async {
    final response = await ApiService.get('/trainer/workout-plans/$planId/members');
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Get members assigned to a specific diet plan
  Future<List<Map<String, dynamic>>> getMembersUsingDietPlan(String planId) async {
    final response = await ApiService.get('/trainer/diet-plans/$planId/members');
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Delete a workout plan
  Future<void> deleteWorkoutPlan(String planId) async {
    await ApiService.delete('/trainer/workout-plans/$planId');
  }

  /// Delete a diet plan
  Future<void> deleteDietPlan(String planId) async {
    await ApiService.delete('/trainer/diet-plans/$planId');
  }

  /// Update workout plan name/goal
  Future<void> updateWorkoutPlan({
    required String planId,
    required String name,
    required String goal,
  }) async {
    await ApiService.put('/trainer/workout-plans/$planId', data: {
      'name': name,
      'goal': goal,
    });
  }

  /// Update diet plan title/calories
  Future<void> updateDietPlan({
    required String planId,
    required String title,
    required int dailyCalories,
  }) async {
    await ApiService.put('/trainer/diet-plans/$planId', data: {
      'title': title,
      'daily_calories': dailyCalories,
    });
  }

  /// Delete a single workout plan item
  Future<void> deleteWorkoutPlanItem(String itemId) async {
    // Note:itemId endpoint delete path
    await ApiService.delete('/trainer/workout-plans/0/items/$itemId');
  }

  /// Update a single workout plan item
  Future<void> updateWorkoutPlanItem({
    required String itemId,
    required String exerciseName,
    required int sets,
    required int reps,
  }) async {
    await ApiService.put('/trainer/workout-plans/0/items/$itemId', data: {
      'exercise_name': exerciseName,
      'sets_count': sets,
      'reps': reps,
    });
  }

  /// Delete a single diet plan item
  Future<void> deleteDietPlanItem(String itemId) async {
    await ApiService.delete('/trainer/diet-plans/0/items/$itemId');
  }

  /// Update a single diet plan item
  Future<void> updateDietPlanItem({
    required String itemId,
    required String foodItem,
    required String mealTime,
    int? calories,
  }) async {
    await ApiService.put('/trainer/diet-plans/0/items/$itemId', data: {
      'food_item': foodItem,
      'meal_time': mealTime,
      'calories': calories,
    });
  }

  /// Unassign a member from a workout plan
  Future<void> unassignWorkoutPlan({
    required String planId,
    required String userId,
  }) async {
    await ApiService.post('/trainer/workout-plans/$planId/unassign', data: {
      'user_id': userId,
    });
  }

  /// Unassign a member from a diet plan
  Future<void> unassignDietPlan({
    required String planId,
    required String userId,
  }) async {
    await ApiService.post('/trainer/diet-plans/$planId/unassign', data: {
      'user_id': userId,
    });
  }

  /// Get all exercise videos
  Future<List<Map<String, dynamic>>> getMyVideos(String trainerId) async {
    final response = await ApiService.get('/trainer/videos');
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Submit a new exercise video
  Future<void> submitVideo({
    required String trainerId,
    required String name,
    required String muscleGroup,
    required String difficulty,
    String? description,
    String? videoUrl,
  }) async {
    await ApiService.post('/trainer/videos', data: {
      'name': name,
      'muscle_group': muscleGroup,
      'difficulty': difficulty,
      'description': description,
      'video_url': videoUrl,
    });
  }

  /// Update an exercise video
  Future<void> updateVideo({
    required String videoId,
    required String name,
    required String muscleGroup,
    required String difficulty,
    String? description,
    String? videoUrl,
  }) async {
    await ApiService.put('/trainer/videos/$videoId', data: {
      'name': name,
      'muscle_group': muscleGroup,
      'difficulty': difficulty,
      'description': description,
      'video_url': videoUrl,
    });
  }

  /// Delete a video
  Future<void> deleteMyVideo(String videoId) async {
    await ApiService.delete('/trainer/videos/$videoId');
  }

  /// Toggle attendance for a member
  Future<String> markManualAttendance(String memberId) async {
    final response = await ApiService.post('/trainer/attendance/$memberId');
    return response.data['status'] as String;
  }
}

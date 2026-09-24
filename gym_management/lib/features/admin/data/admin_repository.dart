import 'package:gym_management/core/services/api_service.dart';
import 'package:image_picker/image_picker.dart';

class AdminRepository {
  final String? gymId;
  AdminRepository({this.gymId});

  // ============================================================
  // Dashboard Stats
  // ============================================================
  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await ApiService.get('/admin/dashboard');
    return Map<String, dynamic>.from(response.data);
  }

  // ============================================================
  // User Management
  // ============================================================
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final response = await ApiService.get('/admin/users');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> updateUserRole(String userId, String newRole) async {
    await ApiService.patch('/admin/users/$userId/role', data: {'role': newRole});
  }

  Future<void> updateUserDetails(String userId, Map<String, dynamic> updates) async {
    await ApiService.put('/admin/users/$userId', data: updates);
  }

  Future<void> updateFullUserProfile(
    String userId, {
    required String fullName,
    required String phone,
    required String email,
    String? newPassword,
    Map<String, dynamic>? selectedPlan,
  }) async {
    await ApiService.put('/admin/users/full-profile', data: {
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'new_password': newPassword,
      'selected_plan': selectedPlan,
    });
  }

  Future<void> createMemberAccount({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    Map<String, dynamic>? selectedPlan,
    String? role,
  }) async {
    await ApiService.post('/admin/users/create', data: {
      'email': email,
      'password': password,
      'full_name': fullName,
      'phone': phone,
      'selected_plan': selectedPlan,
      'role': role ?? 'member',
    });
  }

  // ============================================================
  // Trainer Management
  // ============================================================
  Future<List<Map<String, dynamic>>> getAllTrainers() async {
    final response = await ApiService.get('/admin/trainers');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> createTrainerAccount({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String? specialization,
    int? experienceYears,
    String? bio,
  }) async {
    await ApiService.post('/admin/trainers/create', data: {
      'email': email,
      'password': password,
      'full_name': fullName,
      'phone': phone,
      'specialization': specialization,
      'experience_years': experienceYears,
      'bio': bio,
    });
  }

  Future<void> addTrainer({
    required String userId,
    String? specialization,
    int? experienceYears,
    String? bio,
  }) async {
    await ApiService.post('/admin/trainers/promote', data: {
      'user_id': userId,
      'specialization': specialization,
      'experience_years': experienceYears,
      'bio': bio,
    });
  }

  Future<void> updateFullTrainerProfile(
    String trainerId, {
    required String fullName,
    required String phone,
    required String email,
    required String specialization,
    required int experienceYears,
    required String bio,
    String? newPassword,
  }) async {
    await ApiService.put('/admin/trainers/$trainerId', data: {
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'specialization': specialization,
      'experience_years': experienceYears,
      'bio': bio,
      'new_password': newPassword,
    });
  }

  Future<void> assignTrainerToMember(String trainerId, String memberId) async {
    await ApiService.post('/admin/trainers/assign', data: {
      'trainer_id': trainerId,
      'member_id': memberId,
    });
  }

  Future<void> removeTrainerAssignment(String memberId) async {
    await ApiService.delete('/admin/trainers/unassign/$memberId');
  }

  Future<List<Map<String, dynamic>>> getUnassignedMembers() async {
    final response = await ApiService.get('/admin/members/unassigned');
    return List<Map<String, dynamic>>.from(response.data);
  }

  // ============================================================
  // Membership Plan Management
  // ============================================================
  Future<List<Map<String, dynamic>>> getAllMembershipPlans() async {
    final response = await ApiService.get('/admin/plans');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> createMembershipPlan({
    required String name,
    required int durationMonths,
    required double price,
    List<String>? features,
  }) async {
    await ApiService.post('/admin/plans', data: {
      'name': name,
      'duration_months': durationMonths,
      'price': price,
      'features': features,
    });
  }

  Future<void> updateMembershipPlan(String planId, Map<String, dynamic> updates) async {
    await ApiService.put('/admin/plans/$planId', data: updates);
  }

  Future<void> togglePlanActive(String planId, bool isActive) async {
    await ApiService.patch('/admin/plans/$planId/toggle', data: {
      'is_active': isActive,
    });
  }

  // ============================================================
  // Payment Monitoring
  // ============================================================
  Future<List<Map<String, dynamic>>> getAllPayments() async {
    final response = await ApiService.get('/admin/payments');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> updatePaymentStatus(String paymentId, String newStatus) async {
    await ApiService.patch('/admin/payments/$paymentId/status', data: {
      'status': newStatus,
    });
  }

  Future<Map<String, dynamic>> getRevenueReport() async {
    final response = await ApiService.get('/admin/revenue');
    return Map<String, dynamic>.from(response.data);
  }

  // ============================================================
  // Complaints & Feedback
  // ============================================================
  Future<List<Map<String, dynamic>>> getAllComplaints() async {
    final response = await ApiService.get('/admin/complaints');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> updateComplaintStatus(String complaintId, String newStatus) async {
    await ApiService.patch('/admin/complaints/$complaintId/status', data: {
      'status': newStatus,
    });
  }

  Future<void> submitComplaintAboutTrainer({
    required String userId,
    required String subject,
    required String description,
    String? trainerId,
  }) async {
    await ApiService.post('/admin/complaints/submit', data: {
      'user_id': userId,
      'subject': subject,
      'description': description,
      'trainer_id': trainerId,
    });
  }

  Future<void> submitTrainerFeedback({
    required String userId,
    required String trainerId,
    required int rating,
    String? comment,
  }) async {
    await ApiService.post('/admin/feedback', data: {
      'user_id': userId,
      'trainer_id': trainerId,
      'rating': rating,
      'comment': comment,
    });
  }

  Future<List<Map<String, dynamic>>> getTrainerFeedback() async {
    final response = await ApiService.get('/admin/feedback');
    return List<Map<String, dynamic>>.from(response.data);
  }

  // ============================================================
  // Exercise / Video Library
  // ============================================================
  Future<List<Map<String, dynamic>>> getExerciseLibrary() async {
    final response = await ApiService.get('/admin/exercises');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> addExercise({
    required String name,
    required String muscleGroup,
    required String difficulty,
    String? description,
    String? videoUrl,
  }) async {
    await ApiService.post('/admin/exercises', data: {
      'name': name,
      'muscle_group': muscleGroup,
      'difficulty': difficulty,
      'description': description,
      'video_url': videoUrl,
    });
  }

  Future<void> updateExercise(String exerciseId, Map<String, dynamic> updates) async {
    await ApiService.put('/admin/exercises/$exerciseId', data: updates);
  }

  Future<void> approveExercise(String exerciseId) async {
    await ApiService.patch('/admin/exercises/$exerciseId/approve');
  }

  Future<void> deleteExercise(String exerciseId) async {
    await ApiService.delete('/admin/exercises/$exerciseId');
  }

  // ============================================================
  // Reminder Logs
  // ============================================================
  Future<List<Map<String, dynamic>>> getReminderLogs() async {
    final response = await ApiService.get('/admin/reminders');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> getExpiringMembers(int days) async {
    final response = await ApiService.get('/admin/expiring-members', queryParameters: {'days': days});
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> sendReminderToUser({required String userId, required String type}) async {
    await ApiService.post('/admin/reminders', data: {
      'user_id': userId,
      'type': type,
    });
  }

  Future<int> sendBulkExpiryReminders(List<String> userIds) async {
    final response = await ApiService.post('/admin/reminders/bulk', data: {
      'user_ids': userIds,
    });
    return response.data['count'] as int? ?? 0;
  }

  Future<Map<String, dynamic>> getReminderStats() async {
    final response = await ApiService.get('/admin/reminders/stats');
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> clearReminderLogs() async {
    await ApiService.delete('/admin/reminders');
  }

  // ============================================================
  // Advertisements
  // ============================================================
  Future<List<Map<String, dynamic>>> getAllAdvertisements() async {
    final response = await ApiService.get('/admin/advertisements');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> createAdvertisement({
    required String title,
    required String imageUrl,
    required String targetSegment,
    required String redirectType,
    String? redirectUrl,
    required DateTime startDate,
    required DateTime endDate,
    bool isActive = true,
  }) async {
    await ApiService.post('/admin/advertisements', data: {
      'title': title,
      'image_url': imageUrl,
      'target_segment': targetSegment,
      'redirect_type': redirectType,
      'redirect_url': redirectUrl,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
    });
  }

  Future<void> updateAdvertisement(String adId, Map<String, dynamic> updates) async {
    await ApiService.put('/admin/advertisements/$adId', data: updates);
  }

  Future<void> deleteAdvertisement(String adId) async {
    await ApiService.delete('/admin/advertisements/$adId');
  }

  Future<Map<String, dynamic>> getAdvertisementPerformance(String adId) async {
    final response = await ApiService.get('/admin/advertisements/$adId/performance');
    return Map<String, dynamic>.from(response.data);
  }

  // ============================================================
  // Gym Location (GPS Settings)
  // ============================================================
  Future<Map<String, dynamic>?> getGymLocation() async {
    final response = await ApiService.get('/admin/gym/location');
    if (response.data == null) return null;
    return Map<String, dynamic>.from(response.data);
  }

  // ============================================================
  // App Settings
  // ============================================================
  Future<Map<String, dynamic>> getAppSettings() async {
    final response = await ApiService.get('/admin/settings');
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> updateAppSetting(String key, dynamic value) async {
    await ApiService.put('/admin/settings', data: {
      'key': key,
      'value': value,
    });
  }

  // ============================================================
  // Admin Profile
  // ============================================================
  Future<void> updateAdminProfile({required String fullName}) async {
    await ApiService.put('/admin/profile', data: {
      'full_name': fullName,
    });
  }

  // ============================================================
  // Trainer Today Attendance
  // ============================================================
  Future<Map<String, Map<String, dynamic>>> getTrainersTodayAttendance(List<String> trainerIds) async {
    final response = await ApiService.post('/admin/attendance/trainers', data: {
      'trainer_ids': trainerIds,
    });
    final Map<String, dynamic> raw = response.data;
    return raw.map((key, value) => MapEntry(key, Map<String, dynamic>.from(value)));
  }

  Future<List<Map<String, dynamic>>> getTodayAttendance() async {
    final response = await ApiService.get('/admin/attendance/today');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> getGymSubscription() async {
    final response = await ApiService.get('/admin/gym/subscription');
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> updateGymSubscription({required String status, required DateTime endDate}) async {
    await ApiService.put('/admin/gym/subscription', data: {
      'status': status,
      'end_date': endDate.toIso8601String(),
    });
  }

  Future<void> updateRazorpayCredentials({required String keyId, required String secretEncrypted}) async {
    await ApiService.put('/admin/gym/razorpay', data: {
      'key_id': keyId,
      'secret_encrypted': secretEncrypted,
    });
  }

  Future<void> updateGymInfo({
    required String name,
    required String address,
    required String phone,
    required String email,
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) async {
    await ApiService.put('/admin/gym/info', data: {
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
    });
  }

  Future<void> deleteUserAccount(String userId) async {
    await ApiService.delete('/admin/users/$userId');
  }

  Future<String?> uploadGymLogo(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return await ApiService.uploadFile('/uploads/gym-logo', bytes, imageFile.name);
  }

  Future<String?> uploadAdvertisementImage(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return await ApiService.uploadFile('/uploads/ad-image', bytes, imageFile.name);
  }
}

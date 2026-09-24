import 'package:gym_management/core/services/api_service.dart';

class ProfileRepository {
  final String? gymId;
  ProfileRepository({this.gymId});

  /// Fetch user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await ApiService.get('/member/profile');
      if (response.data == null) return null;
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return null;
    }
  }

  /// Fetch assigned trainer profile
  Future<Map<String, dynamic>?> getAssignedTrainer() async {
    try {
      final response = await ApiService.get('/member/trainer');
      if (response.data == null) return null;
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return null;
    }
  }

  /// Fetch user's complaints
  Future<List<Map<String, dynamic>>> getMyComplaints() async {
    try {
      final response = await ApiService.get('/member/complaints');
      if (response.data == null) return [];
      return List<Map<String, dynamic>>.from(response.data);
    } catch (_) {
      return [];
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    await ApiService.put('/member/profile', data: updates);
  }

  /// Fetch user_health record
  Future<Map<String, dynamic>?> getUserHealth(String userId) async {
    try {
      final response = await ApiService.get('/member/health');
      if (response.data == null) return null;
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return null;
    }
  }

  /// Save user health data
  Future<void> saveUserHealth({
    required String userId,
    required double heightCm,
    required double weightKg,
    int? age,
    String? gender,
    String? bloodGroup,
    String? medicalConditions,
    String? allergies,
    String? goal,
    String? experienceLevel,
  }) async {
    await ApiService.put('/member/health', data: {
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'age': age,
      'gender': gender,
      'blood_group': bloodGroup,
      'medical_conditions': medicalConditions,
      'allergies': allergies,
      'goal': goal,
      'experience_level': experienceLevel,
    });
  }

  /// Save BMI record
  Future<void> saveBmiRecord({
    required String userId,
    required double bmiValue,
    double? heightCm,
    double? weightKg,
  }) async {
    await ApiService.post('/member/bmi', data: {
      'bmi_value': bmiValue,
    });
  }

  /// Get BMI history
  Future<List<Map<String, dynamic>>> getBmiHistory(String userId) async {
    final response = await ApiService.get('/member/bmi');
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Change user password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await ApiService.put('/member/profile/password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }
}

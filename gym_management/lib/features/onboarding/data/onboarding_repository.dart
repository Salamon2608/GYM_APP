import 'package:gym_management/core/services/api_service.dart';

class OnboardingRepository {
  final String? gymId;
  OnboardingRepository({this.gymId});

  /// Check if user has completed onboarding
  Future<bool> isOnboardingCompleted(String userId) async {
    try {
      final response = await ApiService.get('/member/health');
      if (response.data == null) return false;
      return response.data['onboarding_completed'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Save all onboarding data in one update
  Future<void> saveOnboardingData({
    required String userId,
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    String? bloodGroup,
    String? medicalConditions,
    String? allergies,
    required String goal,
    required String experienceLevel,
  }) async {
    await ApiService.put('/member/health', data: {
      'age': age,
      'gender': gender,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'blood_group': bloodGroup,
      'medical_conditions': medicalConditions,
      'allergies': allergies,
      'goal': goal,
      'experience_level': experienceLevel,
      'onboarding_completed': true,
    });
  }

  /// Save initial BMI record
  Future<void> saveBmiRecord({
    required String userId,
    required double bmiValue,
  }) async {
    await ApiService.post('/member/bmi', data: {
      'bmi_value': bmiValue,
    });
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/features/member/data/profile_repository.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';

// Repository provider
final profileRepositoryProvider = Provider.autoDispose<ProfileRepository>((ref) {
  final authState = ref.watch(authProvider);
  return ProfileRepository(gymId: authState.gymId);
});

// User profile provider
final userProfileProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, userId) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getUserProfile(userId);
});

// User health provider
final userHealthProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>(
  (ref, userId) async {
    final repo = ref.watch(profileRepositoryProvider);
    return repo.getUserHealth(userId);
  },
);

// My complaints provider
final myComplaintsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getMyComplaints();
});

// BMI history provider
final bmiHistoryProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((
      ref,
      userId,
    ) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getBmiHistory(userId);
});

/// Calculate BMI
double calculateBmi(double heightCm, double weightKg) {
  final heightM = heightCm / 100;
  return weightKg / (heightM * heightM);
}

/// Get BMI category
String getBmiCategory(double bmi) {
  if (bmi < 18.5) return 'Underweight';
  if (bmi < 25) return 'Normal';
  if (bmi < 30) return 'Overweight';
  return 'Obese';
}

/// Get BMI color hex
int getBmiColorHex(double bmi) {
  if (bmi < 18.5) return 0xFF42A5F5; // Blue
  if (bmi < 25) return 0xFF66BB6A; // Green
  if (bmi < 30) return 0xFFFFA726; // Orange
  return 0xFFEF5350; // Red
}

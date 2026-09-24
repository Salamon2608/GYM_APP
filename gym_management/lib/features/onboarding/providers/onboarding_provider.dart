import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/features/onboarding/data/onboarding_repository.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';

// Repository provider
final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final authState = ref.watch(authProvider);
  return OnboardingRepository(gymId: authState.gymId);
});

// Check if onboarding is completed
final onboardingCompletedProvider = FutureProvider.family<bool, String>((
  ref,
  userId,
) async {
  final repo = ref.read(onboardingRepositoryProvider);
  return repo.isOnboardingCompleted(userId);
});

/// Onboarding form data
class OnboardingData {
  // Step 1: Body Measurements
  int? age;
  String? gender;
  double? heightCm;
  double? weightKg;

  // Step 2: Health Information
  String? bloodGroup;
  String? medicalConditions;
  String? allergies;

  // Step 3: Fitness Goals
  String? goal;
  String? experienceLevel;
}

/// Onboarding state
class OnboardingState {
  final int currentStep;
  final bool isLoading;
  final String? errorMessage;
  final bool isCompleted;
  final OnboardingData data;

  const OnboardingState({
    this.currentStep = 0,
    this.isLoading = false,
    this.errorMessage,
    this.isCompleted = false,
    required this.data,
  });

  OnboardingState copyWith({
    int? currentStep,
    bool? isLoading,
    String? errorMessage,
    bool? isCompleted,
    OnboardingData? data,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isCompleted: isCompleted ?? this.isCompleted,
      data: data ?? this.data,
    );
  }
}

/// Onboarding notifier
class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    return OnboardingState(data: OnboardingData());
  }

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 2) {
      state = state.copyWith(currentStep: step);
    }
  }

  // Step 1 data
  void updateBodyMeasurements({
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
  }) {
    final data = state.data;
    if (age != null) data.age = age;
    if (gender != null) data.gender = gender;
    if (heightCm != null) data.heightCm = heightCm;
    if (weightKg != null) data.weightKg = weightKg;
    state = state.copyWith(data: data);
  }

  // Step 2 data
  void updateHealthInfo({
    String? bloodGroup,
    String? medicalConditions,
    String? allergies,
  }) {
    final data = state.data;
    if (bloodGroup != null) data.bloodGroup = bloodGroup;
    if (medicalConditions != null) data.medicalConditions = medicalConditions;
    if (allergies != null) data.allergies = allergies;
    state = state.copyWith(data: data);
  }

  // Step 3 data
  void updateFitnessGoals({String? goal, String? experienceLevel}) {
    final data = state.data;
    if (goal != null) data.goal = goal;
    if (experienceLevel != null) data.experienceLevel = experienceLevel;
    state = state.copyWith(data: data);
  }

  /// Submit all onboarding data
  Future<bool> submitOnboarding(String userId) async {
    final data = state.data;

    // Validate required fields
    if (data.age == null ||
        data.gender == null ||
        data.heightCm == null ||
        data.weightKg == null ||
        data.goal == null ||
        data.experienceLevel == null) {
      state = state.copyWith(
        errorMessage: 'Please fill in all required fields',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final repo = ref.read(onboardingRepositoryProvider);

      // Save onboarding data
      await repo.saveOnboardingData(
        userId: userId,
        age: data.age!,
        gender: data.gender!,
        heightCm: data.heightCm!,
        weightKg: data.weightKg!,
        bloodGroup: data.bloodGroup,
        medicalConditions: data.medicalConditions,
        allergies: data.allergies,
        goal: data.goal!,
        experienceLevel: data.experienceLevel!,
      );

      // Calculate and save BMI
      final heightM = data.heightCm! / 100;
      final bmi = data.weightKg! / (heightM * heightM);
      await repo.saveBmiRecord(userId: userId, bmiValue: bmi);

      state = state.copyWith(isLoading: false, isCompleted: true);
      return true;
    } catch (e) {
      debugPrint('Onboarding error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save data. Please try again.',
      );
      return false;
    }
  }
}

// Provider
final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(() {
      return OnboardingNotifier();
    });

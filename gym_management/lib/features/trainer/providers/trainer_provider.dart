import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/features/trainer/data/trainer_repository.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';

final trainerRepositoryProvider = Provider.autoDispose<TrainerRepository>((ref) {
  final authState = ref.watch(authProvider);
  return TrainerRepository(gymId: authState.gymId);
});

/// Trainer stats (member count, plans, rating)
final trainerStatsProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, trainerId) async {
  final repo = ref.watch(trainerRepositoryProvider);
  return repo.getTrainerStats(trainerId);
});

/// List of members assigned to the trainer
final assignedMembersProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((
  ref,
  trainerId,
) async {
  final repo = ref.watch(trainerRepositoryProvider);
  return repo.getAssignedMembers(trainerId);
});

/// Videos submitted by this trainer
final myVideosProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((
  ref,
  trainerId,
) async {
  final repo = ref.watch(trainerRepositoryProvider);
  return repo.getMyVideos(trainerId);
});

/// Feedback received by this trainer
final trainerFeedbackProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((
  ref,
  trainerId,
) async {
  final repo = ref.watch(trainerRepositoryProvider);
  return repo.getTrainerFeedback(trainerId);
});

/// Workout plans created by this trainer
final trainerWorkoutPlansProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((
  ref,
  trainerId,
) async {
  final repo = ref.watch(trainerRepositoryProvider);
  return repo.getWorkoutPlans(trainerId);
});

/// Diet plans created by this trainer
final trainerDietPlansProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((
  ref,
  trainerId,
) async {
  final repo = ref.watch(trainerRepositoryProvider);
  return repo.getDietPlans(trainerId);
});

/// Detailed stats and profile for a specific member
final memberDetailedDataProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, memberId) async {
  final repo = ref.watch(trainerRepositoryProvider);
  return repo.getMemberDetailedProfile(memberId);
});

/// Trainer's own profile (specialization, experience, bio, etc.)
final trainerProfileProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, trainerId) async {
  final repo = ref.watch(trainerRepositoryProvider);
  return repo.getTrainerProfile(trainerId);
});

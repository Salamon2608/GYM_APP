import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/features/super_admin/data/super_admin_repository.dart';

final superAdminRepositoryProvider = Provider<SuperAdminRepository>((ref) {
  return SuperAdminRepository();
});

final gymsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(superAdminRepositoryProvider);
  return await repo.getGyms();
});

final gymAdminsProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, String>((ref, gymId) async {
  final repo = ref.read(superAdminRepositoryProvider);
  return await repo.getGymAdmins(gymId);
});

final platformPlansProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(superAdminRepositoryProvider);
  return await repo.getPlatformPlans();
});

final gymSubscriptionsProvider = FutureProvider.family.autoDispose<List<Map<String, dynamic>>, String>((ref, gymId) async {
  final repo = ref.read(superAdminRepositoryProvider);
  return await repo.getGymSubscriptions(gymId);
});

final platformPaymentsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(superAdminRepositoryProvider);
  return await repo.getAllPlatformPayments();
});

final platformLogoProvider = FutureProvider.autoDispose<String?>((ref) async {
  final repo = ref.read(superAdminRepositoryProvider);
  return await repo.getPlatformLogoUrl();
});

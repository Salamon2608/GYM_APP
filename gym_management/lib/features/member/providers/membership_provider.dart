import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/features/member/data/membership_repository.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';

final membershipRepositoryProvider = Provider.autoDispose<MembershipRepository>((ref) {
  final authState = ref.watch(authProvider);
  return MembershipRepository(gymId: authState.gymId);
});

/// All available membership plans
final membershipPlansProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.watch(membershipRepositoryProvider);
  return repo.getMembershipPlans();
});

/// User's active membership
final activeMembershipProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, userId) async {
  final repo = ref.watch(membershipRepositoryProvider);
  return repo.getActiveMembership(userId);
});

/// Membership history
final membershipHistoryProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((
  ref,
  userId,
) async {
  final repo = ref.watch(membershipRepositoryProvider);
  return repo.getMembershipHistory(userId);
});

// === Expiry Fallback Logic ===

/// Membership status enum
enum MembershipStatus { active, expired, none, loading }

/// Derives membership status from active membership data
final membershipStatusProvider = Provider.family<MembershipStatus, String>((
  ref,
  userId,
) {
  final asyncMembership = ref.watch(activeMembershipProvider(userId));

  return asyncMembership.when(
    data: (membership) {
      if (membership == null) return MembershipStatus.none;
      final endDate = DateTime.tryParse(membership['end_date'] ?? '');
      if (endDate == null) return MembershipStatus.none;
      return endDate.isAfter(DateTime.now())
          ? MembershipStatus.active
          : MembershipStatus.expired;
    },
    loading: () => MembershipStatus.loading,
    error: (_, _) => MembershipStatus.none,
  );
});

/// Features available only with active membership
enum GymFeature { checkIn, assignedWorkouts, assignedDiets, trainerSupport }

/// Features available in fallback mode (expired/no membership)
const fallbackAllowedScreens = {
  'workout', // Can browse general workout content
  'diet', // Can view general diet info
  'profile', // Can manage profile
  'membership', // Can purchase new membership
};

/// Check if a gym-specific feature requires active membership
bool isFeatureGated(MembershipStatus status, GymFeature feature) {
  if (status == MembershipStatus.active) return false; // all allowed
  return true; // gated for expired/none
}

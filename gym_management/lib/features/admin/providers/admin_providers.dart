import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/features/admin/data/admin_repository.dart';
import 'package:gym_management/features/admin/data/repositories/lead_repository.dart';
import 'package:gym_management/features/admin/data/models/lead_model.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';

// === Repository Provider ===
final adminRepositoryProvider = Provider.autoDispose<AdminRepository>((ref) {
  final authState = ref.watch(authProvider);
  return AdminRepository(gymId: authState.gymId);
});

final leadRepositoryProvider = Provider.autoDispose<LeadRepository>((ref) {
  final authState = ref.watch(authProvider);
  return LeadRepository(gymId: authState.gymId);
});

// === 4.1 Dashboard Stats ===
final adminDashboardStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getDashboardStats();
});

// === 4.2 User Management ===
final allUsersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getAllUsers();
});

// === 4.3 Trainer Management ===
final allTrainersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getAllTrainers();
});

final unassignedMembersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getUnassignedMembers();
});

// === 4.4 Membership Plans ===
final allMembershipPlansProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getAllMembershipPlans();
});

// === 4.5 Payment Monitoring ===
final allPaymentsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getAllPayments();
});

final revenueReportProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getRevenueReport();
});

// === 4.6 Complaints & Feedback ===
final allComplaintsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getAllComplaints();
});

final trainerFeedbackProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getTrainerFeedback();
});

// === 4.7 Exercise / Video Library ===
final exerciseLibraryProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getExerciseLibrary();
});

// === 4.8 Reminder Logs ===
final reminderLogsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getReminderLogs();
});

/// Members expiring within [days] days — used for bulk reminder send
final expiringMembersProvider =
    FutureProvider.family<List<Map<String, dynamic>>, int>((ref, days) async {
      final repo = ref.read(adminRepositoryProvider);
      return repo.getExpiringMembers(days);
    });

/// Reminder stats for this month
final reminderStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.read(adminRepositoryProvider);
  return repo.getReminderStats();
});

// === 4.9 Internal Advertisements ===
final allAdvertisementsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final repo = ref.read(adminRepositoryProvider);
  return repo.getAllAdvertisements();
});

// === Trainer Today Attendance ===
/// Takes a list of trainer IDs and returns a map { trainerId: attendanceRow }
final trainerAttendanceTodayProvider =
    FutureProvider.family<Map<String, Map<String, dynamic>>, List<String>>((
      ref,
      trainerIds,
    ) async {
      final repo = ref.read(adminRepositoryProvider);
      return repo.getTrainersTodayAttendance(trainerIds);
    });

// === Lead Management ===
final allLeadsProvider = FutureProvider<List<LeadModel>>((ref) async {
  final repo = ref.read(leadRepositoryProvider);
  return repo.fetchLeads();
});

// === Navigation & Dashboard Utilities ===
/// Controls the active tab index in AdminShell
/// Controls the active tab index in AdminShell
/// Controls the active tab index in AdminShell
class AdminNavigationNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

final adminNavigationProvider = NotifierProvider<AdminNavigationNotifier, int>(AdminNavigationNotifier.new);

/// Fetches today's gym entries (check-ins/outs) for all users
final todayAttendanceProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final repo = ref.watch(adminRepositoryProvider);
      return repo.getTodayAttendance();
    });

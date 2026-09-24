import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/features/member/data/attendance_repository.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';

final attendanceRepositoryProvider = Provider.autoDispose<AttendanceRepository>((ref) {
  final authState = ref.watch(authProvider);
  return AttendanceRepository(gymId: authState.gymId);
});

final todayAttendanceProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, userId) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getTodayAttendance(userId);
});

final attendanceHistoryProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((
  ref,
  userId,
) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getAttendanceHistory(userId);
});

final monthlyAttendanceProvider = FutureProvider.autoDispose.family<int, String>((
  ref,
  userId,
) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getMonthlyAttendanceCount(userId);
});

final yearlyAttendanceProvider = FutureProvider.autoDispose.family<int, String>((
  ref,
  userId,
) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getYearlyAttendanceCount(userId);
});

/// Calculates consecutive days streak from attendance history
final attendanceStreakProvider = FutureProvider.autoDispose.family<int, String>((
  ref,
  userId,
) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  final history = await repo.getAttendanceHistory(userId);

  if (history.isEmpty) return 0;

  // Get unique dates (sorted descending)
  final dates =
      history
          .map((r) {
            final checkIn = r['check_in'] ?? r['date'];
            if (checkIn == null) return null;
            final checkInStr = checkIn.toString();
            final dt = DateTime.tryParse(checkInStr.endsWith('Z') ? checkInStr : '${checkInStr}Z')?.toLocal();
            return dt != null ? DateTime(dt.year, dt.month, dt.day) : null;
          })
          .where((d) => d != null)
          .cast<DateTime>()
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));

  if (dates.isEmpty) return 0;

  int streak = 0;
  DateTime expected = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  // If the most recent attendance is not today, check if it was yesterday
  if (dates[0] != expected) {
    expected = expected.subtract(const Duration(days: 1));
    if (dates[0] != expected) return 0;
  }

  for (final date in dates) {
    if (date == expected) {
      streak++;
      expected = expected.subtract(const Duration(days: 1));
    } else if (date.isBefore(expected)) {
      break;
    }
  }

  return streak;
});

final attendanceStreamProvider = StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, userId) {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getAttendanceStream(userId);
});

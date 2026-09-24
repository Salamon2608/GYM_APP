import 'dart:async';
import 'package:gym_management/core/services/api_service.dart';

class AttendanceRepository {
  final String? gymId;

  AttendanceRepository({dynamic client, this.gymId});

  /// Check-in user
  Future<void> checkIn({
    required String userId,
    double? latitude,
    double? longitude,
    required String method,
  }) async {
    await ApiService.post('/member/attendance/checkin', data: {
      'method': method,
    });
  }

  /// Check-out user
  Future<void> checkOut(String userId) async {
    await ApiService.post('/member/attendance/checkout');
  }

  /// Get today's attendance
  Future<Map<String, dynamic>?> getTodayAttendance(String userId) async {
    try {
      final response = await ApiService.get('/member/attendance/today');
      if (response.data == null) return null;
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return null;
    }
  }

  /// Get attendance history
  Future<List<Map<String, dynamic>>> getAttendanceHistory(String userId) async {
    final response = await ApiService.get('/member/attendance/history');
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Get monthly attendance count
  Future<int> getMonthlyAttendanceCount(String userId) async {
    final response = await ApiService.get('/member/attendance/monthly');
    return response.data['count'] as int? ?? 0;
  }

  /// Get yearly attendance count
  Future<int> getYearlyAttendanceCount(String userId) async {
    final response = await ApiService.get('/member/attendance/yearly');
    return response.data['count'] as int? ?? 0;
  }

  /// Get gym location from gym_locations table
  Future<Map<String, dynamic>?> getGymLocation() async {
    try {
      final response = await ApiService.get('/member/attendance/gym-location');
      if (response.data == null) return null;
      return Map<String, dynamic>.from(response.data);
    } catch (_) {
      return null;
    }
  }

  /// Stream of today's attendance (simulated via periodic polling)
  Stream<List<Map<String, dynamic>>> getAttendanceStream(String userId) {
    final controller = StreamController<List<Map<String, dynamic>>>();
    Timer? timer;

    void fetch() async {
      try {
        final history = await getAttendanceHistory(userId);
        if (!controller.isClosed) {
          controller.add(history);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    // Fetch immediately
    fetch();

    // Poll every 5 seconds
    timer = Timer.periodic(const Duration(seconds: 5), (_) => fetch());

    controller.onCancel = () {
      timer?.cancel();
      controller.close();
    };

    return controller.stream;
  }
}

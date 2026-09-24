import 'package:gym_management/core/services/api_service.dart';

class NotificationRepository {
  final String? gymId;
  NotificationRepository({this.gymId});

  /// Fetch all notifications for the current user
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    final response = await ApiService.get('/member/notifications');
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// How many unread notifications the user has
  Future<int> getUnreadCount(String userId) async {
    final response = await ApiService.get('/member/notifications/unread');
    return response.data['count'] as int? ?? 0;
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    await ApiService.patch('/member/notifications/$notificationId/read');
  }

  /// Mark all notifications as read for this user
  Future<void> markAllAsRead(String userId) async {
    await ApiService.patch('/member/notifications/read-all');
  }
}

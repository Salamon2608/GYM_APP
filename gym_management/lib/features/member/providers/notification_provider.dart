import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/features/member/data/notification_repository.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';

final notificationRepositoryProvider = Provider.autoDispose<NotificationRepository>(
  (ref) {
    final authState = ref.watch(authProvider);
    return NotificationRepository(gymId: authState.gymId);
  },
);

/// All notifications for user
final notificationsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((
  ref,
  userId,
) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getNotifications(userId);
});

/// Unread notification count (drives the badge)
final unreadNotifCountProvider =
    FutureProvider.autoDispose.family<int, String>((
  ref,
  userId,
) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getUnreadCount(userId);
});

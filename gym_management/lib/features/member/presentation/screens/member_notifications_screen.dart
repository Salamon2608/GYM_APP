import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';
import 'package:gym_management/core/theme/app_theme.dart';
import 'package:gym_management/features/member/providers/notification_provider.dart';

class MemberNotificationsScreen extends ConsumerStatefulWidget {
  const MemberNotificationsScreen({super.key});

  @override
  ConsumerState<MemberNotificationsScreen> createState() =>
      _MemberNotificationsScreenState();
}

class _MemberNotificationsScreenState
    extends ConsumerState<MemberNotificationsScreen> {
  late final String _userId;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authProvider);
    _userId = authState.user?.id ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notifAsync = ref.watch(notificationsProvider(_userId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.done_all_rounded, size: 18),
            label: const Text('Mark all read'),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
            onPressed: () => _markAll(),
          ),
        ],
      ),
      body: notifAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 64,
                    color: theme.disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.disabledColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gym reminders will appear here',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.disabledColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: notifications.length,
            itemBuilder: (_, i) => _buildNotifCard(context, notifications[i]),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: TextStyle(color: AppTheme.errorColor),
          ),
        ),
      ),
    );
  }

  Widget _buildNotifCard(BuildContext context, Map<String, dynamic> notif) {
    final theme = Theme.of(context);
    final isRead = notif['is_read'] == 1 || notif['is_read'] == true;
    final title = notif['title'] as String? ?? 'Notification';
    final body = notif['body'] as String? ?? '';
    final createdAt = DateTime.tryParse(notif['created_at'] ?? '');

    final timeStr = _formatTime(createdAt);

    // Pick icon and color from title emoji prefix
    IconData icon = Icons.notifications_rounded;
    Color color = AppTheme.primaryColor;
    if (title.contains('⏰') || title.contains('Expir')) {
      icon = Icons.timer_outlined;
      color = Colors.orange;
    } else if (title.contains('💳') || title.contains('Payment')) {
      icon = Icons.payment_rounded;
      color = AppTheme.errorColor;
    } else if (title.contains('🎉') || title.contains('Welcome')) {
      icon = Icons.celebration_rounded;
      color = AppTheme.successColor;
    }

    return GestureDetector(
      onTap: () => _markRead(notif),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isRead
              ? theme.cardColor
              : AppTheme.primaryColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead
                ? theme.dividerColor
                : AppTheme.primaryColor.withValues(alpha: 0.3),
            width: isRead ? 1 : 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        // Unread dot
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.75,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timeStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.disabledColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _markRead(Map<String, dynamic> notif) async {
    if (notif['is_read'] == 1 || notif['is_read'] == true) return;
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAsRead(notif['id']);
    ref.invalidate(notificationsProvider(_userId));
    ref.invalidate(unreadNotifCountProvider(_userId));
  }

  Future<void> _markAll() async {
    final repo = ref.read(notificationRepositoryProvider);
    await repo.markAllAsRead(_userId);
    ref.invalidate(notificationsProvider(_userId));
    ref.invalidate(unreadNotifCountProvider(_userId));
  }
}

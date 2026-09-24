import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gym_management/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gym_management/core/router/app_router.dart';
import 'package:gym_management/core/theme/app_theme.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';
import 'package:gym_management/features/member/providers/membership_provider.dart';
import 'package:gym_management/features/member/presentation/widgets/feature_gate.dart';
import 'package:gym_management/features/member/providers/notification_provider.dart';
import 'package:gym_management/features/member/presentation/widgets/advertisement_carousel.dart';
import 'package:gym_management/features/member/providers/profile_provider.dart';
import 'package:gym_management/features/member/providers/attendance_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MemberDashboardScreen extends ConsumerWidget {
  const MemberDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userId = authState.user?.id ?? '';
    final gymName = authState.gymName ?? 'Dashboard';

    final unreadAsync = ref.watch(unreadNotifCountProvider(userId));
    final unreadCount = unreadAsync.when(
      data: (c) => c,
      loading: () => 0,
      error: (_, _) => 0,
    );

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            if (authState.logoUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  AppConstants.getFullImageUrl(authState.logoUrl),
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 32,
                      height: 32,
                      color: Colors.grey.withValues(alpha: 0.3),
                      child: const Icon(Icons.fitness_center, size: 20),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(gymName),
          ],
        ),
        actions: [
          // 🔔 Notification bell with unread badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push(AppRoutes.memberNotifications),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => context.push(AppRoutes.memberProfile),
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryColor,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Internal Advertisement Carousel at the top
            const AdvertisementCarousel(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Text(
                    'Hello, ${ref.watch(authProvider).user?.userMetadata?['full_name'] ?? 'Member'} 👋',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Expiry banner (shows only when membership expired/none)
                  const ExpiryBanner(),
                  const SizedBox(height: 4),
                  Text(
                    "Let's crush your goals today!",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Membership Status Card
                  _buildMembershipCard(context, ref, userId),
                  const SizedBox(height: 16),

                  // Quick Stats Row
                  _buildDynamicStatsRow(context, ref, userId),
                  const SizedBox(height: 24),

                  // Quick Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quick Actions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => context.push(AppRoutes.memberPaymentHistory),
                        icon: const Icon(Icons.receipt_long_rounded, size: 16, color: AppTheme.primaryColor),
                        label: const Text(
                          'History',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _AnimatedActionCard(
                        title: 'My Workout',
                        icon: Icons.fitness_center,
                        color: AppTheme.primaryColor,
                        onTap: () => context.push(AppRoutes.memberWorkout),
                      ),
                      _AnimatedActionCard(
                        title: 'Diet Plan',
                        icon: Icons.restaurant_menu,
                        color: AppTheme.secondaryColor,
                        onTap: () => context.push(AppRoutes.memberDiet),
                      ),
                      _AnimatedActionCard(
                        title: 'Membership',
                        icon: Icons.card_membership,
                        color: AppTheme.accentColor,
                        onTap: () => context.push(AppRoutes.memberMembership),
                      ),
                      _AnimatedActionCard(
                        title: 'Check In',
                        icon: Icons.location_on,
                        color: AppTheme.successColor,
                        onTap: () {
                          final userId = ref.read(authProvider).user?.id;
                          if (userId != null) {
                            final status = ref.read(
                              membershipStatusProvider(userId),
                            );
                            if (status == MembershipStatus.active ||
                                status == MembershipStatus.loading) {
                              context.push(AppRoutes.memberAttendance);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Check-in requires an active membership',
                                  ),
                                  backgroundColor: AppTheme.errorColor,
                                  action: SnackBarAction(
                                    label: 'Get Plan',
                                    textColor: Colors.white,
                                    onPressed: () => context.push(
                                      AppRoutes.memberMembership,
                                    ),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      _AnimatedActionCard(
                        title: 'Rate Trainer',
                        icon: Icons.star_rounded,
                        color: Colors.amber,
                        onTap: () =>
                            context.push(AppRoutes.memberTrainerRating),
                      ),
                      _AnimatedActionCard(
                        title: 'Videos',
                        icon: Icons.video_library_rounded,
                        color: AppTheme.primaryDark,
                        onTap: () => context.push(AppRoutes.memberVideos),
                      ),
                    ].animate(interval: 50.ms).fade(duration: 400.ms).scale(curve: Curves.easeOutBack, begin: const Offset(0.8, 0.8)),
                  ),
                ].animate(interval: 60.ms).fade(duration: 500.ms).slideY(begin: 0.1, curve: Curves.easeOutQuad),
              ),
            ),
          ],
        ),
      ),
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: BottomNavigationBar(
            currentIndex: 0,
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: theme.unselectedWidgetColor,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            onTap: (index) {
              if (index == 1) {
                context.push(AppRoutes.memberWorkout);
              } else if (index == 2) {
                context.push(AppRoutes.memberDiet);
              } else if (index == 3) {
                context.push(AppRoutes.memberProfile);
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.fitness_center_outlined),
                activeIcon: Icon(Icons.fitness_center),
                label: 'Workout',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.restaurant_menu_outlined),
                activeIcon: Icon(Icons.restaurant_menu),
                label: 'Diet',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
        ),
      ),
      ),
    );
  }

  Widget _buildMembershipCard(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    final membershipAsync = ref.watch(activeMembershipProvider(userId));

    return membershipAsync.when(
      data: (membership) {
        if (membership == null) {
          return _buildNoMembershipCard(context);
        }

        final planName =
            membership['membership_plans']?['name'] ?? 'Membership';
        final status = membership['status'] ?? 'active';
        final endDateStr = membership['end_date'] ?? '';
        final startDateStr = membership['start_date'] ?? '';
        final endDate = DateTime.tryParse(endDateStr);
        final startDate = DateTime.tryParse(startDateStr);
        final now = DateTime.now();

        final isActive =
            status == 'active' && endDate != null && endDate.isAfter(now);
        final formattedEnd = endDate != null
            ? DateFormat('MMM dd, yyyy').format(endDate)
            : 'N/A';

        // Calculate progress
        double progress = 0.5;
        String remainingText = '';
        if (startDate != null && endDate != null) {
          final totalDays = endDate.difference(startDate).inDays;
          final daysUsed = now.difference(startDate).inDays;
          final daysLeft = endDate.difference(now).inDays;
          progress = totalDays > 0
              ? (daysUsed / totalDays).clamp(0.0, 1.0)
              : 0.0;
          remainingText = '$daysLeft of $totalDays days remaining';
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isActive
                  ? [AppTheme.primaryColor, AppTheme.primaryDark]
                  : [Colors.grey.shade700, Colors.grey.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (isActive ? AppTheme.primaryColor : Colors.grey)
                    .withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$planName Membership',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActive ? 'ACTIVE' : 'EXPIRED',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Expires: $formattedEnd',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                remainingText,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        width: double.infinity,
        height: 130,
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      ),
      error: (_, _) => _buildNoMembershipCard(context),
    );
  }

  Widget _buildNoMembershipCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.memberMembership),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.card_membership_rounded,
              color: AppTheme.textSecondary,
              size: 40,
            ),
            const SizedBox(height: 8),
            const Text(
              'No Active Membership',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to browse plans',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicStatsRow(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) {
    final bmiAsync = ref.watch(bmiHistoryProvider(userId));
    final streakAsync = ref.watch(yearlyAttendanceProvider(userId));

    final bmiValue = bmiAsync.when(
      data: (records) {
        if (records.isEmpty) return '--';
        final latestBmi = (records.first['bmi_value'] as num).toDouble();
        return latestBmi.toStringAsFixed(1);
      },
      loading: () => '...',
      error: (_, _) => '--',
    );

    final streakValue = streakAsync.when(
      data: (streak) => '$streak 🔥',
      loading: () => '...',
      error: (_, _) => '0 🔥',
    );

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'BMI',
            bmiValue,
            Icons.monitor_weight_outlined,
            AppTheme.secondaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Yearly Days',
            streakValue,
            Icons.local_fire_department,
            AppTheme.errorColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: isDark ? 0.2 : 0.1),
            color.withValues(alpha: isDark ? 0.05 : 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedActionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _AnimatedActionCard({
    required this.title,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  State<_AnimatedActionCard> createState() => _AnimatedActionCardState();
}

class _AnimatedActionCardState extends State<_AnimatedActionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null) setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        if (widget.onTap != null) {
          setState(() => _isPressed = false);
          widget.onTap!();
        }
      },
      onTapCancel: () {
        if (widget.onTap != null) setState(() => _isPressed = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? theme.cardColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : widget.color.withValues(alpha: 0.1),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: isDark ? 0.05 : 0.08),
              blurRadius: _isPressed ? 5 : 15,
              offset: _isPressed ? const Offset(0, 2) : const Offset(0, 5),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 30),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

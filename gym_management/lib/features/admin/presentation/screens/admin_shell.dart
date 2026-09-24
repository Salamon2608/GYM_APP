import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_management/core/router/app_router.dart';

import 'package:gym_management/features/admin/presentation/theme/admin_theme.dart';
import 'package:gym_management/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:gym_management/features/admin/presentation/screens/user_management_screen.dart';

import 'package:gym_management/features/admin/presentation/screens/payment_management_screen.dart';
import 'package:gym_management/features/admin/presentation/screens/complaints_screen.dart';
import 'package:gym_management/features/admin/presentation/screens/admin_settings_screen.dart';
import 'package:gym_management/features/admin/presentation/screens/leads_screen.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart'; // Added import
import 'package:gym_management/features/admin/providers/admin_providers.dart';
import 'package:gym_management/core/constants/app_constants.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Bottom nav pages: Dashboard, Users, Payments, Complaints, Settings, Leads
  final List<Widget> _pages = const [
    AdminDashboardScreen(),
    UserManagementScreen(),
    PaymentManagementScreen(),
    ComplaintsScreen(),
    AdminSettingsScreen(),
    LeadsScreen(),
  ];

  void _onTabTapped(int index) {
    ref.read(adminNavigationProvider.notifier).setIndex(index);
  }

  // Navigate from drawer & close it
  void _drawerNav(int tabIndex) {
    Navigator.pop(context); // close drawer
    ref.read(adminNavigationProvider.notifier).setIndex(tabIndex);
  }

  void _drawerPush(String route) {
    Navigator.pop(context); // close drawer
    context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(adminNavigationProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AdminTheme.scaffold,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopAppBar(),
            Expanded(
              child: IndexedStack(index: currentIndex, children: _pages),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOP APP BAR — Hamburger, GymPro logo, Search, Notifications, Avatar
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTopAppBar() {
    final authState = ref.watch(authProvider);
    final gymName = authState.gymName ?? 'Gym';

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 6, 8, 6),
      child: Row(
        children: [
          // Hamburger menu
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 24),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          // GymPro Logo
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: authState.logoUrl == null
                  ? const LinearGradient(
                      colors: [AdminTheme.orange, AdminTheme.orangeDark],
                    )
                  : null,
              color: authState.logoUrl != null ? Colors.transparent : null,
              borderRadius: BorderRadius.circular(8),
              image: authState.logoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(AppConstants.getFullImageUrl(authState.logoUrl!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: authState.logoUrl == null
                ? const Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                    size: 16,
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            gymName,
            style: AdminTheme.headingSmall.copyWith(color: Colors.white),
          ),
          const Spacer(),
          // Notifications with badge
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 22,
            ),
            onPressed: () => context.push(AppRoutes.adminReminders),
          ),
          // Profile avatar
          GestureDetector(
            onTap: () => _onTabTapped(4), // Navigate to Settings tab
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AdminTheme.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SIDE DRAWER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildDrawer() {
    final authState = ref.watch(authProvider);
    final gymName = authState.gymName ?? 'Gym';

    return Drawer(
      backgroundColor: AdminTheme.scaffold,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: authState.logoUrl == null
                          ? const LinearGradient(
                              colors: [AdminTheme.orange, AdminTheme.orangeDark],
                            )
                          : null,
                      color: authState.logoUrl != null ? Colors.transparent : null,
                      borderRadius: BorderRadius.circular(8),
                      image: authState.logoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(AppConstants.getFullImageUrl(authState.logoUrl!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: authState.logoUrl == null
                        ? const Icon(
                            Icons.fitness_center,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    gymName,
                    style: AdminTheme.headingSmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AdminTheme.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Nav items
              _drawerItem(Icons.dashboard_rounded, 'Dashboard', 0),
              _drawerItem(Icons.people_rounded, 'Users', 1),
              _drawerItemPush(
                Icons.sports_rounded,
                'Trainers',
                AppRoutes.adminTrainers,
              ),
              _drawerItemPush(
                Icons.card_membership_rounded,
                'Plans',
                AppRoutes.adminPlans,
              ),
              _drawerItem(Icons.payments_rounded, 'Payments', 2),
              _drawerItemPush(
                Icons.play_circle_outline,
                'Videos',
                AppRoutes.adminVideoLibrary,
              ),
              _drawerItemPush(
                Icons.campaign_outlined,
                'Advertisements',
                AppRoutes.adminAdvertisements,
              ),
              _drawerItem(Icons.chat_bubble_outline, 'Complaints', 3),
              _drawerItem(Icons.person_add_alt_1, 'Leads', 5), // Added Leads drawer item
              _drawerItemPush(
                Icons.bar_chart_rounded,
                'Reminders',
                AppRoutes.adminReminders,
              ),
              const Spacer(),
              const Divider(color: AdminTheme.border),
              // Settings
              _drawerItem(Icons.settings_rounded, 'Settings', 4),
              const SizedBox(height: 8),
              // Logout
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authProvider.notifier).signOut();
                  if (mounted) context.go(AppRoutes.login);
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: AdminTheme.error, size: 22),
                      const SizedBox(width: 14),
                      Text(
                        'Logout',
                        style: AdminTheme.bodyLarge.copyWith(
                          color: AdminTheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(
    IconData icon,
    String label,
    int tabIndex, {
    VoidCallback? onTap,
  }) {
    final currentIndex = ref.watch(adminNavigationProvider);
    final isActive = currentIndex == tabIndex;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap ?? () => _drawerNav(tabIndex),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: isActive
              ? BoxDecoration(
                  color: AdminTheme.orange,
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : AdminTheme.textSecondary,
                size: 22,
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: AdminTheme.bodyLarge.copyWith(
                  color: isActive ? Colors.white : AdminTheme.textSecondary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              if (isActive) ...[
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItemPush(IconData icon, String label, String route) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => _drawerPush(route),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: AdminTheme.textSecondary, size: 22),
              const SizedBox(width: 14),
              Text(
                label,
                style: AdminTheme.bodyLarge.copyWith(
                  color: AdminTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BOTTOM NAVIGATION — Dashboard, Users, Payments, Complaints, Settings
  // ═══════════════════════════════════════════════════════════════

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AdminTheme.card,
        border: Border(top: BorderSide(color: AdminTheme.border, width: 0.5)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.dashboard_rounded, 'Dashboard'),
              _navItem(1, Icons.people_rounded, 'Users'),
              _navItem(2, Icons.payments_rounded, 'Payments'),
              _navItem(3, Icons.chat_bubble_outline, 'Complaints'),
              _navItem(4, Icons.settings_rounded, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final currentIndex = ref.watch(adminNavigationProvider);
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: AdminTheme.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isActive ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                color: isActive ? AdminTheme.orange : AdminTheme.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AdminTheme.orange : AdminTheme.textMuted,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

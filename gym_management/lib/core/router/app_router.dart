import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gym_management/features/auth/providers/auth_provider.dart';
import 'package:gym_management/features/auth/presentation/screens/login_screen.dart';
import 'package:gym_management/features/auth/presentation/screens/register_screen.dart';
import 'package:gym_management/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:gym_management/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:gym_management/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:gym_management/features/auth/presentation/screens/inactive_gym_screen.dart';
import 'package:gym_management/features/super_admin/presentation/screens/super_admin_dashboard_screen.dart';
import 'package:gym_management/features/super_admin/presentation/screens/gym_management_screen.dart';
import 'package:gym_management/features/super_admin/presentation/screens/platform_plans_screen.dart';
import 'package:gym_management/features/super_admin/presentation/screens/super_admin_settings_screen.dart';
import 'package:gym_management/features/super_admin/presentation/screens/super_admin_payments_screen.dart';
import 'package:gym_management/features/splash/presentation/screens/splash_screen.dart';
import 'package:gym_management/features/member/presentation/screens/member_dashboard_screen.dart';
import 'package:gym_management/features/member/presentation/screens/profile_screen.dart';
import 'package:gym_management/features/member/presentation/screens/membership_screen.dart';
import 'package:gym_management/features/member/presentation/screens/payment_history_screen.dart';
import 'package:gym_management/features/member/presentation/screens/workout_screen.dart';
import 'package:gym_management/features/member/presentation/screens/diet_screen.dart';
import 'package:gym_management/features/member/presentation/screens/attendance_screen.dart';
import 'package:gym_management/features/member/presentation/screens/member_notifications_screen.dart';
import 'package:gym_management/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:gym_management/features/member/presentation/screens/trainer_rating_screen.dart';
import 'package:gym_management/features/member/presentation/screens/member_video_library_screen.dart';
import 'package:gym_management/features/trainer/presentation/screens/trainer_shell.dart';
import 'package:gym_management/features/trainer/presentation/screens/trainer_video_screen.dart';
import 'package:gym_management/features/trainer/presentation/screens/trainer_member_detail_screen.dart';
import 'package:gym_management/features/trainer/presentation/screens/trainer_create_workout_screen.dart';
import 'package:gym_management/features/trainer/presentation/screens/trainer_create_diet_screen.dart';
import 'package:gym_management/features/admin/presentation/screens/admin_shell.dart';
import 'package:gym_management/features/admin/presentation/screens/membership_plans_screen.dart';
import 'package:gym_management/features/admin/presentation/screens/complaints_screen.dart';
import 'package:gym_management/features/admin/presentation/screens/video_library_screen.dart';
import 'package:gym_management/features/admin/presentation/screens/reminder_logs_screen.dart';
import 'package:gym_management/features/admin/presentation/screens/trainer_management_screen.dart';
import 'package:gym_management/features/admin/presentation/screens/manage_advertisements_screen.dart';

// Route names

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyOtp = '/verify-otp';
  static const String resetPassword = '/reset-password';
  static const String inactiveGym = '/inactive-gym';
  static const String memberDashboard = '/member';
  static const String memberOnboarding = '/member/onboarding';
  static const String memberProfile = '/member/profile';
  static const String memberMembership = '/member/membership';
  static const String memberPaymentHistory = '/member/payment-history';
  static const String memberWorkout = '/member/workout';
  static const String memberDiet = '/member/diet';
  static const String memberAttendance = '/member/attendance';
  static const String memberNotifications = '/member/notifications';
  static const String memberTrainerRating = '/member/trainer-rating';
  static const String memberVideos = '/member/videos';
  static const String trainerDashboard = '/trainer';
  static const String trainerVideos = '/trainer/videos';
  static const String trainerMemberDetail = '/trainer/member-detail';
  static const String trainerCreateWorkout = '/trainer/create-workout';
  static const String trainerCreateDiet = '/trainer/create-diet';
  // Super Admin Routes
  static const String superAdminDashboard = '/super-admin';
  static const String superAdminPlans = '/super-admin/plans';
  static const String superAdminGymDetail = '/super-admin/gym/:id';
  static const String superAdminSettings = '/super-admin/settings';

  // Admin shell hosts Dashboard, Users, Trainers, Payments as tabs
  static const String adminDashboard = '/admin';
  static const String adminUsers = '/admin/users';
  static const String adminTrainers = '/admin/trainers';
  static const String adminPayments = '/admin/payments';
  // Admin push routes (from More menu)
  static const String adminPlans = '/admin/plans';
  static const String adminComplaints = '/admin/complaints';
  static const String adminLeads = '/admin/leads';
  static const String adminSettings = '/admin/settings';
  static const String adminVideoLibrary = '/admin/video-library';
  static const String adminReminders = '/admin/reminders';
  static const String adminAdvertisements = '/admin/advertisements';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final listenable = ValueNotifier<AuthState>(ref.read(authProvider));
  ref.listen(authProvider, (prev, next) {
    debugPrint('Auth state changed: ${next.status}, role: ${next.role}');
    listenable.value = next;
  });

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: listenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final loggingIn = state.matchedLocation == AppRoutes.login;
      final registering = state.matchedLocation == AppRoutes.register;
      final forgotPassword = state.matchedLocation == AppRoutes.forgotPassword;
      final verifyOtp = state.matchedLocation == AppRoutes.verifyOtp;
      final resetPassword = state.matchedLocation == AppRoutes.resetPassword;
      final isSplash = state.matchedLocation == AppRoutes.splash;

      // Handle unauthenticated state
      if (authState.status == AuthStatus.loading) return null;

      if (!authState.isAuthenticated) {
        // Only allow staying on auth screens
        if (loggingIn || registering || forgotPassword || verifyOtp || resetPassword) {
          return null;
        }
        // Force everyone else (including Splash) to Login
        return AppRoutes.login;
      }

      // If authenticated...

      // If the user is currently resetting their password, keep them on the reset screen
      if (authState.isResettingPassword == true) {
        if (resetPassword) return null;
        return AppRoutes.resetPassword;
      }

      // Normal authentication redirect: If on auth screens or splash, go to dashboard
      // OR if gym is inactive, redirect to inactive gym screen.
      final isInactiveGymScreen = state.matchedLocation == AppRoutes.inactiveGym;
      final role = authState.role;

      if (authState.isGymActive == false && role != 'super_admin') {
        if (!isInactiveGymScreen) return AppRoutes.inactiveGym;
        return null; // Stay on inactive gym screen
      }

      // If gym is active but user is on inactive screen, send to dashboard
      if (isInactiveGymScreen && authState.isGymActive == true) {
        if (role == 'admin') return AppRoutes.adminDashboard;
        if (role == 'trainer') return AppRoutes.trainerDashboard;
        if (role == 'super_admin') return '/super-admin';
        return AppRoutes.memberDashboard;
      }

      if (loggingIn || registering || forgotPassword || verifyOtp || resetPassword || isSplash) {
        debugPrint('AppRouter: Redirecting authenticated user with role: $role');
        
        if (role == 'super_admin') return '/super-admin';
        if (role == 'admin') return AppRoutes.adminDashboard;
        if (role == 'trainer') return AppRoutes.trainerDashboard;
        return AppRoutes.memberDashboard;
      }

      // Enforce dashboard constraints based on role
      final location = state.matchedLocation;

      // Super Admin access
      if (role == 'super_admin') {
        if (!location.startsWith('/super-admin')) return '/super-admin';
        return null;
      }

      // Admin access
      if (role == 'admin') {
        // If an admin lands on a member or trainer dashboard, redirect them to admin dashboard
        if (location == AppRoutes.memberDashboard || location == AppRoutes.trainerDashboard) {
           debugPrint('AppRouter: Admin detected on wrong dashboard. Redirecting to Admin Dashboard.');
           return AppRoutes.adminDashboard;
        }
        return null; 
      }

      // Trainer access
      if (role == 'trainer') {
        if (location == AppRoutes.memberDashboard || location.startsWith('/admin')) {
          debugPrint('AppRouter: Trainer detected on wrong dashboard. Redirecting to Trainer Dashboard.');
          return AppRoutes.trainerDashboard;
        }
        return null;
      }

      // Member access
      if (role == 'member') {
        if (location.startsWith('/admin') || location.startsWith('/trainer')) {
          debugPrint('AppRouter: Member attempted unauthorized access. Redirecting to Member Dashboard.');
          return AppRoutes.memberDashboard;
        }
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyOtp,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerifyOtpScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.inactiveGym,
        builder: (context, state) => const InactiveGymScreen(),
      ),

      // === Member Routes ===
      GoRoute(
        path: AppRoutes.memberDashboard,
        pageBuilder: (context, state) => _buildSmoothPage(const MemberDashboardScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.memberOnboarding,
        pageBuilder: (context, state) => _buildSmoothPage(const OnboardingScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.memberProfile,
        pageBuilder: (context, state) => _buildSmoothPage(const ProfileScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.memberMembership,
        pageBuilder: (context, state) => _buildSmoothPage(const MembershipScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.memberPaymentHistory,
        pageBuilder: (context, state) => _buildSmoothPage(const PaymentHistoryScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.memberWorkout,
        pageBuilder: (context, state) => _buildSmoothPage(const WorkoutScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.memberDiet,
        pageBuilder: (context, state) => _buildSmoothPage(const DietScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.memberAttendance,
        pageBuilder: (context, state) => _buildSmoothPage(const AttendanceScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.memberNotifications,
        pageBuilder: (context, state) => _buildSmoothPage(const MemberNotificationsScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.memberTrainerRating,
        pageBuilder: (context, state) => _buildSmoothPage(const TrainerRatingScreen(), state),
      ),
      GoRoute(
        path: AppRoutes.memberVideos,
        pageBuilder: (context, state) => _buildSmoothPage(const MemberVideoLibraryScreen(), state),
      ),

      // === Trainer Routes ===
      GoRoute(
        path: AppRoutes.trainerDashboard,
        builder: (context, state) => const TrainerShell(),
      ),
      GoRoute(
        path: AppRoutes.trainerVideos,
        builder: (context, state) => const TrainerVideoScreen(),
      ),
      GoRoute(
        path: AppRoutes.trainerMemberDetail,
        builder: (context, state) {
          final memberId = state.uri.queryParameters['id'] ?? '';
          return TrainerMemberDetailScreen(memberId: memberId);
        },
      ),
      GoRoute(
        path: AppRoutes.trainerCreateWorkout,
        builder: (context, state) => const TrainerCreateWorkoutScreen(),
      ),
      GoRoute(
        path: AppRoutes.trainerCreateDiet,
        builder: (context, state) => const TrainerCreateDietScreen(),
      ),

      // === Super Admin Routes ===
      GoRoute(
        path: AppRoutes.superAdminDashboard,
        builder: (context, state) => const SuperAdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'plans',
            builder: (context, state) => const PlatformPlansScreen(),
          ),
          GoRoute(
            path: 'gym/:id',
            builder: (context, state) {
              final gymId = state.pathParameters['id'] ?? 'new';
              return GymManagementScreen(gymId: gymId);
            },
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SuperAdminSettingsScreen(),
          ),
          GoRoute(
            path: 'payments',
            builder: (context, state) => const SuperAdminPaymentsScreen(),
          ),
        ],
      ),

      // === Admin Shell (bottom nav with 4 tabs) ===
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const AdminShell(),
      ),

      // === Admin Push Routes (from Drawer / More menu) ===
      GoRoute(
        path: AppRoutes.adminTrainers,
        builder: (context, state) => const TrainerManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminPlans,
        builder: (context, state) => const MembershipPlansScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminComplaints,
        builder: (context, state) => const ComplaintsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminVideoLibrary,
        builder: (context, state) => const VideoLibraryScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminReminders,
        builder: (context, state) => const ReminderLogsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminAdvertisements,
        builder: (context, state) => const ManageAdvertisementsScreen(),
      ),
    ],

    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );
});

Page<dynamic> _buildSmoothPage(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.02, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}


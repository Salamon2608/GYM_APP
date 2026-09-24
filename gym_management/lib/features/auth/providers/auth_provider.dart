import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/features/auth/data/auth_repository.dart';
import 'package:gym_management/core/services/api_service.dart';
import 'package:gym_management/core/services/auth_storage.dart';

/// Auth state representation
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? role;
  final String? gymId;
  final String? gymName;
  final String? logoUrl;
  final bool isGymActive;
  final bool isResettingPassword;
  final String? resetToken; // stores intermediate reset JWT
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.role,
    this.gymId,
    this.gymName,
    this.logoUrl,
    this.isGymActive = true,
    this.isResettingPassword = false,
    this.resetToken,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? role,
    String? gymId,
    String? gymName,
    String? logoUrl,
    bool? isGymActive,
    bool? isResettingPassword,
    String? resetToken,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      role: role ?? this.role,
      gymId: gymId ?? this.gymId,
      gymName: gymName ?? this.gymName,
      logoUrl: logoUrl ?? this.logoUrl,
      isGymActive: isGymActive ?? this.isGymActive,
      isResettingPassword: isResettingPassword ?? this.isResettingPassword,
      resetToken: resetToken ?? this.resetToken,
      errorMessage: errorMessage,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
}

/// Auth notifier using modern Riverpod Notifier
class AuthNotifier extends Notifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    // Listen for auth changes
    final sub = _repo.authStateChanges.listen((isLoggedIn) {
      if (isLoggedIn) {
        _repo.currentUser.then((user) {
          if (user != null) {
            _loadUserRole(user);
          }
        });
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });
    ref.onDispose(() => sub.cancel());

    // Check if already logged in from saved storage
    _checkInitialAuth();

    return const AuthState(status: AuthStatus.initial);
  }

  Future<void> _checkInitialAuth() async {
    final loggedIn = await _repo.isLoggedIn;
    if (loggedIn) {
      final user = await _repo.currentUser;
      if (user != null) {
        state = AuthState(status: AuthStatus.loading, user: user);
        await _loadUserRole(user);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> _loadUserRole(AppUser user) async {
    try {
      debugPrint('AuthNotifier: Loading role for user: ${user.id}');
      
      String? role = user.role;
      String? gymId = user.gymId;
      String? gymName;
      String? logoUrl;

      // Sync role/gym details from local cache first, then verify via API
      final localGym = await AuthStorage.getGymData();
      if (localGym != null) {
        gymName = localGym['name'] as String?;
        logoUrl = localGym['logo_url'] as String?;
      }

      // Fetch fresh /me from server to verify account is active
      try {
        final response = await ApiService.get('/auth/me').timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final freshUser = AppUser.fromJson(response.data['user']);
          role = freshUser.role;
          gymId = freshUser.gymId;
          
          await AuthStorage.updateUserData(freshUser.toJson());

          final freshGym = response.data['gym'];
          if (freshGym != null) {
            gymName = freshGym['name'] as String?;
            logoUrl = freshGym['logo_url'] as String?;
            await AuthStorage.updateGymData(freshGym);
          }
        }
      } catch (e) {
        debugPrint('AuthNotifier: Remote verification failed, using cached fallback: $e');
      }

      role ??= 'member';

      bool isGymActive = true;
      if (gymId != null && role == 'admin') {
        try {
          final response = await ApiService.get('/admin/gym/subscription');
          if (response.statusCode == 200 && response.data != null) {
            final gymData = response.data;
            gymName = gymData['name'] as String?;
            logoUrl = gymData['logo_url'] as String?;
            final status = gymData['status'];
            final endDateStr = gymData['subscription_end_date'];

            if (status != 'active') {
              isGymActive = false;
            } else if (endDateStr != null) {
              final endDate = DateTime.parse(endDateStr);
              if (endDate.isBefore(DateTime.now())) {
                isGymActive = false;
              }
            }
          }
        } catch (e) {
          debugPrint('AuthNotifier: Error checking gym status: $e');
        }
      }

      debugPrint('AuthNotifier: Final role determined: $role, GymId: $gymId, GymName: $gymName, isGymActive: $isGymActive');
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        role: role,
        gymId: gymId,
        gymName: gymName,
        logoUrl: logoUrl,
        isGymActive: isGymActive,
      );
    } catch (e) {
      debugPrint('AuthNotifier: Error in _loadUserRole: $e');
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        role: 'member',
        isGymActive: true,
        errorMessage: 'Failed to load user details: $e',
      );
    }
  }

  /// Re-fetches gym details
  Future<void> refreshGymDetails() async {
    final gymId = state.gymId;
    if (gymId == null || !state.isAuthenticated) return;

    try {
      final response = await ApiService.get('/admin/gym/subscription');
      if (response.statusCode == 200 && response.data != null) {
        final gymData = response.data;
        final gymName = gymData['name'] as String?;
        final logoUrl = gymData['logo_url'] as String?;
        final status = gymData['status'];
        final endDateStr = gymData['subscription_end_date'];
        
        bool isGymActive = true;
        if (status != 'active') {
          isGymActive = false;
        } else if (endDateStr != null) {
          final endDate = DateTime.parse(endDateStr);
          if (endDate.isBefore(DateTime.now())) {
            isGymActive = false;
          }
        }

        state = state.copyWith(
          gymName: gymName,
          logoUrl: logoUrl,
          isGymActive: isGymActive,
        );
        debugPrint('AuthNotifier: Gym details refreshed manually: $gymName');
      }
    } catch (e) {
      debugPrint('AuthNotifier: Error refreshing gym details: $e');
    }
  }

  /// Reload user details
  Future<void> reloadUser() async {
    final u = state.user;
    if (u != null) {
      await _loadUserRole(u);
    }
  }

  /// Sign in
  Future<bool> signIn({required String email, required String password}) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _repo.signIn(email: email, password: password);
      if (response.user != null) {
        await _loadUserRole(response.user!);
        return true;
      }
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Login failed. Please try again.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Sign up
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String gymId,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _repo.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        gymId: gymId,
      );
      if (response.user != null) {
        await _loadUserRole(response.user!);
        return true;
      }
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Registration failed.',
      );
      return false;
    } catch (e) {
      debugPrint('Error during sign up: $e');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> sendPasswordResetOtp(String email) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final success = await _repo.sendResetOtp(email);
      if (success) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return true;
      }
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Failed to send reset email.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Error: $e',
      );
      return false;
    }
  }

  Future<bool> verifyPasswordResetOtp(String email, String otp) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final resetToken = await _repo.verifyResetOtp(email, otp);
      if (resetToken != null) {
        state = state.copyWith(
          status: AuthStatus.authenticated,
          isResettingPassword: true,
          resetToken: resetToken,
        );
        return true;
      }
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Invalid or expired OTP.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Verification error: $e',
      );
      return false;
    }
  }

  Future<bool> finalizePasswordReset(String newPassword) async {
    final resetToken = state.resetToken;
    if (resetToken == null) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'Missing reset token');
      return false;
    }

    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final success = await _repo.finalizePasswordReset(resetToken, newPassword);
      if (success) {
        await signOut();
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          isResettingPassword: false,
          resetToken: null,
        );
        return true;
      }
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Failed to update password.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Reset error: $e',
      );
      return false;
    }
  }
}

// === Providers ===
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

final publicGymsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final response = await ApiService.get('/auth/gyms');
  if (response.statusCode == 200) {
    return List<Map<String, dynamic>>.from(response.data);
  }
  return [];
});

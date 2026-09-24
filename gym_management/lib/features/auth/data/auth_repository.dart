import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:gym_management/core/services/api_service.dart';
import 'package:gym_management/core/services/auth_storage.dart';

/// Local User model mimicking the required user object structure
class AppUser {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final String? role;
  final String? gymId;

  AppUser({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.role,
    this.gymId,
  });

  Map<String, dynamic> get userMetadata => {
    'full_name': fullName,
    'phone': phone,
    'role': role,
    'gym_id': gymId,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String?,
      gymId: json['gym_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone': phone,
      'avatar_url': avatarUrl,
      'role': role,
      'gym_id': gymId,
    };
  }
}

/// Helper model for auth response
class AuthResponse {
  final AppUser? user;
  final String? accessToken;
  final String? refreshToken;

  AuthResponse({this.user, this.accessToken, this.refreshToken});
}

/// Repository handling all Node.js auth operations
class AuthRepository {
  final _authStateController = StreamController<bool>.broadcast();

  /// Sign up with email, password, and metadata
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String? gymId,
  }) async {
    try {
      final response = await ApiService.post('/auth/signup', data: {
        'email': email,
        'password': password,
        'full_name': fullName,
        'phone': phone,
        'gym_id': gymId,
        'role': 'member',
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;
        final user = AppUser.fromJson(data['user']);
        final access = data['access_token'];
        final refresh = data['refresh_token'];

        await AuthStorage.saveSession(
          accessToken: access,
          refreshToken: refresh,
          userData: user.toJson(),
          gymData: data['gym'],
        );

        _authStateController.add(true);
        return AuthResponse(user: user, accessToken: access, refreshToken: refresh);
      }
      throw Exception(response.data['error'] ?? 'Sign up failed');
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['error'] ?? e.response?.data?['message'] ?? 'Sign up failed';
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        final user = AppUser.fromJson(data['user']);
        final access = data['access_token'];
        final refresh = data['refresh_token'];

        await AuthStorage.saveSession(
          accessToken: access,
          refreshToken: refresh,
          userData: user.toJson(),
          gymData: data['gym'],
        );

        _authStateController.add(true);
        return AuthResponse(user: user, accessToken: access, refreshToken: refresh);
      }
      throw Exception(response.data['error'] ?? 'Sign in failed');
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['error'] ?? e.response?.data?['message'] ?? 'Sign in failed';
      throw Exception(errorMsg);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await ApiService.post('/auth/logout');
    } catch (e) {
      debugPrint('Sign out API error: $e');
    } finally {
      await AuthStorage.clearSession();
      _authStateController.add(false);
    }
  }

  /// Send password reset OTP
  Future<bool> sendResetOtp(String email) async {
    try {
      final response = await ApiService.post('/auth/forgot-password', data: {'email': email});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error sending reset OTP: $e');
      return false;
    }
  }

  /// Verify password reset OTP
  Future<String?> verifyResetOtp(String email, String otp) async {
    try {
      final response = await ApiService.post('/auth/verify-otp', data: {'email': email, 'otp': otp});
      if (response.statusCode == 200) {
        return response.data['reset_token'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error verifying reset OTP: $e');
      return null;
    }
  }

  /// Finalize password reset
  Future<bool> finalizePasswordReset(String resetToken, String newPassword) async {
    try {
      final response = await ApiService.post('/auth/reset-password', data: {
        'reset_token': resetToken,
        'new_password': newPassword,
      });
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error finalizing password reset: $e');
      return false;
    }
  }

  /// Check if user is logged in
  Future<bool> get isLoggedIn async {
    final token = await AuthStorage.getAccessToken();
    return token != null;
  }

  /// Get the current user profile from storage
  Future<AppUser?> get currentUser async {
    final data = await AuthStorage.getUserData();
    if (data == null) return null;
    return AppUser.fromJson(data);
  }

  /// Get the user role from API/storage
  Future<String?> getUserRole(String userId) async {
    try {
      final user = await currentUser;
      if (user != null && user.id == userId) {
        return user.role;
      }
      final response = await ApiService.get('/auth/me');
      if (response.statusCode == 200) {
        final userData = response.data['user'];
        return userData['role'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return null;
    }
  }

  /// Stream of authentication state updates
  Stream<bool> get authStateChanges => _authStateController.stream;
}

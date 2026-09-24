import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage();

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserData = 'user_data';
  static const _keyGymData = 'gym_data';

  /// Save both tokens and metadata
  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> userData,
    Map<String, dynamic>? gymData,
  }) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAccessToken, accessToken);
      await prefs.setString(_keyRefreshToken, refreshToken);
      await prefs.setString(_keyUserData, jsonEncode(userData));
      if (gymData != null) {
        await prefs.setString(_keyGymData, jsonEncode(gymData));
      } else {
        await prefs.remove(_keyGymData);
      }
    } else {
      await _storage.write(key: _keyAccessToken, value: accessToken);
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
      await _storage.write(key: _keyUserData, value: jsonEncode(userData));
      if (gymData != null) {
        await _storage.write(key: _keyGymData, value: jsonEncode(gymData));
      } else {
        await _storage.delete(key: _keyGymData);
      }
    }
  }

  /// Get the active Access Token
  static Future<String?> getAccessToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyAccessToken);
    }
    return await _storage.read(key: _keyAccessToken);
  }

  /// Get the active Refresh Token
  static Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRefreshToken);
    }
    return await _storage.read(key: _keyRefreshToken);
  }

  /// Get saved User profile metadata
  static Future<Map<String, dynamic>?> getUserData() async {
    final String? data;
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      data = prefs.getString(_keyUserData);
    } else {
      data = await _storage.read(key: _keyUserData);
    }
    if (data == null) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Get saved Gym metadata
  static Future<Map<String, dynamic>?> getGymData() async {
    final String? data;
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      data = prefs.getString(_keyGymData);
    } else {
      data = await _storage.read(key: _keyGymData);
    }
    if (data == null) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Update saved user details locally
  static Future<void> updateUserData(Map<String, dynamic> updates) async {
    final current = await getUserData() ?? {};
    final merged = {...current, ...updates};
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserData, jsonEncode(merged));
    } else {
      await _storage.write(key: _keyUserData, value: jsonEncode(merged));
    }
  }

  /// Update saved gym details locally
  static Future<void> updateGymData(Map<String, dynamic> updates) async {
    final current = await getGymData() ?? {};
    final merged = {...current, ...updates};
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyGymData, jsonEncode(merged));
    } else {
      await _storage.write(key: _keyGymData, value: jsonEncode(merged));
    }
  }

  /// Delete all stored credentials
  static Future<void> clearSession() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAccessToken);
      await prefs.remove(_keyRefreshToken);
      await prefs.remove(_keyUserData);
      await prefs.remove(_keyGymData);
    } else {
      await _storage.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyRefreshToken);
      await _storage.delete(key: _keyUserData);
      await _storage.delete(key: _keyGymData);
    }
  }
}

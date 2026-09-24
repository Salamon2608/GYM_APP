import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_management/core/constants/app_constants.dart';
import 'package:gym_management/core/services/auth_storage.dart';

class ApiService {
  static final StreamController<DioException> _errorStreamController =
      StreamController<DioException>.broadcast();

  static Stream<DioException> get errorStream => _errorStreamController.stream;

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  static Dio get dio => _dio;

  static Future<bool> pingServer() async {
    try {
      final apiUri = Uri.parse(AppConstants.apiBaseUrl);
      final healthUrl =
          '${apiUri.scheme}://${apiUri.host}${apiUri.hasPort ? ":${apiUri.port}" : ""}/health';
      final response = await Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      )).get(healthUrl);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static void initialize() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await AuthStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        // Broadcast connection/offline errors
        final errorStr = error.toString().toLowerCase();
        final isOffline = error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.connectionError ||
            errorStr.contains('socket') ||
            errorStr.contains('connection') ||
            errorStr.contains('network') ||
            errorStr.contains('failed host lookup') ||
            errorStr.contains('handshake');
        if (isOffline) {
          _errorStreamController.add(error);
        }

        // Handle token expiry refresh if 401 encountered
        if (error.response?.statusCode == 401) {
          final path = error.requestOptions.path;
          // Do not attempt token refresh for public auth endpoints
          if (path.contains('/auth/login') ||
              path.contains('/auth/signup') ||
              path.contains('/auth/register') ||
              path.contains('/auth/forgot-password') ||
              path.contains('/auth/verify-otp') ||
              path.contains('/auth/reset-password') ||
              path.contains('/auth/refresh')) {
            return handler.next(error);
          }

          final refreshToken = await AuthStorage.getRefreshToken();
          if (refreshToken != null) {
            try {
              final refreshResponse = await Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl))
                  .post('/auth/refresh', data: {'refresh_token': refreshToken});

              if (refreshResponse.statusCode == 200) {
                final newAccess = refreshResponse.data['access_token'];
                final newRefresh = refreshResponse.data['refresh_token'];

                final userData = await AuthStorage.getUserData() ?? {};
                final gymData = await AuthStorage.getGymData();

                await AuthStorage.saveSession(
                  accessToken: newAccess,
                  refreshToken: newRefresh,
                  userData: userData,
                  gymData: gymData,
                );

                // Retry original request with new token
                final options = error.requestOptions;
                options.headers['Authorization'] = 'Bearer $newAccess';
                final clone = await _dio.fetch(options);
                return handler.resolve(clone);
              }
            } catch (refreshErr) {
              debugPrint('Auth token refresh failed: $refreshErr');
              // Clear session so user goes to login screen
              await AuthStorage.clearSession();
            }
          }
        }
        return handler.next(error);
      },
    ));
  }

  // === HTTP METHODS ===

  static Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      // Cache successful response data
      _saveToCache(path, queryParameters, response.data);
      return response;
    } on DioException catch (e) {
      if (_isConnectionError(e)) {
        final cachedData = await _readFromCache(path, queryParameters);
        if (cachedData != null) {
          debugPrint('🌐 API Offline Fallback: Serving cached data for GET $path');
          return Response(
            requestOptions: e.requestOptions,
            data: cachedData,
            statusCode: 200,
            statusMessage: 'OK (Cached Offline)',
          );
        }
      }
      rethrow;
    }
  }

  static bool _isConnectionError(DioException error) {
    final errorStr = error.toString().toLowerCase();
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        errorStr.contains('socket') ||
        errorStr.contains('connection') ||
        errorStr.contains('network') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('handshake');
  }

  static String _getCacheKey(String path, Map<String, dynamic>? queryParameters) {
    if (queryParameters == null || queryParameters.isEmpty) {
      return 'api_cache_get_$path';
    }
    // Encode query parameters to make the key unique per query
    final sortedParams = Map.fromEntries(
      queryParameters.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return 'api_cache_get_${path}_${jsonEncode(sortedParams)}';
  }

  static Future<void> _saveToCache(String path, Map<String, dynamic>? queryParameters, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getCacheKey(path, queryParameters);
      if (data != null) {
        await prefs.setString(key, jsonEncode(data));
      }
    } catch (e) {
      debugPrint('Failed to save API cache: $e');
    }
  }

  static Future<dynamic> _readFromCache(String path, Map<String, dynamic>? queryParameters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getCacheKey(path, queryParameters);
      final cachedStr = prefs.getString(key);
      if (cachedStr != null) {
        return jsonDecode(cachedStr);
      }
    } catch (e) {
      debugPrint('Failed to read API cache: $e');
    }
    return null;
  }

  static Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await _dio.post(path, data: data, queryParameters: queryParameters);
  }

  static Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await _dio.put(path, data: data, queryParameters: queryParameters);
  }

  static Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await _dio.patch(path, data: data, queryParameters: queryParameters);
  }

  static Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await _dio.delete(path, data: data, queryParameters: queryParameters);
  }

  // === FILE UPLOADS ===

  static Future<String?> uploadFile(
    String path,
    Uint8List bytes,
    String fileName, {
    String fieldName = 'image',
  }) async {
    try {
      final formData = FormData.fromMap({
        fieldName: MultipartFile.fromBytes(
          bytes,
          filename: fileName,
        ),
      });

      final response = await _dio.post(path, data: formData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['publicUrl'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('File upload error to $path: $e');
      return null;
    }
  }
}

import 'dart:typed_data';
import 'package:gym_management/core/services/api_service.dart';


class SuperAdminRepository {

  Future<List<Map<String, dynamic>>> getGyms() async {
    final response = await ApiService.get('/superadmin/gyms');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> createGym({
    required String name,
    required String address,
    required String status,
    required DateTime? subscriptionEndDate,
  }) async {
    final response = await ApiService.post('/superadmin/gyms', data: {
      'name': name,
      'address': address,
      'status': status,
      'subscription_end_date': subscriptionEndDate?.toIso8601String(),
    });
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> updateGym(String id, Map<String, dynamic> data) async {
    await ApiService.put('/superadmin/gyms/$id', data: data);
  }

  Future<List<Map<String, dynamic>>> getGymAdmins(String gymId) async {
    final response = await ApiService.get('/superadmin/gyms/$gymId/admins');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> createUserAccount({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    required String gymId,
  }) async {
    await ApiService.post('/superadmin/users/create', data: {
      'email': email,
      'password': password,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'gym_id': gymId,
    });
  }

  Future<void> updateUserAccount({
    required String userId,
    String? email,
    String? password,
    String? fullName,
    String? phone,
    required String role,
    required String gymId,
  }) async {
    await ApiService.put('/superadmin/users/$userId', data: {
      'email': email,
      'password': password,
      'full_name': fullName,
      'phone': phone,
      'role': role,
      'gym_id': gymId,
    });
  }

  Future<void> addGymSubscription({
    required String gymId,
    required double amount,
    required DateTime validFrom,
    required DateTime validUntil,
    String? notes,
  }) async {
    await ApiService.post('/superadmin/subscriptions', data: {
      'gym_id': gymId,
      'amount': amount,
      'valid_from': validFrom.toIso8601String(),
      'valid_until': validUntil.toIso8601String(),
      'notes': notes,
    });
  }

  // === Platform Plans ===

  Future<List<Map<String, dynamic>>> getPlatformPlans() async {
    final response = await ApiService.get('/superadmin/plans');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<void> createPlatformPlan({
    required String name,
    required String description,
    required double price,
    required int durationMonths,
  }) async {
    await ApiService.post('/superadmin/plans', data: {
      'name': name,
      'description': description,
      'price': price,
      'duration_months': durationMonths,
    });
  }

  Future<void> updatePlatformPlan(String id, Map<String, dynamic> data) async {
    await ApiService.put('/superadmin/plans/$id', data: data);
  }

  Future<void> deletePlatformPlan(String id) async {
    await ApiService.delete('/superadmin/plans/$id');
  }

  Future<void> subscribeGymToPlan({
    required String gymId,
    required Map<String, dynamic> plan,
  }) async {
    await ApiService.post('/superadmin/plans/${plan['id']}/subscribe', data: {
      'gym_id': gymId,
    });
  }

  Future<List<Map<String, dynamic>>> getGymSubscriptions(String gymId) async {
    final response = await ApiService.get('/superadmin/subscriptions/$gymId');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<List<Map<String, dynamic>>> getAllPlatformPayments() async {
    final response = await ApiService.get('/superadmin/payments');
    return List<Map<String, dynamic>>.from(response.data);
  }

  // === Platform Settings (Razorpay) ===

  Future<Map<String, String>> getPlatformRazorpayCredentials() async {
    final response = await ApiService.get('/superadmin/razorpay');
    final Map<String, dynamic> raw = response.data;
    return raw.map((key, value) => MapEntry(key, value.toString()));
  }

  Future<void> updatePlatformRazorpayCredentials({
    required String keyId,
    required String secretEncrypted,
  }) async {
    await ApiService.put('/superadmin/razorpay', data: {
      'key_id': keyId,
      'secret_encrypted': secretEncrypted,
    });
  }

  // === Platform Logo ===

  Future<void> uploadPlatformLogo(Uint8List fileBytes, String fileExt) async {
    try {
      await ApiService.uploadFile('/uploads/platform-logo', fileBytes, 'platform_logo.$fileExt');
    } catch (_) {}
  }

  Future<String?> getPlatformLogoUrl() async {
    try {
      final response = await ApiService.get('/auth/logo');
      return response.data['logo_url'] as String?;
    } catch (_) {
      return null;
    }
  }
}

import 'package:gym_management/core/services/api_service.dart';

class MembershipRepository {
  final String? gymId;
  MembershipRepository({this.gymId});

  /// Get all available membership plans
  Future<List<Map<String, dynamic>>> getMembershipPlans() async {
    final response = await ApiService.get('/member/membership/plans');
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Get user's current active membership
  Future<Map<String, dynamic>?> getActiveMembership(String userId) async {
    try {
      final response = await ApiService.get('/member/membership/active');
      if (response.data == null) return null;
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      return null;
    }
  }

  /// Get membership history
  Future<List<Map<String, dynamic>>> getMembershipHistory(String userId) async {
    final response = await ApiService.get('/member/membership/history');
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Create a Razorpay order via API
  Future<Map<String, dynamic>> createRazorpayOrder({
    required String userId,
    required String planId,
  }) async {
    final response = await ApiService.post('/payments/create-order', data: {
      'plan_id': planId,
      'gym_id': gymId,
      'type': 'member_subscription',
    });

    if (response.statusCode != 200) {
      throw Exception('Failed to create Razorpay order: ${response.data}');
    }

    return Map<String, dynamic>.from(response.data);
  }

  /// Verify Razorpay payment via API
  Future<bool> verifyRazorpayPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final response = await ApiService.post('/payments/verify', data: {
      'razorpay_order_id': orderId,
      'razorpay_payment_id': paymentId,
      'razorpay_signature': signature,
      'gym_id': gymId,
      'type': 'member_subscription',
    });

    if (response.statusCode != 200) {
      throw Exception('Payment verification failed: ${response.data}');
    }

    return response.data['success'] == true;
  }

  /// Purchase a membership plan (create payment record)
  Future<void> purchaseMembership({
    required String userId,
    required String planId,
    required double amount,
    required String paymentMethod,
  }) async {
    await ApiService.post('/member/membership/purchase', data: {
      'plan_id': planId,
      'amount': amount,
      'payment_method': paymentMethod,
    });
  }
}

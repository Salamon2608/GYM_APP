import 'package:gym_management/core/services/api_service.dart';

class PaymentRepository {
  final String? gymId;
  PaymentRepository({this.gymId});

  /// Get the member's payment history
  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    final response = await ApiService.get('/member/payments/history');
    return List<Map<String, dynamic>>.from(response.data);
  }

  /// Get specific receipt details
  Future<Map<String, dynamic>> getPaymentReceipt(String paymentId) async {
    final response = await ApiService.get('/payments/receipt/$paymentId');
    if (response.statusCode != 200) {
      throw Exception('Failed to load receipt: ${response.data}');
    }
    return Map<String, dynamic>.from(response.data);
  }
}

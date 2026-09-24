import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/features/member/data/payment_repository.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';

final paymentRepositoryProvider = Provider.autoDispose<PaymentRepository>((ref) {
  final authState = ref.watch(authProvider);
  return PaymentRepository(gymId: authState.gymId);
});

/// Fetches the member's payment history
final paymentHistoryProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.getPaymentHistory();
});

/// Fetches individual receipt details by payment ID
final paymentReceiptProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, paymentId) async {
  final repo = ref.watch(paymentRepositoryProvider);
  return repo.getPaymentReceipt(paymentId);
});

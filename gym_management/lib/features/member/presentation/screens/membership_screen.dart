import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gym_management/core/router/app_router.dart';
import 'package:gym_management/core/theme/app_theme.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';
import 'package:gym_management/features/member/providers/membership_provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class MembershipScreen extends ConsumerStatefulWidget {
  const MembershipScreen({super.key});

  @override
  ConsumerState<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends ConsumerState<MembershipScreen> {
  bool _isPurchasing = false;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // 1. Verify payment with backend
    setState(() => _isPurchasing = true);
    try {
      final repo = ref.read(membershipRepositoryProvider);
      final success = await repo.verifyRazorpayPayment(
        orderId: response.orderId!,
        paymentId: response.paymentId!,
        signature: response.signature!,
      );

      if (success && mounted) {
        final userId = ref.read(authProvider).user?.id;
        if (userId != null) {
          ref.invalidate(activeMembershipProvider(userId));
          ref.invalidate(membershipHistoryProvider(userId));
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Membership activated successfully! 🎉'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment Failed: ${response.message}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('External Wallet: ${response.walletName}'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
  }

  Future<void> _purchasePlan(Map<String, dynamic> plan) async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: Text(
          'Confirm Purchase',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Purchase "${plan['name']}" for ₹${plan['price']}?\n\nDuration: ${((plan['duration_months'] ?? 1) * 30)} days',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text(
              'Purchase',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isPurchasing = true);

    try {
      final repo = ref.read(membershipRepositoryProvider);

      // 1. Create Razorpay Order via Node.js backend
      final orderData = await repo.createRazorpayOrder(
        userId: user.id,
        planId: plan['id'],
      );

      final orderId = orderData['id'] as String;
      final keyId = orderData['key_id'] as String;

      if (keyId == 'mock' || orderId.startsWith('order_mock_')) {
        // Bypass Razorpay Checkout in mock/test mode
        final mockPaymentId = 'pay_mock_${DateTime.now().millisecondsSinceEpoch}';
        final mockSignature = 'sig_mock_${DateTime.now().millisecondsSinceEpoch}';
        
        final success = await repo.verifyRazorpayPayment(
          orderId: orderId,
          paymentId: mockPaymentId,
          signature: mockSignature,
        );

        if (success && mounted) {
          ref.invalidate(activeMembershipProvider(user.id));
          ref.invalidate(membershipHistoryProvider(user.id));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Membership activated successfully! 🎉 (Mock Payment)'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
        return;
      }

      // 2. Open Razorpay Checkout
      var options = {
        'key': keyId,
        'amount': orderData['amount'],
        'name': 'TRACEFIT',
        'order_id': orderId,
        'description': '${plan['name']} Membership',
        'prefill': {
          'contact': user.userMetadata['phone'] ?? '',
          'email': user.email,
          'method': 'upi', // Force UPI intent
        },
        'external': {
          'wallets': ['paytm'],
        },
      };

      _razorpay.open(options);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed to initiate: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPurchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authProvider).user?.id;
    final plansAsync = ref.watch(membershipPlansProvider);
    final activeMembershipAsync = userId != null
        ? ref.watch(activeMembershipProvider(userId))
        : null;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      appBar: AppBar(
        title: const Text('Membership Plans'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go(AppRoutes.memberDashboard),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded),
            tooltip: 'Payment History',
            onPressed: () => context.push(AppRoutes.memberPaymentHistory),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Membership Card
            if (activeMembershipAsync != null)
              activeMembershipAsync.when(
                data: (membership) {
                  if (membership == null) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.errorColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppTheme.errorColor),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No active membership. Choose a plan below!',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return _buildActiveMembershipCard(membership);
                },
                loading: () => Container(
                  width: double.infinity,
                  height: 130,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),

            // Plans
            Text(
              'Available Plans',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            plansAsync.when(
              data: (plans) {
                if (plans.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.card_membership_outlined,
                          color: AppTheme.textSecondary,
                          size: 48,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No plans available yet',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: plans.map((plan) => _buildPlanCard(plan)).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Error loading plans: $e',
                  style: const TextStyle(color: AppTheme.errorColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveMembershipCard(Map<String, dynamic> membership) {
    final planData = membership['membership_plans'] as Map<String, dynamic>?;
    final planName = planData?['name'] ?? 'Membership';
    final status = membership['status'] ?? 'active';
    final endDateStr = membership['end_date'] ?? '';
    final startDateStr = membership['start_date'] ?? '';
    final endDate = DateTime.tryParse(endDateStr);
    final startDate = DateTime.tryParse(startDateStr);
    final now = DateTime.now();

    final isActive =
        status == 'active' && endDate != null && endDate.isAfter(now);
    final formattedEnd = endDate != null
        ? DateFormat('MMM dd, yyyy').format(endDate)
        : 'N/A';

    // Calculate progress
    double progress = 0.5;
    String remainingText = '';
    if (startDate != null && endDate != null) {
      final totalDays = endDate.difference(startDate).inDays;
      final daysUsed = now.difference(startDate).inDays;
      final daysLeft = endDate.difference(now).inDays;
      progress = totalDays > 0 ? (daysUsed / totalDays).clamp(0.0, 1.0) : 0.0;
      remainingText = '$daysLeft of $totalDays days remaining';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [AppTheme.primaryColor, AppTheme.primaryDark]
              : [Colors.grey.shade700, Colors.grey.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isActive ? AppTheme.primaryColor : Colors.grey).withValues(
              alpha: 0.3,
            ),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$planName Membership',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? 'ACTIVE' : 'EXPIRED',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Expires: $formattedEnd',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            remainingText,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final name = plan['name'] ?? 'Plan';
    final price = plan['price'] ?? 0;
    final months = plan['duration_months'] ?? 1;
    final duration = months * 30;
    final description = plan['description'] ?? '';
    final features = plan['features'] as List<dynamic>? ?? [];

    final isPopular = months >= 3;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPopular
              ? AppTheme.primaryColor.withValues(alpha: 0.5)
              : AppTheme.borderDark,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isPurchasing ? null : () => _purchasePlan(plan),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (isPopular) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.2,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'POPULAR',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$duration days',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹$price',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (features.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...features
                      .take(3)
                      .map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppTheme.successColor,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  f.toString(),
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

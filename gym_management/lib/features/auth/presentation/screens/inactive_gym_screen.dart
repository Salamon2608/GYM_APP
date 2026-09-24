import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/core/services/api_service.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class InactiveGymScreen extends ConsumerStatefulWidget {
  const InactiveGymScreen({super.key});

  @override
  ConsumerState<InactiveGymScreen> createState() => _InactiveGymScreenState();
}

class _InactiveGymScreenState extends ConsumerState<InactiveGymScreen> {
  bool _isLoading = false;
  late Razorpay _razorpay;
  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic>? _selectedPlan;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    try {
      final response = await ApiService.get('/payments/plans');
      if (mounted) {
        setState(() {
          _plans = List<Map<String, dynamic>>.from(response.data);
          if (_plans.isNotEmpty) {
            _selectedPlan = _plans.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching plans: $e');
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isLoading = true);
    
    try {
      final authState = ref.read(authProvider);
      final gymId = authState.gymId;
      
      if (gymId == null) throw Exception('Gym ID not found');
      if (_selectedPlan == null) throw Exception('No plan selected');
      
      // 1. Verify Payment Signature via API
      final verifyResponse = await ApiService.post(
        '/payments/verify',
        data: {
          'razorpay_order_id': response.orderId,
          'razorpay_payment_id': response.paymentId,
          'razorpay_signature': response.signature,
          'gym_id': gymId,
          'type': 'gym_subscription',
          'plan_id': _selectedPlan!['id'],
        },
      );

      if (verifyResponse.statusCode != 200 || verifyResponse.data['success'] != true) {
        throw Exception(verifyResponse.data['error'] ?? 'Payment verification failed');
      }
      
      if (mounted) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Payment Successful'),
            content: Text('Subscription renewed! Payment ID: ${response.paymentId}. Please log out and log in again to refresh your session.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(authProvider.notifier).signOut();
                },
                child: const Text('Log Out'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating subscription: $e')),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message} (Code: ${response.code})')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet: ${response.walletName}')),
    );
  }

  void _handleOnlinePayment() async {
    if (_selectedPlan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a plan first')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authProvider);
      final gymId = authState.gymId;
      if (gymId == null) throw Exception('Gym ID not found');

      final amount = double.tryParse(_selectedPlan!['price']?.toString() ?? '') ?? 0.0;
      
      // 1. Create Razorpay Order via API
      final response = await ApiService.post(
        '/payments/create-order',
        data: {
          'gym_id': gymId,
          'type': 'gym_subscription', // Critical: tells function to use platform keys
          'plan_id': _selectedPlan!['id'],
        },
      );

      if (response.statusCode != 200) {
        throw Exception(response.data['error'] ?? 'Failed to create order');
      }

      final orderData = response.data;
      final orderId = orderData['id'] as String;
      final razorpayKey = orderData['key_id'] as String; // Dynamic key from platform settings

      debugPrint('Razorpay Order Created: $orderId');
      debugPrint('Using Razorpay Key: $razorpayKey');

      if (razorpayKey == 'mock' || orderId.startsWith('order_mock_')) {
        // Bypass Razorpay Checkout in mock/test mode
        final mockPaymentId = 'pay_mock_${DateTime.now().millisecondsSinceEpoch}';
        final mockSignature = 'sig_mock_${DateTime.now().millisecondsSinceEpoch}';
        
        final verifyResponse = await ApiService.post(
          '/payments/verify',
          data: {
            'razorpay_order_id': orderId,
            'razorpay_payment_id': mockPaymentId,
            'razorpay_signature': mockSignature,
            'gym_id': gymId,
            'type': 'gym_subscription',
            'plan_id': _selectedPlan!['id'],
          },
        );

        if (verifyResponse.statusCode != 200 || verifyResponse.data['success'] != true) {
          throw Exception(verifyResponse.data['error'] ?? 'Payment verification failed');
        }
        
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Payment Successful'),
              content: Text('Subscription renewed! (Mock Payment ID: $mockPaymentId). Please log out and log in again to refresh your session.'),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ref.read(authProvider.notifier).signOut();
                  },
                  child: const Text('Log Out'),
                ),
              ],
            ),
          );
        }
        return;
      }

      var options = {
        'key': razorpayKey,
        'amount': (amount * 100).toInt(),
        'name': 'TRACEFIT',
        'description': '${_selectedPlan!['name']} Subscription Renewal',
        'order_id': orderId,
        'retry': {'enabled': true, 'max_count': 1},
        'send_sms_hash': true,
        'prefill': {
          'contact': authState.user?.userMetadata?['phone'] ?? '',
          'email': authState.user?.email ?? '',
          'method': 'upi', // Force UPI intent
        },
      };

      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment initiation failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCashInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pay Cash in Hand'),
        content: const Text(
            'To renew your subscription via Cash in Hand, please contact the platform administrator to organize the payment. '
            'Once the payment is received, the administrator will manually activate your gym\'s subscription.\n\n'
            'Admin Contact: superadmin@example.com / +1 234 567 8900'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final role = authState.role;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
            },
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.block,
                size: 80,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 24),
              Text(
                role == 'admin' ? 'Subscription Expired' : 'Gym Inactive',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                role == 'admin' 
                  ? 'Your gym\'s subscription has expired or is currently inactive. Please renew your subscription using Razorpay to continue.'
                  : 'Your gym\'s subscription has expired or is currently inactive. Please contact your gym administrator.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              if (role == 'admin' && _plans.isNotEmpty) ...[
                const Text(
                  'Select a Membership Plan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ..._plans.map((plan) {
                  final isSelected = _selectedPlan?['id'] == plan['id'];
                  return Card(
                    elevation: isSelected ? 4 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? Colors.indigo : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      onTap: () => setState(() => _selectedPlan = plan),
                      title: Text(
                        plan['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${plan['duration_months']} months - ${plan['description'] ?? ''}',
                      ),
                      trailing: Text(
                        '₹${plan['price']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      leading: Radio<String>(
                        value: plan['id'].toString(),
                        groupValue: _selectedPlan?['id']?.toString(),
                        onChanged: (val) => setState(() => _selectedPlan = plan),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 16),
              if (_isLoading)
                const CircularProgressIndicator()
              else if (role == 'admin') ...[
                ElevatedButton.icon(
                  onPressed: _handleOnlinePayment,
                  icon: const Icon(Icons.payment),
                  label: const Text('Pay with Razorpay'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    minimumSize: const Size(200, 50),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _showCashInstructions,
                  icon: const Icon(Icons.money),
                  label: const Text('Pay Cash in Hand'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    minimumSize: const Size(200, 50),
                  ),
                ),
                const SizedBox(height: 32),
              ],
              if (!_isLoading)
                TextButton.icon(
                  onPressed: () {
                    ref.read(authProvider.notifier).signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

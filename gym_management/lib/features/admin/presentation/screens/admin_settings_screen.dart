import 'package:flutter/material.dart';
import 'package:gym_management/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gym_management/core/services/api_service.dart';
import 'package:gym_management/features/admin/presentation/theme/admin_theme.dart';
import 'package:gym_management/features/admin/providers/admin_providers.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';
import 'package:gym_management/core/utils/validators.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:gym_management/core/services/encryption_service.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  // Gym Info
  final _gymNameCtrl = TextEditingController(text: 'My Gym');
  final _gymPhoneCtrl = TextEditingController();
  final _gymEmailCtrl = TextEditingController();
  final _gymAddressCtrl = TextEditingController();

  // GPS Location
  final _gymLatCtrl = TextEditingController();
  final _gymLngCtrl = TextEditingController();

  // Admin Profile
  final _adminNameCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();
  final _razorpayKeyController = TextEditingController();
  final _razorpaySecretController = TextEditingController();
  bool _obscureSecret = true;

  // Toggles & Configs
  bool _autoApproveVideos = false;
  bool _requireGpsCheckin = true;
  int _gpsRadius = 100;
  int _expiryReminderDays = 7;

  bool _saving = false;
  bool _fetchingLocation = false;

  // Subscription Info
  late Razorpay _razorpay;
  String _gymStatus = 'active';
  DateTime? _subscriptionEndDate;

  // App Membership Payment State
  Map<String, dynamic>? _selectedAppMembershipPlan;
  String? _currentRazorpayOrderId;
  bool _uploadingLogo = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadAdminProfile();
    // Only load if gymId is already available, otherwise wait for ref.listen
    final gymId = ref.read(adminRepositoryProvider).gymId;
    if (gymId != null) {
      _loadGymLocation();
    }
  }

  Future<void> _uploadLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _uploadingLogo = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final url = await repo.uploadGymLogo(image);
      
      if (url != null) {
        // Refresh auth state to show new logo in shell
        await ref.read(authProvider.notifier).refreshGymDetails();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logo uploaded successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  Future<void> _loadAdminProfile() async {
    final user = ref.read(authProvider).user;
    if (user != null) {
      setState(() {
        _adminEmailCtrl.text = user.email;
        _adminNameCtrl.text =
            user.userMetadata['full_name'] as String? ?? 'Admin';
      });
    }
  }

  Future<void> _loadGymLocation() async {
    final repo = ref.read(adminRepositoryProvider);

    // Load Gym Location & Info
    final loc = await repo.getGymLocation();
    if (loc != null && mounted) {
      setState(() {
        _gymLatCtrl.text = loc['latitude']?.toString() ?? '';
        _gymLngCtrl.text = loc['longitude']?.toString() ?? '';
        _gpsRadius = (loc['radius_meters'] as int?) ?? 100;
        if (loc['name'] != null) _gymNameCtrl.text = loc['name'];
        if (loc['address'] != null) _gymAddressCtrl.text = loc['address'];
        if (loc['phone'] != null) _gymPhoneCtrl.text = loc['phone'];
        if (loc['email'] != null) _gymEmailCtrl.text = loc['email'];
      });
    }

    // Load App Settings
    final settings = await repo.getAppSettings();
    if (mounted) {
      setState(() {
        _autoApproveVideos = settings['auto_approve_trainer_videos'] == true;
        _requireGpsCheckin = settings['require_gps_check_in'] != false;
      });
    }

    // Load Subscription Info
    try {
      final sub = await repo.getGymSubscription();
      if (mounted) {
        setState(() {
          _gymStatus = sub['status'] ?? 'active';
          if (sub['subscription_end_date'] != null) {
            _subscriptionEndDate = DateTime.tryParse(sub['subscription_end_date']);
          }
          
          // Load Razorpay Credentials from gym record
          _razorpayKeyController.text = sub['razorpay_key'] ?? '';
          final encryptedSecret = sub['razorpay_secret_encrypted'] ?? '';
          if (encryptedSecret.isNotEmpty) {
            try {
              _razorpaySecretController.text = EncryptionService.decrypt(encryptedSecret);
            } catch (e) {
              debugPrint('Error decrypting Razorpay secret: $e');
              _razorpaySecretController.text = '';
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading subscription: $e');
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    _gymNameCtrl.dispose();
    _gymPhoneCtrl.dispose();
    _gymEmailCtrl.dispose();
    _gymAddressCtrl.dispose();
    _gymLatCtrl.dispose();
    _gymLngCtrl.dispose();
    _adminNameCtrl.dispose();
    _adminEmailCtrl.dispose();
    _razorpayKeyController.dispose();
    _razorpaySecretController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _saving = true);
    
    try {
      final repo = ref.read(adminRepositoryProvider);
      final gymId = repo.gymId;
      if (gymId == null) throw Exception('Gym ID not available');
      
      // Extend current end date or start from now if expired
      DateTime startDate = DateTime.now();
      if (_subscriptionEndDate != null && _subscriptionEndDate!.isAfter(DateTime.now())) {
        startDate = _subscriptionEndDate!;
      }
      
      final durationMonths = _selectedAppMembershipPlan?['duration_months'] as int? ?? 1;
      final newEndDate = startDate.add(Duration(days: durationMonths * 30));

      // 1. Verify Payment Signature via API
      final verifyResponse = await ApiService.post(
        '/payments/verify',
        data: {
          'razorpay_order_id': response.orderId,
          'razorpay_payment_id': response.paymentId,
          'razorpay_signature': response.signature,
          'gym_id': gymId,
          'type': 'gym_subscription',
          'plan_id': _selectedAppMembershipPlan!['id'],
        },
      );

      if (verifyResponse.statusCode != 200 || verifyResponse.data['success'] != true) {
        throw Exception(verifyResponse.data['error'] ?? 'Payment verification failed');
      }
      
      if (mounted) {
        setState(() {
          _gymStatus = 'active';
          _subscriptionEndDate = newEndDate;
          _saving = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Subscription renewed successfully! Payment ID: ${response.paymentId}'),
            backgroundColor: AdminTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating subscription: $e'), backgroundColor: AdminTheme.error),
        );
      }
    } finally {
      _selectedAppMembershipPlan = null;
      _currentRazorpayOrderId = null;
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message} (Code: ${response.code})'), backgroundColor: AdminTheme.error),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet: ${response.walletName}')),
    );
  }

  Future<void> _handleOnlinePayment() async {
    final authState = ref.read(authProvider);
    final gymId = authState.gymId;
    if (gymId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wait for gym data to load')));
      return;
    }
    
    setState(() => _saving = true);
    try {
      // 1. Fetch active platform plans
      final response = await ApiService.get('/payments/plans');
      final plansResponse = List<Map<String, dynamic>>.from(response.data);
          
      if (!mounted) return;
      setState(() => _saving = false);

      if (plansResponse.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active membership plans available.'), backgroundColor: AdminTheme.error)
        );
        return;
      }

      // 2. Show Modal to Select Plan
      final selectedPlan = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        backgroundColor: AdminTheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => _PlanSelectionSheet(plans: plansResponse),
      );

      if (selectedPlan == null) return; // User cancelled
      _selectedAppMembershipPlan = selectedPlan;

      // 3. Create Razorpay Order
      setState(() => _saving = true);
      
      final orderResponse = await ApiService.post(
        '/payments/create-order',
        data: {
          'gym_id': gymId,
          'type': 'gym_subscription',
          'plan_id': selectedPlan['id'],
        },
      );

      if (orderResponse.statusCode != 200) {
        throw Exception(orderResponse.data['error'] ?? 'Failed to create order');
      }

      final orderData = orderResponse.data;
      final orderId = orderData['id'] as String;
      _currentRazorpayOrderId = orderId;
      final razorpayKey = orderData['key_id'] as String;
      final amount = double.tryParse(selectedPlan['price']?.toString() ?? '') ?? 0.0;

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
            'plan_id': selectedPlan['id'],
          },
        );

        if (verifyResponse.statusCode != 200 || verifyResponse.data['success'] != true) {
          throw Exception(verifyResponse.data['error'] ?? 'Payment verification failed');
        }
        
        // Extend current end date or start from now if expired
        DateTime startDate = DateTime.now();
        if (_subscriptionEndDate != null && _subscriptionEndDate!.isAfter(DateTime.now())) {
          startDate = _subscriptionEndDate!;
        }
        
        final durationMonths = selectedPlan['duration_months'] as int? ?? 1;
        final newEndDate = startDate.add(Duration(days: durationMonths * 30));

        if (mounted) {
          setState(() {
            _gymStatus = 'active';
            _subscriptionEndDate = newEndDate;
            _saving = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Subscription renewed successfully! (Mock Payment ID: $mockPaymentId)'),
              backgroundColor: AdminTheme.success,
            ),
          );
        }
        return;
      }

      var options = {
        'key': razorpayKey,
        'amount': (amount * 100).toInt(),
        'name': 'TRACEFIT',
        'description': '${selectedPlan['name']} Subscription Renewal',
        'order_id': orderId,
        'retry': {'enabled': true, 'max_count': 1},
        'send_sms_hash': true,
        'prefill': {
          'contact': _gymPhoneCtrl.text.isNotEmpty ? _gymPhoneCtrl.text : authState.user?.userMetadata?['phone'] ?? '',
          'email': _gymEmailCtrl.text.isNotEmpty ? _gymEmailCtrl.text : authState.user?.email ?? '',
          'method': 'upi',
        },
      };

      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment initiation failed: $e'), backgroundColor: AdminTheme.error)
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showCashInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminTheme.radiusLg)),
        title: const Text('Pay Cash in Hand', style: TextStyle(color: Colors.white)),
        content: const Text(
            'To renew your subscription via Cash in Hand, please contact the platform administrator to organize the payment. '
            'Once the payment is received, the administrator will manually activate your gym\'s subscription.\n\n'
            'Admin Contact: superadmin@example.com / +1 234 567 8900',
            style: TextStyle(color: AdminTheme.textSecondary)),
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
    // Listen for changes to the repository (which depends on gymId)
    // to reload data when the admin session is fully ready.
    ref.listen(adminRepositoryProvider, (previous, next) {
      if (previous?.gymId == null && next.gymId != null) {
        _loadGymLocation();
      }
    });

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page title
            Text('Settings', style: AdminTheme.headingLarge),
            const SizedBox(height: 4),
            Text('Manage your gym configuration', style: AdminTheme.bodySmall),
            const SizedBox(height: 20),

            // ── Gym Info ──

            _sectionHeader('Admin Profile', Icons.person_rounded),
            const SizedBox(height: 10),
            _buildSettingsCard([
              _settingsField(
                _adminNameCtrl,
                'Profile Name',
                Icons.badge_rounded,
                validator: Validators.validateName,
              ),
              _settingsField(
                _adminEmailCtrl,
                'Email (Read Only)',
                Icons.alternate_email_rounded,
                readOnly: true,
              ),
            ]),
            const SizedBox(height: 24),

            // ── Gym Info ──
            _sectionHeader('Gym Information', Icons.business_rounded),
            const SizedBox(height: 10),
            _buildSettingsCard([
              // ── Gym Logo Upload ──
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AdminTheme.card,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AdminTheme.border,
                                width: 2,
                              ),
                              image: ref.watch(authProvider).logoUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        AppConstants.getFullImageUrl(
                                          ref.watch(authProvider).logoUrl!,
                                        ),
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: ref.watch(authProvider).logoUrl == null
                                ? const Icon(
                                    Icons.fitness_center_rounded,
                                    color: AdminTheme.textMuted,
                                    size: 40,
                                  )
                                : null,
                          ),
                          if (_uploadingLogo)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AdminTheme.orange,
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _uploadingLogo ? null : _uploadLogo,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AdminTheme.orange,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Gym Logo',
                        style: AdminTheme.bodyLarge.copyWith(
                          color: AdminTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(color: AdminTheme.border, height: 1),
              _settingsField(
                _gymNameCtrl,
                'Gym Name',
                Icons.fitness_center,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              _settingsField(
                _gymPhoneCtrl,
                'Phone Number',
                Icons.phone_rounded,
                keyboard: TextInputType.phone,
                validator: Validators.validatePhone,
              ),
              _settingsField(
                _gymEmailCtrl,
                'Contact Email',
                Icons.email_rounded,
                keyboard: TextInputType.emailAddress,
                validator: Validators.validateEmail,
              ),
              _settingsField(
                _gymAddressCtrl,
                'Address',
                Icons.location_on_rounded,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
            ]),
            const SizedBox(height: 24),

            // ── Razorpay Configuration ──
            _sectionHeader('Razorpay Configuration', Icons.payment_rounded),
            const SizedBox(height: 10),
            _buildRazorpaySection(),
            const SizedBox(height: 24),

            // ── App Configuration ──
            _sectionHeader('App Configuration', Icons.tune_rounded),
            const SizedBox(height: 10),
            _buildSettingsCard([
              _settingsToggle(
                'Auto-Approve Trainer Videos',
                'Skip manual approval for trainer-uploaded videos',
                _autoApproveVideos,
                (v) => setState(() => _autoApproveVideos = v),
              ),
              const Divider(color: AdminTheme.border, height: 1),
              _settingsToggle(
                'Require GPS Check-In',
                'Members must be within gym radius to check in',
                _requireGpsCheckin,
                (v) => setState(() => _requireGpsCheckin = v),
              ),
              const Divider(color: AdminTheme.border, height: 1),
              // GPS Location — auto-detect button + display
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Gym GPS Location',
                            style: AdminTheme.bodyLarge.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _fetchingLocation
                              ? null
                              : _fetchCurrentLocation,
                          icon: _fetchingLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.my_location_rounded, size: 18),
                          label: Text(
                            _fetchingLocation
                                ? 'Detecting...'
                                : 'Detect Location',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminTheme.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AdminTheme.radiusMd,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _settingsField(
                _gymLatCtrl,
                'Latitude',
                Icons.north_rounded,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (_requireGpsCheckin) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid number';
                  }
                  return null;
                },
              ),
              _settingsField(
                _gymLngCtrl,
                'Longitude',
                Icons.east_rounded,
                keyboard: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (_requireGpsCheckin) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid number';
                  }
                  return null;
                },
              ),
              const Divider(color: AdminTheme.border, height: 1),
              _settingsSlider(
                'GPS Radius',
                '${_gpsRadius}m',
                _gpsRadius.toDouble(),
                50,
                500,
                (v) => setState(() => _gpsRadius = v.round()),
              ),
              const Divider(color: AdminTheme.border, height: 1),
              _settingsSlider(
                'Expiry Reminder Days',
                '$_expiryReminderDays days before',
                _expiryReminderDays.toDouble(),
                1,
                30,
                (v) => setState(() => _expiryReminderDays = v.round()),
              ),
            ]),
            const SizedBox(height: 24),

            // ── App Membership ──
            _sectionHeader('App Membership', Icons.card_membership_rounded),
            const SizedBox(height: 10),
            _buildSettingsCard([
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Status',
                              style: AdminTheme.label,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _gymStatus == 'active' 
                                  ? AdminTheme.success.withValues(alpha: 0.1) 
                                  : AdminTheme.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _gymStatus.toUpperCase(),
                                style: AdminTheme.badgeText.copyWith(
                                  color: _gymStatus == 'active' ? AdminTheme.success : AdminTheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_subscriptionEndDate != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Expires On',
                                style: AdminTheme.label,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd MMM yyyy').format(_subscriptionEndDate!),
                                style: AdminTheme.bodySmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _handleOnlinePayment,
                            icon: const Icon(Icons.payment, size: 18),
                            label: const Text('Pay with Razorpay'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showCashInstructions,
                            icon: const Icon(Icons.money, size: 18),
                            label: const Text('Cash in Hand'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: AdminTheme.border),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ]),

            // ── Danger Zone ──
            _sectionHeader('Danger Zone', Icons.warning_amber_rounded),
            const SizedBox(height: 10),
            _buildSettingsCard([
              _dangerButton(
                'Clear All Reminder Logs',
                'You have a new reminder from TRACEFIT.',
                Icons.delete_sweep_rounded,
                () => _confirmDanger(
                  'Clear Reminder Logs',
                  'This will permanently delete all reminder log entries.',
                  () async {
                    final repo = ref.read(adminRepositoryProvider);
                    await repo.clearReminderLogs();
                  },
                ),
              ),
            ]),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                  ),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 20),
                label: Text(
                  _saving ? 'Saving...' : 'Save Settings',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                onPressed: _saving ? null : _saveSettings,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // SECTION HEADER
  // ═══════════════════════════════════════════════

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AdminTheme.orange, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: AdminTheme.headingSmall.copyWith(
            color: AdminTheme.textPrimary,
          ),
        ),
      ],
    );
  }


  // ═══════════════════════════════════════════════
  // SETTINGS CARD (container)
  // ═══════════════════════════════════════════════

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AdminTheme.card,
        borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Column(children: children),
    );
  }

  // ═══════════════════════════════════════════════
  // SETTINGS FIELD
  // ═══════════════════════════════════════════════

  Widget _settingsField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    bool readOnly = false,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        readOnly: readOnly,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        obscureText: obscureText,
        style: TextStyle(
          color: readOnly ? AdminTheme.textSecondary : AdminTheme.textPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AdminTheme.textSecondary, fontSize: 13),
          prefixIcon: Icon(icon, color: AdminTheme.textMuted, size: 20),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: readOnly
              ? AdminTheme.scaffold.withValues(alpha: 0.5)
              : AdminTheme.scaffold,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
            borderSide: const BorderSide(color: AdminTheme.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
            borderSide: const BorderSide(color: AdminTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
            borderSide: BorderSide(
              color: readOnly ? AdminTheme.border : AdminTheme.orange,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 12,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // SETTINGS TOGGLE
  // ═══════════════════════════════════════════════

  Widget _settingsToggle(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AdminTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AdminTheme.label),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AdminTheme.orange,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // SETTINGS SLIDER
  // ═══════════════════════════════════════════════

  Widget _settingsSlider(
    String title,
    String valueLabel,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AdminTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AdminTheme.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  valueLabel,
                  style: AdminTheme.badgeText.copyWith(
                    color: AdminTheme.orange,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AdminTheme.orange,
              inactiveTrackColor: AdminTheme.border,
              thumbColor: AdminTheme.orange,
              overlayColor: AdminTheme.orange.withValues(alpha: 0.12),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: (max - min).toInt(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // DANGER BUTTON
  // ═══════════════════════════════════════════════

  Widget _dangerButton(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AdminTheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AdminTheme.error, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AdminTheme.bodyLarge.copyWith(
                      color: AdminTheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(subtitle, style: AdminTheme.label),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AdminTheme.error,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // RAZORPAY SECTION
  // ═══════════════════════════════════════════════

  Widget _buildRazorpaySection() {
    return _buildSettingsCard([
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Members will pay directly to this Razorpay account.',
              style: AdminTheme.label,
            ),
            const SizedBox(height: 16),
            _settingsField(
              _razorpayKeyController,
              'Razorpay Key ID',
              Icons.vpn_key_rounded,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            _settingsField(
              _razorpaySecretController,
              'Razorpay Secret Key',
              Icons.lock_outline_rounded,
              obscureText: _obscureSecret,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureSecret ? Icons.visibility : Icons.visibility_off,
                  color: AdminTheme.textSecondary,
                ),
                onPressed: () => setState(() => _obscureSecret = !_obscureSecret),
              ),
            ),
          ],
        ),
      ),
    ]);
  }

  // ═══════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════

  Future<void> _fetchCurrentLocation() async {
    setState(() => _fetchingLocation = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location services are disabled. Please enable GPS.',
              ),
              backgroundColor: AdminTheme.error,
            ),
          );
        }
        return;
      }

      // Check / request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied.'),
                backgroundColor: AdminTheme.error,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission permanently denied. Enable in device settings.',
              ),
              backgroundColor: AdminTheme.error,
            ),
          );
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() {
          _gymLatCtrl.text = position.latitude.toStringAsFixed(6);
          _gymLngCtrl.text = position.longitude.toStringAsFixed(6);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '📍 Location detected: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
            ),
            backgroundColor: AdminTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error detecting location: $e'),
            backgroundColor: AdminTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(adminRepositoryProvider);

      // 1. Save Admin Profile
      if (_adminNameCtrl.text.trim().isNotEmpty) {
        await repo.updateAdminProfile(fullName: _adminNameCtrl.text.trim());
      }

      // 1. Update basic info
      await repo.updateGymInfo(
        name: _gymNameCtrl.text.trim(),
        address: _gymAddressCtrl.text.trim(),
        phone: _gymPhoneCtrl.text.trim(),
        email: _gymEmailCtrl.text.trim(),
        latitude: double.tryParse(_gymLatCtrl.text) ?? 0.0,
        longitude: double.tryParse(_gymLngCtrl.text) ?? 0.0,
        radiusMeters: _gpsRadius,
      );

      // 2. Update Razorpay credentials
      final encryptedSecret = EncryptionService.encrypt(_razorpaySecretController.text.trim());
      await repo.updateRazorpayCredentials(
        keyId: _razorpayKeyController.text.trim(),
        secretEncrypted: encryptedSecret,
      );

      // 3. Save App Settings
      await repo.updateAppSetting(
        'auto_approve_trainer_videos',
        _autoApproveVideos,
      );
      await repo.updateAppSetting('require_gps_check_in', _requireGpsCheckin);

      // 4. Refresh auth state with new gym name/status
      await ref.read(authProvider.notifier).refreshGymDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Settings saved successfully'),
            backgroundColor: AdminTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AdminTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDanger(
    String title,
    String message,
    Future<void> Function() action,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminTheme.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
        ),
        title: Text(title, style: const TextStyle(color: AdminTheme.error)),
        content: Text(
          message,
          style: TextStyle(color: AdminTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AdminTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: AdminTheme.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await action();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Done'),
              backgroundColor: AdminTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}

class _PlanSelectionSheet extends StatelessWidget {
  final List<dynamic> plans;
  const _PlanSelectionSheet({required this.plans});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Membership Plan', style: AdminTheme.headingMedium),
          const SizedBox(height: 8),
          Text('Choose a plan to renew your gym\'s app access.', style: AdminTheme.bodySmall),
          const SizedBox(height: 16),
          ...plans.map((plan) {
            final price = plan['price'];
            final name = plan['name'];
            final duration = plan['duration_months'];
            return Card(
              color: AdminTheme.card,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                side: const BorderSide(color: AdminTheme.border),
              ),
              child: ListTile(
                title: Text(name, style: AdminTheme.bodyLarge),
                subtitle: Text('$duration Months', style: AdminTheme.label),
                trailing: Text('₹$price', style: AdminTheme.headingMedium.copyWith(color: AdminTheme.orange)),
                onTap: () => Navigator.pop(context, plan),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}


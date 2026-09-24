import 'package:flutter/material.dart';
import 'package:gym_management/core/constants/app_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gym_management/features/admin/presentation/theme/admin_theme.dart';
import 'package:gym_management/core/services/encryption_service.dart';
import 'package:gym_management/features/super_admin/providers/super_admin_providers.dart';

class SuperAdminSettingsScreen extends ConsumerStatefulWidget {
  const SuperAdminSettingsScreen({super.key});

  @override
  ConsumerState<SuperAdminSettingsScreen> createState() => _SuperAdminSettingsScreenState();
}

class _SuperAdminSettingsScreenState extends ConsumerState<SuperAdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _razorpayKeyController = TextEditingController();
  final _razorpaySecretController = TextEditingController();
  final _imagePicker = ImagePicker();
  
  bool _obscureSecret = true;
  bool _saving = false;
  bool _loading = true;
  bool _uploadingLogo = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final repo = ref.read(superAdminRepositoryProvider);
      final creds = await repo.getPlatformRazorpayCredentials();
      
      if (creds.containsKey('superadmin_razorpay_key')) {
        _razorpayKeyController.text = creds['superadmin_razorpay_key']!;
      }
      
      if (creds.containsKey('superadmin_razorpay_secret_encrypted')) {
        final encrypted = creds['superadmin_razorpay_secret_encrypted']!;
        if (encrypted.isNotEmpty) {
          try {
            _razorpaySecretController.text = EncryptionService.decrypt(encrypted);
          } catch (e) {
            debugPrint('Error decrypting secret: $e');
            _razorpaySecretController.text = '';
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final repo = ref.read(superAdminRepositoryProvider);
      final secret = _razorpaySecretController.text.trim();
      final encryptedSecret = secret.isNotEmpty ? EncryptionService.encrypt(secret) : '';

      await repo.updatePlatformRazorpayCredentials(
        keyId: _razorpayKeyController.text.trim(),
        secretEncrypted: encryptedSecret,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Platform settings saved successfully'),
            backgroundColor: AdminTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _pickAndUploadLogo() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (file == null) return;

    if (mounted) setState(() => _uploadingLogo = true);
    
    try {
      final bytes = await file.readAsBytes();
      final ext = file.name.split('.').last.toLowerCase();
      final repo = ref.read(superAdminRepositoryProvider);

      await repo.uploadPlatformLogo(bytes, ext.isEmpty ? 'png' : ext);
      
      // Invalidate the provider so listeners get the new URL
      ref.invalidate(platformLogoProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Platform logo updated successfully!'),
            backgroundColor: AdminTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload logo: $e'),
            backgroundColor: AdminTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.scaffold,
      appBar: AppBar(
        title: const Text('Platform Settings'),
        backgroundColor: AdminTheme.card,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLogoSection(),
                    const SizedBox(height: 32),
                    _sectionHeader('Platform Razorpay Credentials', Icons.payment_rounded),
                    const SizedBox(height: 12),
                    _buildSettingsCard([
                      _settingsField(
                        _razorpayKeyController,
                        'Platform Razorpay Key ID',
                        Icons.vpn_key_rounded,
                        validator: (v) => v == null || v.isEmpty ? 'Key ID is required' : null,
                      ),
                      _settingsField(
                        _razorpaySecretController,
                        'Platform Razorpay Secret Key',
                        Icons.security_rounded,
                        obscureText: _obscureSecret,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureSecret ? Icons.visibility_off : Icons.visibility,
                            size: 20,
                            color: AdminTheme.textMuted,
                          ),
                          onPressed: () => setState(() => _obscureSecret = !_obscureSecret),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Secret Key is required' : null,
                      ),
                    ]),
                    const SizedBox(height: 32),
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
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        onPressed: _saving ? null : _saveSettings,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLogoSection() {
    final currentLogoAsync = ref.watch(platformLogoProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Platform Appearance', Icons.brush_rounded),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AdminTheme.card,
            borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
            border: Border.all(color: AdminTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AdminTheme.scaffold,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AdminTheme.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: currentLogoAsync.when(
                    data: (url) {
                      if (url != null && url.isNotEmpty) {
                        return Image.network(
                          AppConstants.getFullImageUrl(url),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: AdminTheme.textMuted),
                        );
                      }
                      return const Icon(Icons.fitness_center_rounded, size: 40, color: AdminTheme.textMuted);
                    },
                    loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    error: (_, __) => const Icon(Icons.error_outline, color: AdminTheme.error),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome Screen Logo',
                      style: TextStyle(
                        color: AdminTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Recommended size: 200x200px (PNG or JPG)',
                      style: TextStyle(
                        color: AdminTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.surface,
                        foregroundColor: AdminTheme.orange,
                        side: const BorderSide(color: AdminTheme.orange),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                        ),
                      ),
                      onPressed: _uploadingLogo ? null : _pickAndUploadLogo,
                      icon: _uploadingLogo 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AdminTheme.orange)) 
                          : const Icon(Icons.upload_rounded, size: 18),
                      label: Text(_uploadingLogo ? 'Uploading...' : 'Upload Logo'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AdminTheme.orange, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: AdminTheme.headingSmall.copyWith(color: AdminTheme.textPrimary),
        ),
      ],
    );
  }

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

  Widget _settingsField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: TextFormField(
        controller: ctrl,
        obscureText: obscureText,
        validator: validator,
        style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AdminTheme.textSecondary, fontSize: 13),
          prefixIcon: Icon(icon, color: AdminTheme.textMuted, size: 20),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: AdminTheme.scaffold,
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
            borderSide: const BorderSide(color: AdminTheme.orange, width: 1.5),
          ),
        ),
      ),
    );
  }
}

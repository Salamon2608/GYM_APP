import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_management/core/router/app_router.dart';
import 'package:gym_management/core/theme/app_theme.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';
import 'package:gym_management/features/auth/data/auth_repository.dart';

import 'package:gym_management/features/member/providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _medicalController = TextEditingController();
  final _allergiesController = TextEditingController();
  String _selectedGoal = 'fat_loss';
  bool _isLoading = false;
  bool _isDataLoaded = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _isChangingPassword = false;

  final Map<String, String> _fitnessGoals = {
    'fat_loss': 'Fat Loss',
    'muscle_gain': 'Muscle Gain',
    'general_fitness': 'General Fitness',
    'flexibility': 'Flexibility',
    'endurance': 'Endurance',
    'sports': 'Sports Performance',
  };

  @override
  void dispose() {
    try {
      _nameController.dispose();
      _emailController.dispose();
      _currentPasswordController.dispose();
      _newPasswordController.dispose();
      _ageController.dispose();
      _heightController.dispose();
      _weightController.dispose();
      _bloodGroupController.dispose();
      _medicalController.dispose();
      _allergiesController.dispose();
    } catch (_) {}
    super.dispose();
  }

  void _loadExistingData(Map<String, dynamic>? healthData, AppUser? user) {
    if (_isDataLoaded) return;
    if (healthData == null || user == null) return;
    _isDataLoaded = true;
    _nameController.text = user.fullName ?? '';
    _emailController.text = user.email;
    _ageController.text = (healthData['age'] ?? '').toString();
    _heightController.text = (healthData['height_cm'] ?? '').toString();
    _weightController.text = (healthData['weight_kg'] ?? '').toString();
    _bloodGroupController.text = healthData['blood_group'] ?? '';
    _medicalController.text = healthData['medical_conditions'] ?? '';
    _allergiesController.text = healthData['allergies'] ?? '';
    _selectedGoal = healthData['goal'] ?? 'fat_loss';
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final userId = ref.read(authProvider).user?.id;
    if (userId == null) return;

    final height = double.parse(_heightController.text);
    final weight = double.parse(_weightController.text);
    final bmi = calculateBmi(height, weight);

    final repo = ref.read(profileRepositoryProvider);

    try {
      // 1. Update Name and Email in users table
      await repo.updateUserProfile(userId, {
        'full_name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
      });

      // 2. Save health metrics
      await repo.saveUserHealth(
        userId: userId,
        heightCm: height,
        weightKg: weight,
        bloodGroup: _bloodGroupController.text.isNotEmpty
            ? _bloodGroupController.text
            : null,
        medicalConditions: _medicalController.text.isNotEmpty
            ? _medicalController.text
            : null,
        allergies: _allergiesController.text.isNotEmpty
            ? _allergiesController.text
            : null,
        goal: _selectedGoal,
        age: _ageController.text.isNotEmpty
            ? int.tryParse(_ageController.text)
            : null,
      );

      // 3. Save BMI record
      await repo.saveBmiRecord(
        userId: userId,
        bmiValue: bmi,
        heightCm: height,
        weightKg: weight,
      );

      // Invalidate cached data
      ref.invalidate(userHealthProvider(userId));
      ref.invalidate(bmiHistoryProvider(userId));
      ref.invalidate(userProfileProvider(userId));

      // Reload local user auth details so the changes reflect on the dashboard & profile
      await ref.read(authProvider.notifier).reloadUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile saved! BMI: ${bmi.toStringAsFixed(1)} (${getBmiCategory(bmi)})',
            ),
            backgroundColor: Color(getBmiColorHex(bmi)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userId = authState.user?.id;
    final healthAsync = userId != null
        ? ref.watch(userHealthProvider(userId))
        : null;

    // Load existing data once
    if (healthAsync != null && authState.user != null) {
      healthAsync.whenData((data) => _loadExistingData(data, authState.user));
    }

    return Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go(AppRoutes.memberDashboard),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // BMI Card
              _buildBmiPreviewCard(),
              const SizedBox(height: 24),

              // Section: Personal Details
              _buildSectionTitle('Personal Details'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(
                    Icons.person_outline_rounded,
                    color: AppTheme.textSecondary,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Full Name is required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                style: const TextStyle(color: AppTheme.textPrimary),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: AppTheme.textSecondary,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Invalid email address';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Section: Body Measurements
              _buildSectionTitle('Body Measurements'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Age',
                  prefixIcon: Icon(
                    Icons.cake_outlined,
                    color: AppTheme.textSecondary,
                  ),
                ),
                validator: (v) {
                  if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
                    return 'Invalid age';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Height (cm)',
                        prefixIcon: Icon(
                          Icons.height,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(v) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        prefixIcon: Icon(
                          Icons.monitor_weight_outlined,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(v) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Section: Health Info
              _buildSectionTitle('Health Information'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bloodGroupController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Blood Group (e.g. A+, B-, O+)',
                  prefixIcon: Icon(
                    Icons.bloodtype_outlined,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _medicalController,
                style: const TextStyle(color: AppTheme.textPrimary),
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Medical Conditions (if any)',
                  prefixIcon: Icon(
                    Icons.medical_information_outlined,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _allergiesController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Allergies (if any)',
                  prefixIcon: Icon(
                    Icons.warning_amber_outlined,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Fitness Goal
              _buildSectionTitle('Fitness Goal'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGoal,
                    isExpanded: true,
                    dropdownColor: AppTheme.cardDark,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    items: _fitnessGoals.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedGoal = v!),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Save Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Change Password Card
              _buildChangePasswordSection(),
              const SizedBox(height: 24),

              // BMI History
              if (userId != null) _buildBmiHistory(userId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBmiPreviewCard() {
    final h = double.tryParse(_heightController.text);
    final w = double.tryParse(_weightController.text);
    if (h == null || w == null || h <= 0 || w <= 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderDark),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.monitor_weight_outlined,
              color: AppTheme.textSecondary,
              size: 40,
            ),
            SizedBox(height: 8),
            Text(
              'Enter height & weight to see BMI',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }
    final bmi = calculateBmi(h, w);
    final category = getBmiCategory(bmi);
    final color = Color(getBmiColorHex(bmi));

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.3),
            isDark ? AppTheme.cardDark : AppTheme.cardLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                bmi.toStringAsFixed(1),
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BMI Score',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${h.toInt()} cm  •  ${w.toInt()} kg',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.7,
                    ),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildBmiHistory(String userId) {
    final bmiAsync = ref.watch(bmiHistoryProvider(userId));

    return bmiAsync.when(
      data: (records) {
        if (records.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('BMI History'),
            const SizedBox(height: 12),
            ...records.take(5).map((r) {
              final bmi = (r['bmi_value'] as num).toDouble();
              final color = Color(getBmiColorHex(bmi));
              final date = DateTime.tryParse(r['recorded_at'] ?? '');
              final dateStr = date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : '';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          bmi.toStringAsFixed(1),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          getBmiCategory(bmi),
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
  Widget _buildChangePasswordSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Change Password'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _currentPasswordController,
            obscureText: _obscureCurrentPassword,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Current Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textSecondary),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureCurrentPassword ? Icons.visibility : Icons.visibility_off,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscureNewPassword,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppTheme.textSecondary),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _isChangingPassword ? null : _changePassword,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.primaryColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isChangingPassword
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2),
                    )
                  : const Text('Update Password'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (currentPassword.isEmpty || newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both password fields'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password must be at least 6 characters long'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.changePassword(currentPassword, newPassword);
      
      _currentPasswordController.clear();
      _newPasswordController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChangingPassword = false);
      }
    }
  }
}

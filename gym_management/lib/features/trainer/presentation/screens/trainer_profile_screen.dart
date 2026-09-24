import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gym_management/core/router/app_router.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';
import 'package:gym_management/features/trainer/presentation/theme/trainer_theme.dart';
import 'package:gym_management/features/trainer/providers/trainer_provider.dart';
import 'package:gym_management/core/utils/validators.dart';

class TrainerProfileScreen extends ConsumerStatefulWidget {
  const TrainerProfileScreen({super.key});

  @override
  ConsumerState<TrainerProfileScreen> createState() =>
      _TrainerProfileScreenState();
}

class _TrainerProfileScreenState extends ConsumerState<TrainerProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final trainerId = authState.user?.id;

    if (trainerId == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final feedbackAsync = ref.watch(trainerFeedbackProvider(trainerId));
    final statsAsync = ref.watch(trainerStatsProvider(trainerId));
    final profileAsync = ref.watch(trainerProfileProvider(trainerId));

    return Scaffold(
      backgroundColor: TrainerTheme.scaffold,
      appBar: AppBar(
        backgroundColor: TrainerTheme.scaffold,
        elevation: 0,
        title: Text(
          'My Profile & Feedback',
          style: TrainerTheme.headingSmall.copyWith(fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: TrainerTheme.error),
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: TrainerTheme.orange,
        onRefresh: () async {
          ref.invalidate(trainerFeedbackProvider(trainerId));
          ref.invalidate(trainerStatsProvider(trainerId));
          ref.invalidate(trainerProfileProvider(trainerId));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dynamic profile card
              profileAsync.when(
                data: (profile) => _buildProfileCard(
                  name: authState.user?.userMetadata?['full_name'] ?? 'Trainer',
                  specialization: profile['specialization'] as String? ?? '',
                  experienceYears: profile['experience_years'] as int? ?? 0,
                  bio: profile['bio'] as String? ?? '',
                ),
                loading: () => _buildProfileCard(
                  name: authState.user?.userMetadata?['full_name'] ?? 'Trainer',
                  specialization: '',
                  experienceYears: 0,
                  bio: '',
                ),
                error: (_, _) => _buildProfileCard(
                  name: authState.user?.userMetadata?['full_name'] ?? 'Trainer',
                  specialization: '',
                  experienceYears: 0,
                  bio: '',
                ),
              ),
              const SizedBox(height: 24),
              _buildActionTiles(context, trainerId),
              const SizedBox(height: 32),

              // Summary
              statsAsync.when(
                data: (stats) {
                  final rating = (stats['rating'] as num?)?.toDouble() ?? 0.0;
                  final totalReviews = feedbackAsync.value?.length ?? 0;
                  return _buildFeedbackSummary(rating, totalReviews);
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: TrainerTheme.orange),
                ),
                error: (e, _) => const Text(
                  'Error loading stats',
                  style: TextStyle(color: TrainerTheme.error),
                ),
              ),

              const SizedBox(height: 24),
              Text('Recent Client Reviews', style: TrainerTheme.headingMedium),
              const SizedBox(height: 16),

              // Feedback List
              feedbackAsync.when(
                data: (feedbacks) {
                  if (feedbacks.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No reviews yet.',
                          style: TextStyle(color: TrainerTheme.textSecondary),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: feedbacks
                        .map((fb) => _buildFeedbackTile(fb))
                        .toList(),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: TrainerTheme.orange),
                ),
                error: (e, _) => Text(
                  'Error loading reviews: $e',
                  style: const TextStyle(color: TrainerTheme.error),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard({
    required String name,
    required String specialization,
    required int experienceYears,
    required String bio,
  }) {
    final subtitle = specialization.isNotEmpty
        ? specialization
        : 'Fitness Trainer';
    final expText = experienceYears > 0
        ? '$experienceYears yr${experienceYears > 1 ? 's' : ''} experience'
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TrainerTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TrainerTheme.border, width: 1),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: TrainerTheme.scaffold,
            child: const Icon(
              Icons.person,
              size: 36,
              color: TrainerTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TrainerTheme.headingLarge.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TrainerTheme.bodyMedium.copyWith(
                    color: TrainerTheme.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (expText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    expText,
                    style: TrainerTheme.bodySmall.copyWith(
                      color: TrainerTheme.textSecondary,
                    ),
                  ),
                ],
                if (bio.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    bio,
                    style: TrainerTheme.bodySmall.copyWith(
                      color: TrainerTheme.textPrimary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTiles(BuildContext context, String trainerId) {
    return Column(
      children: [
        _buildListTile(
          icon: Icons.video_library_rounded,
          title: 'Exercise Video Library',
          subtitle: 'Manage your uploaded demo videos',
          onTap: () {
            context.push(AppRoutes.trainerVideos);
          },
        ),
        const SizedBox(height: 12),
        _buildListTile(
          icon: Icons.settings_rounded,
          title: 'Settings',
          subtitle: 'App preferences and account info',
          onTap: () => _showSettingsSheet(context, trainerId),
        ),
      ],
    );
  }

  void _showSettingsSheet(BuildContext context, String trainerId) {
    final profileAsync = ref.read(trainerProfileProvider(trainerId));

    showModalBottomSheet(
      context: context,
      backgroundColor: TrainerTheme.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: TrainerTheme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Settings', style: TrainerTheme.headingMedium),
                  const SizedBox(height: 24),

                  // Account Info section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Account Information',
                        style: TrainerTheme.bodySmall.copyWith(
                          color: TrainerTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          if (profileAsync.hasValue) {
                            final profileData = profileAsync.value!;
                            final name =
                                ref
                                    .read(authProvider)
                                    .user
                                    ?.userMetadata?['full_name'] ??
                                '';
                            final email =
                                ref.read(authProvider).user?.email ?? '';

                            Navigator.pop(ctx); // Close settings sheet first
                            _openEditProfileForm(
                              context,
                              ref,
                              trainerId,
                              profileData,
                              name,
                              email,
                            );
                          }
                        },
                        icon: const Icon(
                          Icons.edit_rounded,
                          size: 16,
                          color: TrainerTheme.orange,
                        ),
                        label: const Text(
                          'Edit',
                          style: TextStyle(color: TrainerTheme.orange),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  profileAsync.when(
                    data: (profile) => _buildSettingsInfo(
                      profile,
                      ref.read(authProvider).user?.userMetadata?['full_name'] ??
                          '--',
                      ref.read(authProvider).user?.email ?? '--',
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: TrainerTheme.orange,
                      ),
                    ),
                    error: (_, _) => const Text(
                      'Could not load profile',
                      style: TextStyle(color: TrainerTheme.error),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // App section
                  Text(
                    'App',
                    style: TrainerTheme.bodySmall.copyWith(
                      color: TrainerTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsTile(
                    icon: Icons.info_outline_rounded,
                    title: 'App Version',
                    trailing: Text(
                      '1.0.0',
                      style: TrainerTheme.bodySmall.copyWith(
                        color: TrainerTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await ref.read(authProvider.notifier).signOut();
                        if (context.mounted) {
                          context.go(AppRoutes.login);
                        }
                      },
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: TrainerTheme.error,
                        size: 18,
                      ),
                      label: Text(
                        'Sign Out',
                        style: TrainerTheme.bodyMedium.copyWith(
                          color: TrainerTheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: TrainerTheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSettingsInfo(
    Map<String, dynamic> profile,
    String name,
    String email,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: TrainerTheme.scaffold,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildInfoRow('Name', name),
          _buildInfoRow('Email', email),
          _buildInfoRow(
            'Specialization',
            (profile['specialization'] as String?)?.isNotEmpty == true
                ? profile['specialization']
                : '--',
          ),
          _buildInfoRow(
            'Experience',
            (profile['experience_years'] as int?) != null &&
                    (profile['experience_years'] as int) > 0
                ? '${profile['experience_years']} years'
                : '--',
          ),
          _buildInfoRow(
            'Bio',
            (profile['bio'] as String?)?.isNotEmpty == true
                ? profile['bio']
                : '--',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: TrainerTheme.border, width: 0.5),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TrainerTheme.bodySmall.copyWith(
              color: TrainerTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: TrainerTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TrainerTheme.scaffold,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: TrainerTheme.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: TrainerTheme.bodyMedium)),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TrainerTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TrainerTheme.border, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TrainerTheme.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: TrainerTheme.orange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TrainerTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TrainerTheme.bodySmall),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: TrainerTheme.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSummary(double rating, int totalReviews) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [TrainerTheme.orange, TrainerTheme.orangeDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overall Rating',
                style: TrainerTheme.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    rating.toStringAsFixed(1),
                    style: TrainerTheme.headingLarge.copyWith(
                      fontSize: 48,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/ 5.0',
                    style: TrainerTheme.bodyLarge.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating.floor()
                        ? Icons.star_rounded
                        : (index < rating
                              ? Icons.star_half_rounded
                              : Icons.star_border_rounded),
                    color: Colors.white,
                    size: 20,
                  );
                }),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'Total Reviews',
                  style: TrainerTheme.bodySmall.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalReviews',
                  style: TrainerTheme.headingMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackTile(Map<String, dynamic> feedback) {
    // Parse nested user data securely
    final userNode = feedback['users'] as Map<String, dynamic>?;
    final userName = userNode?['full_name'] ?? 'Unknown User';
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

    final rating = (feedback['rating'] as num?)?.toInt() ?? 0;
    final comment = feedback['comment'] as String? ?? 'No comment provided.';

    // Format date
    String dateStr = 'Unknown Date';
    if (feedback['created_at'] != null) {
      try {
        final date = DateTime.parse(feedback['created_at']);
        dateStr = DateFormat('MMM dd, yyyy').format(date);
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TrainerTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TrainerTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: TrainerTheme.scaffold,
                    child: Text(
                      initial,
                      style: TrainerTheme.bodyMedium.copyWith(
                        color: TrainerTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    userName,
                    style: TrainerTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(dateStr, style: TrainerTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                color: TrainerTheme.orange,
                size: 16,
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(comment, style: TrainerTheme.bodyMedium.copyWith(height: 1.5)),
        ],
      ),
    );
  }

  void _openEditProfileForm(
    BuildContext context,
    WidgetRef ref,
    String trainerId,
    Map<String, dynamic> currentProfile,
    String currentName,
    String currentEmail,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TrainerTheme.card,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _EditProfileForm(
          trainerId: trainerId,
          initialName: currentName,
          initialEmail: currentEmail,
          initialSpec: currentProfile['specialization'] ?? '',
          initialExp: currentProfile['experience_years'] ?? 0,
          initialBio: currentProfile['bio'] ?? '',
        ),
      ),
    );
  }
}

class _EditProfileForm extends ConsumerStatefulWidget {
  final String trainerId;
  final String initialName;
  final String initialEmail;
  final String initialSpec;
  final int initialExp;
  final String initialBio;

  const _EditProfileForm({
    required this.trainerId,
    required this.initialName,
    required this.initialEmail,
    required this.initialSpec,
    required this.initialExp,
    required this.initialBio,
  });

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _specController;
  late final TextEditingController _expController;
  late final TextEditingController _bioController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _specController = TextEditingController(text: widget.initialSpec);
    _expController = TextEditingController(text: widget.initialExp.toString());
    _bioController = TextEditingController(text: widget.initialBio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _specController.dispose();
    _expController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(trainerRepositoryProvider);

      final expYears = int.tryParse(_expController.text.trim()) ?? 0;

      await repo.updateTrainerProfile(
        trainerId: widget.trainerId,
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        specialization: _specController.text.trim(),
        experienceYears: expYears,
        bio: _bioController.text.trim(),
      );

      // Invalidate providers to refresh data
      ref.invalidate(trainerProfileProvider(widget.trainerId));
      ref.invalidate(authProvider); // Re-fetch auth if email/name changed

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: TrainerTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: TrainerTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: TrainerTheme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: TrainerTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Edit Profile', style: TrainerTheme.headingMedium),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                validator: Validators.validateName,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _specController,
                label: 'Specialization (e.g. Weight Training)',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _expController,
                label: 'Experience (Years)',
                keyboardType: TextInputType.number,
                validator: (v) => Validators.validateNonNegativeInteger(v, 'Experience'),
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _bioController,
                label: 'Bio',
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TrainerTheme.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Save Changes',
                          style: TrainerTheme.bodyLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: TrainerTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TrainerTheme.bodySmall.copyWith(
          color: TrainerTheme.textSecondary,
        ),
        filled: true,
        fillColor: TrainerTheme.scaffold,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TrainerTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TrainerTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TrainerTheme.orange),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:gym_management/features/admin/presentation/theme/admin_theme.dart';
import 'package:gym_management/features/admin/providers/admin_providers.dart';
import 'package:gym_management/features/admin/presentation/widgets/trainer_details_bottom_sheet.dart';
import 'package:gym_management/core/utils/validators.dart';

/// Trainer Management — push route from Side Drawer
class TrainerManagementScreen extends ConsumerWidget {
  const TrainerManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainersAsync = ref.watch(allTrainersProvider);

    return Scaffold(
      backgroundColor: AdminTheme.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trainer Management',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Manage your gym trainers and their assignments',
                          style: TextStyle(
                            color: AdminTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showAddTrainerSheet(context, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AdminTheme.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '+ Add',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Content ──
            Expanded(
              child: trainersAsync.when(
                data: (trainers) => _buildContent(context, ref, trainers),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AdminTheme.orange),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Error: $e',
                    style: const TextStyle(color: AdminTheme.error),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> trainers,
  ) {
    // Get all trainer IDs to fetch today's attendance
    final trainerIds = trainers.map((t) => t['id'].toString()).toList();
    final attendanceAsync = ref.watch(
      trainerAttendanceTodayProvider(trainerIds),
    );
    final attendanceMap = attendanceAsync.when(
      data: (d) => d,
      loading: () => <String, Map<String, dynamic>>{},
      error: (_, _) => <String, Map<String, dynamic>>{},
    );

    return RefreshIndicator(
      color: AdminTheme.orange,
      backgroundColor: AdminTheme.card,
      onRefresh: () async {
        ref.invalidate(allTrainersProvider);
        ref.invalidate(trainerAttendanceTodayProvider(trainerIds));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // ── Stats Row ──
            Row(
              children: [
                Expanded(
                  child: _miniStatCard(
                    'Total Trainers',
                    trainers.length.toString(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _miniStatCard('Avg. Rating', _avgRating(trainers)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Trainer Cards ──
            ...trainers.map(
              (t) => _buildTrainerCard(context, ref, t, attendanceMap),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _miniStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AdminTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: AdminTheme.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainerCard(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> trainer,
    Map<String, Map<String, dynamic>> attendanceMap,
  ) {
    final userData = trainer['users'] as Map<String, dynamic>?;
    final name = userData?['full_name'] ?? 'Unknown';
    final specialization = trainer['specialization'] ?? 'General';
    final rating = (trainer['rating'] as num?)?.toDouble() ?? 5.0;
    final initials = _getInitials(name);
    final assignedMembers = trainer['assigned_members'] as List? ?? [];

    // Attendance data
    final trainerId = trainer['id'].toString();
    final attendance = attendanceMap[trainerId];
    final isPresent = attendance != null;
    final checkInTime = attendance != null
        ? DateTime.tryParse((attendance['check_in'] ?? '').isNotEmpty ? ((attendance['check_in'] ?? '').endsWith('Z') ? attendance['check_in']! : '${attendance['check_in']}Z') : '')?.toLocal()
        : null;
    final checkOutTime = attendance != null
        ? DateTime.tryParse((attendance['check_out'] ?? '').isNotEmpty ? ((attendance['check_out'] ?? '').endsWith('Z') ? attendance['check_out']! : '${attendance['check_out']}Z') : '')?.toLocal()
        : null;
    final timeFormat = DateFormat('hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showTrainerDetailsSheet(
          context,
          name,
          trainerId,
          assignedMembers,
          ref,
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AdminTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminTheme.border),
          ),
          child: Column(
            children: [
              // Top row: Avatar + Info + Attendance badge
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AdminTheme.orange,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          specialization,
                          style: TextStyle(
                            color: AdminTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Attendance badge
                  if (isPresent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AdminTheme.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Present',
                        style: TextStyle(
                          color: AdminTheme.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),

              // Attendance times (if present today)
              if (isPresent && checkInTime != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.login_rounded,
                      color: AdminTheme.success,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'In: ${timeFormat.format(checkInTime)}',
                      style: TextStyle(
                        color: AdminTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (checkOutTime != null) ...[
                      Icon(
                        Icons.logout_rounded,
                        color: AdminTheme.orange,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Out: ${timeFormat.format(checkOutTime)}',
                        style: TextStyle(
                          color: AdminTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ] else
                      Text(
                        'Still working',
                        style: TextStyle(
                          color: AdminTheme.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),

              // Stats row
              Row(
                children: [
                  const Icon(Icons.star, color: AdminTheme.orange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.people_outline,
                    color: AdminTheme.textMuted,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${assignedMembers.length} members',
                    style: TextStyle(
                      color: AdminTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),

              // Assigned members
              if (assignedMembers.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: assignedMembers.map((a) {
                    final memberName = a['member_name'] ?? 'Unknown';
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AdminTheme.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        memberName,
                        style: const TextStyle(
                          color: AdminTheme.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 14),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AdminTheme.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _showEditSheet(context, ref, trainer),
                      child: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _showAssignSheet(context, ref, trainer),
                      child: const Text('Assign'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AdminTheme.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AdminTheme.error,
                        size: 20,
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AdminTheme.card,
                            title: const Text(
                              'Delete Trainer',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: Text(
                              'Are you sure you want to delete ${trainer['full_name']}? This will hard-delete their account and unassign all their members.',
                              style: TextStyle(color: AdminTheme.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(
                                  'Delete',
                                  style: TextStyle(color: AdminTheme.error),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          try {
                            final repo = ref.read(adminRepositoryProvider);
                            await repo.deleteUserAccount(trainer['id']);
                            ref.invalidate(allTrainersProvider);
                            ref.invalidate(allUsersProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Trainer deleted successfully'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTrainerDetailsSheet(
    BuildContext context,
    String trainerName,
    String trainerId,
    List<dynamic> assignedMembers,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TrainerDetailsBottomSheet(
        trainerName: trainerName,
        trainerId: trainerId,
        assignedMembers: assignedMembers,
        parentRef: ref,
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  String _avgRating(List<Map<String, dynamic>> trainers) {
    if (trainers.isEmpty) return '0.0';
    final total = trainers.fold<double>(
      0,
      (sum, t) => sum + ((t['rating'] as num?)?.toDouble() ?? 0),
    );
    return (total / trainers.length).toStringAsFixed(1);
  }

  void _showAddTrainerSheet(BuildContext context, WidgetRef ref) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final specCtrl = TextEditingController();
    final expCtrl = TextEditingController();

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AdminTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AdminTheme.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Add New Trainer', style: AdminTheme.headingMedium),
              const SizedBox(height: 16),
              _sheetField(
                emailCtrl,
                'Email',
                Icons.email_outlined,
                validator: Validators.validateEmail,
              ),
              _sheetField(
                passCtrl,
                'Password',
                Icons.lock_outline,
                obscure: true,
                validator: Validators.validatePassword,
              ),
              _sheetField(
                nameCtrl,
                'Full Name',
                Icons.person_outline,
                validator: Validators.validateName,
              ),
              _sheetField(
                phoneCtrl,
                'Phone',
                Icons.phone_outlined,
                inputType: TextInputType.phone,
                validator: Validators.validatePhone,
              ),
              _sheetField(
                specCtrl,
                'Specialization',
                Icons.sports_outlined,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
              ),
              _sheetField(
                expCtrl,
                'Experience (years)',
                Icons.timeline,
                inputType: TextInputType.number,
                validator: (v) => Validators.validateNonNegativeInteger(
                  v,
                  'Experience',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(ctx);
                    final repo = ref.read(adminRepositoryProvider);
                    await repo.createTrainerAccount(
                      email: emailCtrl.text.trim(),
                      password: passCtrl.text.trim(),
                      fullName: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      specialization: specCtrl.text.trim(),
                      experienceYears: int.tryParse(expCtrl.text.trim()) ?? 0,
                    );
                    ref.invalidate(allTrainersProvider);
                  },
                  child: const Text('Create Trainer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> trainer,
  ) {
    final userData = trainer['users'] as Map<String, dynamic>?;

    final nameCtrl = TextEditingController(text: userData?['full_name'] ?? '');
    final emailCtrl = TextEditingController(text: userData?['email'] ?? '');
    final phoneCtrl = TextEditingController(text: userData?['phone'] ?? '');
    final passCtrl = TextEditingController(); // Leave blank to not change

    final specCtrl = TextEditingController(
      text: trainer['specialization'] ?? '',
    );
    final expCtrl = TextEditingController(
      text: trainer['experience_years']?.toString() ?? '0',
    );
    final bioCtrl = TextEditingController(text: trainer['bio'] ?? '');

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AdminTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AdminTheme.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Edit Trainer', style: AdminTheme.headingMedium),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _sheetField(
                        nameCtrl,
                        'Full Name',
                        Icons.person_outline,
                        validator: Validators.validateName,
                      ),
                      _sheetField(
                        emailCtrl,
                        'Email',
                        Icons.email_outlined,
                        inputType: TextInputType.emailAddress,
                        validator: Validators.validateEmail,
                      ),
                      _sheetField(
                        passCtrl,
                        'New Password (Optional)',
                        Icons.lock_outline,
                        obscure: true,
                        validator: (v) => (v != null && v.isNotEmpty)
                            ? Validators.validatePassword(v)
                            : null,
                      ),
                      _sheetField(
                        phoneCtrl,
                        'Phone',
                        Icons.phone_outlined,
                        inputType: TextInputType.phone,
                        validator: Validators.validatePhone,
                      ),
                      _sheetField(
                        specCtrl,
                        'Specialization',
                        Icons.sports_outlined,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      _sheetField(
                        expCtrl,
                        'Experience (years)',
                        Icons.timeline,
                        inputType: TextInputType.number,
                        validator: (v) => Validators.validateNonNegativeInteger(
                          v,
                          'Experience',
                        ),
                      ),
                      _sheetField(bioCtrl, 'Bio', Icons.info_outline),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(ctx);
                    final repo = ref.read(adminRepositoryProvider);
                    await repo.updateFullTrainerProfile(
                      trainer['id'],
                      fullName: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      newPassword: passCtrl.text.trim(),
                      specialization: specCtrl.text.trim(),
                      experienceYears: int.tryParse(expCtrl.text.trim()) ?? 0,
                      bio: bioCtrl.text.trim(),
                    );
                    ref.invalidate(allTrainersProvider);
                    ref.invalidate(allUsersProvider);
                  },
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAssignSheet(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> trainer,
  ) async {
    // Fetch unassigned members BEFORE opening the sheet
    final repo = ref.read(adminRepositoryProvider);
    List<Map<String, dynamic>> members;
    try {
      members = await repo.getUnassignedMembers();
    } catch (_) {
      members = [];
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AdminTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AdminTheme.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Assign Member', style: AdminTheme.headingMedium),
              const SizedBox(height: 12),
              if (members.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'All members are assigned',
                      style: TextStyle(color: AdminTheme.textMuted),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (_, i) {
                      final m = members[i];
                      return ListTile(
                        title: Text(
                          m['full_name'] ?? '',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          m['email'] ?? '',
                          style: TextStyle(
                            color: AdminTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminTheme.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            textStyle: const TextStyle(fontSize: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await repo.assignTrainerToMember(
                              trainer['id'],
                              m['id'],
                            );
                            ref.invalidate(allTrainersProvider);
                            ref.invalidate(allUsersProvider);
                          },
                          child: const Text('Assign'),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool obscure = false,
    TextInputType? inputType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: inputType,
        style: AdminTheme.bodyLarge,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/features/admin/presentation/theme/admin_theme.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:gym_management/features/trainer/data/trainer_repository.dart';
import 'package:intl/intl.dart';
import 'package:gym_management/features/admin/providers/admin_providers.dart';
import 'package:gym_management/core/utils/validators.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';
import 'package:gym_management/features/super_admin/providers/super_admin_providers.dart';

/// Users tab body — embedded inside AdminShell
class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    return Column(
      children: [
        // ── Header ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'User Management',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage and monitor all gym members',
                      style: TextStyle(
                        color: AdminTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // + Add User button
              GestureDetector(
                onTap: () => _showAddUserSheet(ref),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AdminTheme.orange,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    '+ Add User',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Search Bar ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search users by name, email, or phone...',
              hintStyle: TextStyle(color: AdminTheme.textMuted),
              prefixIcon: const Icon(Icons.search, color: AdminTheme.textMuted),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: AdminTheme.textMuted,
                        size: 18,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AdminTheme.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (val) {
              setState(() => _searchQuery = val.trim().toLowerCase());
            },
          ),
        ),
        const SizedBox(height: 12),

        // ── User List ──
        Expanded(
          child: usersAsync.when(
            data: (users) {
              final filtered = _searchQuery.isEmpty
                  ? users
                  : users.where((u) {
                      final name = (u['full_name'] ?? '')
                          .toString()
                          .toLowerCase();
                      final email = (u['email'] ?? '').toString().toLowerCase();
                      final phone = (u['phone'] ?? '').toString().toLowerCase();
                      return name.contains(_searchQuery) ||
                          email.contains(_searchQuery) ||
                          phone.contains(_searchQuery);
                    }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 56,
                        color: AdminTheme.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text('No users found', style: AdminTheme.bodySmall),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: AdminTheme.orange,
                backgroundColor: AdminTheme.card,
                onRefresh: () async => ref.invalidate(allUsersProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _buildUserCard(filtered[i]),
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AdminTheme.orange),
            ),
            error: (e, _) => Center(
              child: Text(
                'Error: $e',
                style: TextStyle(color: AdminTheme.error),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final name = user['full_name'] ?? 'Unknown';
    final email = user['email'] ?? '';
    final role = user['role'] ?? 'member';
    final roleColor = role == 'admin'
        ? AdminTheme.error
        : role == 'trainer'
        ? AdminTheme.info
        : AdminTheme.success;
    final initials = _getInitials(name);
    final assignedTrainer = user['assigned_trainer_name'] ?? '';

    // Get plan name and expiry
    final memberships = user['user_membership'] as List?;
    String planName = '';
    String expiryDate = '';
    if (memberships != null && memberships.isNotEmpty) {
      final activeMembership = memberships.firstWhere(
        (m) => m['status'] == 'active',
        orElse: () => memberships.first,
      );
      planName = activeMembership['membership_plans']?['name'] ?? '';
      final endDate = activeMembership['end_date']?.toString() ?? '';
      if (endDate.isNotEmpty) {
        expiryDate = 'Exp: ${endDate.substring(0, 10)}';
      }
    }

    return GestureDetector(
      onTap: () =>
          _showUserDetailsModal(user, planName, expiryDate, assignedTrainer),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AdminTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminTheme.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AdminTheme.orange.withValues(alpha: 0.15),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: AdminTheme.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name + Email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          color: AdminTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role[0].toUpperCase() + role.substring(1),
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Bottom row: Plan badge + Expiry + Action buttons
            Row(
              children: [
                if (planName.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AdminTheme.border),
                    ),
                    child: Text(
                      planName,
                      style: TextStyle(
                        color: AdminTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (expiryDate.isNotEmpty)
                  Text(
                    expiryDate,
                    style: TextStyle(color: AdminTheme.textMuted, fontSize: 11),
                  ),
                if (assignedTrainer.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AdminTheme.info.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.sports_gymnastics,
                          color: AdminTheme.info,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          assignedTrainer,
                          style: const TextStyle(
                            color: AdminTheme.info,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                // 2 Action buttons: Edit + Delete
                _actionIcon(
                  Icons.edit_outlined,
                  AdminTheme.orange,
                  () => _showEditDialog(user, ref),
                ),
                const SizedBox(width: 6),
                _actionIcon(Icons.delete_outline, AdminTheme.error, () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AdminTheme.card,
                      title: const Text(
                        'Delete User',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: Text(
                        'Are you sure you want to delete $name?',
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
                      // Hard-delete the user via the Node.js backend API, which cleanly
                      // cascades all related data (trainers, assignments, memberships).
                      final repo = ref.read(adminRepositoryProvider);
                      await repo.deleteUserAccount(user['id']);
                      ref.invalidate(allUsersProvider);
                      ref.invalidate(
                        allTrainersProvider,
                      ); // refresh trainers as well
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User deleted')),
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
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 16),
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

  // ── User Details Modal ──
  void _showUserDetailsModal(
    Map<String, dynamic> user,
    String planName,
    String expiryDate,
    String assignedTrainer,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => UserDetailsBottomSheet(
        user: user,
        planName: planName,
        expiryDate: expiryDate,
        assignedTrainer: assignedTrainer,
      ),
    );
  }

  // ── Add User Sheet ──

  void _showAddUserSheet(WidgetRef ref) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    String? selectedRole = 'member';
    String? selectedGymId;

    List<Map<String, dynamic>> gyms = [];
    bool isLoadingGyms = false;

    List<Map<String, dynamic>> plans = [];
    bool isLoadingPlans = true;
    bool fetchInitiated = false;
    String? selectedPlanId;

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AdminTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          if (!fetchInitiated) {
            fetchInitiated = true;
            final authState = ref.read(authProvider);
            final repo = ref.read(adminRepositoryProvider);
            
            if (authState.role == 'super_admin') {
              isLoadingGyms = true;
              ref.read(superAdminRepositoryProvider).getGyms().then((fetchedGyms) {
                if (mounted) {
                  setSheetState(() {
                    gyms = fetchedGyms;
                    isLoadingGyms = false;
                  });
                }
              });
            } else {
              selectedGymId = authState.gymId;
            }

            repo
                .getAllMembershipPlans()
                .then((fetchedPlans) {
                  if (mounted) {
                    setSheetState(() {
                      // Tolerate null as true
                      plans = fetchedPlans
                          .where((p) => p['is_active'] == true || p['is_active'] == 1)
                          .toList();
                      if (plans.isNotEmpty) {
                        selectedPlanId = plans.first['id'].toString();
                      }
                      isLoadingPlans = false;
                    });
                  }
                })
                .catchError((_) {
                  if (mounted) {
                    setSheetState(() => isLoadingPlans = false);
                  }
                });
          }
          return Padding(
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
                Text('Add New User', style: AdminTheme.headingMedium),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailCtrl,
                  style: AdminTheme.bodyLarge,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passCtrl,
                  style: AdminTheme.bodyLarge,
                  obscureText: true,
                  validator: Validators.validatePassword,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  style: AdminTheme.bodyLarge,
                  validator: Validators.validateName,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneCtrl,
                  style: AdminTheme.bodyLarge,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                // Role selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AdminTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AdminTheme.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedRole,
                      dropdownColor: AdminTheme.surface,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      items: ['member', 'admin', 'trainer']
                          .map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(r[0].toUpperCase() + r.substring(1)),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setSheetState(() => selectedRole = val ?? 'member'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Gym selector (only for Super Admin)
                if (ref.read(authProvider).role == 'super_admin') ...[
                  if (isLoadingGyms)
                    const Center(child: CircularProgressIndicator(color: AdminTheme.orange))
                  else if (gyms.isEmpty)
                    const Text('No gyms available, please create one first.', style: TextStyle(color: AdminTheme.error))
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AdminTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AdminTheme.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedGymId,
                          hint: const Text('Select Gym', style: TextStyle(color: Colors.white70)),
                          dropdownColor: AdminTheme.surface,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          items: gyms
                              .map(
                                (g) => DropdownMenuItem(
                                  value: g['id'].toString(),
                                  child: Text(g['name'] ?? 'Unknown'),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setSheetState(() => selectedGymId = val),
                        ),
                      ),
                    ),
                ],
                if (selectedRole == 'member') ...[
                  if (isLoadingPlans)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AdminTheme.orange,
                        ),
                      ),
                    )
                  else if (plans.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AdminTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AdminTheme.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedPlanId,
                          dropdownColor: AdminTheme.surface,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          items: plans
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p['id'].toString(),
                                  child: Text('${p['name']} - \$${p['price']}'),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setSheetState(() => selectedPlanId = val),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AdminTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AdminTheme.border),
                      ),
                      child: const Text(
                        'No active plans available. Create one first.',
                        style: TextStyle(
                          color: AdminTheme.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 20),
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

                      final email = emailCtrl.text.trim();
                      final password = passCtrl.text.trim();
                      final fullName = nameCtrl.text.trim();
                      final phone = phoneCtrl.text.trim();

                      if (email.isEmpty ||
                          password.isEmpty ||
                          fullName.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all required fields'),
                          ),
                        );
                        return;
                      }

                      Navigator.pop(ctx);

                      try {
                        final repo = ref.read(adminRepositoryProvider);
                        if (selectedRole == 'member') {
                          Map<String, dynamic>? sp;
                          if (selectedPlanId != null) {
                            sp = plans.firstWhere(
                              (p) => p['id'].toString() == selectedPlanId,
                            );
                          }
                          await repo.createMemberAccount(
                            email: email,
                            password: password,
                            fullName: fullName,
                            phone: phone,
                            selectedPlan: sp,
                          );
                        } else {
                          // Create admin or generic role using REST API
                          await repo.createMemberAccount(
                            email: email,
                            password: password,
                            fullName: fullName,
                            phone: phone,
                            role: selectedRole,
                          );
                        }

                        ref.invalidate(allUsersProvider);
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('User created successfully'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(
                            this.context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                    child: const Text('Create User'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

  // ── Edit Dialog ──

  void _showEditDialog(Map<String, dynamic> user, WidgetRef ref) {
    final nameCtrl = TextEditingController(text: user['full_name'] ?? '');
    final emailCtrl = TextEditingController(text: user['email'] ?? '');
    final phoneCtrl = TextEditingController(text: user['phone'] ?? '');
    final passCtrl = TextEditingController();

    List<Map<String, dynamic>> plans = [];
    bool isLoadingPlans = true;
    bool fetchInitiated = false;
    String? selectedPlanId;

    final memberships = user['user_membership'] as List? ?? [];
    if (memberships.isNotEmpty) {
      final activeMembership = memberships.firstWhere(
        (m) => m['status'] == 'active',
        orElse: () => memberships.first,
      );
      selectedPlanId = activeMembership['plan_id']?.toString();
    }

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AdminTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          if (!fetchInitiated) {
            fetchInitiated = true;
            final repo = ref.read(adminRepositoryProvider);
            repo
                .getAllMembershipPlans()
                .then((fetchedPlans) {
                  if (mounted) {
                    setSheetState(() {
                      plans = fetchedPlans
                          .where((p) => p['is_active'] == true || p['is_active'] == 1)
                          .toList();
                      if (selectedPlanId != null &&
                          !plans.any(
                            (p) => p['id'].toString() == selectedPlanId,
                          )) {
                        selectedPlanId = null;
                      }
                      isLoadingPlans = false;
                    });
                  }
                })
                .catchError((_) {
                  if (mounted) {
                    setSheetState(() => isLoadingPlans = false);
                  }
                });
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
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
                  Text('Edit User', style: AdminTheme.headingMedium),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    style: AdminTheme.bodyLarge,
                    validator: Validators.validateName,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    style: AdminTheme.bodyLarge,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passCtrl,
                    style: AdminTheme.bodyLarge,
                    obscureText: true,
                    validator: (v) => (v != null && v.isNotEmpty) ? Validators.validatePassword(v) : null,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      labelText: 'New Password (Optional)',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    style: AdminTheme.bodyLarge,
                    keyboardType: TextInputType.phone,
                    validator: Validators.validatePhone,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  if (isLoadingPlans)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AdminTheme.orange,
                        ),
                      ),
                    )
                  else if (plans.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AdminTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AdminTheme.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedPlanId,
                          hint: const Text(
                            'Select a Plan',
                            style: TextStyle(color: AdminTheme.textMuted),
                          ),
                          dropdownColor: AdminTheme.surface,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          items: plans
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p['id'].toString(),
                                  child: Text('${p['name']} - \$${p['price']}'),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setSheetState(() => selectedPlanId = val),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AdminTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AdminTheme.border),
                      ),
                      child: const Text(
                        'No active plans available.',
                        style: TextStyle(
                          color: AdminTheme.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
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
                        Map<String, dynamic>? sp;
                        if (selectedPlanId != null) {
                          sp = plans.firstWhere(
                            (p) => p['id'].toString() == selectedPlanId,
                          );
                        }
                        try {
                          await repo.updateFullUserProfile(
                            user['id'],
                            fullName: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            email: emailCtrl.text.trim(),
                            newPassword: passCtrl.text.trim(),
                            selectedPlan: sp,
                          );
                          ref.invalidate(allUsersProvider);
                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text('User updated successfully'),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update user: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
}

// ── User Details Bottom Sheet (Tabs) ──
class UserDetailsBottomSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  final String planName;
  final String expiryDate;
  final String assignedTrainer;

  const UserDetailsBottomSheet({
    super.key,
    required this.user,
    required this.planName,
    required this.expiryDate,
    required this.assignedTrainer,
  });

  @override
  State<UserDetailsBottomSheet> createState() => _UserDetailsBottomSheetState();
}

class _UserDetailsBottomSheetState extends State<UserDetailsBottomSheet> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late final Future<List<dynamic>> _attendanceFuture;

  @override
  void initState() {
    super.initState();
    _attendanceFuture = _loadAttendance();
  }

  Future<List<dynamic>> _loadAttendance() async {
    try {
      final repo = TrainerRepository();
      final details = await repo.getMemberDetailedProfile(widget.user['id']);
      return details['attendance_records'] as List<dynamic>? ?? [];
    } catch (_) {
      return [];
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return ''.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AdminTheme.orange, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AdminTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttendanceHistory(List<Map<String, dynamic>> records) {
    final Set<DateTime> attendanceDates = records
        .map((r) {
          final date = DateTime.tryParse((r['check_in'] ?? '').isNotEmpty ? ((r['check_in'] ?? '').endsWith('Z') ? r['check_in']! : '${r['check_in']}Z') : '')?.toLocal();
          return date != null
              ? DateTime(date.year, date.month, date.day)
              : null;
        })
        .whereType<DateTime>()
        .toSet();

    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          calendarFormat: CalendarFormat.month,
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
            rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: AdminTheme.textSecondary),
            weekendStyle: TextStyle(color: AdminTheme.orange),
          ),
          calendarStyle: CalendarStyle(
            defaultTextStyle: const TextStyle(color: Colors.white),
            weekendTextStyle: const TextStyle(color: Colors.white),
            outsideTextStyle: TextStyle(color: Colors.white38),
            todayDecoration: BoxDecoration(
              color: AdminTheme.orange.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: AdminTheme.orange,
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              final normalizedDay = DateTime(day.year, day.month, day.day);
              final isAttended = attendanceDates.any(
                (d) =>
                    d.year == normalizedDay.year &&
                    d.month == normalizedDay.month &&
                    d.day == normalizedDay.day,
              );

              if (isAttended) {
                return Center(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AdminTheme.success,
                      shape: BoxShape.circle,
                    ),
                    width: 35,
                    height: 35,
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 16),
        const Divider(color: AdminTheme.border),
        const SizedBox(height: 16),
        Text(
          _selectedDay == null
              ? 'Select a day to see times'
              : 'Sessions on ${DateFormat('MMM dd, yyyy').format(_selectedDay!)}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedDay != null) ...[
          ...records
              .where((r) {
                final dt = DateTime.tryParse((r['check_in'] ?? '').isNotEmpty ? ((r['check_in'] ?? '').endsWith('Z') ? r['check_in']! : '${r['check_in']}Z') : '')?.toLocal();
                return dt != null &&
                    dt.year == _selectedDay!.year &&
                    dt.month == _selectedDay!.month &&
                    dt.day == _selectedDay!.day;
              })
              .map((r) {
                final checkIn = DateTime.tryParse((r['check_in'] ?? '').isNotEmpty ? ((r['check_in'] ?? '').endsWith('Z') ? r['check_in']! : '${r['check_in']}Z') : '')?.toLocal();
                final checkOut = DateTime.tryParse((r['check_out'] ?? '').isNotEmpty ? ((r['check_out'] ?? '').endsWith('Z') ? r['check_out']! : '${r['check_out']}Z') : '')?.toLocal();
                final timeFormat = DateFormat('hh:mm a');

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminTheme.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AdminTheme.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Check In',
                            style: TextStyle(
                              color: AdminTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            checkIn != null ? timeFormat.format(checkIn) : '--',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AdminTheme.textSecondary,
                        size: 16,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Check Out',
                            style: TextStyle(
                              color: AdminTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            checkOut != null
                                ? timeFormat.format(checkOut)
                                : 'Active',
                            style: TextStyle(
                              color: checkOut != null
                                  ? Colors.white
                                  : AdminTheme.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          if (records.where((r) {
            final dt = DateTime.tryParse((r['check_in'] ?? '').isNotEmpty ? ((r['check_in'] ?? '').endsWith('Z') ? r['check_in']! : '${r['check_in']}Z') : '')?.toLocal();
            return dt != null &&
                dt.year == _selectedDay!.year &&
                dt.month == _selectedDay!.month &&
                dt.day == _selectedDay!.day;
          }).isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No attendance records for this day.',
                style: TextStyle(color: AdminTheme.textSecondary),
              ),
            ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AdminTheme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AdminTheme.orange.withValues(alpha: 0.15),
                    child: Text(
                      _getInitials(widget.user['full_name'] ?? 'Unknown'),
                      style: const TextStyle(
                        color: AdminTheme.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.user['full_name'] ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const TabBar(
              labelColor: AdminTheme.orange,
              unselectedLabelColor: AdminTheme.textSecondary,
              indicatorColor: AdminTheme.orange,
              dividerColor: AdminTheme.border,
              tabs: [
                Tab(text: 'Details'),
                Tab(text: 'Attendance'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Details
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailRow(
                          Icons.phone_outlined,
                          'Phone',
                          widget.user['phone'] ?? 'N/A',
                        ),
                        const SizedBox(height: 16),
                        _detailRow(
                          Icons.email_outlined,
                          'Email',
                          widget.user['email'] ?? 'N/A',
                        ),
                        const SizedBox(height: 16),
                        _detailRow(
                          Icons.card_membership_outlined,
                          'Plan Name',
                          widget.planName.isNotEmpty
                              ? widget.planName
                              : 'No Active Plan',
                        ),
                        const SizedBox(height: 16),
                        _detailRow(
                          Icons.event_busy_outlined,
                          'Expire Time',
                          widget.expiryDate.isNotEmpty
                              ? widget.expiryDate.replaceAll('Exp: ', '')
                              : 'N/A',
                        ),
                        const SizedBox(height: 16),
                        _detailRow(
                          Icons.sports_gymnastics,
                          'Trainer Name',
                          widget.assignedTrainer.isNotEmpty
                              ? widget.assignedTrainer
                              : 'No Trainer Assigned',
                        ),
                      ],
                    ),
                  ),
                  // Tab 2: Attendance
                  FutureBuilder<List<dynamic>>(
                    future: _attendanceFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AdminTheme.orange,
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ',
                            style: const TextStyle(color: AdminTheme.error),
                          ),
                        );
                      }
                      final records = snapshot.data ?? [];
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildAttendanceHistory(
                          records.cast<Map<String, dynamic>>(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

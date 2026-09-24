import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/features/admin/presentation/theme/admin_theme.dart';
import 'package:gym_management/features/admin/providers/admin_providers.dart';
import 'package:gym_management/core/utils/validators.dart';

/// Membership Plans Screen — push route from Side Drawer
class MembershipPlansScreen extends ConsumerStatefulWidget {
  const MembershipPlansScreen({super.key});

  @override
  ConsumerState<MembershipPlansScreen> createState() =>
      _MembershipPlansScreenState();
}

class _MembershipPlansScreenState extends ConsumerState<MembershipPlansScreen> {
  bool _isMonthly = true;

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(allMembershipPlansProvider);

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Membership Plans',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Manage subscription plans and pricing',
                          style: TextStyle(
                            color: AdminTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showCreatePlanSheet(),
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
                        '+ Create Plan',
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
            const SizedBox(height: 16),

            // ── Monthly / Yearly Toggle ──
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AdminTheme.card,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AdminTheme.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _toggleBtn('Monthly', _isMonthly),
                  _toggleBtn('Yearly', !_isMonthly),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Plans List ──
            Expanded(
              child: plansAsync.when(
                data: (plans) {
                  final activePlans = plans
                      .where((p) => p['is_active'] == true || p['is_active'] == 1)
                      .toList();

                  if (activePlans.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.card_membership,
                            size: 56,
                            color: AdminTheme.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No plans created yet',
                            style: AdminTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: AdminTheme.orange,
                    backgroundColor: AdminTheme.card,
                    onRefresh: () async =>
                        ref.invalidate(allMembershipPlansProvider),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: activePlans.length,
                      itemBuilder: (_, i) => _buildPlanCard(
                        activePlans[i],
                        i == 1,
                      ), // 2nd plan = recommended
                    ),
                  );
                },
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

  Widget _toggleBtn(String label, bool isActive, {String? badge}) {
    return GestureDetector(
      onTap: () => setState(() => _isMonthly = label == 'Monthly'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AdminTheme.orange : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AdminTheme.textSecondary,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AdminTheme.success,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan, bool isRecommended) {
    final name = plan['name'] ?? 'Plan';
    final price = double.tryParse(plan['price']?.toString() ?? '') ?? 0.0;
    final features = (plan['features'] as List?)?.cast<String>() ?? [];
    final duration = plan['duration_months'] ?? 1;
    final displayPrice = _isMonthly ? price : price * 12;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: 16, top: isRecommended ? 14 : 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AdminTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRecommended ? AdminTheme.orange : AdminTheme.border,
              width: isRecommended ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              // Plan name
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              // Price
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${displayPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AdminTheme.orange,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _isMonthly ? ' /month' : ' /year',
                    style: TextStyle(
                      color: AdminTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Plan Duration: $duration month${duration == 1 ? '' : 's'}',
                style: TextStyle(color: AdminTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              // Features
              ...features.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AdminTheme.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          f,
                          style: TextStyle(
                            color: AdminTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AdminTheme.border),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                      onPressed: () => _showEditPlanSheet(plan),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Delete button
                  Container(
                    decoration: BoxDecoration(
                      color: AdminTheme.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(
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
                              'Delete Plan',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: Text(
                              'Are you sure you want to delete the plan "${plan['name']}"? Active users will remain on it until it expires.',
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
                          final repo = ref.read(adminRepositoryProvider);
                          await repo.togglePlanActive(plan['id'], false);
                          ref.invalidate(allMembershipPlansProvider);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Recommended badge
        if (isRecommended)
          Positioned(
            top: 2,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AdminTheme.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Recommended',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showCreatePlanSheet() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '1');
    final featuresCtrl = TextEditingController();
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
              Text('Create New Plan', style: AdminTheme.headingMedium),
              const SizedBox(height: 16),
              _field(
                nameCtrl,
                'Plan Name',
                Icons.label_outline,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              _field(
                priceCtrl,
                'Price (₹)',
                Icons.attach_money,
                inputType: TextInputType.number,
                validator: (v) => Validators.validatePositiveDouble(v, 'Price'),
              ),
              _field(
                durationCtrl,
                'Duration (months)',
                Icons.calendar_today,
                inputType: TextInputType.number,
                validator: (v) => Validators.validatePositiveInteger(v, 'Duration'),
              ),
              _field(featuresCtrl, 'Features (comma separated)', Icons.list),
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
                    await repo.createMembershipPlan(
                      name: nameCtrl.text.trim(),
                      price: double.tryParse(priceCtrl.text.trim()) ?? 0,
                      durationMonths: int.tryParse(durationCtrl.text.trim()) ?? 1,
                      features: featuresCtrl.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList(),
                    );
                    ref.invalidate(allMembershipPlansProvider);
                  },
                  child: const Text('Create Plan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditPlanSheet(Map<String, dynamic> plan) {
    final nameCtrl = TextEditingController(text: plan['name'] ?? '');
    final priceCtrl = TextEditingController(
      text: (plan['price'] ?? '').toString(),
    );
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
              Text('Edit Plan', style: AdminTheme.headingMedium),
              const SizedBox(height: 16),
              _field(
                nameCtrl,
                'Plan Name',
                Icons.label_outline,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              _field(
                priceCtrl,
                'Price (₹)',
                Icons.attach_money,
                inputType: TextInputType.number,
                validator: (v) => Validators.validatePositiveDouble(v, 'Price'),
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
                    await repo.updateMembershipPlan(plan['id'], {
                      'name': nameCtrl.text.trim(),
                      'price': double.tryParse(priceCtrl.text.trim()) ?? 0,
                    });
                    ref.invalidate(allMembershipPlansProvider);
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

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? inputType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
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

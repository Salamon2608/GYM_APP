import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/features/admin/presentation/theme/admin_theme.dart';
import 'package:gym_management/features/admin/data/models/lead_model.dart';
import 'package:gym_management/features/admin/providers/admin_providers.dart';
import 'package:gym_management/core/utils/validators.dart';

class ConvertLeadDialog extends ConsumerStatefulWidget {
  final LeadModel lead;
  const ConvertLeadDialog({super.key, required this.lead});

  @override
  ConsumerState<ConvertLeadDialog> createState() => _ConvertLeadDialogState();
}

class _ConvertLeadDialogState extends ConsumerState<ConvertLeadDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  Map<String, dynamic>? _selectedPlan;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.lead.email);
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(allMembershipPlansProvider);

    return Dialog(
      backgroundColor: AdminTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 450),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Convert to Member', style: AdminTheme.headingMedium),
                const SizedBox(height: 8),
                Text(
                  'This will create a member account for ${widget.lead.fullName}.',
                  style: AdminTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _emailController,
                  style: AdminTheme.bodyLarge,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _passwordController,
                  style: AdminTheme.bodyLarge,
                  obscureText: true,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Assign Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 16),

                const Text('Select Membership Plan', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                plansAsync.when(
                  data: (plans) => DropdownButtonFormField<Map<String, dynamic>>(
                    dropdownColor: AdminTheme.card,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                    items: plans.map((p) => DropdownMenuItem(
                      value: p,
                      child: Text('${p['name']} - ₹${p['price']}', style: const TextStyle(color: Colors.white, fontSize: 14)),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedPlan = v),
                    validator: (v) => v == null ? 'Please select a plan' : null,
                  ),
                  loading: () => const LinearProgressIndicator(color: AdminTheme.orange),
                  error: (e, _) => Text('Error loading plans: $e', style: const TextStyle(color: AdminTheme.error)),
                ),

                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _convert,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.success,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Convert & Join', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _convert() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final repo = ref.read(leadRepositoryProvider);
      await repo.convertToMember(
        lead: widget.lead.copyWith(email: _emailController.text.trim()),
        password: _passwordController.text.trim(),
        selectedPlan: _selectedPlan!,
      );
      
      ref.invalidate(allLeadsProvider);
      ref.invalidate(allUsersProvider); // Refresh member list too
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lead converted to member successfully!'), backgroundColor: AdminTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to convert: $e'), backgroundColor: AdminTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

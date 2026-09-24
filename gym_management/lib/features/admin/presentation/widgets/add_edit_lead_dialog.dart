import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/features/admin/presentation/theme/admin_theme.dart';
import 'package:gym_management/features/admin/data/models/lead_model.dart';
import 'package:gym_management/features/admin/providers/admin_providers.dart';
import 'package:gym_management/core/utils/validators.dart';

class AddEditLeadDialog extends ConsumerStatefulWidget {
  final LeadModel? lead;
  const AddEditLeadDialog({super.key, this.lead});

  @override
  ConsumerState<AddEditLeadDialog> createState() => _AddEditLeadDialogState();
}

class _AddEditLeadDialogState extends ConsumerState<AddEditLeadDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _sourceController;
  late TextEditingController _notesController;
  late LeadStatus _status;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.lead?.fullName);
    _phoneController = TextEditingController(text: widget.lead?.phone);
    _emailController = TextEditingController(text: widget.lead?.email);
    _sourceController = TextEditingController(text: widget.lead?.source);
    _notesController = TextEditingController(text: widget.lead?.notes);
    _status = widget.lead?.status ?? LeadStatus.new_;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _sourceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AdminTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.lead == null ? 'Add New Lead' : 'Edit Lead',
                  style: AdminTheme.headingMedium,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  style: AdminTheme.bodyLarge,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: Validators.validateName,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  style: AdminTheme.bodyLarge,
                  keyboardType: TextInputType.phone,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: Validators.validatePhone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  style: AdminTheme.bodyLarge,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) => (v != null && v.isNotEmpty)
                      ? Validators.validateEmail(v)
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _sourceController,
                  style: AdminTheme.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Source (e.g. Walk-in, Website)',
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<LeadStatus>(
                  initialValue: _status,
                  dropdownColor: AdminTheme.card,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: LeadStatus.values.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(s.value[0].toUpperCase() + s.value.substring(1)),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _status = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  style: AdminTheme.bodyLarge,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminTheme.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(widget.lead == null ? 'Create Lead' : 'Update Lead', style: const TextStyle(color: Colors.white)),
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

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedLead = (widget.lead ?? LeadModel(fullName: '', phone: '')).copyWith(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      source: _sourceController.text.trim(),
      notes: _notesController.text.trim(),
      status: _status,
    );

    try {
      final repo = ref.read(leadRepositoryProvider);
      if (widget.lead == null) {
        await repo.addLead(updatedLead);
      } else {
        await repo.updateLead(updatedLead);
      }
      ref.invalidate(allLeadsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

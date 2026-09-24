import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_management/features/super_admin/providers/super_admin_providers.dart';

class GymManagementScreen extends ConsumerStatefulWidget {
  final String gymId;
  const GymManagementScreen({super.key, required this.gymId});

  @override
  ConsumerState<GymManagementScreen> createState() => _GymManagementScreenState();
}

class _GymManagementScreenState extends ConsumerState<GymManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  
  String _status = 'active';
  DateTime? _subscriptionEndDate;
  Map<String, dynamic>? _selectedPlan;

  bool get isNew => widget.gymId == 'new';

  @override
  void initState() {
    super.initState();
    if (!isNew) {
      _loadGymDetails();
    } else {
      _subscriptionEndDate = DateTime.now().add(const Duration(days: 30));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadGymDetails() async {
    try {
      final repos = ref.read(superAdminRepositoryProvider);
      final gyms = await repos.getGyms(); // In a real app, fetch single by ID
      final gym = gyms.firstWhere((g) => g['id'] == widget.gymId);
      
      setState(() {
        _nameCtrl.text = gym['name'] ?? '';
        _addressCtrl.text = gym['address'] ?? '';
        _status = gym['status'] ?? 'inactive';
        if (gym['subscription_end_date'] != null) {
          _subscriptionEndDate = DateTime.tryParse(gym['subscription_end_date']);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading gym: $e')));
      }
    }
  }

  Future<void> _saveGym() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try {
      final repo = ref.read(superAdminRepositoryProvider);
      String gymId = widget.gymId;
      
      if (isNew) {
        final newGym = await repo.createGym(
          name: _nameCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          status: _status,
          subscriptionEndDate: _subscriptionEndDate,
        );
        gymId = newGym['id'] as String;
      } else {
        await repo.updateGym(gymId, {
          'name': _nameCtrl.text.trim(),
          'address': _addressCtrl.text.trim(),
          'status': _status,
          'subscription_end_date': _subscriptionEndDate?.toIso8601String(),
        });
      }

      // Record subscription if a plan was selected
      if (_selectedPlan != null) {
        await repo.subscribeGymToPlan(gymId: gymId, plan: _selectedPlan!);
      }
      
      ref.invalidate(gymsProvider);
      if (!isNew) ref.invalidate(gymSubscriptionsProvider(gymId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gym saved successfully')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving gym: $e')));
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _subscriptionEndDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _subscriptionEndDate) {
      setState(() {
        _subscriptionEndDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Create New Gym' : 'Edit Gym'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Gym Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'Address'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _status = val);
                },
                onSaved: (val) {
                  if (val != null) _status = val;
                },
              ),
              const SizedBox(height: 24),
              const Text('Select Subscription Plan', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ref.watch(platformPlansProvider).when(
                    data: (plans) {
                      if (plans.isEmpty) return const Text('No platform plans available.');
                      return DropdownButtonFormField<Map<String, dynamic>>(
                        decoration: const InputDecoration(
                          hintText: 'Choose a plan to set expiry date',
                          border: OutlineInputBorder(),
                        ),
                        items: plans.map((plan) {
                          return DropdownMenuItem(
                            value: plan,
                            child: Text('${plan['name']} (${plan['duration_months']} months)'),
                          );
                        }).toList(),
                        onChanged: (plan) {
                          if (plan != null) {
                            final months = plan['duration_months'] as int;
                            setState(() {
                              _selectedPlan = plan;
                              _subscriptionEndDate = DateTime.now().add(Duration(days: months * 30));
                            });
                          }
                        },
                      );
                    },
                    loading: () => const LinearProgressIndicator(),
                    error: (e, s) => Text('Error loading plans: $e'),
                  ),
              const SizedBox(height: 24),
              ListTile(
                title: const Text('Subscription End Date'),
                subtitle: Text(_subscriptionEndDate != null 
                    ? _subscriptionEndDate!.toLocal().toString().split(' ')[0] 
                    : 'Not set'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveGym,
                child: const Text('Save Gym'),
              ),
              if (!isNew) ...[
                const SizedBox(height: 48),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  'Subscription History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ref.watch(gymSubscriptionsProvider(widget.gymId)).when(
                      data: (subs) {
                        if (subs.isEmpty) {
                          return const Center(child: Text('No subscription history found.'));
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: subs.length,
                          itemBuilder: (context, index) {
                            final sub = subs[index];
                            final DateTime payDate = DateTime.parse(sub['payment_date']);
                            final DateTime untilDate = DateTime.parse(sub['valid_until']);
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.receipt_long),
                                title: Text('Amount: ₹${sub['amount']}'),
                                subtitle: Text(
                                  'Paid: ${payDate.toLocal().toString().split(' ')[0]}\n'
                                  'Valid Until: ${untilDate.toLocal().toString().split(' ')[0]}\n'
                                  'Note: ${sub['notes'] ?? 'None'}',
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Text('Error: $e'),
                    ),
                const SizedBox(height: 48),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Gym Admins',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAdminDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Admin'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ref.watch(gymAdminsProvider(widget.gymId)).when(
                      data: (admins) {
                        if (admins.isEmpty) {
                          return const Center(child: Text('No admins assigned to this gym.'));
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: admins.length,
                          itemBuilder: (context, index) {
                            final admin = admins[index];
                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(child: Icon(Icons.person)),
                                title: Text(admin['full_name'] ?? 'No Name'),
                                subtitle: Text(admin['email'] ?? 'No Email'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (admin['phone'] != null && admin['phone'].toString().isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.message, color: Colors.green),
                                        onPressed: () {
                                          // Placeholder for WhatsApp deep link if needed
                                        },
                                      ),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                                onTap: () => _showAdminDialog(context, admin: admin),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Text('Error: $e'),
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAdminDialog(BuildContext context, {Map<String, dynamic>? admin}) {
    final bool isEdit = admin != null;
    final emailCtrl = TextEditingController(text: admin?['email'] ?? '');
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController(text: admin?['full_name'] ?? '');
    final phoneCtrl = TextEditingController(text: admin?['phone']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Gym Admin' : 'Add Gym Admin'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    helperText: 'Used as username for login',
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: passCtrl,
                  decoration: InputDecoration(
                    labelText: isEdit ? 'New Password (leave blank to keep current)' : 'Password',
                  ),
                  obscureText: true,
                  validator: (val) {
                    if (!isEdit && (val == null || val.length < 6)) {
                      return 'Min 6 chars';
                    }
                    if (isEdit && val != null && val.isNotEmpty && val.length < 6) {
                      return 'Min 6 chars';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              
              try {
                final repo = ref.read(superAdminRepositoryProvider);
                
                if (isEdit) {
                  await repo.updateUserAccount(
                    userId: admin['id'],
                    email: emailCtrl.text.trim(),
                    password: passCtrl.text.trim().isEmpty ? null : passCtrl.text.trim(),
                    fullName: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    role: 'admin',
                    gymId: widget.gymId,
                  );
                } else {
                  await repo.createUserAccount(
                    email: emailCtrl.text.trim(),
                    password: passCtrl.text.trim(),
                    fullName: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    role: 'admin',
                    gymId: widget.gymId,
                  );
                }
                
                ref.invalidate(gymAdminsProvider(widget.gymId));
                if (!context.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isEdit ? 'Admin updated successfully' : 'Admin created successfully'))
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'))
                );
              }
            },
            child: Text(isEdit ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }
}

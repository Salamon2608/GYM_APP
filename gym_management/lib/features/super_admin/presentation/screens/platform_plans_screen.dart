import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/features/super_admin/providers/super_admin_providers.dart';

class PlatformPlansScreen extends ConsumerWidget {
  const PlatformPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(platformPlansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Platform Membership Plans'),
      ),
      body: plansAsync.when(
        data: (plans) {
          if (plans.isEmpty) {
            return const Center(child: Text('No plans created yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(plan['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${plan['duration_months']} Months - ₹${plan['price']}\n${plan['description'] ?? ''}',
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showPlanDialog(context, ref, plan: plan),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, ref, plan),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPlanDialog(context, ref),
        label: const Text('Add Plan'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showPlanDialog(BuildContext context, WidgetRef ref, {Map<String, dynamic>? plan}) {
    final nameCtrl = TextEditingController(text: plan?['name']);
    final descCtrl = TextEditingController(text: plan?['description']);
    final priceCtrl = TextEditingController(text: plan?['price']?.toString());
    final durationCtrl = TextEditingController(text: plan?['duration_months']?.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(plan == null ? 'Create New Plan' : 'Edit Plan'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Plan Name (e.g. Basic, Pro)'),
                  validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                TextFormField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: 'Price (INR)'),
                  keyboardType: TextInputType.number,
                  validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid price' : null,
                ),
                TextFormField(
                  controller: durationCtrl,
                  decoration: const InputDecoration(labelText: 'Duration (Months)'),
                  keyboardType: TextInputType.number,
                  validator: (val) => val == null || int.tryParse(val) == null ? 'Invalid duration' : null,
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
              
              final repo = ref.read(superAdminRepositoryProvider);
              try {
                if (plan == null) {
                  await repo.createPlatformPlan(
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    price: double.parse(priceCtrl.text),
                    durationMonths: int.parse(durationCtrl.text),
                  );
                } else {
                  await repo.updatePlatformPlan(plan['id'], {
                    'name': nameCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'price': double.parse(priceCtrl.text),
                    'duration_months': int.parse(durationCtrl.text),
                  });
                }
                ref.invalidate(platformPlansProvider);
                if (context.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: Text(plan == null ? 'Create' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Map<String, dynamic> plan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text('Are you sure you want to delete "${plan['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(superAdminRepositoryProvider).deletePlatformPlan(plan['id']);
                ref.invalidate(platformPlansProvider);
                if (context.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

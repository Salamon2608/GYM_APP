import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';
import 'package:gym_management/features/super_admin/providers/super_admin_providers.dart';
import 'package:gym_management/core/router/app_router.dart';
import 'package:intl/intl.dart';

class SuperAdminDashboardScreen extends ConsumerWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gymsAsync = ref.watch(gymsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.card_membership),
            onPressed: () {
              context.push('${AppRoutes.superAdminDashboard}/plans');
            },
            tooltip: 'Platform Plans',
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              context.push('${AppRoutes.superAdminDashboard}/payments');
            },
            tooltip: 'Payment History',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push(AppRoutes.superAdminSettings);
            },
            tooltip: 'Platform Settings',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
            },
            tooltip: 'Log Out',
          ),
        ],
      ),
      body: gymsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (gyms) {
          if (gyms.isEmpty) {
            return const Center(child: Text('No gyms found. Add one to get started.'));
          }
          return ListView.builder(
            itemCount: gyms.length,
            itemBuilder: (context, index) {
              final gym = gyms[index];
              final isActive = gym['status'] == 'active';
              final String endDateStr = gym['subscription_end_date'] ?? '';
              DateTime? endDate;
              if (endDateStr.isNotEmpty) {
                endDate = DateTime.tryParse(endDateStr);
                if (endDate != null && endDate.isBefore(DateTime.now())) {
                   // Status might say active but date is expired
                   // The backend RLS checks this, but UI should reflect it
                }
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isActive ? Colors.green : Colors.red,
                    child: const Icon(Icons.fitness_center, color: Colors.white),
                  ),
                  title: Text(gym['name'] ?? 'Unknown Gym'),
                  subtitle: Text(
                    'Status: ${gym['status']}\n'
                    'Expires: ${endDate != null ? DateFormat.yMMMd().format(endDate) : 'Never'}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('${AppRoutes.superAdminDashboard}/gym/${gym['id']}');
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('${AppRoutes.superAdminDashboard}/gym/new');
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Gym'),
      ),
    );
  }
}

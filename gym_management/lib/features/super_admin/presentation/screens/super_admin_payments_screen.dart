import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/features/super_admin/providers/super_admin_providers.dart';
import 'package:intl/intl.dart';

class SuperAdminPaymentsScreen extends ConsumerWidget {
  const SuperAdminPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(platformPaymentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
      ),
      body: paymentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (payments) {
          if (payments.isEmpty) {
            return const Center(child: Text('No payment history found.'));
          }
          return ListView.builder(
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              final amountStr = payment['amount']?.toString() ?? '0';
              final amount = double.tryParse(amountStr) ?? 0.0;
              
              // Extract gym name dynamically from the joined table
              final gymData = payment['gyms'];
              final String gymName;
              if (gymData is Map && gymData.containsKey('name')) {
                gymName = gymData['name'] as String;
              } else {
                gymName = 'Unknown Gym';
              }

              final dateStr = payment['payment_date'] as String?;
              final date = dateStr != null ? DateTime.tryParse(dateStr)?.toLocal() : null;
              final notes = payment['notes'] as String? ?? 'No notes';

              final validUntilStr = payment['valid_until'] as String?;
              final validUntil = validUntilStr != null ? DateTime.tryParse(validUntilStr) : null;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Expanded(
                             child: Text(
                               gymName,
                               style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                           ),
                           Text(
                             '₹${amount.toStringAsFixed(2)}',
                             style: Theme.of(context).textTheme.titleMedium?.copyWith(
                               color: Colors.green,
                               fontWeight: FontWeight.w600,
                             ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 8),
                       Text('Date: ${date != null ? DateFormat.yMMMd().add_jm().format(date) : 'N/A'}'),
                       if (validUntil != null)
                         Text('Valid Until: ${DateFormat.yMMMd().format(validUntil)}'),
                       const SizedBox(height: 4),
                       Text(
                         notes,
                         style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                       ),
                     ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

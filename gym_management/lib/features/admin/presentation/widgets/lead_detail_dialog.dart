import 'package:flutter/material.dart';
import 'package:gym_management/features/admin/presentation/theme/admin_theme.dart';
import 'package:gym_management/features/admin/data/models/lead_model.dart';

class LeadDetailDialog extends StatelessWidget {
  final LeadModel lead;
  final VoidCallback onEdit;
  final VoidCallback onCall;
  final VoidCallback? onConvert;

  const LeadDetailDialog({
    super.key,
    required this.lead,
    required this.onEdit,
    required this.onCall,
    this.onConvert,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AdminTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Lead Details', style: AdminTheme.headingMedium),
                IconButton(
                  icon: const Icon(Icons.close, color: AdminTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            _buildDetailRow(Icons.person_outline, 'Full Name', lead.fullName),
            _buildDetailRow(Icons.phone_outlined, 'Phone', lead.phone),
            if (lead.email != null && lead.email!.isNotEmpty)
              _buildDetailRow(Icons.email_outlined, 'Email', lead.email!),
            
            _buildDetailRow(Icons.info_outline, 'Source', lead.source ?? 'Not specified'),
            
            Row(
              children: [
                const Icon(Icons.flag_outlined, color: AdminTheme.orange, size: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status', style: TextStyle(color: AdminTheme.textMuted, fontSize: 12)),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(lead.status).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        lead.status.value.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(lead.status),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (lead.notes != null && lead.notes!.isNotEmpty) ...[
              const Divider(color: AdminTheme.border, height: 32),
              Text('Notes', style: TextStyle(color: AdminTheme.textMuted, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AdminTheme.scaffold,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AdminTheme.border),
                ),
                child: Text(
                  lead.notes!,
                  style: AdminTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            const Divider(color: AdminTheme.border, height: 32),
            Text(
              'Added on: ${lead.formattedDate}',
              style: TextStyle(color: AdminTheme.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCall,
                    icon: const Icon(Icons.phone_outlined),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminTheme.success,
                      side: const BorderSide(color: AdminTheme.success),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminTheme.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            if (onConvert != null && lead.status != LeadStatus.joined) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onConvert,
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Convert to Member'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminTheme.info,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AdminTheme.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: AdminTheme.textMuted, fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: AdminTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.new_: return AdminTheme.info;
      case LeadStatus.contacted: return Colors.blueGrey;
      case LeadStatus.interested: return AdminTheme.orange;
      case LeadStatus.trial: return Colors.purple;
      case LeadStatus.joined: return AdminTheme.success;
      case LeadStatus.lost: return AdminTheme.error;
    }
  }
}

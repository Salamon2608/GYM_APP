import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/features/admin/presentation/theme/admin_theme.dart';
import 'package:gym_management/features/admin/providers/admin_providers.dart';
import 'package:gym_management/features/admin/data/models/lead_model.dart';
import 'package:gym_management/features/admin/presentation/widgets/add_edit_lead_dialog.dart';
import 'package:gym_management/features/admin/presentation/widgets/convert_lead_dialog.dart';
import 'package:gym_management/features/admin/presentation/widgets/lead_detail_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class LeadsScreen extends ConsumerStatefulWidget {
  const LeadsScreen({super.key});

  @override
  ConsumerState<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends ConsumerState<LeadsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  LeadStatus? _selectedStatus;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leadsAsync = ref.watch(allLeadsProvider);

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
                      'Lead Management',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Track and convert potential members',
                      style: TextStyle(
                        color: AdminTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // + Add Lead button
              GestureDetector(
                onTap: () => _showAddEditLeadDialog(),
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
                    '+ Add Lead',
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

        // ── Search & Filter ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search leads...',
                    hintStyle: TextStyle(color: AdminTheme.textMuted),
                    prefixIcon: const Icon(Icons.search, color: AdminTheme.textMuted),
                    filled: true,
                    fillColor: AdminTheme.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AdminTheme.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<LeadStatus?>(
                    value: _selectedStatus,
                    dropdownColor: AdminTheme.card,
                    hint: const Text('Status', style: TextStyle(color: Colors.white, fontSize: 14)),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Status')),
                      ...LeadStatus.values.map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.value[0].toUpperCase() + s.value.substring(1))),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedStatus = val),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Leads List ──
        Expanded(
          child: leadsAsync.when(
            data: (leads) {
              final filtered = leads.where((l) {
                final matchSearch = l.fullName.toLowerCase().contains(_searchQuery) ||
                    l.phone.contains(_searchQuery) ||
                    (l.email?.toLowerCase().contains(_searchQuery) ?? false);
                final matchStatus = _selectedStatus == null || l.status == _selectedStatus;
                return matchSearch && matchStatus;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_search_outlined, size: 56, color: AdminTheme.textMuted),
                      const SizedBox(height: 12),
                      Text('No leads found', style: AdminTheme.bodySmall),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: AdminTheme.orange,
                onRefresh: () async => ref.invalidate(allLeadsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _buildLeadCard(filtered[i]),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AdminTheme.orange)),
            error: (e, _) => Center(child: Text('Error: $e', style: TextStyle(color: AdminTheme.error))),
          ),
        ),
      ],
    );
  }

  Widget _buildLeadCard(LeadModel lead) {
    final statusColor = _getStatusColor(lead.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AdminTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLeadDetailDialog(lead),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AdminTheme.orange.withValues(alpha: 0.1),
                      child: Text(
                        lead.fullName[0].toUpperCase(),
                        style: const TextStyle(color: AdminTheme.orange, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lead.fullName,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            lead.phone,
                            style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        lead.status.value.toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (lead.source != null) ...[
                      Icon(Icons.info_outline, size: 14, color: AdminTheme.textMuted),
                      const SizedBox(width: 4),
                      Text(lead.source!, style: TextStyle(color: AdminTheme.textMuted, fontSize: 12)),
                    ],
                    const Spacer(),
                    _actionIcon(Icons.phone_outlined, AdminTheme.success, () => _launchCaller(lead.phone)),
                    const SizedBox(width: 8),
                    _actionIcon(Icons.edit_outlined, AdminTheme.orange, () => _showAddEditLeadDialog(lead)),
                    const SizedBox(width: 8),
                    if (lead.status != LeadStatus.joined)
                      _actionIcon(Icons.person_add_alt_1_outlined, AdminTheme.info, () => _showConvertDialog(lead)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 18),
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

  void _launchCaller(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _showAddEditLeadDialog([LeadModel? lead]) {
    showDialog(
      context: context,
      builder: (ctx) => AddEditLeadDialog(lead: lead),
    );
  }

  void _showConvertDialog(LeadModel lead) {
    showDialog(
      context: context,
      builder: (ctx) => ConvertLeadDialog(lead: lead),
    );
  }

  void _showLeadDetailDialog(LeadModel lead) {
    showDialog(
      context: context,
      builder: (ctx) => LeadDetailDialog(
        lead: lead,
        onEdit: () {
          Navigator.pop(ctx);
          _showAddEditLeadDialog(lead);
        },
        onCall: () => _launchCaller(lead.phone),
        onConvert: () {
          Navigator.pop(ctx);
          _showConvertDialog(lead);
        },
      ),
    );
  }
}

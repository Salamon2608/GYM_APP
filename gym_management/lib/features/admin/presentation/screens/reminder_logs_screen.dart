import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management/features/admin/presentation/theme/admin_theme.dart';
import 'package:gym_management/features/admin/providers/admin_providers.dart';

// Reminder type options
const _typeOptions = ['All', 'expiry_warning', 'payment_due', 'welcome'];
const _typeLabels = {
  'expiry_warning': 'Expiry Warning',
  'payment_due': 'Payment Due',
  'welcome': 'Welcome',
};
const _expiryDayOptions = [3, 7, 15];

// Date filter options
const _dateOptions = ['All Time', 'Today', 'This Week', 'This Month'];

class ReminderLogsScreen extends ConsumerStatefulWidget {
  const ReminderLogsScreen({super.key});

  @override
  ConsumerState<ReminderLogsScreen> createState() => _ReminderLogsScreenState();
}

class _ReminderLogsScreenState extends ConsumerState<ReminderLogsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  String _selectedType = 'All';
  String _selectedDate = 'All Time';
  String _search = '';
  final _searchCtrl = TextEditingController();
  int _selectedExpiryDays = 7;
  bool _bulkSending = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.scaffold,
      appBar: AppBar(
        backgroundColor: AdminTheme.scaffold,
        title: Text('Reminders', style: AdminTheme.headingMedium),
        iconTheme: const IconThemeData(color: AdminTheme.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AdminTheme.textPrimary,
            ),
            onPressed: () {
              ref.invalidate(reminderLogsProvider);
              ref.invalidate(reminderStatsProvider);
              ref.invalidate(expiringMembersProvider(_selectedExpiryDays));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AdminTheme.orange,
          labelColor: AdminTheme.orange,
          unselectedLabelColor: AdminTheme.textMuted,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Send Reminders'),
            Tab(text: 'Logs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [_buildSendTab(), _buildLogsTab()],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // TAB 1: SEND REMINDERS
  // ═══════════════════════════════════════════════════

  Widget _buildSendTab() {
    final expiringAsync = ref.watch(
      expiringMembersProvider(_selectedExpiryDays),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bulk expiry section header
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AdminTheme.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('Expiring Members', style: AdminTheme.headingSmall),
            ],
          ),
          const SizedBox(height: 12),

          // Expiry day filter buttons
          Row(
            children: [
              Text('Show expiring in:', style: AdminTheme.label),
              const SizedBox(width: 10),
              ..._expiryDayOptions.map((days) {
                final isSelected = _selectedExpiryDays == days;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedExpiryDays = days),
                    child: AnimatedContainer(
                      duration: AdminTheme.shortDuration,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AdminTheme.orange : AdminTheme.card,
                        borderRadius: BorderRadius.circular(
                          AdminTheme.radiusMd,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? AdminTheme.orange
                              : AdminTheme.border,
                        ),
                      ),
                      child: Text(
                        '$days days',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AdminTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 14),

          // Expiring members list
          expiringAsync.when(
            data: (members) => _buildExpiringMembersSection(members),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: AdminTheme.orange),
              ),
            ),
            error: (e, _) => Center(
              child: Text(
                'Error: $e',
                style: const TextStyle(color: AdminTheme.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiringMembersSection(List<Map<String, dynamic>> members) {
    if (members.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AdminTheme.card,
          borderRadius: BorderRadius.circular(AdminTheme.radiusLg),
          border: Border.all(color: AdminTheme.border),
        ),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: AdminTheme.success,
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(
                'No members expiring in $_selectedExpiryDays days',
                style: AdminTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Remind All button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.warning,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
              ),
            ),
            icon: _bulkSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.black54,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.notifications_active_rounded, size: 20),
            label: Text(
              _bulkSending
                  ? 'Sending...'
                  : 'Remind All ${members.length} Member${members.length == 1 ? '' : 's'}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            onPressed: _bulkSending ? null : () => _sendBulkReminders(members),
          ),
        ),
        const SizedBox(height: 12),

        // Member cards
        ...members.map((m) => _buildExpiringMemberCard(m)),
      ],
    );
  }

  Widget _buildExpiringMemberCard(Map<String, dynamic> membership) {
    final user = membership['users'] as Map<String, dynamic>? ?? {};
    final endDateStr = membership['end_date'] ?? '';
    final endDate = DateTime.tryParse(endDateStr);
    final daysLeft = endDate != null
        ? endDate.difference(DateTime.now()).inDays
        : 0;
    final userId = user['id']?.toString() ?? '';

    Color urgencyColor = AdminTheme.success;
    if (daysLeft <= 3) {
      urgencyColor = AdminTheme.error;
    } else if (daysLeft <= 7) {
      urgencyColor = AdminTheme.warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AdminTheme.card,
        borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
        border: Border.all(color: urgencyColor.withValues(alpha: 0.4)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: urgencyColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$daysLeft',
              style: TextStyle(
                color: urgencyColor,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ),
        title: Text(
          user['full_name'] ?? 'Unknown',
          style: AdminTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user['email'] ?? '', style: AdminTheme.label),
            Text(
              'Expires: $endDateStr',
              style: AdminTheme.label.copyWith(color: urgencyColor),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.send_rounded,
            color: AdminTheme.orange,
            size: 20,
          ),
          tooltip: 'Send Reminder',
          onPressed: userId.isNotEmpty
              ? () => _sendSingleReminder(userId, user['full_name'] ?? '')
              : null,
        ),
      ),
    );
  }

  Future<void> _sendBulkReminders(List<Map<String, dynamic>> members) async {
    setState(() => _bulkSending = true);
    try {
      final userIds = members
          .map((m) => (m['users'] as Map?)?['id']?.toString())
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      final repo = ref.read(adminRepositoryProvider);
      final count = await repo.sendBulkExpiryReminders(userIds);

      ref.invalidate(reminderLogsProvider);
      ref.invalidate(reminderStatsProvider);

      if (mounted) {
        _showSnackBar('Sent $count expiry reminders!', AdminTheme.success);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', AdminTheme.error);
    } finally {
      if (mounted) setState(() => _bulkSending = false);
    }
  }

  Future<void> _sendSingleReminder(String userId, String name) async {
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.sendReminderToUser(userId: userId, type: 'expiry_warning');
      ref.invalidate(reminderLogsProvider);
      ref.invalidate(reminderStatsProvider);
      if (mounted) {
        _showSnackBar('Reminder sent to $name', AdminTheme.success);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', AdminTheme.error);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // TAB 2: LOGS
  // ═══════════════════════════════════════════════════

  Widget _buildLogsTab() {
    final logsAsync = ref.watch(reminderLogsProvider);

    return Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by member name...',
              hintStyle: const TextStyle(
                color: AdminTheme.textMuted,
                fontSize: 13,
              ),
              filled: true,
              fillColor: AdminTheme.card,
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AdminTheme.textMuted,
                size: 20,
              ),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear_rounded,
                        color: AdminTheme.textMuted,
                        size: 18,
                      ),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _search = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                borderSide: const BorderSide(color: AdminTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                borderSide: const BorderSide(color: AdminTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                borderSide: const BorderSide(
                  color: AdminTheme.orange,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 12,
              ),
            ),
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
          ),
        ),

        // Type filter chips
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _typeOptions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final t = _typeOptions[i];
              final label = t == 'All' ? 'All Types' : (_typeLabels[t] ?? t);
              final isSelected = _selectedType == t;
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedType = t),
                backgroundColor: AdminTheme.card,
                selectedColor: AdminTheme.orange,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AdminTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                side: BorderSide(
                  color: isSelected ? AdminTheme.orange : AdminTheme.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                ),
              );
            },
          ),
        ),

        // Date filter chips
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _dateOptions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final d = _dateOptions[i];
              final isSelected = _selectedDate == d;
              return ChoiceChip(
                label: Text(d),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedDate = d),
                backgroundColor: AdminTheme.card,
                selectedColor: AdminTheme.info,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AdminTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                side: BorderSide(
                  color: isSelected ? AdminTheme.info : AdminTheme.border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
                ),
              );
            },
          ),
        ),

        // Logs list
        Expanded(
          child: logsAsync.when(
            data: (logs) {
              final filtered = _applyFilters(logs);
              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_off_rounded,
                        size: 48,
                        color: AdminTheme.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No reminder logs found',
                        style: AdminTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _buildReminderCard(filtered[i]),
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
    );
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> logs) {
    final now = DateTime.now();
    return logs.where((log) {
      // Type filter
      if (_selectedType != 'All' && log['type'] != _selectedType) return false;

      // Date filter
      final sentAt = DateTime.tryParse(log['sent_at'] ?? '');
      if (_selectedDate != 'All Time' && sentAt != null) {
        if (_selectedDate == 'Today') {
          final today = DateTime(now.year, now.month, now.day);
          if (sentAt.isBefore(today)) return false;
        } else if (_selectedDate == 'This Week') {
          final weekAgo = now.subtract(const Duration(days: 7));
          if (sentAt.isBefore(weekAgo)) return false;
        } else if (_selectedDate == 'This Month') {
          final firstOfMonth = DateTime(now.year, now.month, 1);
          if (sentAt.isBefore(firstOfMonth)) return false;
        }
      }

      // Name search
      if (_search.isNotEmpty) {
        final user = log['users'] as Map<String, dynamic>? ?? {};
        final name = (user['full_name'] ?? '').toString().toLowerCase();
        final email = (user['email'] ?? '').toString().toLowerCase();
        if (!name.contains(_search) && !email.contains(_search)) return false;
      }

      return true;
    }).toList();
  }

  Widget _buildReminderCard(Map<String, dynamic> log) {
    final user = log['users'] as Map<String, dynamic>? ?? {};
    final type = log['type'] ?? 'expiry_warning';
    final label = _typeLabels[type] ?? type.toString().replaceAll('_', ' ');
    final sentAt = DateTime.tryParse(log['sent_at'] ?? '');

    Color typeColor = AdminTheme.warning;
    IconData typeIcon = Icons.notifications_active_rounded;
    if (type == 'welcome') {
      typeColor = AdminTheme.success;
      typeIcon = Icons.waving_hand_rounded;
    } else if (type == 'payment_due') {
      typeColor = AdminTheme.error;
      typeIcon = Icons.payment_rounded;
    }

    String dateStr = 'Unknown';
    if (sentAt != null) {
      final now = DateTime.now();
      final diff = now.difference(sentAt);
      if (diff.inMinutes < 1) {
        dateStr = 'Just now';
      } else if (diff.inHours < 1) {
        dateStr = '${diff.inMinutes}m ago';
      } else if (diff.inDays < 1) {
        dateStr = '${diff.inHours}h ago';
      } else if (diff.inDays == 1) {
        dateStr = 'Yesterday';
      } else {
        dateStr = '${sentAt.day}/${sentAt.month}/${sentAt.year}';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AdminTheme.card,
        borderRadius: BorderRadius.circular(AdminTheme.radiusMd),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(typeIcon, color: typeColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['full_name'] ?? 'Unknown User',
                  style: AdminTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(user['email'] ?? '', style: AdminTheme.label),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: typeColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        label.toUpperCase(),
                        style: AdminTheme.badgeText.copyWith(color: typeColor),
                      ),
                    ),
                    const Spacer(),
                    Text(dateStr, style: AdminTheme.label),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

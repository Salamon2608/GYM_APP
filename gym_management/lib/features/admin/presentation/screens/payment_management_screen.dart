import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:gym_management/features/admin/presentation/theme/admin_theme.dart';
import 'package:gym_management/features/admin/providers/admin_providers.dart';

/// Payments tab body — embedded inside AdminShell
class PaymentManagementScreen extends ConsumerStatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  ConsumerState<PaymentManagementScreen> createState() =>
      _PaymentManagementScreenState();
}

class _PaymentManagementScreenState
    extends ConsumerState<PaymentManagementScreen> {
  String _chartPeriod = 'Last 7 Days';
  String _statusFilter = 'All Status';

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(allPaymentsProvider);
    final statsAsync = ref.watch(adminDashboardStatsProvider);

    return RefreshIndicator(
      color: AdminTheme.orange,
      backgroundColor: AdminTheme.card,
      onRefresh: () async {
        ref.invalidate(allPaymentsProvider);
        ref.invalidate(adminDashboardStatsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            const Text(
              'Payment Monitoring',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Track and manage all payment transactions',
              style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // ── 2x2 Stats Grid ──
            statsAsync.when(
              data: (stats) => _buildStatsGrid(stats, paymentsAsync),
              loading: () => const SizedBox(
                height: 180,
                child: Center(
                  child: CircularProgressIndicator(color: AdminTheme.orange),
                ),
              ),
              error: (e, _) => Text(
                'Error: $e',
                style: const TextStyle(color: AdminTheme.error),
              ),
            ),
            const SizedBox(height: 16),

            // ── Revenue Trends Chart ──
            _buildChartSection(paymentsAsync),
            const SizedBox(height: 16),

            // ── Recent Transactions ──
            _buildTransactionsSection(paymentsAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
    Map<String, dynamic> stats,
    AsyncValue<List<Map<String, dynamic>>> paymentsAsync,
  ) {
    final totalRevenue = stats['total_revenue'] ?? 0.0;

    // Calculate completed & pending counts
    int completed = 0;
    int pending = 0;
    double monthRevenue = 0;
    paymentsAsync.whenData((payments) {
      for (final p in payments) {
        if (p['status'] == 'completed') {
          completed++;
          final createdAt = DateTime.tryParse(
            p['created_at']?.toString() ?? '',
          );
          if (createdAt != null &&
              createdAt.month == DateTime.now().month &&
              createdAt.year == DateTime.now().year) {
            monthRevenue += (double.tryParse(p['amount']?.toString() ?? '') ?? 0.0);
          }
        } else if (p['status'] == 'pending') {
          pending++;
        }
      }
    });

    final successRate = completed > 0
        ? ((completed / (completed + pending)) * 100).toStringAsFixed(1)
        : '0.0';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                'Total Revenue',
                '₹${_fmt(totalRevenue)}',
                '+23% from last month',
                true,
                Icons.attach_money_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                'This Month',
                '₹${_fmt(monthRevenue)}',
                '+15% from last week',
                true,
                Icons.trending_up_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statCard(
                'Successful',
                _fmt(completed),
                '$successRate% success rate',
                true,
                Icons.check_circle_outline,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                'Pending',
                pending.toString(),
                'Awaiting confirmation',
                false,
                Icons.schedule_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(
    String title,
    String value,
    String subtitle,
    bool positive,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AdminTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AdminTheme.orange,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: positive ? AdminTheme.success : AdminTheme.warning,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(
    AsyncValue<List<Map<String, dynamic>>> paymentsAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Revenue Trends',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AdminTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AdminTheme.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isDense: true,
                    value: _chartPeriod,
                    dropdownColor: AdminTheme.surface,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: AdminTheme.textMuted,
                    ),
                    items: ['Last 7 Days', 'Last 30 Days', 'Last 6 Months']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _chartPeriod = val ?? 'Last 7 Days'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: paymentsAsync.when(
              data: (payments) => _buildBarChart(payments),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AdminTheme.orange),
              ),
              error: (_, _) => const Center(
                child: Text(
                  'Unable to load chart',
                  style: TextStyle(color: AdminTheme.textMuted),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> payments) {
    final now = DateTime.now();
    final List<_ChartData> chartData = [];

    if (_chartPeriod == 'Last 7 Days') {
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final label = DateFormat.E().format(date);
        double total = 0;
        for (final p in payments) {
          if (p['status'] == 'completed') {
            final dt = DateTime.tryParse(p['created_at']?.toString() ?? '')?.toLocal();
            if (dt != null &&
                dt.year == date.year &&
                dt.month == date.month &&
                dt.day == date.day) {
              total += double.tryParse(p['amount']?.toString() ?? '') ?? 0.0;
            }
          }
        }
        chartData.add(_ChartData(label, total));
      }
    } else if (_chartPeriod == 'Last 30 Days') {
      for (int i = 29; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final label = DateFormat('d').format(date);
        double total = 0;
        for (final p in payments) {
          if (p['status'] == 'completed') {
            final dt = DateTime.tryParse(p['created_at']?.toString() ?? '')?.toLocal();
            if (dt != null &&
                dt.year == date.year &&
                dt.month == date.month &&
                dt.day == date.day) {
              total += double.tryParse(p['amount']?.toString() ?? '') ?? 0.0;
            }
          }
        }
        chartData.add(_ChartData(label, total));
      }
    } else {
      // Last 6 Months
      for (int i = 5; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);
        final label = DateFormat.MMM().format(date);
        double total = 0;
        for (final p in payments) {
          if (p['status'] == 'completed') {
            final dt = DateTime.tryParse(p['created_at']?.toString() ?? '')?.toLocal();
            if (dt != null && dt.year == date.year && dt.month == date.month) {
              total += double.tryParse(p['amount']?.toString() ?? '') ?? 0.0;
            }
          }
        }
        chartData.add(_ChartData(label, total));
      }
    }

    final barWidth = _chartPeriod == 'Last 30 Days' ? 8.0 : 28.0;

    return BarChart(
      key: ValueKey(_chartPeriod),
      BarChartData(
        barGroups: List.generate(chartData.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: chartData[i].value,
                color: AdminTheme.orange,
                width: barWidth,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget:
                  (value, meta) => Text(
                    _fmtChart(value),
                    style: const TextStyle(
                      color: AdminTheme.textMuted,
                      fontSize: 10,
                    ),
                  ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < chartData.length) {
                  // For 30 days, skip some labels to avoid crowding
                  if (_chartPeriod == 'Last 30 Days' && idx % 5 != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      chartData[idx].label,
                      style: const TextStyle(
                        color: AdminTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine:
              (value) => FlLine(color: AdminTheme.border, strokeWidth: 0.5),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem:
                (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                  '₹${_fmtChart(rod.toY)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsSection(
    AsyncValue<List<Map<String, dynamic>>> paymentsAsync,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AdminTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AdminTheme.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isDense: true,
                  value: _statusFilter,
                  dropdownColor: AdminTheme.surface,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: AdminTheme.textMuted,
                  ),
                  items: ['All Status', 'completed', 'pending', 'failed']
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            s == 'All Status'
                                ? s
                                : s[0].toUpperCase() + s.substring(1),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _statusFilter = val ?? 'All Status'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        paymentsAsync.when(
          data: (payments) {
            var filtered = _statusFilter == 'All Status'
                ? payments
                : payments.where((p) => p['status'] == _statusFilter).toList();
            final recent = filtered.take(10).toList();
            if (recent.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No transactions found',
                  style: AdminTheme.bodySmall,
                ),
              );
            }
            return Column(children: recent.map(_buildTransactionItem).toList());
          },
          loading: () => const SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(color: AdminTheme.orange),
            ),
          ),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> payment) {
    final user = payment['users'] as Map<String, dynamic>?;
    final name = user?['full_name'] ?? 'Unknown';
    final amount = double.tryParse(payment['amount']?.toString() ?? '') ?? 0.0;
    final status = payment['status'] ?? 'pending';
    final statusColor = status == 'completed'
        ? AdminTheme.success
        : status == 'pending'
        ? AdminTheme.warning
        : AdminTheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '₹${amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AdminTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(
                        color: AdminTheme.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat.jm().format(
                        DateTime.tryParse(payment['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
                      ),
                      style: TextStyle(
                        color: AdminTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status[0].toUpperCase() + status.substring(1),
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(dynamic value) {
    if (value is double) {
      if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
      return value.toStringAsFixed(0);
    }
    final intVal = value as int;
    if (intVal >= 1000) return '${(intVal / 1000).toStringAsFixed(1)}K';
    return intVal.toString();
  }

  String _fmtChart(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }
}

class _ChartData {
  final String label;
  final double value;
  _ChartData(this.label, this.value);
}

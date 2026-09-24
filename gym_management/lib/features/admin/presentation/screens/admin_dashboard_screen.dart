import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:gym_management/core/router/app_router.dart';
import 'package:gym_management/features/admin/presentation/theme/admin_theme.dart';
import 'package:gym_management/features/admin/providers/admin_providers.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';
import 'package:gym_management/features/shared/presentation/connectivity_error_widget.dart';

/// Dashboard tab body — embedded inside AdminShell
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);
    final paymentsAsync = ref.watch(allPaymentsProvider);

    // Check for network errors in either provider
    final hasError = statsAsync.hasError || paymentsAsync.hasError;
    final error = statsAsync.error ?? paymentsAsync.error;
    if (hasError && error != null) {
      final errorStr = error.toString().toLowerCase();
      final isOffline = errorStr.contains('socket') || 
                        errorStr.contains('connection') || 
                        errorStr.contains('network') || 
                        errorStr.contains('timeout') ||
                        errorStr.contains('failed host lookup') ||
                        errorStr.contains('handshake');
      if (isOffline) {
        return Scaffold(
          backgroundColor: AdminTheme.scaffold,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(ref.watch(authProvider).gymName ?? 'TRACEFIT', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            elevation: 0,
          ),
          body: ConnectivityErrorWidget(
            accentColor: AdminTheme.orange,
            onRetry: () {
              ref.invalidate(adminDashboardStatsProvider);
              ref.invalidate(allPaymentsProvider);
              ref.invalidate(todayAttendanceProvider);
            },
          ),
        );
      }
    }

    return RefreshIndicator(
      color: AdminTheme.orange,
      backgroundColor: AdminTheme.card,
      onRefresh: () async {
        ref.invalidate(adminDashboardStatsProvider);
        ref.invalidate(allPaymentsProvider);
        ref.invalidate(todayAttendanceProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            const Text(
              'Dashboard Overview',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Welcome back! Here's what's happening today.",
              style: TextStyle(color: AdminTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // ── 2x2 Stats Grid ──
            statsAsync.when(
              data: (stats) => _buildStatsGrid(ref, context, stats),
              loading: () => const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: AdminTheme.orange),
                ),
              ),
              error: (e, _) => _errorCard('Error: $e'),
            ),
            const SizedBox(height: 20),

            // ── Revenue Overview Chart ──
            _buildRevenueChart(paymentsAsync),
            const SizedBox(height: 20),

            // ── Today's Gym Entries ──
            const Text(
              "Today's Check-ins",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _buildTodayAttendance(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(WidgetRef ref, BuildContext context, Map<String, dynamic> stats) {
    final totalUsers = stats['total_users'] ?? 0;
    final activeMembers = stats['active_members'] ?? 0;
    final totalRevenue = stats['total_revenue'] ?? 0.0;
    final activeTrainers = stats['active_trainers'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total Members',
                value: _formatNumber(totalUsers),
                icon: Icons.people_rounded,
                onTap: () => ref.read(adminNavigationProvider.notifier).setIndex(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Active Members',
                value: _formatNumber(activeMembers),
                icon: Icons.person_add_rounded,
                onTap: () => ref.read(adminNavigationProvider.notifier).setIndex(1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Monthly Revenue',
                value: '₹${_formatNumber(totalRevenue)}',
                icon: Icons.attach_money_rounded,
                onTap: () => ref.read(adminNavigationProvider.notifier).setIndex(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Active Trainers',
                value: activeTrainers.toString(),
                icon: Icons.sports_gymnastics_rounded,
                onTap: () => context.push(AppRoutes.adminTrainers),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueChart(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: paymentsAsync.when(
              data: (payments) => _buildLineChart(payments),
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

  Widget _buildLineChart(List<Map<String, dynamic>> payments) {
    // Get the last 6 months dynamically ending with the current month
    final now = DateTime.now();
    final List<DateTime> last6Months = List.generate(6, (i) {
      return DateTime(now.year, now.month - (5 - i), 1);
    });

    final monthlyData = <String, double>{}; // Key format: "YYYY-MM"
    for (final p in payments) {
      if (p['status'] == 'completed') {
        final createdAt = DateTime.tryParse(p['created_at']?.toString() ?? '');
        if (createdAt != null) {
          final key = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
          monthlyData[key] = (monthlyData[key] ?? 0) +
              (double.tryParse(p['amount']?.toString() ?? '') ?? 0.0);
        }
      }
    }

    final months = last6Months.map((date) => DateFormat('MMM').format(date)).toList();
    final spots = List.generate(6, (i) {
      final date = last6Months[i];
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      return FlSpot(i.toDouble(), monthlyData[key] ?? 0);
    });

    double maxVal = 0.0;
    for (final spot in spots) {
      if (spot.y > maxVal) maxVal = spot.y;
    }
    final double computedMaxY = maxVal > 0 ? maxVal * 1.2 : 1000.0;

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: computedMaxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: AdminTheme.border, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) => Text(
                _formatChartValue(value),
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
              interval: 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < months.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      months[idx],
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
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AdminTheme.orange,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: 4,
                color: AdminTheme.orange,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AdminTheme.orange.withValues(alpha: 0.08),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
              return LineTooltipItem(
                '₹${_formatChartValue(spot.y)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _formatNumber(dynamic value) {
    if (value is double) {
      if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
      return value.toStringAsFixed(0);
    }
    final intVal = value as int;
    if (intVal >= 1000) return '${(intVal / 1000).toStringAsFixed(1)}K';
    return intVal.toString();
  }

  String _formatChartValue(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }

  Widget _buildTodayAttendance(WidgetRef ref) {
    final attendanceAsync = ref.watch(todayAttendanceProvider);

    return attendanceAsync.when(
      data: (list) {
        if (list.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AdminTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AdminTheme.border),
            ),
            child: const Center(
              child: Text(
                'No entries recorded yet today.',
                style: TextStyle(color: AdminTheme.textMuted, fontSize: 13),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final entry = list[index];
            final users = entry['users'] as Map<String, dynamic>?;
            final name = users?['full_name'] ?? 'Unknown User';
            final role = users?['role'] ?? 'member';
            
            final checkInStr = entry['check_in']?.toString() ?? '';
            final checkOutStr = entry['check_out']?.toString() ?? '';
            
            String timeDisplay = 'Checked in at --:--';
            if (checkInStr.isNotEmpty) {
              final dt = DateTime.tryParse(checkInStr.endsWith('Z') ? checkInStr : '${checkInStr}Z');
              if (dt != null) {
                timeDisplay = 'In: ${DateFormat('hh:mm a').format(dt.toLocal())}';
              }
            }
            
            String outDisplay = 'Still inside';
            if (checkOutStr.isNotEmpty) {
              final dt = DateTime.tryParse(checkOutStr.endsWith('Z') ? checkOutStr : '${checkOutStr}Z');
              if (dt != null) {
                outDisplay = 'Out: ${DateFormat('hh:mm a').format(dt.toLocal())}';
              }
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AdminTheme.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: role == 'trainer' 
                    ? AdminTheme.orange.withValues(alpha: 0.5) 
                    : AdminTheme.border,
                  width: role == 'trainer' ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: role == 'trainer' ? AdminTheme.orange : Colors.blueGrey,
                    child: Icon(
                      role == 'trainer' ? Icons.sports_gymnastics : Icons.person,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                        Text(
                          role.toUpperCase(),
                          style: TextStyle(
                            color: AdminTheme.textSecondary,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeDisplay,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        outDisplay,
                        style: TextStyle(
                          color: checkOutStr.isNotEmpty 
                              ? AdminTheme.textMuted 
                              : AdminTheme.orange,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: AdminTheme.orange),
        ),
      ),
      error: (e, _) => _errorCard('Failed to load attendance: $e'),
    );
  }

  Widget _errorCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AdminTheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(color: AdminTheme.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STAT CARD — Matches screenshot layout exactly
// ═══════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Orange circle icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AdminTheme.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

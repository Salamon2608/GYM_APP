import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';
import 'package:gym_management/features/trainer/presentation/theme/trainer_theme.dart';
import 'package:gym_management/features/trainer/providers/trainer_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class TrainerMemberDetailScreen extends ConsumerStatefulWidget {
  final String memberId;
  const TrainerMemberDetailScreen({super.key, required this.memberId});

  @override
  ConsumerState<TrainerMemberDetailScreen> createState() =>
      _TrainerMemberDetailScreenState();
}

class _TrainerMemberDetailScreenState
    extends ConsumerState<TrainerMemberDetailScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final memberDetailAsync = ref.watch(
      memberDetailedDataProvider(widget.memberId),
    );

    return Scaffold(
      backgroundColor: TrainerTheme.scaffold,
      appBar: AppBar(
        backgroundColor: TrainerTheme.scaffold,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: TrainerTheme.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Member Detail',
          style: TrainerTheme.headingSmall.copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: memberDetailAsync.when(
        data: (data) {
          final userInfo = data['user_info'] as Map<String, dynamic>? ?? {};
          final healthStats =
              data['health_metrics'] as Map<String, dynamic>? ?? {};
          final recentVisits = data['recent_visits_count'] as int? ?? 0;
          final workoutPlan = data['workout_plan'] as Map<String, dynamic>?;
          final dietPlan = data['diet_plan'] as Map<String, dynamic>?;
          final bmiRecords =
              (data['bmi_records'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ??
              [];
          final attendanceRecords =
              (data['attendance_records'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>() ??
              [];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileHeader(userInfo),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const SizedBox(height: 24),
                _buildBasicStats(healthStats, userInfo),
                const SizedBox(height: 32),
                _buildBmiHistory(healthStats, bmiRecords),
                const SizedBox(height: 32),
                _buildAssignedPlans(workoutPlan, dietPlan),
                const SizedBox(height: 32),
                _buildMembershipStatus(userInfo, recentVisits, attendanceRecords),
                const SizedBox(height: 32),
                _buildAttendanceHistory(attendanceRecords),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: TrainerTheme.orange),
        ),
        error: (e, _) => Center(
          child: Text(
            'Error loading member: $e',
            style: const TextStyle(color: TrainerTheme.error),
          ),
        ),
      ),
    );
  }

  Widget _buildAssignedPlans(
    Map<String, dynamic>? workoutPlan,
    Map<String, dynamic>? dietPlan,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Assigned Plans', style: TrainerTheme.headingMedium),
        const SizedBox(height: 16),
        if (workoutPlan == null && dietPlan == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: TrainerTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: TrainerTheme.border),
            ),
            child: Text(
              'No active plans assigned',
              textAlign: TextAlign.center,
              style: TrainerTheme.bodyLarge.copyWith(
                color: TrainerTheme.textSecondary,
              ),
            ),
          )
        else ...[
          if (workoutPlan != null)
            _buildPlanCard(
              title: workoutPlan['workout_plans']?['name'] ?? 'Workout Plan',
              type: 'Workout',
              icon: Icons.fitness_center_rounded,
              color: TrainerTheme.orange,
              onTap: () => _showAssignedWorkoutDetail(workoutPlan['id']),
            ),
          if (workoutPlan != null && dietPlan != null)
            const SizedBox(height: 16),
          if (dietPlan != null)
            _buildPlanCard(
              title: dietPlan['diet_plans']?['name'] ?? 'Diet Plan',
              type: 'Diet',
              icon: Icons.restaurant_menu_rounded,
              color: TrainerTheme.success,
              onTap: () => _showAssignedDietDetail(dietPlan['id']),
            ),
        ],
      ],
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String type,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TrainerTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TrainerTheme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TrainerTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type,
                    style: TrainerTheme.bodyMedium.copyWith(
                      color: TrainerTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: TrainerTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> userInfo) {
    final String name = userInfo['full_name'] ?? 'Unknown Member';
    final String email = userInfo['email'] ?? '';

    // Check if membership is active
    final memberships = userInfo['user_membership'] as List<dynamic>? ?? [];
    bool isActive = false;
    if (memberships.isNotEmpty) {
      final activeMember = memberships.firstWhere(
        (p) => p['status'] == 'active',
        orElse: () => null,
      );
      if (activeMember != null) isActive = true;
    }

    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: TrainerTheme.card,
              child: const Icon(
                Icons.person,
                size: 48,
                color: TrainerTheme.textSecondary,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 6,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isActive ? TrainerTheme.success : TrainerTheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: TrainerTheme.scaffold, width: 3),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(name, style: TrainerTheme.headingLarge.copyWith(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          email,
          style: TrainerTheme.bodyMedium.copyWith(
            color: TrainerTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _showAssignPlanBottomSheet(context);
            },
            icon: const Icon(Icons.assignment_rounded, size: 18),
            label: const Text(
              'Assign Plan',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: TrainerTheme.card,
              foregroundColor: TrainerTheme.textPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: TrainerTheme.border),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              final memberId = widget.memberId;
              if (memberId.isEmpty) return;

              try {
                final repo = ref.read(trainerRepositoryProvider);
                final result = await repo.markManualAttendance(memberId);

                if (mounted) {
                  final msg = result == 'checked_in'
                      ? 'Member checked in'
                      : '👋 Member checked out';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      backgroundColor: result == 'checked_in'
                          ? Colors.green
                          : Colors.orange,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  // Refresh member detail
                  ref.invalidate(memberDetailedDataProvider(memberId));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.fingerprint_rounded, size: 18),
            label: const Text(
              'Mark Attendance',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: TrainerTheme.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicStats(
    Map<String, dynamic> healthStats,
    Map<String, dynamic> userInfo,
  ) {
    final weight = healthStats['weight_kg']?.toString() ?? '--';
    final height = healthStats['height_cm']?.toString() ?? '--';
    final age = healthStats['age']?.toString() ?? '--';

    return Row(
      children: [
        _buildStatBox('Weight', weight, 'kg', null, false),
        const SizedBox(width: 12),
        _buildStatBox('Height', height, 'cm', null, false),
        const SizedBox(width: 12),
        _buildStatBox('Age', age, 'yrs', null, false),
      ],
    );
  }

  Widget _buildStatBox(
    String title,
    String value,
    String unit,
    String? dynamicText,
    bool isPositive,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: TrainerTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TrainerTheme.border, width: 1),
        ),
        child: Column(
          children: [
            Text(title, style: TrainerTheme.bodySmall),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TrainerTheme.headingMedium.copyWith(fontSize: 24),
                ),
                const SizedBox(width: 2),
                Text(unit, style: TrainerTheme.bodySmall),
              ],
            ),
            if (dynamicText != null) ...[
              const SizedBox(height: 4),
              Text(
                dynamicText,
                style: TrainerTheme.bodySmall.copyWith(
                  color: isPositive ? TrainerTheme.success : TrainerTheme.error,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else ...[
              const SizedBox(height: 18), // Placeholder for consistent height
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBmiHistory(
    Map<String, dynamic> healthStats,
    List<Map<String, dynamic>> bmiRecords,
  ) {
    final bmiVal = healthStats['bmi'];
    final bmiString = bmiVal != null
        ? (bmiVal as num).toStringAsFixed(1)
        : '--';

    String bmiLabel = 'Unknown';
    Color bmiColor = TrainerTheme.textSecondary;
    if (bmiVal != null) {
      if (bmiVal < 18.5) {
        bmiLabel = 'Underweight';
        bmiColor = TrainerTheme.error;
      } else if (bmiVal < 25) {
        bmiLabel = 'Normal Weight';
        bmiColor = TrainerTheme.success;
      } else if (bmiVal < 30) {
        bmiLabel = 'Overweight';
        bmiColor = TrainerTheme.orange;
      } else {
        bmiLabel = 'Obese';
        bmiColor = TrainerTheme.error;
      }
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text('BMI History', style: TrainerTheme.headingSmall)],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: TrainerTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TrainerTheme.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Real BMI chart or empty state
              SizedBox(
                height: 120,
                child: bmiRecords.isEmpty
                    ? Center(
                        child: Text(
                          'No BMI records yet',
                          style: TrainerTheme.bodySmall.copyWith(
                            color: TrainerTheme.textSecondary,
                          ),
                        ),
                      )
                    : CustomPaint(
                        painter: _BmiChartPainter(bmiRecords: bmiRecords),
                        size: const Size(double.infinity, 120),
                      ),
              ),
              const SizedBox(height: 16),
              const Divider(color: TrainerTheme.border, height: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: bmiColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Current BMI: ', style: TrainerTheme.bodySmall),
                      Text(
                        bmiString,
                        style: TrainerTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: TrainerTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: bmiColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      bmiLabel,
                      style: TrainerTheme.bodySmall.copyWith(
                        color: bmiColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMembershipStatus(
    Map<String, dynamic> userInfo,
    int recentVisits,
    List<Map<String, dynamic>> attendanceRecords,
  ) {
    final memberships = userInfo['user_membership'] as List<dynamic>? ?? [];
    Map<String, dynamic>? activeMembership;
    if (memberships.isNotEmpty) {
      activeMembership = memberships.firstWhere(
        (p) => p['status'] == 'active',
        orElse: () => null,
      );
    }

    final planName =
        activeMembership?['membership_plans']?['name'] ?? 'No Active Plan';
    final endDateStr = activeMembership?['end_date'];
    int daysRemaining = 0;

    if (endDateStr != null) {
      final end = DateTime.tryParse(endDateStr);
      if (end != null) {
        daysRemaining = end.difference(DateTime.now()).inDays;
        if (daysRemaining < 0) daysRemaining = 0;
      }
    }

    int totalMinutes = 0;
    int validSessions = 0;
    for (var r in attendanceRecords) {
      final checkIn = DateTime.tryParse(r['check_in'] ?? '');
      final checkOut = DateTime.tryParse(r['check_out'] ?? '');
      if (checkIn != null && checkOut != null) {
        final diff = checkOut.difference(checkIn).inMinutes;
        if (diff > 0) {
          totalMinutes += diff;
          validSessions++;
        }
      }
    }
    final avgDurationStr = validSessions > 0
        ? '${(totalMinutes / validSessions).round()} mins'
        : '--';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Membership Status', style: TrainerTheme.headingSmall),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: TrainerTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TrainerTheme.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Plan', style: TrainerTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        planName,
                        style: TrainerTheme.headingSmall.copyWith(fontSize: 20),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TrainerTheme.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: TrainerTheme.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Days Remaining', style: TrainerTheme.bodySmall),
                  Text(
                    '$daysRemaining Days',
                    style: TrainerTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: TrainerTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: daysRemaining > 0
                      ? (daysRemaining / 365).clamp(0.0, 1.0)
                      : 0,
                  backgroundColor: TrainerTheme.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    TrainerTheme.orange,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Visits this month',
                          style: TrainerTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Text('$recentVisits', style: TrainerTheme.headingSmall),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Average Duration', style: TrainerTheme.bodySmall),
                        const SizedBox(height: 4),
                        Text(avgDurationStr, style: TrainerTheme.headingSmall),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceHistory(List<Map<String, dynamic>> records) {
    // Create a set of dates where attendance occurred for fast lookup
    final Set<DateTime> attendanceDates = records
        .map((r) {
          final date = DateTime.tryParse((r['check_in'] ?? '').isNotEmpty ? ((r['check_in'] ?? '').endsWith('Z') ? r['check_in']! : '${r['check_in']}Z') : '')?.toLocal();
          return date != null
              ? DateTime(date.year, date.month, date.day)
              : null;
        })
        .whereType<DateTime>()
        .toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Attendance History', style: TrainerTheme.headingSmall),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: TrainerTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TrainerTheme.border, width: 1),
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarFormat: CalendarFormat.month,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                color: TrainerTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: TrainerTheme.textPrimary,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: TrainerTheme.textPrimary,
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: TrainerTheme.textSecondary),
              weekendStyle: TextStyle(color: TrainerTheme.orange),
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: const TextStyle(
                color: TrainerTheme.textPrimary,
              ),
              weekendTextStyle: const TextStyle(
                color: TrainerTheme.textPrimary,
              ),
              outsideTextStyle: TextStyle(
                color: TrainerTheme.textSecondary.withValues(alpha: 0.5),
              ),
              todayDecoration: BoxDecoration(
                color: TrainerTheme.orange.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: TrainerTheme.orange,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final normalizedDay = DateTime(day.year, day.month, day.day);
                final isAttended = attendanceDates.any(
                  (d) =>
                      d.year == normalizedDay.year &&
                      d.month == normalizedDay.month &&
                      d.day == normalizedDay.day,
                );

                if (isAttended) {
                  return Center(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: TrainerTheme.success,
                        shape: BoxShape.circle,
                      ),
                      width: 35,
                      height: 35,
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _selectedDay == null
              ? 'Select a day to see times'
              : 'Sessions on ${DateFormat('MMM dd, yyyy').format(_selectedDay!)}',
          style: TrainerTheme.headingSmall.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 12),
        if (_selectedDay != null) ...[
          ...records
              .where((r) {
                final dt = DateTime.tryParse((r['check_in'] ?? '').isNotEmpty ? ((r['check_in'] ?? '').endsWith('Z') ? r['check_in']! : '${r['check_in']}Z') : '')?.toLocal();
                return dt != null &&
                    dt.year == _selectedDay!.year &&
                    dt.month == _selectedDay!.month &&
                    dt.day == _selectedDay!.day;
              })
              .map((r) {
                final checkIn = DateTime.tryParse((r['check_in'] ?? '').isNotEmpty ? ((r['check_in'] ?? '').endsWith('Z') ? r['check_in']! : '${r['check_in']}Z') : '')?.toLocal();
                final checkOut = DateTime.tryParse((r['check_out'] ?? '').isNotEmpty ? ((r['check_out'] ?? '').endsWith('Z') ? r['check_out']! : '${r['check_out']}Z') : '')?.toLocal();
                final timeFormat = DateFormat('hh:mm a');

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TrainerTheme.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: TrainerTheme.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Check In', style: TrainerTheme.bodySmall),
                          const SizedBox(height: 4),
                          Text(
                            checkIn != null ? timeFormat.format(checkIn) : '--',
                            style: TrainerTheme.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: TrainerTheme.textSecondary,
                        size: 20,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Check Out', style: TrainerTheme.bodySmall),
                          const SizedBox(height: 4),
                          Text(
                            checkOut != null
                                ? timeFormat.format(checkOut)
                                : 'Active',
                            style: TrainerTheme.bodyLarge.copyWith(
                              color: checkOut != null
                                  ? TrainerTheme.textPrimary
                                  : TrainerTheme.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              })
              ,
          if (records.where((r) {
            final dt = DateTime.tryParse((r['check_in'] ?? '').isNotEmpty ? ((r['check_in'] ?? '').endsWith('Z') ? r['check_in']! : '${r['check_in']}Z') : '')?.toLocal();
            return dt != null &&
                dt.year == _selectedDay!.year &&
                dt.month == _selectedDay!.month &&
                dt.day == _selectedDay!.day;
          }).isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No attendance records for this day.',
                  style: TrainerTheme.bodySmall,
                ),
              ),
            ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  void _showAssignPlanBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TrainerTheme.scaffold,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _AssignPlanBottomSheet(memberId: widget.memberId);
      },
    );
  }

  void _showAssignedWorkoutDetail(String planId) {
    final repo = ref.read(trainerRepositoryProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: TrainerTheme.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return FutureBuilder(
          future: repo.getWorkoutPlanDetail(planId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: TrainerTheme.orange),
                ),
              );
            }
            if (snapshot.hasError) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: TrainerTheme.error),
                  ),
                ),
              );
            }

            final detail = snapshot.data as Map<String, dynamic>;
            final items = List<dynamic>.from(
              detail['workout_plan_items'] as List? ?? [],
            );

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: TrainerTheme.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        detail['name'] ?? 'Plan',
                        style: TrainerTheme.headingMedium,
                      ),
                      if ((detail['goal'] ?? '').toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Goal: ${detail['goal']}',
                            style: TrainerTheme.bodySmall,
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Exercises
                      Text(
                        'Exercises (${items.length})',
                        style: TrainerTheme.headingSmall,
                      ),
                      const SizedBox(height: 12),
                      if (items.isEmpty)
                        Text(
                          'No exercises added yet.',
                          style: TrainerTheme.bodySmall,
                        )
                      else
                        ...items.map((item) {
                          final dayNum = item['day_number'] ?? 0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: TrainerTheme.scaffold,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: TrainerTheme.orange.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'D$dayNum',
                                      style: TrainerTheme.bodySmall.copyWith(
                                        color: TrainerTheme.orange,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['exercise_name'] ?? '',
                                        style: TrainerTheme.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${item['sets'] ?? '-'} sets × ${item['reps'] ?? '-'} reps',
                                        style: TrainerTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAssignedDietDetail(String planId) {
    final repo = ref.read(trainerRepositoryProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: TrainerTheme.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return FutureBuilder(
          future: repo.getDietPlanDetail(planId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: TrainerTheme.orange),
                ),
              );
            }
            if (snapshot.hasError) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: TrainerTheme.error),
                  ),
                ),
              );
            }

            final detail = snapshot.data as Map<String, dynamic>;
            final items = List<dynamic>.from(
              detail['diet_plan_items'] as List? ?? [],
            );
            final calories =
                detail['calories_target'] ?? detail['daily_calories'];

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: TrainerTheme.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        detail['title'] ?? detail['name'] ?? 'Diet Plan',
                        style: TrainerTheme.headingMedium,
                      ),
                      if (calories != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '$calories kcal/day',
                            style: TrainerTheme.bodySmall.copyWith(
                              color: TrainerTheme.orange,
                            ),
                          ),
                        ),
                      if ((detail['goal'] ?? '').toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Goal: ${detail['goal']}',
                            style: TrainerTheme.bodySmall,
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Meals
                      Text(
                        'Meals (${items.length})',
                        style: TrainerTheme.headingSmall,
                      ),
                      const SizedBox(height: 12),
                      if (items.isEmpty)
                        Text(
                          'No meals added yet.',
                          style: TrainerTheme.bodySmall,
                        )
                      else
                        ...items.map((item) {
                          final mealType = item['meal_time'] ?? 'Meal';
                          final dayNum = item['day_number'] ?? '-';
                          final calories = item['calories'];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: TrainerTheme.scaffold,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: TrainerTheme.success.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.local_dining_rounded,
                                      color: TrainerTheme.success,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mealType.toString().toUpperCase(),
                                        style: TrainerTheme.bodySmall.copyWith(
                                          color: TrainerTheme.success,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item['food_item'] ?? '',
                                        style: TrainerTheme.bodyLarge.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Day $dayNum${calories != null ? ' \u00b7 $calories kcal' : ''}',
                                        style: TrainerTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Note: the original _buildPlanTypeSelector was removed from here.
}

class _AssignPlanBottomSheet extends ConsumerStatefulWidget {
  final String memberId;
  const _AssignPlanBottomSheet({required this.memberId});

  @override
  ConsumerState<_AssignPlanBottomSheet> createState() =>
      _AssignPlanBottomSheetState();
}

class _AssignPlanBottomSheetState
    extends ConsumerState<_AssignPlanBottomSheet> {
  String? _selectedWorkoutPlanId;
  String? _selectedDietPlanId;
  bool _isAssigning = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final trainerId = authState.user?.id;

    if (trainerId == null) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Text('Trainer not logged in.'),
      );
    }

    final workoutPlansAsync = ref.watch(trainerWorkoutPlansProvider(trainerId));
    final dietPlansAsync = ref.watch(trainerDietPlansProvider(trainerId));

    return Padding(
      padding: EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 24.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Assign Plan', style: TrainerTheme.headingMedium),
          const SizedBox(height: 16),
          Text(
            'Select a plan to assign to this member.',
            style: TrainerTheme.bodySmall,
          ),
          const SizedBox(height: 24),

          workoutPlansAsync.when(
            data: (plans) => _buildDropdown(
              'Workout Plan',
              plans,
              _selectedWorkoutPlanId,
              (val) => setState(() => _selectedWorkoutPlanId = val),
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: TrainerTheme.orange),
            ),
            error: (e, _) => Text(
              'Error loading workout plans',
              style: TextStyle(color: TrainerTheme.error),
            ),
          ),

          const SizedBox(height: 16),

          dietPlansAsync.when(
            data: (plans) => _buildDropdown(
              'Diet Plan',
              plans,
              _selectedDietPlanId,
              (val) => setState(() => _selectedDietPlanId = val),
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: TrainerTheme.orange),
            ),
            error: (e, _) => Text(
              'Error loading diet plans',
              style: TextStyle(color: TrainerTheme.error),
            ),
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _isAssigning ||
                      (_selectedWorkoutPlanId == null &&
                          _selectedDietPlanId == null)
                  ? null
                  : () => _assignPlans(trainerId),
              style: ElevatedButton.styleFrom(
                backgroundColor: TrainerTheme.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isAssigning
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Assign Plans',
                      style: TrainerTheme.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<Map<String, dynamic>> items,
    String? selectedValue,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TrainerTheme.bodySmall),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: TrainerTheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TrainerTheme.border, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              isExpanded: true,
              hint: Text(
                items.isEmpty ? 'No plans available' : 'Select a plan',
                style: TrainerTheme.bodyLarge.copyWith(
                  color: TrainerTheme.textSecondary,
                ),
              ),
              dropdownColor: TrainerTheme.card,
              icon: const Icon(
                Icons.expand_more_rounded,
                color: TrainerTheme.textSecondary,
              ),
              style: TrainerTheme.bodyLarge.copyWith(
                color: TrainerTheme.textPrimary,
              ),
              items: items.map((plan) {
                // Ensure map key exists otherwise use a fallback
                final title = plan['name'] ?? plan['title'] ?? 'Unnamed Plan';
                return DropdownMenuItem<String>(
                  value: plan['id'].toString(),
                  child: Text(title),
                );
              }).toList(),
              onChanged: items.isEmpty ? null : onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _assignPlans(String trainerId) async {
    setState(() => _isAssigning = true);
    final repo = ref.read(trainerRepositoryProvider);
    final List<String> alreadyAssigned = [];
    final List<String> newlyAssigned = [];

    try {
      if (_selectedWorkoutPlanId != null) {
        final result = await repo.assignWorkoutPlan(
          trainerId: trainerId,
          memberId: widget.memberId,
          planId: _selectedWorkoutPlanId!,
        );
        if (result == 'already_assigned') {
          alreadyAssigned.add('Workout Plan');
        } else {
          newlyAssigned.add('Workout Plan');
        }
      }
      if (_selectedDietPlanId != null) {
        final result = await repo.assignDietPlan(
          trainerId: trainerId,
          memberId: widget.memberId,
          planId: _selectedDietPlanId!,
        );
        if (result == 'already_assigned') {
          alreadyAssigned.add('Diet Plan');
        } else {
          newlyAssigned.add('Diet Plan');
        }
      }

      if (mounted) {
        context.pop();
        if (alreadyAssigned.isNotEmpty && newlyAssigned.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${alreadyAssigned.join(' & ')} already assigned to this member',
              ),
              backgroundColor: TrainerTheme.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else if (alreadyAssigned.isNotEmpty && newlyAssigned.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${newlyAssigned.join(' & ')} assigned! (${alreadyAssigned.join(' & ')} was already assigned)',
              ),
              backgroundColor: TrainerTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Plans successfully assigned!'),
              backgroundColor: TrainerTheme.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning plan: $e'),
            backgroundColor: TrainerTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAssigning = false);
      }
    }
  }
}

// Real data-driven BMI chart painter
class _BmiChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> bmiRecords;

  _BmiChartPainter({required this.bmiRecords});

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (bmiRecords.isEmpty) return;

    // Parse data points
    final points = <_BmiPoint>[];
    for (final record in bmiRecords) {
      final bmi = (record['bmi_value'] as num?)?.toDouble();
      final dateStr = record['recorded_at'] as String?;
      if (bmi == null || dateStr == null) continue;
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;
      points.add(_BmiPoint(date: date, value: bmi));
    }
    if (points.isEmpty) return;

    // Sort by date
    points.sort((a, b) => a.date.compareTo(b.date));

    // Chart area (leave space for labels at bottom)
    const labelHeight = 20.0;
    const topPad = 20.0;
    final chartHeight = size.height - labelHeight - topPad;

    // Find min/max BMI for scaling
    double minBmi = points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    double maxBmi = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    // Add padding to range
    final range = maxBmi - minBmi;
    if (range < 2) {
      minBmi -= 1;
      maxBmi += 1;
    } else {
      minBmi -= range * 0.1;
      maxBmi += range * 0.1;
    }
    final bmiRange = maxBmi - minBmi;

    // Map points to pixel coordinates
    final pixelPoints = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final x = points.length == 1
          ? size.width / 2
          : (i / (points.length - 1)) * size.width;
      final yNorm = (points[i].value - minBmi) / bmiRange;
      final y = topPad + chartHeight * (1 - yNorm);
      pixelPoints.add(Offset(x, y));
    }

    // Draw gradient fill under the line
    if (pixelPoints.length > 1) {
      final fillPath = Path();
      fillPath.moveTo(pixelPoints.first.dx, topPad + chartHeight);
      for (final p in pixelPoints) {
        fillPath.lineTo(p.dx, p.dy);
      }
      fillPath.lineTo(pixelPoints.last.dx, topPad + chartHeight);
      fillPath.close();

      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          TrainerTheme.orange.withValues(alpha: 0.3),
          TrainerTheme.orange.withValues(alpha: 0.0),
        ],
      );
      final fillPaint = Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(0, topPad, size.width, chartHeight),
        );
      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw connecting line
    if (pixelPoints.length > 1) {
      final linePath = Path();
      linePath.moveTo(pixelPoints.first.dx, pixelPoints.first.dy);
      for (int i = 1; i < pixelPoints.length; i++) {
        linePath.lineTo(pixelPoints[i].dx, pixelPoints[i].dy);
      }
      final linePaint = Paint()
        ..color = TrainerTheme.orange
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(linePath, linePaint);
    }

    // Draw data points and month labels
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    for (int i = 0; i < points.length; i++) {
      final p = pixelPoints[i];
      final isLast = i == points.length - 1;

      // Dot
      canvas.drawCircle(
        p,
        isLast ? 5 : 3.5,
        Paint()..color = TrainerTheme.orange,
      );
      if (isLast) {
        canvas.drawCircle(
          p,
          7,
          Paint()
            ..color = TrainerTheme.orange.withValues(alpha: 0.2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }

      // Tooltip on last point
      if (isLast) {
        final tooltipText = TextPainter(
          text: TextSpan(
            text: points[i].value.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        );
        tooltipText.layout();
        final rRect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(p.dx, p.dy - 16),
            width: tooltipText.width + 12,
            height: 20,
          ),
          const Radius.circular(4),
        );
        canvas.drawRRect(rRect, Paint()..color = TrainerTheme.orange);
        tooltipText.paint(
          canvas,
          Offset(p.dx - tooltipText.width / 2, p.dy - 16 - 6),
        );
      }

      // Month label
      final monthLabel = _monthNames[points[i].date.month - 1];
      textPainter.text = TextSpan(
        text: monthLabel,
        style: TrainerTheme.bodySmall.copyWith(
          color: isLast ? TrainerTheme.orange : TrainerTheme.textSecondary,
          fontWeight: isLast ? FontWeight.w700 : FontWeight.w400,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(p.dx - textPainter.width / 2, size.height - labelHeight + 4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BmiChartPainter oldDelegate) {
    return oldDelegate.bmiRecords != bmiRecords;
  }
}

class _BmiPoint {
  final DateTime date;
  final double value;
  _BmiPoint({required this.date, required this.value});
}

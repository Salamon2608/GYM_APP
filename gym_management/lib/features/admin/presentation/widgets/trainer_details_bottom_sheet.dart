import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:gym_management/features/trainer/data/trainer_repository.dart';
import 'package:gym_management/features/admin/presentation/theme/admin_theme.dart';
import 'package:gym_management/features/admin/providers/admin_providers.dart';

class TrainerDetailsBottomSheet extends StatefulWidget {
  final String trainerName;
  final String trainerId;
  final List<dynamic> assignedMembers;
  final WidgetRef parentRef; // Pass ref for invalidation

  const TrainerDetailsBottomSheet({
    super.key,
    required this.trainerName,
    required this.trainerId,
    required this.assignedMembers,
    required this.parentRef,
  });

  @override
  State<TrainerDetailsBottomSheet> createState() =>
      _TrainerDetailsBottomSheetState();
}

class _TrainerDetailsBottomSheetState extends State<TrainerDetailsBottomSheet> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late final Future<List<dynamic>> _attendanceFuture;

  @override
  void initState() {
    super.initState();
    _attendanceFuture = _loadAttendance();
  }

  Future<List<dynamic>> _loadAttendance() async {
    try {
      final repo = TrainerRepository();
      final details = await repo.getMemberDetailedProfile(widget.trainerId);
      return details['attendance_records'] as List<dynamic>? ?? [];
    } catch (_) {
      return [];
    }
  }

  String _getInitials(String name) {
    name = name.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }

  Widget _buildAttendanceHistory(List<Map<String, dynamic>> records) {
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
      children: [
        TableCalendar(
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
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
            rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: AdminTheme.textSecondary),
            weekendStyle: TextStyle(color: AdminTheme.orange),
          ),
          calendarStyle: CalendarStyle(
            defaultTextStyle: const TextStyle(color: Colors.white),
            weekendTextStyle: const TextStyle(color: Colors.white),
            outsideTextStyle: TextStyle(color: Colors.white38),
            todayDecoration: BoxDecoration(
              color: AdminTheme.orange.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: AdminTheme.orange,
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
                      color: AdminTheme.success,
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
        const SizedBox(height: 16),
        const Divider(color: AdminTheme.border),
        const SizedBox(height: 16),
        Text(
          _selectedDay == null
              ? 'Select a day to see times'
              : 'Sessions on ${DateFormat('MMM dd, yyyy').format(_selectedDay!)}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AdminTheme.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Check In',
                            style: TextStyle(
                              color: AdminTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            checkIn != null ? timeFormat.format(checkIn) : '--',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AdminTheme.textSecondary,
                        size: 16,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Check Out',
                            style: TextStyle(
                              color: AdminTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            checkOut != null
                                ? timeFormat.format(checkOut)
                                : 'Active',
                            style: TextStyle(
                              color: checkOut != null
                                  ? Colors.white
                                  : AdminTheme.success,
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
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No attendance records for this day.',
                style: TextStyle(color: AdminTheme.textSecondary),
              ),
            ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AdminTheme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AdminTheme.orange.withValues(alpha: 0.15),
                    child: Text(
                      _getInitials(widget.trainerName),
                      style: const TextStyle(
                        color: AdminTheme.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.trainerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const TabBar(
              labelColor: AdminTheme.orange,
              unselectedLabelColor: AdminTheme.textSecondary,
              indicatorColor: AdminTheme.orange,
              dividerColor: AdminTheme.border,
              tabs: [
                Tab(text: 'Members'),
                Tab(text: 'Attendance'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Assigned Members
                  widget.assignedMembers.isEmpty
                      ? const Center(
                          child: Text(
                            'No members assigned to this trainer yet.',
                            style: TextStyle(color: AdminTheme.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: widget.assignedMembers.length,
                          itemBuilder: (_, i) {
                            final m =
                                widget.assignedMembers[i]
                                    as Map<String, dynamic>;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AdminTheme.orange,
                                child: Text(
                                  _getInitials(m['member_name'] ?? '?'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              title: Text(
                                m['member_name'] ?? 'Unknown',
                                style: const TextStyle(color: Colors.white),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: AdminTheme.error,
                                ),
                                onPressed: () async {
                                  final memberId = m['member_id'];
                                    if (memberId != null) {
                                      final repo = widget.parentRef.read(
                                        adminRepositoryProvider,
                                      );
                                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                                      final navigator = Navigator.of(context);
                                      
                                      await repo.removeTrainerAssignment(
                                        memberId.toString(),
                                      );
                                      
                                      widget.parentRef.invalidate(
                                        allTrainersProvider,
                                      );
                                      widget.parentRef.invalidate(
                                        allUsersProvider,
                                      );
                                      
                                      if (mounted) {
                                        navigator.pop(); // Close sheet
                                        scaffoldMessenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Member unassigned successfully',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                },
                              ),
                            );
                          },
                        ),
                  // Tab 2: Attendance
                  FutureBuilder<List<dynamic>>(
                    future: _attendanceFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AdminTheme.orange,
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: AdminTheme.error),
                          ),
                        );
                      }
                      final records = snapshot.data ?? [];
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildAttendanceHistory(
                          records.cast<Map<String, dynamic>>(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

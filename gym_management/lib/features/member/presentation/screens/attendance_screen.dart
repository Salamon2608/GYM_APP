import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gym_management/core/constants/app_constants.dart';
import 'package:gym_management/features/auth/providers/auth_provider.dart';
import 'package:gym_management/features/member/providers/attendance_provider.dart';
import 'package:gym_management/core/theme/app_theme.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  bool _isLoading = false;
  String _statusMessage = '';
  StreamSubscription<Position>? _positionSubscription;
  bool _isAutoCheckingOut = false;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _statusMessage = 'Location services are disabled');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _statusMessage = 'Location permission denied');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(
        () => _statusMessage =
            'Location permission permanently denied. Enable in settings.',
      );
      return null;
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw Exception('GPS timed out. Please try again.');
      },
    );
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295;
    final a =
        0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; // meters
  }

  Future<void> _handleCheckIn() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Getting your location...';
    });

    try {
      final position = await _getCurrentLocation();
      if (position == null) {
        setState(() => _isLoading = false);
        return;
      }

      setState(() => _statusMessage = 'Verifying gym location...');

      // Fetch gym location from database
      final repo = ref.read(attendanceRepositoryProvider);
      final gymLocation = await repo.getGymLocation();

      double gymLat = gymLocation?['latitude']?.toDouble() ?? 0.0;
      double gymLng = gymLocation?['longitude']?.toDouble() ?? 0.0;
      int radiusMeters =
          (gymLocation?['radius_meters'] as int?) ??
          AppConstants.defaultGeoFenceRadiusMeters;

      // If gym coords are set, check geofence
      if (gymLat != 0.0 && gymLng != 0.0) {
        final distance = _calculateDistance(
          position.latitude,
          position.longitude,
          gymLat,
          gymLng,
        );

        if (distance > radiusMeters) {
          setState(() {
            _isLoading = false;
            _statusMessage =
                'You are ${distance.toInt()}m away from the gym. Must be within ${radiusMeters}m.';
          });
          return;
        }
      }

      final userId = ref.read(authProvider).user?.id;
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'User not logged in. Please log in again.';
        });
        return;
      }

      setState(() => _statusMessage = 'Marking attendance...');

      await repo.checkIn(
        userId: userId,
        latitude: position.latitude,
        longitude: position.longitude,
        method: 'gps',
      );

      ref.invalidate(todayAttendanceProvider(userId));
      ref.invalidate(attendanceHistoryProvider(userId));
      ref.invalidate(monthlyAttendanceProvider(userId));

      setState(() {
        _isLoading = false;
        _statusMessage = 'Checked in successfully!';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Check-in failed: $e';
      });
    }
  }

  Future<void> _handleCheckOut() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
      _stopGeofencing();
    });

    try {
      final repo = ref.read(attendanceRepositoryProvider);
      await repo.checkOut(userId);

      ref.invalidate(todayAttendanceProvider(userId));
      ref.invalidate(attendanceHistoryProvider(userId));

      setState(() {
        _isLoading = false;
        _statusMessage = _isAutoCheckingOut
            ? 'Checked out automatically (Left Gym Area)'
            : 'Checked out successfully!';
        _isAutoCheckingOut = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Check-out failed: $e';
      });
    }
  }

  void _startGeofencing() async {
    if (_positionSubscription != null) return;

    final userId = ref.read(authProvider).user?.id;
    if (userId == null) return;

    // Get gym location for reference
    final repo = ref.read(attendanceRepositoryProvider);
    final gymLocation = await repo.getGymLocation();
    if (gymLocation == null) return;

    double gymLat = gymLocation['latitude']?.toDouble() ?? 0.0;
    double gymLng = gymLocation['longitude']?.toDouble() ?? 0.0;
    int radiusMeters =
        (gymLocation['radius_meters'] as int?) ??
        AppConstants.defaultGeoFenceRadiusMeters;

    if (gymLat == 0.0 || gymLng == 0.0) return;

    int outsideCount = 0;
    final geofenceStartTime = DateTime.now();

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: null,
          ),
        ).listen((Position position) {
          // Allow 30 seconds for GPS to stabilize before processing geofence
          if (DateTime.now().difference(geofenceStartTime).inSeconds < 30) return;

          // Ignore highly inaccurate readings (e.g., accuracy > 50 meters)
          if (position.accuracy > 50) return;

          final distance = _calculateDistance(
            position.latitude,
            position.longitude,
            gymLat,
            gymLng,
          );

          // If user left radius
          if (distance > radiusMeters) {
            outsideCount++;
            // Require 3 consecutive outside readings to confirm checkout
            if (outsideCount >= 3) {
              if (!_isLoading && !_isAutoCheckingOut) {
                setState(() => _isAutoCheckingOut = true);
                _handleCheckOut();
              }
            }
          } else {
            // Reset counter if they are back inside
            outsideCount = 0;
          }
        });
  }

  void _stopGeofencing() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  @override
  void dispose() {
    _stopGeofencing();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authProvider).user?.id;
    final todayAsync = userId != null
        ? ref.watch(todayAttendanceProvider(userId))
        : null;
    final monthlyAsync = userId != null
        ? ref.watch(monthlyAttendanceProvider(userId))
        : null;
    final historyAsync = userId != null
        ? ref.watch(attendanceHistoryProvider(userId))
        : null;

    final isCheckedIn =
        todayAsync?.whenOrNull(
          data: (d) => d != null && d['check_out'] == null,
        ) ??
        false;

    // Start/Stop geofencing based on check-in status
    if (isCheckedIn && !_isLoading && !_isAutoCheckingOut) {
      // Auto-checkout if they checked in more than 4 hours ago and forgot
      final checkInTimeStr = todayAsync?.value?['check_in'];
      if (checkInTimeStr != null) {
        final checkInTime = DateTime.tryParse(checkInTimeStr.endsWith('Z') ? checkInTimeStr : '${checkInTimeStr}Z')?.toLocal();
        if (checkInTime != null) {
          final diff = DateTime.now().difference(checkInTime).inHours;
          if (diff >= 4) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _isAutoCheckingOut = true);
                _handleCheckOut();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Automatically checked out of stale session (>4 hours)',
                    ),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                );
              }
            });
          } else {
            _startGeofencing();
          }
        } else {
          _startGeofencing();
        }
      } else {
        _startGeofencing();
      }
    } else if (!isCheckedIn) {
      _stopGeofencing();
    }

    return Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      appBar: AppBar(
        title: const Text('Attendance'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Check-in/out card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isCheckedIn
                      ? [AppTheme.successColor, const Color(0xFF2E7D32)]
                      : [AppTheme.primaryColor, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color:
                        (isCheckedIn
                                ? AppTheme.successColor
                                : AppTheme.primaryColor)
                            .withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    isCheckedIn
                        ? Icons.check_circle_outline
                        : Icons.location_on_outlined,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isCheckedIn ? 'You are checked in' : 'Ready to check in?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : (isCheckedIn ? _handleCheckOut : _handleCheckIn),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: isCheckedIn
                                    ? AppTheme.successColor
                                    : AppTheme.primaryColor,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              isCheckedIn ? 'Check Out' : 'Check In',
                              style: TextStyle(
                                color: isCheckedIn
                                    ? AppTheme.successColor
                                    : AppTheme.primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // Status message
            if (_statusMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        _statusMessage.contains('Checked in') ||
                            _statusMessage.contains('Checked out')
                        ? AppTheme.successColor
                        : AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Monthly stats
            if (monthlyAsync != null)
              monthlyAsync.when(
                data: (count) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: AppTheme.accentColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$count days this month',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),

            const SizedBox(height: 24),

            // History (Calendar View)
            if (historyAsync != null)
              historyAsync.when(
                data: (records) {
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
                      const Text(
                        'Attendance History',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.cardDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderDark),
                        ),
                        child: TableCalendar(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
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
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            leftChevronIcon: Icon(
                              Icons.chevron_left,
                              color: AppTheme.textPrimary,
                            ),
                            rightChevronIcon: Icon(
                              Icons.chevron_right,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          daysOfWeekStyle: const DaysOfWeekStyle(
                            weekdayStyle: TextStyle(
                              color: AppTheme.textSecondary,
                            ),
                            weekendStyle: TextStyle(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          calendarStyle: CalendarStyle(
                            defaultTextStyle: const TextStyle(
                              color: AppTheme.textPrimary,
                            ),
                            weekendTextStyle: const TextStyle(
                              color: AppTheme.textPrimary,
                            ),
                            outsideTextStyle: TextStyle(
                              color: AppTheme.textSecondary.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            todayDecoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          calendarBuilders: CalendarBuilders(
                            defaultBuilder: (context, day, focusedDay) {
                              final normalizedDay = DateTime(
                                day.year,
                                day.month,
                                day.day,
                              );
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
                                      color: AppTheme.successColor,
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
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardDark,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.borderDark,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Check In',
                                          style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          checkIn != null
                                              ? timeFormat.format(checkIn)
                                              : '--',
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: AppTheme.textSecondary,
                                      size: 20,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'Check Out',
                                          style: TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          checkOut != null
                                              ? timeFormat.format(checkOut)
                                              : 'Active',
                                          style: TextStyle(
                                            color: checkOut != null
                                                ? AppTheme.textPrimary
                                                : AppTheme.successColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                        if (records.where((r) {
                          final dt = DateTime.tryParse((r['check_in'] ?? '').isNotEmpty ? ((r['check_in'] ?? '').endsWith('Z') ? r['check_in']! : '${r['check_in']}Z') : '')?.toLocal();
                          return dt != null &&
                              dt.year == _selectedDay!.year &&
                              dt.month == _selectedDay!.month &&
                              dt.day == _selectedDay!.day;
                        }).isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'No attendance records for this day.',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: 40),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}

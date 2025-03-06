// lib/providers/sleep_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:fitglide_mobile_application/services/health_service.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final healthServiceProvider = Provider<HealthService>((ref) => HealthService());

final sleepTrackerProvider = StateNotifierProvider<SleepTrackerNotifier, SleepTrackerState>((ref) {
  return SleepTrackerNotifier(
    ref.watch(apiServiceProvider),
    ref.watch(healthServiceProvider),
  );
});

class SleepTrackerState {
  final List<Map<String, dynamic>> sleepSchedule;
  final List<FlSpot> sleepSpots;
  final List<FlSpot> deepSleepSpots;
  final Map<String, String> sleepStats;
  final Duration sleepDebt;
  final bool isLoading;
  final String? error;

  SleepTrackerState({
    this.sleepSchedule = const [],
    this.sleepSpots = const [],
    this.deepSleepSpots = const [],
    this.sleepStats = const {'today': '0h 0m', 'weekly': '0h 0m', 'monthly': '0h 0m'},
    this.sleepDebt = Duration.zero,
    this.isLoading = false,
    this.error,
  });

  SleepTrackerState copyWith({
    List<Map<String, dynamic>>? sleepSchedule,
    List<FlSpot>? sleepSpots,
    List<FlSpot>? deepSleepSpots,
    Map<String, String>? sleepStats,
    Duration? sleepDebt,
    bool? isLoading,
    String? error,
  }) {
    return SleepTrackerState(
      sleepSchedule: sleepSchedule ?? this.sleepSchedule,
      sleepSpots: sleepSpots ?? this.sleepSpots,
      deepSleepSpots: deepSleepSpots ?? this.deepSleepSpots,
      sleepStats: sleepStats ?? this.sleepStats,
      sleepDebt: sleepDebt ?? this.sleepDebt,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class SleepTrackerNotifier extends StateNotifier<SleepTrackerState> {
  final ApiService apiService;
  final HealthService healthService;

  SleepTrackerNotifier(this.apiService, this.healthService) : super(SleepTrackerState()) {
    fetchSleepData(DateTime.now());
  }

  Future<void> initHealthService() async {
    await healthService.configureHealth();
    final permissionsGranted = await healthService.requestPermissions();
    debugPrint('HealthService initialization complete. Permissions granted: $permissionsGranted');
    if (!permissionsGranted) {
      state = state.copyWith(error: "Health permissions not granted - sleep data may be unavailable");
    }
  }

  Future<void> fetchSleepData(DateTime selectedDate, {String username = 'your_username'}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await initHealthService();

      final startDate = selectedDate.subtract(const Duration(days: 30));
      
      // Fetch sleep logs from Strapi - returns List<Map<String, dynamic>> directly
      final sleepData = await ApiService.getSleepLogs(username);

      // Fetch health data
      final healthData = await healthService.fetchHealthData(startDate, selectedDate);

      // Process sleep schedule from Strapi data
      final schedule = sleepData.map((log) {
        final attributes = log['attributes'];
        final date = DateTime.parse(attributes['date']);
        final plannedSleepTime = attributes['planned_sleep_time'] != null
            ? DateFormat('HH:mm:ss.SSS').parse(attributes['planned_sleep_time'])
            : DateTime(date.year, date.month, date.day, 0, 0); // Default to midnight if null
        final sleepStart = DateTime(date.year, date.month, date.day, plannedSleepTime.hour, plannedSleepTime.minute);
        final sleepEnd = sleepStart.add(Duration(hours: attributes['sleep_duration'] ?? 0));

        return {
          'name': attributes['type'] ?? 'Sleep', // Use 'type' if available, default to 'Sleep'
          'image': (attributes['type'] ?? 'Sleep') == 'Alarm' ? 'assets/img/alarm.png' : 'assets/img/bed.png',
          'time': DateFormat('dd/MM/yyyy hh:mm a').format(sleepStart),
          'duration': _formatDuration(Duration(hours: attributes['sleep_duration'] ?? 0)),
        };
      }).toList();

      // Process chart data
      final sleepSpots = <FlSpot>[];
      final deepSleepSpots = <FlSpot>[];

      // From Strapi data
      for (var log in sleepData) {
        final attributes = log['attributes'];
        final date = DateTime.parse(attributes['date']);
        final dayIndex = date.difference(startDate).inDays.toDouble();
        final sleepHours = (attributes['sleep_duration'] as num?)?.toDouble() ?? 0.0; // Handle int or null
        final deepSleepHours = (attributes['deep_sleep_duration'] as num?)?.toDouble() ?? 0.0;

        sleepSpots.add(FlSpot(dayIndex, sleepHours));
        if (deepSleepHours > 0) {
          deepSleepSpots.add(FlSpot(dayIndex, deepSleepHours));
        }
      }

      // From health data
      for (var data in healthData) {
        if (data.type == HealthDataType.SLEEP_IN_BED) {
          final dayIndex = data.dateFrom.difference(startDate).inDays.toDouble();
          final hours = data.dateTo.difference(data.dateFrom).inMinutes / 60.0;
          sleepSpots.add(FlSpot(dayIndex, hours));
        }
        if (data.type == HealthDataType.SLEEP_ASLEEP) {
          final dayIndex = data.dateFrom.difference(startDate).inDays.toDouble();
          final hours = data.dateTo.difference(data.dateFrom).inMinutes / 60.0;
          deepSleepSpots.add(FlSpot(dayIndex, hours));
        }
      }

      final stats = _calculateStats(sleepSpots, healthData);
      final debt = _calculateSleepDebt(sleepSpots);

      state = state.copyWith(
        sleepSchedule: schedule,
        sleepSpots: sleepSpots,
        deepSleepSpots: deepSleepSpots,
        sleepStats: stats,
        sleepDebt: debt,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addAlarm(DateTime alarmTime, bool vibrate, String username) async {
    final alarmData = {
      'data': {
        'type': 'Alarm',
        'date': DateFormat('yyyy-MM-dd').format(alarmTime),
        'planned_sleep_time': DateFormat('HH:mm:ss.SSS').format(alarmTime),
        'sleep_duration': 0, // Default for alarm
        'username': username,
        'vibrate': vibrate,
      }
    };
    await ApiService.addSleepLog(alarmData);
    await fetchSleepData(DateTime.now(), username: username);
  }

  Map<String, String> _calculateStats(List<FlSpot> sleepSpots, List<HealthDataPoint> healthData) {
    final today = sleepSpots.lastOrNull?.y ?? 0;
    final weeklyAvg = sleepSpots.take(7).fold(0.0, (sum, spot) => sum + spot.y) / (sleepSpots.length > 7 ? 7 : sleepSpots.length);
    final monthlyAvg = sleepSpots.fold(0.0, (sum, spot) => sum + spot.y) / sleepSpots.length;
    
    return {
      'today': _formatHours(today),
      'weekly': _formatHours(weeklyAvg),
      'monthly': _formatHours(monthlyAvg),
    };
  }

  Duration _calculateSleepDebt(List<FlSpot> sleepSpots) {
    const goal = Duration(hours: 8);
    final todaySleep = sleepSpots.lastOrNull?.y ?? 0;
    return goal - Duration(minutes: (todaySleep * 60).toInt());
  }

  String _formatHours(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return '${h}h ${m}m';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return "$hours h $minutes m";
  }
}
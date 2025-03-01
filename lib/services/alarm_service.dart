import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Alarm {
  final DateTime time;
  final bool vibration;
  final double sleepHours;
  final List<String> repeatDays;

  Alarm({
    required this.time,
    this.vibration = false,
    this.sleepHours = 8.0,
    this.repeatDays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  });

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'vibration': vibration,
        'sleepHours': sleepHours,
        'repeatDays': repeatDays,
      };

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      time: DateTime.parse(json['time']),
      vibration: json['vibration'],
      sleepHours: json['sleepHours'],
      repeatDays: List<String>.from(json['repeatDays']),
    );
  }
}

class AlarmService {
  static const MethodChannel _channel = MethodChannel('fitglide/alarm');
  static List<Alarm> _alarms = [];

  /// Initialize the Alarm Service
  static Future<void> init() async {
    await _loadAlarms();
  }

  /// Add a new alarm and save it
  static Future<void> addAlarm(Alarm alarm) async {
    _alarms.add(alarm);
    await _saveAlarms();

    // Call native Android method to set the alarm
    await _channel.invokeMethod('setAlarm', {
      "hour": alarm.time.hour,
      "minute": alarm.time.minute,
      "vibration": alarm.vibration,
      "repeatDays": alarm.repeatDays,
    });

    print("Alarm set for ${alarm.time}");
  }

  /// Update an existing alarm
  static Future<void> updateAlarm(Alarm oldAlarm, Alarm newAlarm) async {
    int index = _alarms.indexWhere((a) => a.time == oldAlarm.time);
    if (index != -1) {
      _alarms[index] = newAlarm;
      await _saveAlarms();

      // Update the alarm in the native Clock app
      await _channel.invokeMethod('updateAlarm', {
        "oldHour": oldAlarm.time.hour,
        "oldMinute": oldAlarm.time.minute,
        "newHour": newAlarm.time.hour,
        "newMinute": newAlarm.time.minute,
        "vibration": newAlarm.vibration,
        "repeatDays": newAlarm.repeatDays,
      });

      print("Alarm updated to ${newAlarm.time}");
    }
  }

  /// Cancel an existing alarm
  static Future<void> cancelAlarm(Alarm alarm) async {
    _alarms.removeWhere((a) => a.time == alarm.time);
    await _saveAlarms();

    await _channel.invokeMethod('cancelAlarm', {
      "hour": alarm.time.hour,
      "minute": alarm.time.minute,
    });

    print("Alarm canceled for ${alarm.time}");
  }

  /// Get all alarms
  static Future<List<Alarm>> getAlarms() async {
    await _loadAlarms();
    return _alarms;
  }

  /// Save alarms to local storage
  static Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = jsonEncode(_alarms.map((a) => a.toJson()).toList());
    await prefs.setString('alarms', alarmsJson);
  }

  /// Load alarms from local storage
  static Future<void> _loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = prefs.getString('alarms');
    if (alarmsJson != null) {
      final List<dynamic> alarmList = jsonDecode(alarmsJson);
      _alarms = alarmList.map((json) => Alarm.fromJson(json)).toList();
    }
  }

  /// Refresh alarms (reload from local storage)
  static Future<void> refreshAlarms() async {
    await _loadAlarms();
    print("Alarms refreshed");
  }
}


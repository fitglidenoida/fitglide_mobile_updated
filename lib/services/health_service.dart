import 'package:health/health.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HealthService {
  final Health _health = Health();

  /// Configure the Health API (must be called before any operation)
  Future<void> configureHealth() async {
    try {
      await _health.configure();
      debugPrint('Health API configured successfully');
    } catch (e) {
      debugPrint('Error configuring Health API: $e');
    }
  }

  /// Check if Health Connect is installed by attempting to open it
  Future<bool> checkHealthConnectInstalled() async {
    const healthConnectUri = 'com.google.android.apps.healthdata';
    
    try {
      bool canOpen = await canLaunch('market://details?id=$healthConnectUri');
      if (!canOpen) {
        _promptInstallHealthConnect();
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Health Connect is not installed. Prompting user...');
      _promptInstallHealthConnect();
      return false;
    }
  }

  /// Launch Google Play Store to install Health Connect
  void _promptInstallHealthConnect() async {
    const url = 'https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      debugPrint('Could not launch Health Connect install URL.');
    }
  }

  /// Request permissions for specific health data types
Future<bool> requestPermissions() async {
  var types = [
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_IN_BED,
  ];

  var permissions = List<HealthDataAccess>.filled(types.length, HealthDataAccess.READ);

  try {
    // Ensure Health Connect is installed before requesting permissions
    if (!await checkHealthConnectInstalled()) {
      return false;
    }

    // Check if permissions are already granted
    bool hasPermissions = await _health.hasPermissions(types, permissions: permissions) ?? false;
    debugPrint('Initial permission check: $hasPermissions');

    if (!hasPermissions) {
      bool granted = await _health.requestAuthorization(types, permissions: permissions);
      debugPrint('Health permissions granted: $granted');
      return granted;
    }
    debugPrint('Permissions already granted');
    return true;
  } catch (e) {
    debugPrint('Error requesting health permissions: $e');
    return false;
  }
}

  /// Fetch health data for the given date range
 Future<List<HealthDataPoint>> fetchHealthData(DateTime startDate, DateTime endDate) async {
  var types = [
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_IN_BED,
  ];

  try {
    // Ensure permissions are granted before fetching data
    bool hasPermission = await requestPermissions();
    if (!hasPermission) {
      debugPrint("Missing Health Connect permissions.");
      return [];
    }

    List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
      types: types,
      startTime: startDate,
      endTime: endDate,
    );
    _health.removeDuplicates(healthData);
    debugPrint('Fetched ${healthData.length} sleep data points');
    return healthData;
  } catch (e) {
    debugPrint("Error fetching sleep data: $e");
    return [];
  }
}


  /// Write health data (e.g., steps, blood glucose)
  Future<bool> writeHealthData(
    double value,
    HealthDataType type,
    DateTime startDate,
    DateTime endDate, {
    RecordingMethod recordingMethod = RecordingMethod.automatic,
  }) async {
    try {
      return await _health.writeHealthData(
        value: value,
        type: type,
        startTime: startDate,
        endTime: endDate,
        recordingMethod: recordingMethod,
      );
    } catch (e) {
      debugPrint("Error writing health data: $e");
      return false;
    }
  }

  /// Fetch total steps for the given date range
  Future<int?> fetchStepCount(DateTime startDate, DateTime endDate) async {
    try {
      return await _health.getTotalStepsInInterval(startDate, endDate);
    } catch (e) {
      debugPrint("Error fetching step count: $e");
      return null;
    }
  }
}

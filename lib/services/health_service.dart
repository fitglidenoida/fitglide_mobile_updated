import 'package:health/health.dart';

class HealthService {
  final Health _health = Health();

  /// Configure the Health API (must be called before any operation)
  Future<void> configureHealth() async {
    await _health.configure();
  }

  /// Request permissions for specific health data types
  Future<bool> requestPermissions() async {
    // Define the health data types for read/write access
    var types = [
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.BLOOD_GLUCOSE,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_AWAKE,
      HealthDataType.SLEEP_AWAKE_IN_BED,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_IN_BED,
      HealthDataType.SLEEP_LIGHT,
      HealthDataType.SLEEP_REM,
      HealthDataType.SLEEP_SESSION,
      HealthDataType.SLEEP_OUT_OF_BED,
      HealthDataType.SLEEP_UNKNOWN
    ];

    // Specify the access level for each type
    var permissions = List<HealthDataAccess>.filled(types.length, HealthDataAccess.READ_WRITE);

    // Request permissions for the defined data types
    return await _health.requestAuthorization(types, permissions: permissions);
  }

  /// Fetch health data for the given date range
  Future<List<HealthDataPoint>> fetchHealthData(DateTime startDate, DateTime endDate) async {
    // Define the data types to fetch
    var types = [
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.BLOOD_GLUCOSE,
      HealthDataType.BLOOD_OXYGEN,
      HealthDataType.ATRIAL_FIBRILLATION_BURDEN,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.BODY_MASS_INDEX,
      HealthDataType.TOTAL_CALORIES_BURNED,
      HealthDataType.DISTANCE_CYCLING,
      HealthDataType.DISTANCE_DELTA,
      HealthDataType.DISTANCE_SWIMMING,
      HealthDataType.DISTANCE_WALKING_RUNNING,
      HealthDataType.BLOOD_OXYGEN,
      HealthDataType.RESTING_HEART_RATE,
      HealthDataType.RESPIRATORY_RATE,
      HealthDataType.HIGH_HEART_RATE_EVENT,
      HealthDataType.LOW_HEART_RATE_EVENT,
      HealthDataType.WORKOUT,
      HealthDataType.ELECTROCARDIOGRAM,
    ];

    try {
      // Fetch data for the defined types
      List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        types: types,
        startTime: startDate,
        endTime: endDate,
      );

      // Remove duplicates for clean data
      _health.removeDuplicates(healthData);

      return healthData;
    } catch (e) {
      print("Error fetching health data: $e");
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
      print("Error writing health data: $e");
      return false;
    }
  }

  /// Fetch total steps for the given date range
  Future<int?> fetchStepCount(DateTime startDate, DateTime endDate) async {
    try {
      return await _health.getTotalStepsInInterval(startDate, endDate);
    } catch (e) {
      print("Error fetching step count: $e");
      return null;
    }
  }
}
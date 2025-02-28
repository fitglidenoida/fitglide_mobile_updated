import 'package:fitglide_mobile_application/common/common.dart';
import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:fitglide_mobile_application/services/storage_service.dart';
import 'package:fitglide_mobile_application/view/meal_planner/meal_schedule_view.dart';
import 'package:fitglide_mobile_application/view/sleep_tracker/sleep_schedule_view.dart';
import 'package:fitglide_mobile_application/view/workout_tracker/add_schedule_view.dart';
import 'package:fitglide_mobile_application/view/workout_tracker/workout_tracker_view.dart'; // Import WorkoutTrackerView
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:animated_text_kit/animated_text_kit.dart'; // For typewriter animation
import '../../common/colo_extension.dart';

// Placeholder for ProfileView (you can replace this with your actual ProfileView implementation)
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: TColor.white,
      ),
      backgroundColor: TColor.white,
      body:  Center(
        child: Text('Profile View - To be implemented', style: TextStyle(color: TColor.black)),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectTab = 0;
  String firstName = "Guest";
  String username = "";
  double? bmi;
  String bmiCategory = "";
  bool isLoading = true;

  List<Map<String, dynamic>> upcomingWorkouts = [];
  List<Map<String, dynamic>> waterIntake = [];
  List<FlSpot> heartRateSpots = [];
  List<Map<String, dynamic>> badges = [];

  String heartRate = "N/A";
  String sleepDuration = "N/A";
  double? caloriesBurned;
  double? caloriesConsumed;
  double? weightLossGoal;
  int? stepsTaken; // New metric for steps, as an example

  // Remove 'late' and initialize lineChartData with a default value
  LineChartData lineChartData = LineChartData(
    gridData: FlGridData(show: false),
    titlesData: FlTitlesData(
      bottomTitles: AxisTitles(sideTitles: SideTitles(
        reservedSize: 30,
        getTitlesWidget: (value, meta) => Text('${value.toInt() + 1}d', style: TextStyle(color: TColor.gray, fontSize: 12)),
      )),
      leftTitles: AxisTitles(sideTitles: SideTitles(
        reservedSize: 40,
        getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: TextStyle(color: TColor.gray, fontSize: 12)),
      )),
      topTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
    ),
    borderData: FlBorderData(show: true, border: Border.all(color: TColor.gray.withOpacity(0.2))),
    lineBarsData: [
      LineChartBarData(
        spots: List.generate(7, (i) => FlSpot(i.toDouble(), 60.0)), // Default spots
        isCurved: true,
        barWidth: 3,
        color: Color(0xFFDDA0A0), // Darker dusty rose
        belowBarData: BarAreaData(show: true, color: Color(0xFFDDA0A0).withOpacity(0.1)),
        dotData: FlDotData(show: true),
      ),
    ],
    minX: 0,
    maxX: 6,
    minY: 0,
    maxY: 100, // Ensure reasonable bounds
  );

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final dataService = DataService();
      final response = await dataService.fetchUserDetails();
      debugPrint('User details response: $response'); // Debug print to check user data
      if (response.isEmpty) {
        throw Exception('No user details returned');
      }
      setState(() {
        firstName = response['First_name'] ?? "Guest";
        username = response['username'] ?? "";
      });
      if (username.isNotEmpty) {
        await Future.wait([
          fetchHealthVitals(username),
          fetchUpcomingWorkouts(username),
          fetchWaterIntake(username),
          fetchRealTimeData(username),
          fetchCalorieData(username),
          fetchWeightLossGoal(username),
          fetchTrendData(username),
          fetchBadges(username),
          fetchStepsTaken(username), // New method to fetch steps
        ]);
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      setState(() {
        firstName = "Guest";
        username = "";
        isLoading = false;
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> fetchTrendData(String username) async {
    try {
      final healthVitalsList = await DataService().fetchHealthVitals(username);
      debugPrint('Trend data (health vitals): $healthVitalsList'); // Debug print to check data
      if (healthVitalsList.isEmpty) {
        throw Exception('No health vitals data returned');
      }
      setState(() {
        heartRateSpots = List.generate(7, (i) {
          final vital = healthVitalsList.length > i ? healthVitalsList[i] : null;
          final heartRate = vital != null && vital['heart_rate'] != null
              ? (vital['heart_rate'] as num).toDouble()
              : 60.0; // Default heart rate if data is missing
          return FlSpot(i.toDouble(), heartRate);
        });
        // Update lineChartData with the new heartRateSpots
        lineChartData = LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              reservedSize: 30,
              getTitlesWidget: (value, meta) => Text('${value.toInt() + 1}d', style: TextStyle(color: TColor.gray, fontSize: 12)),
            )),
            leftTitles: AxisTitles(sideTitles: SideTitles(
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: TextStyle(color: TColor.gray, fontSize: 12)),
            )),
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: TColor.gray.withOpacity(0.2))),
          lineBarsData: [
            LineChartBarData(
              spots: heartRateSpots.isNotEmpty ? heartRateSpots : List.generate(7, (i) => FlSpot(i.toDouble(), 60.0)),
              isCurved: true,
              barWidth: 3,
              color: Color(0xFFDDA0A0), // Darker dusty rose
              belowBarData: BarAreaData(show: true, color: Color(0xFFDDA0A0).withOpacity(0.1)),
              dotData: FlDotData(show: true),
            ),
          ],
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: 100, // Ensure reasonable bounds
        );
      });
    } catch (e) {
      debugPrint('Error fetching trend data: $e');
      setState(() {
        heartRateSpots = List.generate(7, (i) => FlSpot(i.toDouble(), 60.0)); // Fallback data
        lineChartData = LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              reservedSize: 30,
              getTitlesWidget: (value, meta) => Text('${value.toInt() + 1}d', style: TextStyle(color: TColor.gray, fontSize: 12)),
            )),
            leftTitles: AxisTitles(sideTitles: SideTitles(
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: TextStyle(color: TColor.gray, fontSize: 12)),
            )),
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: TColor.gray.withOpacity(0.2))),
          lineBarsData: [
            LineChartBarData(
              spots: heartRateSpots,
              isCurved: true,
              barWidth: 3,
              color: Color(0xFFDDA0A0), // Darker dusty rose
              belowBarData: BarAreaData(show: true, color: Color(0xFFDDA0A0).withOpacity(0.1)),
              dotData: FlDotData(show: true),
            ),
          ],
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: 100, // Ensure reasonable bounds
        );
      });
    }
  }

  Future<void> fetchBadges(String username) async {
    try {
      setState(() {
        badges = [
          if (upcomingWorkouts.isNotEmpty) {"icon": "assets/icons/workout_streak.png", "title": "Workout Streak"},
          if (waterIntake.isNotEmpty) {"icon": "assets/icons/hydration_hero.png", "title": "Hydration Hero"},
          if (caloriesBurned != null && caloriesBurned! > 500) {"icon": "assets/icons/calorie_crusher.png", "title": "Calorie Crusher"},
        ];
      });
    } catch (e) {
      debugPrint('Error fetching badges: $e');
      setState(() => badges = []);
    }
  }

  Future<void> fetchHealthVitals(String username) async {
    try {
      final List<dynamic> healthVitalsList = await DataService().fetchHealthVitals(username);
      debugPrint('Health vitals response: $healthVitalsList'); // Debug print to check data
      if (healthVitalsList.isEmpty) {
        throw Exception('No health vitals data returned');
      }

      final Map<String, dynamic> vitalData = healthVitalsList[0]['attributes'] ?? healthVitalsList[0];
      final String? documentId = healthVitalsList[0]['id']?.toString();

      if (documentId != null) {
        await StorageService.saveData('health_vitals_document_id', documentId);
      }

      final double? weightKg = (vitalData['WeightInKilograms'] as num?)?.toDouble();
      final double? heightCm = (vitalData['height'] as num?)?.toDouble();
      final String? dateOfBirth = vitalData['date_of_birth'] as String?;
      final int? heartRateValue = (vitalData['heart_rate'] as num?)?.toInt();
      final double? waterIntakeValue = (vitalData['water_intake'] as num?)?.toDouble();
      final double? sleepDurationValue = (vitalData['sleep_duration'] as num?)?.toDouble();

      if (weightKg == null || heightCm == null || dateOfBirth == null) {
        throw Exception('Missing vital data for BMI calculation');
      }

      final heightM = heightCm / 100.0;
      final double calculatedBmi = weightKg / (heightM * heightM);
      final int age = calculateAge(dateOfBirth);
      final String category = interpretBMI(calculatedBmi, age);

      setState(() {
        bmi = calculatedBmi;
        bmiCategory = category;
        heartRate = heartRateValue != null ? "$heartRateValue BPM" : "N/A";
        if (waterIntakeValue != null) {
          waterIntake = [
            {"title": "6am - 8am", "subtitle": "${(waterIntakeValue * 0.2).toStringAsFixed(1)}ml"},
            {"title": "9am - 11am", "subtitle": "${(waterIntakeValue * 0.15).toStringAsFixed(1)}ml"},
            {"title": "11am - 2pm", "subtitle": "${(waterIntakeValue * 0.3).toStringAsFixed(1)}ml"},
            {"title": "2pm - 4pm", "subtitle": "${(waterIntakeValue * 0.15).toStringAsFixed(1)}ml"},
            {"title": "4pm - now", "subtitle": "${(waterIntakeValue * 0.2).toStringAsFixed(1)}ml"},
          ];
        }
        sleepDuration = sleepDurationValue != null ? "${sleepDurationValue.toStringAsFixed(1)}h" : "N/A";
        heartRateSpots = List.generate(7, (i) => FlSpot(i.toDouble(), heartRateValue?.toDouble() ?? 60.0));
      });
    } catch (e) {
      debugPrint("Error fetching health vitals: $e");
      setState(() {
        bmiCategory = "Error fetching health vitals.";
        bmi = null;
        heartRate = "N/A";
        waterIntake = [];
        sleepDuration = "N/A";
        heartRateSpots = List.generate(7, (i) => FlSpot(i.toDouble(), 60.0));
      });
    }
  }

  Future<void> fetchUpcomingWorkouts(String username) async {
    try {
      final now = DateTime.now().toLocal();
      final todayStart = DateTime(now.year, now.month, now.day).toLocal();
      final response = await ApiService.get(
          'workout-plans?populate=exercises&filters[users_permissions_user][username][\$eq]=$username&filters[scheduled_date][\$gte]=${todayStart.toIso8601String()}&sort[0]=scheduled_date:asc');
      final workoutData = response['data'] as List<dynamic>? ?? [];
      debugPrint('Upcoming workouts response: $workoutData'); // Debug print to check data
      if (workoutData.isEmpty) {
        throw Exception('No upcoming workouts returned');
      }

      setState(() {
        upcomingWorkouts = workoutData.take(3).map((workout) {
          final exercises = workout['exercises'] as List<dynamic>? ?? [];
          final pendingExercises = exercises.where((e) => (e['completed'] as bool? ?? false) == false).length;
          final totalKcal = exercises.fold<int>(0, (sum, e) => sum + (e['calories_per_minute'] as int? ?? 0) * (e['duration'] as int? ?? 0));
          final totalTime = exercises.fold<int>(0, (sum, e) => sum + (e['duration'] as int? ?? 0));
          final scheduledDate = stringToDate(workout['scheduled_date'] as String, formatStr: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", ).toLocal();
          return {
            "name": workout['Title'] as String? ?? 'Untitled Workout',
            "image": "assets/img/Workout${(workoutData.indexOf(workout) % 3) + 1}.png",
            "pendingExercises": pendingExercises.toString(),
            "kcal": totalKcal.toString(),
            "time": totalTime.toString(),
            "date": dateToString(scheduledDate, formatStr: "dd/MM/yyyy hh:mm aa"),
            "documentId": workout['id'].toString(),
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error fetching upcoming workouts: $e');
      setState(() {
        upcomingWorkouts = [];
      });
    }
  }

  Future<void> fetchWaterIntake(String username) async {
    try {
      final healthVitalsList = await DataService().fetchHealthVitals(username);
      final latestHealth = healthVitalsList.isNotEmpty ? healthVitalsList.first : null;
      debugPrint('Water intake data: $latestHealth'); // Debug print to check data
      if (latestHealth == null || latestHealth['water_intake'] == null) {
        throw Exception('No water intake data returned');
      }

      setState(() {
        final totalWater = (latestHealth['water_intake'] as num).toDouble();
        waterIntake = [
          {"title": "6am - 8am", "subtitle": "${(totalWater * 0.2).toStringAsFixed(1)}ml"},
          {"title": "9am - 11am", "subtitle": "${(totalWater * 0.15).toStringAsFixed(1)}ml"},
          {"title": "11am - 2pm", "subtitle": "${(totalWater * 0.3).toStringAsFixed(1)}ml"},
          {"title": "2pm - 4pm", "subtitle": "${(totalWater * 0.15).toStringAsFixed(1)}ml"},
          {"title": "4pm - now", "subtitle": "${(totalWater * 0.2).toStringAsFixed(1)}ml"},
        ];
      });
    } catch (e) {
      debugPrint('Error fetching water intake: $e');
      setState(() {
        waterIntake = [];
      });
    }
  }

  Future<void> fetchRealTimeData(String username) async {
    try {
      final healthVitalsList = await DataService().fetchHealthVitals(username);
      final latestHealth = healthVitalsList.isNotEmpty ? healthVitalsList.first : null;
      debugPrint('Real-time data: $latestHealth'); // Debug print to check data
      if (latestHealth == null) {
        throw Exception('No real-time data returned');
      }

      setState(() {
        heartRate = latestHealth['heart_rate'] != null ? "${latestHealth['heart_rate']} BPM" : "N/A";
        sleepDuration = latestHealth['sleep_duration'] != null ? "${latestHealth['sleep_duration']}h" : "N/A";
        heartRateSpots = List.generate(7, (i) {
          return FlSpot(
            i.toDouble(),
            latestHealth['heart_rate'] != null ? latestHealth['heart_rate'].toDouble() : 60.0,
          );
        });
        // Update lineChartData with the new heartRateSpots
        lineChartData = LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              reservedSize: 30,
              getTitlesWidget: (value, meta) => Text('${value.toInt() + 1}d', style: TextStyle(color: TColor.gray, fontSize: 12)),
            )),
            leftTitles: AxisTitles(sideTitles: SideTitles(
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: TextStyle(color: TColor.gray, fontSize: 12)),
            )),
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: TColor.gray.withOpacity(0.2))),
          lineBarsData: [
            LineChartBarData(
              spots: heartRateSpots.isNotEmpty ? heartRateSpots : List.generate(7, (i) => FlSpot(i.toDouble(), 60.0)),
              isCurved: true,
              barWidth: 3,
              color: Color(0xFFDDA0A0), // Darker dusty rose
              belowBarData: BarAreaData(show: true, color: Color(0xFFDDA0A0).withOpacity(0.1)),
              dotData: FlDotData(show: true),
            ),
          ],
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: 100, // Ensure reasonable bounds
        );
      });
    } catch (e) {
      debugPrint('Error fetching real-time data: $e');
      setState(() {
        heartRate = "N/A";
        sleepDuration = "N/A";
        heartRateSpots = List.generate(7, (i) => FlSpot(i.toDouble(), 60.0));
        lineChartData = LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              reservedSize: 30,
              getTitlesWidget: (value, meta) => Text('${value.toInt() + 1}d', style: TextStyle(color: TColor.gray, fontSize: 12)),
            )),
            leftTitles: AxisTitles(sideTitles: SideTitles(
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: TextStyle(color: TColor.gray, fontSize: 12)),
            )),
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: TColor.gray.withOpacity(0.2))),
          lineBarsData: [
            LineChartBarData(
              spots: heartRateSpots,
              isCurved: true,
              barWidth: 3,
              color: Color(0xFFDDA0A0), // Darker dusty rose
              belowBarData: BarAreaData(show: true, color: Color(0xFFDDA0A0).withOpacity(0.1)),
              dotData: FlDotData(show: true),
            ),
          ],
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: 100, // Ensure reasonable bounds
        );
      });
    }
  }

  Future<void> fetchCalorieData(String username) async {
    try {
      final now = DateTime.now().toLocal();
      final todayStart = DateTime(now.year, now.month, now.day).toLocal();
      final todayEnd = todayStart.add(const Duration(days: 1));
      debugPrint('Fetching calorie data for username: $username'); // Debug print

      final workoutResponse = await ApiService.fetchWorkoutPlans(username);
      final workoutData = workoutResponse['data'] as List<dynamic>? ?? [];
      debugPrint('Workout data: $workoutData'); // Debug print
      if (workoutData.isEmpty) {
        throw Exception('No workout data returned');
      }

      caloriesBurned = workoutData.fold<double>(
          0, (sum, workout) {
            final scheduledDateStr = workout['scheduled_date'] as String?;
            final scheduledDate = scheduledDateStr != null
                ? stringToDate(scheduledDateStr, formatStr: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", ).toLocal()
                : DateTime.now().toLocal();
            if (scheduledDate.isAfter(todayStart) && scheduledDate.isBefore(todayEnd) && (workout['Completed'] as String?) == 'TRUE') {
              final exercises = workout['exercises'] as List<dynamic>? ?? [];
              return sum + exercises.fold<double>(
                  0, (innerSum, e) => innerSum + ((e['calories_per_minute'] as int? ?? 0) * (e['duration'] as int? ?? 0)).toDouble());
            }
            return sum;
          });

      final mealResponse = await ApiService.get(
          'diet-plans?populate=meals.diet_components&filters[users_permissions_user][username][\$eq]=$username');
      final mealPlans = mealResponse['data'] as List<dynamic>? ?? [];
      debugPrint('Meal plans: $mealPlans'); // Debug print
      if (mealPlans.isEmpty) {
        throw Exception('No meal plans returned');
      }

      caloriesConsumed = 0.0;
      for (var plan in mealPlans) {
        final meals = plan['meals'] as List<dynamic>? ?? [];
        for (var meal in meals) {
          final mealDateStr = meal['meal_date'] as String?;
          final mealDate = mealDateStr != null
              ? stringToDate(mealDateStr, formatStr: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", ).toLocal()
              : DateTime.now().toLocal();
          if (mealDate.isAfter(todayStart) && mealDate.isBefore(todayEnd)) {
            final dietComponents = meal['diet_components'] as List<dynamic>? ?? [];
            caloriesConsumed = dietComponents.fold<double>(
                caloriesConsumed ?? 0, (sum, c) => sum + ((c['consumed'] as bool? ?? false) ? (c['calories'] as int? ?? 0) : 0).toDouble());
          }
        }
      }

      setState(() {
        debugPrint('Calories Burned: $caloriesBurned, Calories Consumed: $caloriesConsumed');
      });
    } catch (e) {
      debugPrint('Error fetching calorie data: $e');
      setState(() {
        caloriesBurned = null;
        caloriesConsumed = null;
      });
    }
  }

  Future<void> fetchWeightLossGoal(String username) async {
    try {
      final healthVitalsList = await DataService().fetchHealthVitals(username);
      debugPrint('Weight loss goal data: $healthVitalsList'); // Debug print
      if (healthVitalsList.isEmpty) {
        throw Exception('No health vitals data returned for weight loss goal');
      }

      final vitalData = healthVitalsList[0]['attributes'] ?? healthVitalsList[0];
      final initialWeight = (vitalData['WeightInKilograms'] as num?)?.toDouble() ?? 0.0;
      final targetWeight = (vitalData['target_weight'] as num?)?.toDouble() ?? 0.0;

      setState(() {
        weightLossGoal = initialWeight > targetWeight ? initialWeight - targetWeight : null;
      });
    } catch (e) {
      debugPrint('Error fetching weight loss goal: $e');
      setState(() {
        weightLossGoal = null;
      });
    }
  }

  Future<void> fetchStepsTaken(String username) async {
    try {
      final response = await ApiService.get('activity?filters[users_permissions_user][username][\$eq]=$username');
      final activityData = response['data'] as List<dynamic>? ?? [];
      debugPrint('Steps taken data: $activityData'); // Debug print
      if (activityData.isEmpty) {
        throw Exception('No activity data returned');
      }

      setState(() {
        stepsTaken = activityData.isNotEmpty ? (activityData[0]['steps'] as int? ?? 0) : null;
      });
    } catch (e) {
      debugPrint('Error fetching steps taken: $e');
      setState(() {
        stepsTaken = null;
      });
    }
  }

  int calculateAge(String dateOfBirth) {
    DateTime dob = DateTime.parse(dateOfBirth);
    DateTime today = DateTime.now().toLocal();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  String interpretBMI(double bmi, [int? age]) {
    if (age != null && age < 18) {
      return 'BMI interpretation for children/teenagers not implemented yet.';
    } else {
      if (bmi < 18.5) return 'Under Weight';
      if (bmi >= 18.5 && bmi < 24.9) return 'Normal Weight';
      if (bmi >= 25 && bmi < 29.9) return 'Over Weight';
      return 'Obese';
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;

    // Debug prints to check data for health metrics
    debugPrint('Water Intake Data: $waterIntake');
    debugPrint('Sleep Duration: $sleepDuration');
    debugPrint('Calories Consumed: $caloriesConsumed');
    debugPrint('Weight Loss Goal: $weightLossGoal');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _buildBodyForTab(selectTab, context), // Use a method to build the body based on the selected tab
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Color(0xFFDDA0A0), // Darker dusty rose
        foregroundColor: Colors.white,
        elevation: 8,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.fitness_center_outlined, size: 24),
            backgroundColor: Color(0xFF90EE90), // Darker sage green
            foregroundColor: Colors.white,
            label: 'Workout',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddScheduleView(date: DateTime.now())),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.restaurant_menu, size: 24),
            backgroundColor: Color(0xFFF5D0A9), // Darker beige
            foregroundColor: Colors.white,
            label: 'Meal',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MealScheduleView()),
              );
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.bedtime, size: 24),
            backgroundColor: Color(0xFFDDA0A0), // Darker dusty rose
            foregroundColor: Colors.white,
            label: 'Sleep',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SleepScheduleView()),
              );
            },
          ),
        ],
      ).animate(
        effects: [
          FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
          ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
          ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectTab,
        onTap: (index) {
          setState(() {
            selectTab = index;
          });
          _navigateToTab(index, context); // Navigate to the corresponding view
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 28).animate(
              target: selectTab == 0 ? 1.0 : 0.0,
              effects: [
                ScaleEffect(
                  duration: 400.ms,
                  curve: Curves.easeInOut,
                  begin: Offset(1.0, 1.0),
                  end: Offset(1.2, 1.2),
                ),
                FadeEffect(
                  duration: 400.ms,
                  curve: Curves.easeInOut,
                ),
                ShakeEffect(duration: 200.ms, curve: Curves.easeOut),
              ],
            ),
            activeIcon: Icon(Icons.home, color: Color(0xFFDDA0A0), size: 28).animate( // Darker dusty rose
              effects: [
                FadeEffect(duration: 300.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 300.ms, curve: Curves.easeInOut, begin: Offset(1.0, 1.0), end: Offset(1.1, 1.1)),
                ShakeEffect(duration: 200.ms, curve: Curves.easeOut),
              ],
            ),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined, size: 28).animate(
              target: selectTab == 1 ? 1.0 : 0.0,
              effects: [
                ScaleEffect(
                  duration: 400.ms,
                  curve: Curves.easeInOut,
                  begin: Offset(1.0, 1.0),
                  end: Offset(1.2, 1.2),
                ),
                FadeEffect(
                  duration: 400.ms,
                  curve: Curves.easeInOut,
                ),
                ShakeEffect(duration: 200.ms, curve: Curves.easeOut),
              ],
            ),
            activeIcon: Icon(Icons.fitness_center, color: Color(0xFFDDA0A0), size: 28).animate( // Darker dusty rose
              effects: [
                FadeEffect(duration: 300.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 300.ms, curve: Curves.easeInOut, begin: Offset(1.0, 1.0), end: Offset(1.1, 1.1)),
                ShakeEffect(duration: 200.ms, curve: Curves.easeOut),
              ],
            ),
            label: "Workout",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu, size: 28).animate(
              target: selectTab == 2 ? 1.0 : 0.0,
              effects: [
                ScaleEffect(
                  duration: 400.ms,
                  curve: Curves.easeInOut,
                  begin: Offset(1.0, 1.0),
                  end: Offset(1.2, 1.2),
                ),
                FadeEffect(
                  duration: 400.ms,
                  curve: Curves.easeInOut,
                ),
                ShakeEffect(duration: 200.ms, curve: Curves.easeOut),
              ],
            ),
            activeIcon: Icon(Icons.restaurant, color: Color(0xFFDDA0A0), size: 28).animate( // Darker dusty rose
              effects: [
                FadeEffect(duration: 300.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 300.ms, curve: Curves.easeInOut, begin: Offset(1.0, 1.0), end: Offset(1.1, 1.1)),
                ShakeEffect(duration: 200.ms, curve: Curves.easeOut),
              ],
            ),
            label: "Meal",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bedtime, size: 28).animate(
              target: selectTab == 3 ? 1.0 : 0.0,
              effects: [
                ScaleEffect(
                  duration: 400.ms,
                  curve: Curves.easeInOut,
                  begin: Offset(1.0, 1.0),
                  end: Offset(1.2, 1.2),
                ),
                FadeEffect(
                  duration: 400.ms,
                  curve: Curves.easeInOut,
                ),
                ShakeEffect(duration: 200.ms, curve: Curves.easeOut),
              ],
            ),
            activeIcon: Icon(Icons.nightlight_round, color: Color(0xFFDDA0A0), size: 28).animate( // Darker dusty rose
              effects: [
                FadeEffect(duration: 300.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 300.ms, curve: Curves.easeInOut, begin: Offset(1.0, 1.0), end: Offset(1.1, 1.1)),
                ShakeEffect(duration: 200.ms, curve: Curves.easeOut),
              ],
            ),
            label: "Sleep",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 28).animate(
              target: selectTab == 4 ? 1.0 : 0.0,
              effects: [
                ScaleEffect(
                  duration: 400.ms,
                  curve: Curves.easeInOut,
                  begin: Offset(1.0, 1.0),
                  end: Offset(1.2, 1.2),
                ),
                FadeEffect(
                  duration: 400.ms,
                  curve: Curves.easeInOut,
                ),
                ShakeEffect(duration: 200.ms, curve: Curves.easeOut),
              ],
            ),
            activeIcon: Icon(Icons.person, color: Color(0xFFDDA0A0), size: 28).animate( // Darker dusty rose
              effects: [
                FadeEffect(duration: 300.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 300.ms, curve: Curves.easeInOut, begin: Offset(1.0, 1.0), end: Offset(1.1, 1.1)),
                ShakeEffect(duration: 200.ms, curve: Curves.easeOut),
              ],
            ),
            label: "Profile",
          ),
        ],
        selectedItemColor: Color(0xFFDDA0A0), // Darker dusty rose
        unselectedItemColor: TColor.gray,
        backgroundColor: Colors.white,
        elevation: 0, // Remove elevation to avoid white strip
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFDDA0A0)),
        unselectedLabelStyle: TextStyle(fontSize: 14, color: TColor.gray),
      ).animate(
        effects: [
          FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
          ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.95, 0.95), end: Offset(1.0, 1.0)),
          ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
        ],
      ),
    );
  }

  // Method to build the body based on the selected tab
  Widget _buildBodyForTab(int tabIndex, BuildContext context) {
    switch (tabIndex) {
      case 0: // Home
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: AnimatedTextKit(
                      animatedTexts: [
                        TypewriterAnimatedText(
                          "FitGlide",
                          textStyle: TextStyle(color: TColor.black, fontSize: 32, fontWeight: FontWeight.bold),
                          speed: const Duration(milliseconds: 100),
                        ),
                      ],
                      totalRepeatCount: 1,
                    ).animate(
                      effects: [
                        FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
                        ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                        ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      print("Notification tapped");
                    },
                    icon: Icon(Icons.notifications, color: Color(0xFFDDA0A0), size: 30).animate(
                      effects: [
                        FadeEffect(duration: 600.ms, curve: Curves.easeInOut),
                        ScaleEffect(duration: 600.ms, curve: Curves.easeInOut, begin: Offset(0.8, 0.8), end: Offset(1.0, 1.0)),
                        ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFFDDA0A0), // Darker dusty rose
                    child: Text(
                      firstName.isNotEmpty ? firstName[0] : "G",
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ).animate(
                    effects: [
                      FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
                      ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.8, 0.8), end: Offset(1.0, 1.0)),
                      ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
                    ],
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome Back,",
                          style: TextStyle(color: TColor.gray, fontSize: 16), // Reduced font size for "Welcome Back,"
                        ).animate(
                          effects: [
                            FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
                            SlideEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(20, 0), end: Offset(0, 0)),
                          ],
                        ),
                        SizedBox(height: 5),
                        Text(
                          firstName,
                          style: TextStyle(color: TColor.black, fontSize: 24, fontWeight: FontWeight.w800), // Reduced font size for name
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ).animate(
                          effects: [
                            FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
                            ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                            ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),

              // Metrics Section (Single Row of 7 Smaller Cards, Full Screen Width with Scroll)
              SizedBox(
                height: 120, // Match height of all metrics cards
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal, // Horizontal scrolling for all 7 cards
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _buildSmallMetricCard(
                        icon: Icons.fitness_center,
                        title: "Pending Exercises",
                        subtitle: upcomingWorkouts.isNotEmpty ? upcomingWorkouts.fold(0, (sum, workout) => sum + int.parse(workout['pendingExercises'] ?? '0')).toString() : "0",
                        gradient: [Color(0xFF90EE90), Color(0xFFF5D0A9)], // Darker sage green to darker beige
                      ),
                      SizedBox(width: 10),
                      _buildSmallMetricCard(
                        icon: Icons.local_fire_department,
                        title: "Calories Burned",
                        subtitle: caloriesBurned != null ? "${caloriesBurned!.toStringAsFixed(0)} kCal" : "N/A",
                        gradient: [Color(0xFFDDA0A0), Color(0xFF90EE90)], // Darker dusty rose to darker sage green
                      ),
                      SizedBox(width: 10),
                      _buildSmallMetricCard(
                        icon: Icons.directions_walk, // Steps Taken
                        title: "Steps Taken",
                        subtitle: stepsTaken != null ? "$stepsTaken steps" : "N/A",
                        gradient: [Color(0xFFF5D0A9), Color(0xFFDDA0A0)], // Darker beige to darker dusty rose
                      ),
                      SizedBox(width: 10),
                      _buildSmallHealthMetricCard(
                        title: "Water Intake",
                        content: _buildProgressIndicator(
                          title: "",
                          value: waterIntake.isNotEmpty ? (waterIntake.fold(0.0, (sum, item) => sum + double.parse(item['subtitle'].replaceAll('ml', '')) / 2000)) : 0.0,
                          goal: "2000ml",
                          color: Color(0xFF90EE90), // Darker sage green
                        ),
                        color: Color(0xFF90EE90), // Darker sage green for water
                      ),
                      SizedBox(width: 10),
                      _buildSmallHealthMetricCard(
                        title: "Sleep",
                        content: _buildProgressIndicator(
                          title: "",
                          value: sleepDuration != "N/A" ? (double.tryParse(sleepDuration.replaceAll('h', '')) ?? 0) / 8 : 0.0,
                          goal: "8h",
                          color: Color(0xFFF5D0A9), // Darker beige
                        ),
                        color: Color(0xFFF5D0A9), // Darker beige for sleep
                      ),
                      SizedBox(width: 10),
                      _buildSmallHealthMetricCard(
                        title: "Calories",
                        content: _buildProgressIndicator(
                          title: "",
                          value: caloriesConsumed != null ? (caloriesConsumed! / 2000) : 0.0,
                          goal: "2000kCal",
                          color: Color(0xFFDDA0A0), // Darker dusty rose
                        ),
                        color: Color(0xFFDDA0A0), // Darker dusty rose for calories
                      ),
                      SizedBox(width: 10),
                      _buildSmallHealthMetricCard(
                        title: "Weight Loss",
                        content: _buildProgressIndicator(
                          title: "",
                          value: weightLossGoal != null ? (1 - (weightLossGoal! / 10)) : 0.0,
                          goal: "10kg",
                          color: Color(0xFFF5D0A9), // Darker beige
                        ),
                        color: Color(0xFFDDA0A0), // Darker beige for weight loss
                      ),
                    ],
                  ),
                ),
              ).animate(
                effects: [
                  FadeEffect(duration: 1000.ms, curve: Curves.easeInOut),
                  ScaleEffect(duration: 1000.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                  ShakeEffect(duration: 500.ms, curve: Curves.easeOut),
                ],
              ),
              SizedBox(height: 30),

              // Reduced-Height BMI Card
              Container( // Removed Card container as requested
                width: MediaQuery.of(context).size.width, // Full screen width
                height: MediaQuery.of(context).size.height * 0.30, // Reduced height for BMI card
                decoration: BoxDecoration(
                  color: Colors.white, // Use white background directly
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildBMIMetricCard(
                  content: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min, // Ensure minimum height
                    children: [
                      Text(
                        "BMI",
                        style: TextStyle(color: TColor.black, fontSize: 16, fontWeight: FontWeight.bold), // Slightly smaller text for title
                      ).animate(
                        effects: [
                          FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
                          ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                          ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
                        ],
                      ),
                      SizedBox(height: 5), // Reduced spacing between "BMI" and "Obese"
                      Text(
                        bmiCategory.isNotEmpty ? bmiCategory : "No BMI data",
                        style: TextStyle(color: TColor.black, fontSize: 14, fontWeight: FontWeight.bold), // Slightly smaller text for category
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 5), // Reduced spacing
                      SizedBox(
                        width: 150, // Reduced width for compactness
                        height: 150, // Further reduced height for compactness
                        child: SfRadialGauge(
                          axes: [
                            RadialAxis(
                              minimum: 0,
                              maximum: 40,
                              startAngle: 135,
                              endAngle: 45,
                              showLabels: false,
                              showTicks: false,
                              showAxisLine: false,
                              radiusFactor: 0.9, // Further reduce gauge size to fit reduced height
                              ranges: [
                                GaugeRange(startValue: 0, endValue: 17.5, color: Color(0xFF90EE90).withOpacity(0.8), startWidth: 8, endWidth: 8), // Darker beige, smaller width
                                GaugeRange(startValue: 18.5, endValue: 24.9, color: Color(0xFFF5D0A9).withOpacity(0.8), startWidth: 8, endWidth: 8), // Darker sage green, smaller width
                                GaugeRange(startValue: 26.0, endValue: 40, color: Color(0xFFDDA0A0).withOpacity(0.8), startWidth: 8, endWidth: 8), // Darker dusty rose, smaller width
                              ],
                              pointers: [
                                MarkerPointer(
                                  value: bmi != null && bmi! >= 0 && bmi! <= 40 ? bmi! : 24.5,
                                  markerType: MarkerType.circle,
                                  markerWidth: 10, // Further reduce marker size
                                  markerHeight: 10, // Further reduce marker size
                                  color: TColor.white,
                                  borderWidth: 4,
                                  borderColor: TColor.white,
                                ),
                              ],
                              annotations: [
                                GaugeAnnotation(
                                  widget: Text(
                                    bmi != null && bmi! >= 0 && bmi! <= 40 ? bmi!.toStringAsFixed(1) : "24.5",
                                    style: TextStyle(color: TColor.black, fontSize: 16, fontWeight: FontWeight.bold), // Further smaller text
                                  ),
                                  positionFactor: 0.1, // Center the BMI number in the arc
                                  angle: 90, // Align horizontally for center of arc
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  color: Color(0xFFF5D0A9), // Darker beige for BMI
                ),
              ).animate(
                effects: [
                  FadeEffect(duration: 1200.ms, curve: Curves.easeInOut),
                  ScaleEffect(duration: 1200.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                  ShakeEffect(duration: 600.ms, curve: Curves.easeOut),
                ],
              ),
              SizedBox(height: 30),

              // Charts and Badges Section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Health Trends",
                        style: TextStyle(color: TColor.black, fontSize: 22, fontWeight: FontWeight.bold),
                      ).animate(
                        effects: [
                          FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
                          ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                          ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
                        ],
                      ),
                      SizedBox(height: 20),
                      SizedBox(
                        height: 180, // Explicit size to ensure layout
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: LineChart(
                            lineChartData,
                          ).animate(
                            effects: [
                              FadeEffect(duration: 1000.ms, curve: Curves.easeInOut),
                              ScaleEffect(duration: 1000.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                              ShakeEffect(duration: 500.ms, curve: Curves.easeOut),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Badges",
                        style: TextStyle(color: TColor.black, fontSize: 22, fontWeight: FontWeight.bold),
                      ).animate(
                        effects: [
                          FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
                          ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                          ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
                        ],
                      ),
                      SizedBox(height: 15),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: badges.map((badge) => _buildBadge(badge)).toList().animate(
                              effects: [
                                FadeEffect(duration: 1000.ms, curve: Curves.easeInOut),
                                ScaleEffect(duration: 1000.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                                ShakeEffect(duration: 500.ms, curve: Curves.easeOut),
                              ],
                            ),
                      ),
                    ],
                  ),
                ),
              ).animate(
                effects: [
                  FadeEffect(duration: 1200.ms, curve: Curves.easeInOut),
                  ScaleEffect(duration: 1200.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                  ShakeEffect(duration: 600.ms, curve: Curves.easeOut),
                ],
              ),
              SizedBox(height: 30),
            ],
          ),
        );
      case 1: // Workout
        return const WorkoutTrackerView();
      case 2: // Meal
        return const MealScheduleView();
      case 3: // Sleep
        return const SleepScheduleView();
      case 4: // Profile
        return const ProfileView();
      default:
        return  Center(child: Text('Unknown Tab', style: TextStyle(color: TColor.black)));
    }
  }

  // Method to navigate to the corresponding tab view
  void _navigateToTab(int index, BuildContext context) {
    switch (index) {
      case 0: // Home (already on this screen, no navigation needed)
        break;
      case 1: // Workout
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WorkoutTrackerView()),
        );
        break;
      case 2: // Meal
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MealScheduleView()),
        );
        break;
      case 3: // Sleep
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SleepScheduleView()),
        );
        break;
      case 4: // Profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileView()),
        );
        break;
    }
  }

  Widget _buildSmallMetricCard({required IconData icon, required String title, required String subtitle, required List<Color> gradient}) {
    return SizedBox(
      width: 160, // Match size of all metrics cards
      height: 120, // Match size of all metrics cards
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(10), // Slightly reduced padding for compactness
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
          children: [
            Icon(icon, color: Colors.white, size: 20), // Slightly smaller icon
            SizedBox(height: 5), // Reduced spacing
            Text(
              title,
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), // Smaller text
            ),
            SizedBox(height: 2), // Reduced spacing
            Text(
              subtitle,
              style: TextStyle(color: Colors.white70, fontSize: 12), // Smaller text
            ),
          ],
        ),
      ),
    ).animate(
      effects: [
        FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
        ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
        ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
      ],
    );
  }

  Widget _buildProgressIndicator({required String title, required double value, required String goal, required Color color}) {
    return SizedBox( // Explicit size to ensure layout
      width: 140, // Slightly reduced width for compactness in smaller cards
      child: Container(
        padding: EdgeInsets.all(8), // Reduced padding for compactness
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Ensure minimum space
          children: [
            if (title.isNotEmpty)
              Text(
                title,
                style: TextStyle(color: TColor.black, fontSize: 14, fontWeight: FontWeight.bold), // Smaller text
              ),
            SizedBox(height: 4), // Reduced spacing
            LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              backgroundColor: TColor.lightGray,
              color: color,
              minHeight: 4, // Smaller height
            ),
            SizedBox(height: 4), // Reduced spacing
            Text(
              "${(value * 100).toStringAsFixed(0)}% of $goal",
              style: TextStyle(color: TColor.gray, fontSize: 10), // Smaller text
            ),
          ],
        ),
      ),
    ).animate(
      effects: [
        FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
        ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
        ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
      ],
    );
  }

  Widget _buildBadge(Map<String, dynamic> badge) {
    return SizedBox( // Explicit size to ensure layout
      width: 120, // Smaller badge size for compactness
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              badge['icon'],
              width: 20,
              height: 20,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.star, color: Color(0xFFDDA0A0), size: 20); // Darker dusty rose fallback
              },
            ),
            SizedBox(width: 8),
            Text(
              badge['title'],
              style: TextStyle(color: TColor.black, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    ).animate(
      effects: [
        FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
        ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
        ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
      ],
    );
  }

  Widget _buildHealthMetricPage({required String title, required Widget content, required Color color}) {
    final media = MediaQuery.of(context).size;
    return Container(
      width: media.width, // Full screen width for each page
      height: media.height * 0.25, // Reduced height to match new card size
      decoration: BoxDecoration(
        color: color.withOpacity(0.2), // Subtle background color for each page
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Ensure minimum space
        children: [
          Text(
            title,
            style: TextStyle(color: TColor.black, fontSize: 20, fontWeight: FontWeight.bold), // Slightly smaller text
          ).animate(
            effects: [
              FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
              ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
              ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
            ],
          ),
          SizedBox(height: 5), // Reduced spacing for compactness
          content,
        ],
      ),
    );
  }

  Widget _buildSmallHealthMetricCard({required String title, required Widget content, required Color color}) {
    return SizedBox(
      width: 160, // Match size of all metrics cards
      height: 120, // Match size of all metrics cards
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.2), // Subtle background color
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(10), // Slightly reduced padding for compactness
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(color: TColor.black, fontSize: 14, fontWeight: FontWeight.bold), // Smaller text
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 5), // Reduced spacing
            content,
          ],
        ),
      ),
    ).animate(
      effects: [
        FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
        ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
        ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
      ],
    );
  }

  Widget _buildBMIMetricCard({ required Widget content, required Color color}) {
    return SizedBox(
      width: 160, // Match size of all metrics cards
      height: 120, // Match size of all metrics cards
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.2), // Subtle background color
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(10), // Slightly reduced padding for compactness
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 5), // Reduced spacing
            content,
          ],
        ),
      ),
    ).animate(
      effects: [
        FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
        ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
        ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
      ],
    );
  }
}
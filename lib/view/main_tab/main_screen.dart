import 'package:fitglide_mobile_application/services/ai_service.dart';
import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:fitglide_mobile_application/view/meal_planner/meal_schedule_view.dart';
import 'package:fitglide_mobile_application/view/sleep_tracker/sleep_schedule_view.dart';
import 'package:fitglide_mobile_application/view/workout_tracker/add_schedule_view.dart';
import 'package:fitglide_mobile_application/view/workout_tracker/workout_tracker_view.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../../common/colo_extension.dart';

// Placeholder for DataService (assumed to exist or replace with ApiService)
class DataService {
  Future<Map<String, dynamic>> fetchUserDetails() async {
    // Replace with actual Strapi call
    final response = await ApiService.get('users/me?populate=*');
    return response['data'] as Map<String, dynamic>? ?? {};
  }

  Future<List<Map<String, dynamic>>> fetchHealthVitals(String username) async {
    final response = await ApiService.get('health-vitals?filters[users_permissions_user][username][\$eq]=$username');
    final data = response['data'] as List<dynamic>? ?? [];
    return data.map((item) => item as Map<String, dynamic>).toList();
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
  int? stepsTaken;

  // Initialize lineChartData with default values
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
        color: TColor.primaryRed, // Vibrant red for charts (FitOn-inspired)
        belowBarData: BarAreaData(show: true, color: TColor.primaryRed.withOpacity(0.1)),
        dotData: FlDotData(show: true),
      ),
    ],
    minX: 0,
    maxX: 6,
    minY: 0,
    maxY: 100, // Ensure reasonable bounds
  );

  String? maxRecommendation;
  String? maxTip;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    _getMaxRecommendations(); // Load Max’s recommendations on init (deferred API calls until later)
  }

  Future<void> fetchUserData() async {
    try {
      final dataService = DataService();
      final response = await dataService.fetchUserDetails();
      debugPrint('User details response: $response');
      if (response.isEmpty) throw Exception('No user details returned');
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
          fetchStepsTaken(username),
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
      debugPrint('Trend data (health vitals): $healthVitalsList');
      if (healthVitalsList.isEmpty) throw Exception('No health vitals data returned');
      setState(() {
        heartRateSpots = List.generate(7, (i) {
          final vital = healthVitalsList.length > i ? healthVitalsList[i] : null;
          final heartRate = vital != null && vital['heart_rate'] != null
              ? (vital['heart_rate'] as num).toDouble()
              : 60.0; // Default heart rate
          return FlSpot(i.toDouble(), heartRate);
        });
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
              color: TColor.primaryRed, // Vibrant red for charts (FitOn-inspired)
              belowBarData: BarAreaData(show: true, color: TColor.primaryRed.withOpacity(0.1)),
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
        heartRateSpots = List.generate(7, (i) => FlSpot(i.toDouble(), 60.0)); // Fallback
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
              color: TColor.primaryRed, // Vibrant red for charts (FitOn-inspired)
              belowBarData: BarAreaData(show: true, color: TColor.primaryRed.withOpacity(0.1)),
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
      final healthVitalsList = await DataService().fetchHealthVitals(username);
      debugPrint('Health vitals response: $healthVitalsList');
      if (healthVitalsList.isEmpty) throw Exception('No health vitals data returned');

      final vitalData = healthVitalsList[0]['attributes'] ?? healthVitalsList[0];
      final double? weightKg = (vitalData['WeightInKilograms'] as num?)?.toDouble();
      final double? heightCm = (vitalData['height'] as num?)?.toDouble();
      final String? dateOfBirth = vitalData['date_of_birth'] as String?;
      final int? heartRateValue = (vitalData['heart_rate'] as num?)?.toInt();
      final double? waterIntakeValue = (vitalData['water_intake'] as num?)?.toDouble();
      final double? sleepDurationValue = (vitalData['sleep_duration'] as num?)?.toDouble();

      if (weightKg == null || heightCm == null || dateOfBirth == null) throw Exception('Missing vital data for BMI');

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
        bmi = null;
        bmiCategory = "Error fetching health vitals.";
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
      debugPrint('Upcoming workouts response: $workoutData');
      if (workoutData.isEmpty) throw Exception('No upcoming workouts returned');

      setState(() {
        upcomingWorkouts = workoutData.take(3).map((workout) {
          final exercises = workout['exercises'] as List<dynamic>? ?? [];
          final pendingExercises = exercises.where((e) => (e['completed'] as bool? ?? false) == false).length;
          final totalKcal = exercises.fold<int>(0, (sum, e) => sum + (e['calories_per_minute'] as int? ?? 0) * (e['duration'] as int? ?? 0));
          final totalTime = exercises.fold<int>(0, (sum, e) => sum + (e['duration'] as int? ?? 0));
          final scheduledDate = DateTime.parse(workout['scheduled_date'] as String).toLocal();
          final dateFormatter = DateFormat('dd/MM/yyyy hh:mm a'); // Format with AM/PM
          return {
            "name": workout['Title'] as String? ?? 'Untitled Workout',
            "image": "assets/img/Workout${(workoutData.indexOf(workout) % 3) + 1}.png",
            "pendingExercises": pendingExercises.toString(),
            "kcal": totalKcal.toString(),
            "time": totalTime.toString(),
            "date": dateFormatter.format(scheduledDate), // Use DateFormat for AM/PM
            "documentId": workout['id'].toString(),
            "fitness_goals": workout['fitness_goals'] ?? [], // Add fitness_goals from workouts
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
      debugPrint('Water intake data: $latestHealth');
      if (latestHealth == null || latestHealth['water_intake'] == null) throw Exception('No water intake data returned');

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
      debugPrint('Real-time data: $latestHealth');
      if (latestHealth == null) throw Exception('No real-time data returned');

      setState(() {
        heartRate = latestHealth['heart_rate'] != null ? "${latestHealth['heart_rate']} BPM" : "N/A";
        sleepDuration = latestHealth['sleep_duration'] != null ? "${latestHealth['sleep_duration']}h" : "N/A";
        heartRateSpots = List.generate(7, (i) {
          return FlSpot(
            i.toDouble(),
            latestHealth['heart_rate'] != null ? latestHealth['heart_rate'].toDouble() : 60.0,
          );
        });
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
              color: TColor.primaryRed, // Vibrant red for charts (FitOn-inspired)
              belowBarData: BarAreaData(show: true, color: TColor.primaryRed.withOpacity(0.1)),
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
              color: TColor.primaryRed, // Vibrant red for charts (FitOn-inspired)
              belowBarData: BarAreaData(show: true, color: TColor.primaryRed.withOpacity(0.1)),
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
      debugPrint('Fetching calorie data for username: $username');

      final workoutResponse = await ApiService.get('workout-plans?populate=exercises&filters[users_permissions_user][username][\$eq]=$username');
      final workoutData = workoutResponse['data'] as List<dynamic>? ?? [];
      debugPrint('Workout data: $workoutData');
      if (workoutData.isEmpty) throw Exception('No workout data returned');

      caloriesBurned = workoutData.fold<double>(
          0, (sum, workout) {
            final scheduledDateStr = workout['scheduled_date'] as String?;
            final scheduledDate = scheduledDateStr != null
                ? DateTime.parse(scheduledDateStr).toLocal()
                : DateTime.now().toLocal();
            if (scheduledDate.isAfter(todayStart) && scheduledDate.isBefore(todayEnd) && (workout['Completed'] as String?) == 'TRUE') {
              final exercises = workout['exercises'] as List<dynamic>? ?? [];
              return sum + exercises.fold<double>(
                  0, (innerSum, e) => innerSum + ((e['calories_per_minute'] as int? ?? 0) * (e['duration'] as int? ?? 0)).toDouble());
            }
            return sum;
          });

      final mealResponse = await ApiService.get('diet-plans?populate=meals.diet_components&filters[users_permissions_user][username][\$eq]=$username');
      final mealPlans = mealResponse['data'] as List<dynamic>? ?? [];
      debugPrint('Meal plans: $mealPlans');
      if (mealPlans.isEmpty) throw Exception('No meal plans returned');

      caloriesConsumed = 0.0;
      for (var plan in mealPlans) {
        final meals = plan['meals'] as List<dynamic>? ?? [];
        for (var meal in meals) {
          final mealDateStr = meal['meal_date'] as String?;
          final mealDate = mealDateStr != null
              ? DateTime.parse(mealDateStr).toLocal()
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
      debugPrint('Weight loss goal data: $healthVitalsList');
      if (healthVitalsList.isEmpty) throw Exception('No health vitals data returned for weight loss goal');

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
      debugPrint('Steps taken data: $activityData');
      if (activityData.isEmpty) throw Exception('No activity data returned');

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
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) age--;
    return age;
  }

  String interpretBMI(double bmi, [int? age]) {
    if (age != null && age < 18) return 'BMI interpretation for children/teenagers not implemented yet.';
    if (bmi < 18.5) return 'Under Weight';
    if (bmi >= 18.5 && bmi < 24.9) return 'Normal Weight';
    if (bmi >= 25 && bmi < 29.9) return 'Over Weight';
    return 'Obese';
  }

  Future<void> _getMaxRecommendations() async {
    try {
      final context = {
        'user': {
          'firstName': firstName, // Use firstName from Strapi's users_permissions
          'username': username, // Use username from Strapi's users_permissions
        },
        'recentWorkouts': upcomingWorkouts, // Use existing upcomingWorkouts data
        'fitnessGoals': upcomingWorkouts.isNotEmpty && upcomingWorkouts[0]['fitness_goals'] != null
            ? (upcomingWorkouts[0]['fitness_goals'] as List<dynamic>).join(', ') // Fetch fitness_goals from workouts
            : 'N/A', // Fallback if no goals
        'healthVitals': {
          'heartRate': heartRate,
          'sleepDuration': sleepDuration,
          'caloriesBurned': caloriesBurned,
          'caloriesConsumed': caloriesConsumed,
          'weightLossGoal': weightLossGoal,
          'stepsTaken': stepsTaken,
        },
      };
      maxRecommendation = await AiService.getMaxRecommendation(
        'Provide fitness progress recommendation for user',
        contextData: context,
        useDatabase: true,
      );
      maxTip = await AiService.getMaxRecommendation(
        'Quick tip for user fitness goals: ${context['fitnessGoals']}',
        contextData: context,
        useDatabase: true,
      );
      setState(() {});
    } catch (e) {
      debugPrint('Error getting Max’s recommendations: $e');
      setState(() {
        maxRecommendation = "Hey, I’m Max—No recommendation available right now, but I’m here to help! Add credits to enable full AI features.";
        maxTip = "Hey, I’m Max—No tip available, but let’s get moving! Add credits to enable full AI features.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;

    debugPrint('Water Intake Data: $waterIntake');
    debugPrint('Sleep Duration: $sleepDuration');
    debugPrint('Calories Consumed: $caloriesConsumed');
    debugPrint('Weight Loss Goal: $weightLossGoal');

    return Scaffold(
      backgroundColor: TColor.white, // White background (FitOn’s light mode)
      body: SafeArea(
        child: _buildBodyForTab(selectTab, context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SpeedDial(
            icon: Icons.add,
            activeIcon: Icons.close,
            backgroundColor: TColor.darkRose, // Dark rose for energy, buttons (FitOn-inspired)
            foregroundColor: TColor.white, // White
            elevation: 8,
            children: [
              SpeedDialChild(
                child: const Icon(Icons.fitness_center_outlined, size: 24),
                backgroundColor: TColor.freshCyan, // Fresh cyan for vibrancy (FitOn-inspired)
                foregroundColor: TColor.white, // White
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
                backgroundColor: TColor.darkBeige, // Dark beige for subtle gradients (FitGlide custom)
                foregroundColor: TColor.white, // White
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
                backgroundColor: TColor.primaryRed, // Vibrant red for CTAs (FitOn-inspired)
                foregroundColor: TColor.white, // White
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
          SizedBox(width: 10), // Spacing between SpeedDial and Max
          GestureDetector(
            onTap: () {
              _showMaxDialogue(context); // Show dialogue on tap
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TColor.lightGray, // Light gray for cards (FitOn-inspired)
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TColor.darkRose.withOpacity(0.3)), // Dark rose border
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/img/max_avatar.png',
                width: 50, // Slightly smaller for navigation bar fit
                height: 50,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.person, color: TColor.darkRose, size: 50); // Dark rose fallback
                },
              ),
            ).animate(
              effects: [
                FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.8, 0.8), end: Offset(1.0, 1.0)),
                ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectTab,
        onTap: (index) {
          setState(() {
            selectTab = index;
          });
          _navigateToTab(index, context);
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
                FadeEffect(duration: 400.ms, curve: Curves.easeInOut),
                ShakeEffect(duration: 200.ms, curve: Curves.easeOut),
              ],
            ),
            activeIcon: Icon(Icons.home, color: TColor.darkRose, size: 28).animate( // Dark rose for navigation (FitOn-inspired)
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
                FadeEffect(duration: 400.ms, curve: Curves.easeInOut),
                ShakeEffect(duration: 200.ms, curve: Curves.easeOut),
              ],
            ),
            activeIcon: Icon(Icons.fitness_center, color: TColor.darkRose, size: 28).animate( // Dark rose for navigation (FitOn-inspired)
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
                FadeEffect(duration: 400.ms, curve: Curves.easeInOut),
                ShakeEffect(duration: 200.ms, curve: Curves.easeOut),
              ],
            ),
            activeIcon: Icon(Icons.restaurant, color: TColor.darkRose, size: 28).animate( // Dark rose for navigation (FitOn-inspired)
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
                FadeEffect(duration: 400.ms, curve: Curves.easeInOut),
                ShakeEffect(duration: 200.ms, curve: Curves.easeOut),
              ],
            ),
            activeIcon: Icon(Icons.nightlight_round, color: TColor.darkRose, size: 28).animate( // Dark rose for navigation (FitOn-inspired)
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
                FadeEffect(duration: 400.ms, curve: Curves.easeInOut),
                ShakeEffect(duration: 200.ms, curve: Curves.easeOut),
              ],
            ),
            activeIcon: Icon(Icons.person, color: TColor.darkRose, size: 28).animate( // Dark rose for navigation (FitOn-inspired)
              effects: [
                FadeEffect(duration: 300.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 300.ms, curve: Curves.easeInOut, begin: Offset(1.0, 1.0), end: Offset(1.1, 1.1)),
                ShakeEffect(duration: 200.ms, curve: Curves.easeOut),
              ],
            ),
            label: "Profile",
          ),
        ],
        selectedItemColor: TColor.darkRose, // Dark rose for navigation (FitOn-inspired)
        unselectedItemColor: TColor.gray,
        backgroundColor: TColor.white, // White
        elevation: 0, // Remove elevation to avoid white strip
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: TColor.darkRose),
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

  Widget _buildBodyForTab(int tabIndex, BuildContext context) {
    switch (tabIndex) {
      case 0: // Home
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section (Removed Max, Kept Welcome Message)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedTextKit(
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
                        SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: TColor.darkRose, // Dark rose for energy (FitOn-inspired)
                              child: Text(
                                firstName.isNotEmpty ? firstName[0] : "G",
                                style: TextStyle(color: TColor.white, fontSize: 24, fontWeight: FontWeight.bold),
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
                                    style: TextStyle(color: TColor.gray, fontSize: 16),
                                  ).animate(
                                    effects: [
                                      FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
                                      SlideEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(20, 0), end: Offset(0, 0)),
                                    ],
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    firstName,
                                    style: TextStyle(color: TColor.black, fontSize: 24, fontWeight: FontWeight.w800),
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
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      print("Notification tapped");
                    },
                    icon: Icon(Icons.notifications, color: TColor.darkRose, size: 30).animate(
                      effects: [
                        FadeEffect(duration: 600.ms, curve: Curves.easeInOut),
                        ScaleEffect(duration: 600.ms, curve: Curves.easeInOut, begin: Offset(0.8, 0.8), end: Offset(1.0, 1.0)),
                        ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),

              // Metrics Section (Single Row of 7 Smaller Cards, Full Screen Width with Scroll, Reduced Size, Boxing Style)
              SizedBox(
                height: 120, // Match height of all metrics cards
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _buildSmallMetricCard(
                        icon: Icons.fitness_center,
                        title: "Pending Exercises",
                        subtitle: upcomingWorkouts.isNotEmpty ? upcomingWorkouts.fold(0, (sum, workout) => sum + int.parse(workout['pendingExercises'] ?? '0')).toString() : "0",
                        gradient: [TColor.lightIndigo, TColor.primaryRed], // Fresh cyan to dark beige (FitOn-inspired)
                      ),
                      SizedBox(width: 10),
                      _buildSmallMetricCard(
                        icon: Icons.local_fire_department,
                        title: "Calories Burned",
                        subtitle: caloriesBurned != null ? "${caloriesBurned!.toStringAsFixed(0)} kCal" : "N/A",
                        gradient: [TColor.primaryRed, TColor.lightIndigo], // Primary red to fresh cyan (FitOn-inspired)
                      ),
                      SizedBox(width: 10),
                      _buildSmallMetricCard(
                        icon: Icons.directions_walk, // Steps Taken
                        title: "Steps Taken",
                        subtitle: stepsTaken != null ? "$stepsTaken steps" : "N/A",
                        gradient: [TColor.lightIndigo, TColor.primaryRed], // Dark beige to primary red (FitOn-inspired)
                      ),
                      SizedBox(width: 10),
                      _buildSmallHealthMetricCard(
                        title: "Water Intake",
                        content: _buildProgressIndicator(
                          title: "",
                          value: waterIntake.isNotEmpty ? (waterIntake.fold(0.0, (sum, item) => sum + double.parse(item['subtitle'].replaceAll('ml', '')) / 2000)) : 0.0,
                          goal: "2000ml",
                          color: TColor.primaryRed, // Fresh cyan for vibrancy (FitOn-inspired)
                        ),
                        color: TColor.primaryRed.withOpacity(0.2), // Subtle fresh cyan
                      ),
                      SizedBox(width: 10),
                      _buildSmallHealthMetricCard(
                        title: "Sleep",
                        content: _buildProgressIndicator(
                          title: "",
                          value: sleepDuration != "N/A" ? (double.tryParse(sleepDuration.replaceAll('h', '')) ?? 0) / 8 : 0.0,
                          goal: "8h",
                          color: TColor.primaryRed, // Dark beige for subtle gradients (FitGlide custom)
                        ),
                        color: TColor.primaryRed, // Subtle dark beige
                      ),
                      SizedBox(width: 10),
                      _buildSmallHealthMetricCard(
                        title: "Calories",
                        content: _buildProgressIndicator(
                          title: "",
                          value: caloriesConsumed != null ? (caloriesConsumed! / 2000) : 0.0,
                          goal: "2000kCal",
                          color: TColor.primaryRed, // Primary red for energy (FitOn-inspired)
                        ),
                        color: TColor.primaryRed.withOpacity(0.2), // Subtle primary red
                      ),
                      SizedBox(width: 10),
                      _buildSmallHealthMetricCard(
                        title: "Weight Loss",
                        content: _buildProgressIndicator(
                          title: "",
                          value: weightLossGoal != null ? (1 - (weightLossGoal! / 10)) : 0.0,
                          goal: "10kg",
                          color: TColor.primaryRed, // Dark beige for subtle gradients (FitGlide custom)
                        ),
                        color: TColor.primaryRed.withOpacity(0.2), // Subtle primary red
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

              // BMI Card (Boxing Style, Reduced Size)
              Container(
                width: MediaQuery.of(context).size.width, // Full screen width
                height: MediaQuery.of(context).size.height * 0.30, // Reduced height for BMI card
                decoration: BoxDecoration(
                  color: TColor.lightGray, // White background
                  borderRadius: BorderRadius.circular(15),
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
                        style: TextStyle(color: TColor.black, fontSize: 16, fontWeight: FontWeight.bold),
                      ).animate(
                        effects: [
                          FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
                          ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                          ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
                        ],
                      ),
                      SizedBox(height: 5),
                      Text(
                        bmiCategory.isNotEmpty ? bmiCategory : "No BMI data",
                        style: TextStyle(color: TColor.black, fontSize: 14, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 5),
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
                                GaugeRange(startValue: 0, endValue: 17.5, color: TColor.lightIndigo.withOpacity(0.8), startWidth: 8, endWidth: 8), // Fresh cyan
                                GaugeRange(startValue: 18.5, endValue: 24.9, color: TColor.darkBeige.withOpacity(0.8), startWidth: 8, endWidth: 8), // Dark beige
                                GaugeRange(startValue: 26.0, endValue: 40, color: TColor.primaryRed.withOpacity(0.8), startWidth: 8, endWidth: 8), // Primary red
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
                                    style: TextStyle(color: TColor.black, fontSize: 16, fontWeight: FontWeight.bold),
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
                  color: TColor.darkBeige.withOpacity(0.2), // Subtle dark beige
                ),
              ).animate(
                effects: [
                  FadeEffect(duration: 1200.ms, curve: Curves.easeInOut),
                  ScaleEffect(duration: 1200.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                  ShakeEffect(duration: 600.ms, curve: Curves.easeOut),
                ],
              ),
              SizedBox(height: 30),

              // Charts and Badges Section (Boxing Style)
              Container(
                decoration: BoxDecoration(
                  color: TColor.white, // White background
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(15),
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
                          color: TColor.lightGray, // Light gray for cards (FitOn-inspired)
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
        return Center(child: Text('Unknown Tab', style: TextStyle(color: TColor.black)));
    }
  }

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

  Widget _buildSmallMetricCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
  }) {
    return SizedBox(
      width: 160, // Match size of all metrics cards
      height: 120, // Match size of all metrics cards
      child: Container(
        decoration: BoxDecoration(
          color: TColor.lightGray, // Light gray background
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TColor.primaryRed, width: 1), // Red border
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 20), // Black icon
            SizedBox(height: 5),
            Text(
              title,
              style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold), // Black text
            ),
            SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(color: Colors.black54, fontSize: 12), // Slightly faded black for subtitle
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
    return SizedBox(
      width: 140,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: TColor.white,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title.isNotEmpty)
              Text(
                title,
                style: TextStyle(color: TColor.black, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            SizedBox(height: 4),
            LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              backgroundColor: TColor.lightGray,
              color: color,
              minHeight: 4,
            ),
            SizedBox(height: 4),
            Text(
              "${(value * 100).toStringAsFixed(0)}% of $goal",
              style: TextStyle(color: TColor.gray, fontSize: 10), // Gray for text (FitOn-inspired)
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
    return SizedBox(
      width: 120,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: TColor.white,
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
              badge['icon'] ?? 'assets/img/default_meal.png', // Fallback to default_meal.png if badge icon fails
              width: 20,
              height: 20,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.star, color: TColor.darkRose, size: 20); // Dark rose fallback (FitOn-inspired)
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
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(color: TColor.black, fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 5),
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

  Widget _buildBMIMetricCard({required Widget content, required Color color}) {
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
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 5),
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

  void _showMaxDialogue(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TColor.lightGray, // Light gray for cards (FitOn-inspired)
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: TColor.darkRose, width: 1), // Dark rose border
        ),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/img/max_avatar.png',
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.person, color: TColor.darkRose, size: 50); // Dark rose fallback
                    },
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      maxRecommendation ?? 'Hey, I’m Max! No recommendation available right now, but I’m here to help! Add credits to enable full AI features.',
                      style: TextStyle(color: TColor.black, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/img/max_avatar.png',
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.person, color: TColor.darkRose, size: 50); // Dark rose fallback
                    },
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      maxTip ?? 'Hey, I’m Max! No tip available, but let’s get moving! Add credits to enable full AI features.',
                      style: TextStyle(color: TColor.black, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: TColor.darkRose, fontSize: 16),
            ),
          ),
        ],
      ),
    ).then((_) {
      // Optional: Re-trigger recommendations after closing to ensure freshness
      _getMaxRecommendations();
    });
  }
}
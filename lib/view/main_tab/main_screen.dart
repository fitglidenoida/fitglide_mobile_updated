import 'package:fitglide_mobile_application/common_widget/round_button.dart';
import 'package:fitglide_mobile_application/common_widget/round_textfield.dart';
import 'package:fitglide_mobile_application/services/ai_service.dart';
import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:fitglide_mobile_application/services/user_service.dart'; // Add this import
import 'package:fitglide_mobile_application/view/meal_planner/meal_planner_view.dart';
import 'package:fitglide_mobile_application/view/profile/profile_view.dart';
import 'package:fitglide_mobile_application/view/sleep_tracker/sleep_tracker_view.dart';
import 'package:fitglide_mobile_application/view/workout_tracker/add_schedule_view.dart';
import 'package:fitglide_mobile_application/view/workout_tracker/workout_hub_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../common/colo_extension.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DataService {
  Future<Map<String, dynamic>> fetchUserDetails() async {
    final response = await ApiService.get('users/me?populate=*');
    return response;
  }

  Future<List<Map<String, dynamic>>> fetchHealthVitals(String username) async {
    final response = await ApiService.get('health-vitals?filters[username][username][\$eq]=$username');
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
  bool showProfilePrompt = false;

  List<Map<String, dynamic>> upcomingWorkouts = [];
  List<Map<String, dynamic>> waterIntake = [];
  List<FlSpot> heartRateSpots = [];
  List<Map<String, dynamic>> badges = [];
  List<Map<String, dynamic>> recentActivities = [];

  String heartRate = "N/A";
  String sleepDuration = "N/A";
  double? caloriesBurned;
  double? caloriesConsumed;
  double? weightLossGoal;
  int? stepsTaken;

  LineChartData lineChartData = LineChartData(
    gridData: FlGridData(show: false),
    titlesData: FlTitlesData(
      bottomTitles: AxisTitles(
          sideTitles: SideTitles(
              reservedSize: 30,
              getTitlesWidget: (value, meta) => Text('${value.toInt() + 1}d',
                  style: TextStyle(color: TColor.textSecondary, fontSize: 12)))),
      leftTitles: AxisTitles(
          sideTitles: SideTitles(
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}',
                  style: TextStyle(color: TColor.textSecondary, fontSize: 12)))),
      topTitles: const AxisTitles(),
      rightTitles: const AxisTitles(),
    ),
    borderData: FlBorderData(show: true, border: Border.all(color: TColor.textSecondary.withOpacity(0.2))),
    lineBarsData: [
      LineChartBarData(
        spots: List.generate(7, (i) => FlSpot(i.toDouble(), 60.0)),
        isCurved: true,
        barWidth: 3,
        color: TColor.primary,
        belowBarData: BarAreaData(show: true, color: TColor.primary.withOpacity(0.1)),
        dotData: FlDotData(show: true),
      ),
    ],
    minX: 0,
    maxX: 6,
    minY: 0,
    maxY: 100,
  );

  String? maxRecommendation;
  String? maxTip;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    _checkProfileCompletion();
    _getMaxRecommendations();
  }

  Future<void> _checkProfileCompletion() async {
    final userData = await UserService.fetchUserData();
    if (userData.heightCm == null || userData.weightKg == null || userData.dateOfBirth == null) {
      setState(() {
        showProfilePrompt = true;
      });
    }
  }

Future<void> fetchUserData() async {
  try {
    setState(() => isLoading = true);
    final userData = await UserService.fetchUserData();
    debugPrint('Raw user data: $userData'); // Log the raw response
    setState(() {
      firstName = userData.firstName ?? "Guest"; // Fallback if null
      username = userData.username ?? "";
      bmi = userData.bmi;
      bmiCategory = userData.bmi != null ? userData.interpretBMI(userData.bmi!) : "Add Data";
      weightLossGoal = userData.weightLossGoal; // Assign weightLossGoal from UserService
      debugPrint('Parsed: firstName=$firstName, username=$username, bmi=$bmi, weightLossGoal=$weightLossGoal'); // Log parsed values
    });

    if (username.isNotEmpty) {
      await Future.wait([
        fetchUpcomingWorkouts(username),
        fetchActivityMetrics(username),
        fetchDietData(username),
        fetchSleepData(username),
        fetchTrendData(username),
        fetchBadges(username),
        fetchRecentActivities(username),
      ]);
    }
  } catch (e) {
    debugPrint('Error fetching user data: $e');
    setState(() {
      firstName = "Guest";
      username = "";
      weightLossGoal = null; // Reset on error
    });
  } finally {
    if (mounted) setState(() => isLoading = false);
  }
}

  Future<void> _updateProfile(Map<String, dynamic> vitals) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await UserService.getUserId(); // Use user ID from UserService

    final data = {
      "data": {
        "WeightInKilograms": double.tryParse(vitals['weight'] ?? ""),
        "height": double.tryParse(vitals['height'] ?? ""),
        "date_of_birth": vitals['dateOfBirth'],
        "fitness_goals": vitals['goal'],
        "username": userId, // Use username as a string, not connect syntax
      }
    };

    await ApiService.post('health-vitals', data);
    await fetchUserData(); // Refresh data
    setState(() => showProfilePrompt = false);
  }

  Future<void> fetchUpcomingWorkouts(String username) async {
    try {
      final response = await ApiService.fetchWorkoutPlans(username);
      final workoutData = response['data'] as List<dynamic>? ?? [];
      if (workoutData.isNotEmpty) {
        final now = DateTime.now().toLocal();
        final todayStart = DateTime(now.year, now.month, now.day).toLocal();
        setState(() {
          upcomingWorkouts = workoutData
              .where((w) => DateTime.parse(w['attributes']['scheduled_date'])
                  .toLocal()
                  .isAfter(todayStart))
              .take(3)
              .map((workout) {
            final exercises = workout['attributes']['exercises']?['data'] as List<dynamic>? ?? [];
            final pendingExercises =
                exercises.where((e) => (e['completed'] as bool? ?? false) == false).length;
            final totalKcal = exercises.fold<int>(
                0,
                (sum, e) =>
                    sum + (e['calories_per_minute'] as int? ?? 0) * (e['duration'] as int? ?? 0));
            final totalTime =
                exercises.fold<int>(0, (sum, e) => sum + (e['duration'] as int? ?? 0));
            final scheduledDate = DateTime.parse(
                workout['attributes']['scheduled_date'] ?? DateTime.now().toIso8601String()).toLocal();
            final dateFormatter = DateFormat('dd/MM/yyyy hh:mm a');
            return {
              "name": workout['attributes']['Title'] as String? ?? 'Untitled Workout',
              "image": "assets/img/Workout${(workoutData.indexOf(workout) % 3) + 1}.png",
              "pendingExercises": pendingExercises.toString(),
              "kcal": totalKcal.toString(),
              "time": totalTime.toString(),
              "date": dateFormatter.format(scheduledDate),
              "documentId": workout['id'].toString(),
              "fitness_goals": workout['attributes']['fitness_goals'] ?? [],
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching upcoming workouts: $e');
    }
  }

  Future<void> fetchActivityMetrics(String username) async {
    try {
      final response = await ApiService.fetchActivityMetrics(username);
      final activityData = response['data'] as List<dynamic>? ?? [];
      if (activityData.isNotEmpty) {
        final latestActivity = activityData.first['attributes'];
        setState(() {
          stepsTaken = (latestActivity['steps'] as num?)?.toInt() ?? 0;
          caloriesBurned = (latestActivity['calories'] as num?)?.toDouble(); // Assuming Strava provides this
          heartRate = (latestActivity['heart_rate'] as num?)?.toInt() != null
              ? "${latestActivity['heart_rate']} BPM"
              : "N/A";
        });
      }
    } catch (e) {
      debugPrint('Error fetching activity metrics: $e');
    }
  }

  Future<void> fetchDietData(String username) async {
    try {
      final now = DateTime.now().toLocal();
      final todayStart = DateTime(now.year, now.month, now.day).toLocal();
      final todayEnd = todayStart.add(const Duration(days: 1));

      final mealResponse = await ApiService.fetchDietPlans(username);
      final mealPlans = mealResponse['data'] as List<dynamic>? ?? [];
      caloriesConsumed = 0.0;
      for (var plan in mealPlans) {
        final meals = plan['attributes']['meals']?['data'] as List<dynamic>? ?? [];
        for (var meal in meals) {
          final mealDate = DateTime.parse(
              meal['attributes']['meal_date'] ?? DateTime.now().toIso8601String()).toLocal();
          if (mealDate.isAfter(todayStart) && mealDate.isBefore(todayEnd)) {
            final dietComponents =
                meal['attributes']['diet_components']?['data'] as List<dynamic>? ?? [];
            caloriesConsumed = dietComponents.fold<double>(
                caloriesConsumed ?? 0,
                (sum, c) =>
                    sum +
                    ((c['attributes']['consumed'] as bool? ?? false)
                        ? (c['attributes']['calories'] as int? ?? 0)
                        : 0).toDouble());
          }
        }
      }
      setState(() {});
    } catch (e) {
      debugPrint('Error fetching diet data: $e');
    }
  }

Future<void> fetchSleepData(String username) async {
  try {
    final sleepData = await ApiService.getSleepLogs(username); // Returns List<Map<String, dynamic>>
    if (sleepData.isNotEmpty) {
      final latestSleep = sleepData.first['attributes'] ?? sleepData.first; // Fallback if no 'attributes'
      setState(() {
        final sleepDurationValue = (latestSleep['sleep_duration'] as num?)?.toDouble();
        sleepDuration = sleepDurationValue != null ? "${sleepDurationValue.toStringAsFixed(1)}h" : "N/A";
      });
    }
  } catch (e) {
    debugPrint('Error fetching sleep data: $e');
    setState(() {
      sleepDuration = "N/A"; // Ensure fallback in case of error
    });
  }
}

  Future<void> fetchWaterIntake(String username) async {
    try {
      final healthVitalsList = await DataService().fetchHealthVitals(username);
      if (healthVitalsList.isNotEmpty && healthVitalsList.first['attributes']['water_intake'] != null) {
        final totalWater = (healthVitalsList.first['attributes']['water_intake'] as num).toDouble();
        setState(() {
          waterIntake = [
            {"title": "6am - 8am", "subtitle": "${(totalWater * 0.2).toStringAsFixed(1)}ml"},
            {"title": "9am - 11am", "subtitle": "${(totalWater * 0.15).toStringAsFixed(1)}ml"},
            {"title": "11am - 2pm", "subtitle": "${(totalWater * 0.3).toStringAsFixed(1)}ml"},
            {"title": "2pm - 4pm", "subtitle": "${(totalWater * 0.15).toStringAsFixed(1)}ml"},
            {"title": "4pm - now", "subtitle": "${(totalWater * 0.2).toStringAsFixed(1)}ml"},
          ];
        });
      }
    } catch (e) {
      debugPrint('Error fetching water intake: $e');
    }
  }

  Future<void> fetchTrendData(String username) async {
    try {
      final activityData = await ApiService.fetchActivityMetrics(username);
      final activities = activityData['data'] as List<dynamic>? ?? [];
      if (activities.isNotEmpty) {
        setState(() {
          heartRateSpots = List.generate(
            7,
            (i) => FlSpot(
              i.toDouble(),
              i < activities.length
                  ? (activities[i]['attributes']['heart_rate'] as num?)?.toDouble() ?? 60.0
                  : 60.0,
            ),
          );
          lineChartData = LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) => Text('${value.toInt() + 1}d',
                          style: TextStyle(color: TColor.textSecondary, fontSize: 12)))),
              leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text('${value.toInt()}',
                          style: TextStyle(color: TColor.textSecondary, fontSize: 12)))),
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
            ),
            borderData: FlBorderData(
                show: true, border: Border.all(color: TColor.textSecondary.withOpacity(0.2))),
            lineBarsData: [
              LineChartBarData(
                spots: heartRateSpots,
                isCurved: true,
                barWidth: 3,
                color: TColor.primary,
                belowBarData: BarAreaData(show: true, color: TColor.primary.withOpacity(0.1)),
                dotData: FlDotData(show: true),
              ),
            ],
            minX: 0,
            maxX: 6,
            minY: 0,
            maxY: 100,
          );
        });
      }
    } catch (e) {
      debugPrint('Error fetching trend data: $e');
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

Future<void> fetchRecentActivities(String username) async {
  try {
    final workoutResponse = await ApiService.fetchWorkoutPlans(username); // Returns Map<String, dynamic>
    final mealResponse = await ApiService.fetchDietPlans(username);       // Returns Map<String, dynamic>
    final sleepResponse = await ApiService.getSleepLogs(username);       // Returns List<Map<String, dynamic>>

    List<Map<String, dynamic>> activities = [
      ...(workoutResponse['data'] as List<dynamic>? ?? []).map((w) => ({
            'type': 'Workout',
            'title': w['attributes']['Title'] ?? 'Untitled',
            'time': DateTime.parse(
                w['attributes']['scheduled_date'] ?? DateTime.now().toIso8601String()).toLocal(),
          })),
      ...(mealResponse['data'] as List<dynamic>? ?? [])
          .expand((m) => (m['attributes']['meals']?['data'] as List<dynamic>? ?? [])
              .map((meal) => ({
                    'type': 'Meal',
                    'title': meal['attributes']['meal_type'] ?? 'Meal',
                    'time': DateTime.parse(
                        meal['attributes']['meal_date'] ?? DateTime.now().toIso8601String()).toLocal(),
                  }))),
      ...(sleepResponse as List<dynamic>).map((s) => ({
            'type': 'Sleep',
            'title': 'Sleep Log',
            'time': DateTime.parse(
                s['attributes']['createdAt'] ?? DateTime.now().toIso8601String()).toLocal(),
          })),
    ];

    activities.sort((a, b) => b['time'].compareTo(a['time']));
    setState(() {
      recentActivities = activities.take(3).toList();
    });
  } catch (e) {
    debugPrint('Error fetching recent activities: $e');
    setState(() => recentActivities = []);
  }
}

  Future<void> fetchWeightLossGoal(String username) async {
    try {
      final healthVitalsList = await DataService().fetchHealthVitals(username);
      if (healthVitalsList.isNotEmpty) {
        final vitalData = healthVitalsList[0]['attributes'];
        final initialWeight = (vitalData['WeightInKilograms'] as num?)?.toDouble() ?? 0.0;
        final targetWeight = (vitalData['target_weight'] as num?)?.toDouble() ?? 0.0;
        setState(() {
          weightLossGoal = initialWeight > targetWeight ? initialWeight - targetWeight : null;
        });
      }
    } catch (e) {
      debugPrint('Error fetching weight loss goal: $e');
    }
  }

  Future<List<SpeedDialChild>> _getDynamicFABOptions() async {
    final now = DateTime.now().hour;
    final healthVitalsList = await DataService().fetchHealthVitals(username);
    final waterLow =
        healthVitalsList.isNotEmpty && ((healthVitalsList[0]['attributes']['water_intake'] as num?)?.toDouble() ?? 0) < 1000;
    final sleepLow =
        sleepDuration != "N/A" && (double.tryParse(sleepDuration.replaceAll('h', '')) ?? 0) < 6;

    List<SpeedDialChild> options = [
      SpeedDialChild(
        child: const Icon(Icons.fitness_center_outlined, size: 24),
        backgroundColor: TColor.accent2,
        foregroundColor: TColor.textPrimaryDark,
        label: 'Workout',
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => AddScheduleView(date: DateTime.now()))),
      ),
      SpeedDialChild(
        child: const Icon(Icons.restaurant_menu, size: 24),
        backgroundColor: TColor.accent1,
        foregroundColor: TColor.textPrimaryDark,
        label: 'Meal',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MealPlannerView())),
      ),
    ];

    if (waterLow) {
      options.add(SpeedDialChild(
        child: const Icon(Icons.local_drink, size: 24),
        backgroundColor: TColor.accent2,
        foregroundColor: TColor.textPrimaryDark,
        label: 'Log Water',
        onTap: () => debugPrint("Log water tapped"),
      ));
    }
    if (now >= 20 && sleepLow) {
      options.add(SpeedDialChild(
        child: const Icon(Icons.bedtime, size: 24),
        backgroundColor: TColor.secondary,
        foregroundColor: TColor.textPrimaryDark,
        label: 'Add Sleep',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SleepTrackerView())),
      ));
    }
    return options;
  }

  Future<void> _getMaxRecommendations() async {
    try {
      final context = {
        'user': {'firstName': firstName, 'username': username},
        'recentWorkouts': upcomingWorkouts,
        'fitnessGoals': upcomingWorkouts.isNotEmpty ? (upcomingWorkouts[0]['fitness_goals'] as List<dynamic>).join(', ') : 'N/A',
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
          'Provide fitness progress recommendation for user', contextData: context, useDatabase: true);
      maxTip = await AiService.getMaxRecommendation(
          'Quick tip for user fitness goals: ${context['fitnessGoals']}', contextData: context, useDatabase: true);
      setState(() {});
    } catch (e) {
      debugPrint('Error getting Max’s recommendations: $e');
      setState(() {
        maxRecommendation = "Hey, I’m Max—No recommendation available right now!";
        maxTip = "Hey, I’m Max—No tip available, but let’s get moving!";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: TColor.backgroundLight,
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                      textStyle: TextStyle(
                                          color: TColor.textPrimary,
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold),
                                      speed: const Duration(milliseconds: 100),
                                    )
                                  ],
                                  totalRepeatCount: 1,
                                ).animate(
                                  effects: [
                                    FadeEffect(duration: 800.ms),
                                    ScaleEffect(
                                        duration: 800.ms,
                                        begin: Offset(0.9, 0.9),
                                        end: Offset(1.0, 1.0)),
                                  ],
                                ),
                                SizedBox(height: 20),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundColor: TColor.primary,
                                      child: Text(
                                        firstName.isNotEmpty ? firstName[0] : "G",
                                        style: TextStyle(
                                            color: TColor.textPrimaryDark,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ).animate(
                                      effects: [
                                        FadeEffect(duration: 800.ms),
                                        ScaleEffect(
                                            duration: 800.ms,
                                            begin: Offset(0.8, 0.8),
                                            end: Offset(1.0, 1.0)),
                                      ],
                                    ),
                                    SizedBox(width: 15),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Welcome Back,",
                                            style: TextStyle(
                                                color: TColor.textSecondary, fontSize: 16),
                                          ).animate(
                                            effects: [
                                              FadeEffect(duration: 800.ms),
                                              SlideEffect(
                                                  duration: 800.ms,
                                                  begin: Offset(20, 0),
                                                  end: Offset(0, 0)),
                                            ],
                                          ),
                                          SizedBox(height: 5),
                                          Text(
                                            firstName,
                                            style: TextStyle(
                                                color: TColor.textPrimary,
                                                fontSize: 24,
                                                fontWeight: FontWeight.w800),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ).animate(
                                            effects: [
                                              FadeEffect(duration: 800.ms),
                                              ScaleEffect(
                                                  duration: 800.ms,
                                                  begin: Offset(0.9, 0.9),
                                                  end: Offset(1.0, 1.0)),
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
                            onPressed: () => debugPrint("Notification tapped"),
                            icon: Icon(Icons.notifications, color: TColor.primary, size: 30).animate(
                              effects: [
                                FadeEffect(duration: 600.ms),
                                ScaleEffect(
                                    duration: 600.ms, begin: Offset(0.8, 0.8), end: Offset(1.0, 1.0)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 30),
                      GridView.count(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.3,
                        children: [
                          _buildSmallMetricCard(
                              icon: Icons.fitness_center,
                              title: "Pending Exercises",
                              subtitle: upcomingWorkouts.isNotEmpty
                                  ? upcomingWorkouts
                                      .fold(
                                          0,
                                          (sum, w) =>
                                              sum + int.parse(w['pendingExercises'] ?? '0'))
                                      .toString()
                                  : "0",
                              gradient: [TColor.secondary, TColor.primary]),
                          _buildSmallMetricCard(
                              icon: Icons.local_fire_department,
                              title: "Calories Burned",
                              subtitle: caloriesBurned != null
                                  ? "${caloriesBurned!.toStringAsFixed(0)} kCal"
                                  : "Add Data",
                              gradient: [TColor.primary, TColor.accent2]),
                          _buildSmallMetricCard(
                              icon: Icons.directions_walk,
                              title: "Steps Taken",
                              subtitle: stepsTaken != null ? "$stepsTaken steps" : "Add Data",
                              gradient: [TColor.accent2, TColor.primary]),
                          _buildSmallMetricCard(
                              icon: Icons.local_drink,
                              title: "Water Intake",
                              subtitle: waterIntake.isNotEmpty
                                  ? "${waterIntake.fold(0.0, (sum, w) => sum + double.parse(w['subtitle'].replaceAll('ml', ''))).toStringAsFixed(0)}ml"
                                  : "Add Data",
                              gradient: [TColor.accent2, TColor.secondary]),
                          _buildSmallMetricCard(
                              icon: Icons.nightlight_round,
                              title: "Sleep",
                              subtitle: sleepDuration != "N/A" ? sleepDuration : "Add Data",
                              gradient: [TColor.secondary, TColor.accent1]),
                          _buildSmallMetricCard(
                              icon: Icons.restaurant,
                              title: "Calories Consumed",
                              subtitle: caloriesConsumed != null
                                  ? "${caloriesConsumed!.toStringAsFixed(0)} kCal"
                                  : "Add Data",
                              gradient: [TColor.accent1, TColor.primary]),
                          _buildSmallMetricCard(
                              icon: Icons.favorite,
                              title: "Heart Rate",
                              subtitle: heartRate != "N/A" ? heartRate : "Add Data",
                              gradient: [TColor.primary, TColor.accent2]),
                          _buildSmallMetricCard(
                              icon: Icons.scale,
                              title: "Weight Loss",
                              subtitle: weightLossGoal != null ? "${weightLossGoal!.toStringAsFixed(1)} kg" : "Add Data",
                              gradient: [TColor.accent1, TColor.secondary]),
                        ],
                      ),
                      SizedBox(height: 20),
                      if (showProfilePrompt) _buildProfileSetupCard(),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              color: TColor.cardLight,
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  children: [
                                    Text("Steps",
                                        style: TextStyle(
                                            color: TColor.textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 10),
                                    SizedBox(
                                      width: 100,
                                      height: 100,
                                      child: SfRadialGauge(
                                        axes: [
                                          RadialAxis(
                                            minimum: 0,
                                            maximum: 10000,
                                            showLabels: false,
                                            showTicks: false,
                                            ranges: [
                                              GaugeRange(
                                                  startValue: 0,
                                                  endValue: 10000,
                                                  color: TColor.accent2.withOpacity(0.3))
                                            ],
                                            pointers: [
                                              NeedlePointer(
                                                  value: stepsTaken?.toDouble() ?? 0,
                                                  needleColor: TColor.accent2)
                                            ],
                                            annotations: [
                                              GaugeAnnotation(
                                                  widget: Text(stepsTaken?.toString() ?? "0",
                                                      style:
                                                          TextStyle(color: TColor.textPrimary)),
                                                  angle: 90,
                                                  positionFactor: 0.5)
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Card(
                              color: TColor.cardLight,
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  children: [
                                    Text("BMI",
                                        style: TextStyle(
                                            color: TColor.textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 10),
                                    SizedBox(
                                      width: 100,
                                      height: 100,
                                      child: SfRadialGauge(
                                        axes: [
                                          RadialAxis(
                                            minimum: 0,
                                            maximum: 40,
                                            showLabels: false,
                                            showTicks: false,
                                            startAngle: 135,
                                            endAngle: 45,
                                            ranges: [
                                              GaugeRange(
                                                  startValue: 0,
                                                  endValue: 18.5,
                                                  color: TColor.accent2.withOpacity(0.8)),
                                              GaugeRange(
                                                  startValue: 18.5,
                                                  endValue: 24.9,
                                                  color: TColor.accent1.withOpacity(0.8)),
                                              GaugeRange(
                                                  startValue: 24.9,
                                                  endValue: 40,
                                                  color: TColor.primary.withOpacity(0.8)),
                                            ],
                                            pointers: [
                                              NeedlePointer(
                                                  value: bmi ?? 24.5, needleColor: TColor.secondary)
                                            ],
                                            annotations: [
                                              GaugeAnnotation(
                                                  widget: Text(bmi?.toStringAsFixed(1) ?? "N/A",
                                                      style:
                                                          TextStyle(color: TColor.textPrimary)),
                                                  angle: 90,
                                                  positionFactor: 0.5)
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: ListView(
                          scrollDirection: Axis.vertical,
                          children: [
                            Card(
                              color: TColor.cardLight,
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Recent Activity",
                                        style: TextStyle(
                                            color: TColor.textPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 10),
                                    ...recentActivities.map((activity) => ListTile(
                                          leading: Icon(
                                              activity['type'] == 'Workout'
                                                  ? Icons.fitness_center
                                                  : activity['type'] == 'Meal'
                                                      ? Icons.restaurant
                                                      : Icons.nightlight_round,
                                              color: TColor.primary),
                                          title: Text(activity['title'],
                                              style: TextStyle(color: TColor.textPrimary)),
                                          subtitle: Text(
                                              DateFormat('dd/MM hh:mm a').format(activity['time']),
                                              style: TextStyle(color: TColor.textSecondary)),
                                        )),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Card(
                              color: TColor.cardLight,
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Health Trends",
                                        style: TextStyle(
                                            color: TColor.textPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 10),
                                    SizedBox(height: 180, child: LineChart(lineChartData)),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Card(
                              color: TColor.cardLight,
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Badges",
                                        style: TextStyle(
                                            color: TColor.textPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 10),
                                    Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: badges.map((badge) => _buildBadge(badge)).toList()),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FutureBuilder<List<SpeedDialChild>>(
        future: _getDynamicFABOptions(),
        builder: (context, snapshot) => snapshot.hasData
            ? Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SpeedDial(
                    icon: Icons.add,
                    activeIcon: Icons.close,
                    backgroundColor: TColor.primary,
                    foregroundColor: TColor.textPrimaryDark,
                    elevation: 8,
                    children: snapshot.data!,
                  ).animate(
                      effects: [
                        FadeEffect(duration: 800.ms),
                        ScaleEffect(
                            duration: 800.ms, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                      ]),
                  SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _showMaxDialogue(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: TColor.cardLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: TColor.primary.withOpacity(0.3))),
                      child: Image.asset('assets/img/max_avatar.png',
                          width: 50,
                          height: 50,
                          errorBuilder: (_, __, ___) =>
                              Icon(Icons.person, color: TColor.primary, size: 50)),
                    ).animate(
                        effects: [
                          FadeEffect(duration: 800.ms),
                          ScaleEffect(
                              duration: 800.ms, begin: Offset(0.8, 0.8), end: Offset(1.0, 1.0)),
                        ]),
                  ),
                ],
              )
            : SizedBox(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectTab,
        onTap: (index) {
          setState(() => selectTab = index);
          _navigateToTab(index, context);
        },
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined, size: 28),
              activeIcon: Icon(Icons.home, color: TColor.primary, size: 28),
              label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_outlined, size: 28),
              activeIcon: Icon(Icons.fitness_center, color: TColor.primary, size: 28),
              label: "Workout"),
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu, size: 28),
              activeIcon: Icon(Icons.restaurant, color: TColor.primary, size: 28),
              label: "Meal"),
          BottomNavigationBarItem(
              icon: Icon(Icons.bedtime, size: 28),
              activeIcon: Icon(Icons.nightlight_round, color: TColor.primary, size: 28),
              label: "Sleep"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 28),
              activeIcon: Icon(Icons.person, color: TColor.primary, size: 28),
              label: "Profile"),
        ],
        selectedItemColor: TColor.primary,
        unselectedItemColor: TColor.textSecondary,
        backgroundColor: TColor.backgroundLight,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 14),
      ).animate(
          effects: [
            FadeEffect(duration: 800.ms),
            ScaleEffect(duration: 800.ms, begin: Offset(0.95, 0.95), end: Offset(1.0, 1.0)),
          ]),
    );
  }

  Widget _buildSmallMetricCard(
      {required IconData icon, required String title, required String subtitle, required List<Color> gradient}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: TColor.textPrimaryDark, size: 24),
            SizedBox(height: 5),
            Text(title,
                style: TextStyle(
                    color: TColor.textPrimaryDark, fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text(subtitle, style: TextStyle(color: TColor.textPrimaryDark, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(Map<String, dynamic> badge) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: TColor.cardLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: TColor.primary.withOpacity(0.3))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(badge['icon'] ?? 'assets/img/default_meal.png',
              width: 20,
              height: 20,
              errorBuilder: (_, __, ___) => Icon(Icons.star, color: TColor.primary, size: 20)),
          SizedBox(width: 8),
          Text(badge['title'], style: TextStyle(color: TColor.textPrimary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildProfileSetupCard() {
    final TextEditingController weightController = TextEditingController();
    final TextEditingController heightController = TextEditingController();
    final TextEditingController dateController = TextEditingController();
    String? selectedGoal;

    return Card(
      color: TColor.cardLight,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset('assets/img/max_avatar.png',
                    width: 40,
                    height: 40,
                    errorBuilder: (_, __, ___) => Icon(Icons.person, color: TColor.primary, size: 40)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Hey $firstName, let’s glide to your goals—add your stats!",
                    style: TextStyle(color: TColor.textPrimary, fontSize: 16),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            RoundTextField(
              controller: weightController,
              hitText: "Weight (kg)",
              icon: "assets/img/weight.png",
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            RoundTextField(
              controller: heightController,
              hitText: "Height (cm)",
              icon: "assets/img/hight.png",
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                );
                if (pickedDate != null) {
                  dateController.text =
                      "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                }
              },
              child: AbsorbPointer(
                child: RoundTextField(
                  controller: dateController,
                  hitText: "Date of Birth (dd/mm/yyyy)",
                  icon: "assets/img/date.png",
                ),
              ),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedGoal,
              hint: Text("Select Your Goal", style: TextStyle(color: TColor.gray)),
              items: ["Body Transformation", "Strength Unleashed", "Weight Loss"]
                  .map((goal) => DropdownMenuItem(value: goal, child: Text(goal)))
                  .toList(),
              onChanged: (value) => selectedGoal = value,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                filled: true,
                fillColor: TColor.lightGray,
              ),
            ),
            SizedBox(height: 10),
            RoundButton(
              title: "Save",
              onPressed: () {
                _updateProfile({
                  'weight': weightController.text,
                  'height': heightController.text,
                  'dateOfBirth': dateController.text,
                  'goal': selectedGoal ?? "Weight Loss",
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMaxDialogue(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TColor.cardLight,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15), side: BorderSide(color: TColor.primary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Image.asset('assets/img/max_avatar.png',
                    width: 50,
                    height: 50,
                    errorBuilder: (_, __, ___) => Icon(Icons.person, color: TColor.primary, size: 50)),
                SizedBox(width: 10),
                Expanded(
                    child: Text(maxRecommendation ?? 'Hey, I’m Max! No recommendation available.',
                        style: TextStyle(color: TColor.textPrimary))),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Image.asset('assets/img/max_avatar.png',
                    width: 50,
                    height: 50,
                    errorBuilder: (_, __, ___) => Icon(Icons.person, color: TColor.primary, size: 50)),
                SizedBox(width: 10),
                Expanded(
                    child: Text(maxTip ?? 'Hey, I’m Max! No tip available.',
                        style: TextStyle(color: TColor.textPrimary))),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close", style: TextStyle(color: TColor.primary)))
        ],
      ),
    ).then((_) => _getMaxRecommendations());
  }

  void _navigateToTab(int index, BuildContext context) {
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const WorkoutHubView()));
        break;
      case 2:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const MealPlannerView()));
        break;
      case 3:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const SleepTrackerView()));
        break;
      case 4:
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const ProfileView()));
        break;
    }
  }
}
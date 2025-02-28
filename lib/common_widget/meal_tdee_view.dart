import 'package:flutter/material.dart';
import 'package:fitglide_mobile_application/services/bmr_tdee_service.dart';
import 'package:fitglide_mobile_application/services/diet_service.dart';
import 'package:fitglide_mobile_application/services/user_service.dart';
import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:fitglide_mobile_application/common/colo_extension.dart';
import 'package:fitglide_mobile_application/common_widget/round_button.dart';
import 'package:fitglide_mobile_application/view/meal_planner/meal_schedule_view.dart';

class MealTdeeView extends StatefulWidget {
  final double maintainTdee;

  const MealTdeeView({super.key, required this.maintainTdee});

  @override
  State<MealTdeeView> createState() => _MealTdeeViewState();
}

class _MealTdeeViewState extends State<MealTdeeView> {
  Future<Map<String, double>>? tdeeOptionsFuture; // Changed to nullable Future

  @override
  void initState() {
    super.initState();
    _determineActivityLevelAndFetchTdee();
  }

  Future<void> _determineActivityLevelAndFetchTdee() async {
    final tdeeService = BmrTdeeService();
    String activityLevel = 'sedentary'; // Default

    try {
      final user = await UserService.fetchUserData();
      final workoutResponse = await ApiService.fetchWorkoutPlans(user.username);
      final workouts = workoutResponse['data'] as List<dynamic>? ?? [];
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 7));

      final weeklyWorkouts = workouts.where((w) {
        final scheduledDate = DateTime.parse(w['scheduled_date'] as String);
        return scheduledDate.isAfter(weekStart) && scheduledDate.isBefore(weekEnd);
      }).toList();

      final workoutCount = weeklyWorkouts.length;
      if (workoutCount >= 5) {
        activityLevel = 'very active';
      } else if (workoutCount >= 3) {
        activityLevel = 'moderately active';
      } else if (workoutCount >= 1) {
        activityLevel = 'lightly active';
      }
      debugPrint('Workout count: $workoutCount, Activity level: $activityLevel');
    } catch (e) {
      debugPrint('Error fetching workout data: $e');
    }

    setState(() {
      tdeeOptionsFuture = Future.value(tdeeService.calculateTDEEOptions(widget.maintainTdee, activityLevel));
    });
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.white,
        centerTitle: true,
        elevation: 0,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TColor.lightGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              "assets/img/black_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          "Calories Overview",
          style: TextStyle(color: TColor.black, fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      backgroundColor: TColor.white,
      body: tdeeOptionsFuture == null
          ? const Center(child: CircularProgressIndicator()) // Show loading if future is null
          : FutureBuilder<Map<String, double>>(
              future: tdeeOptionsFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tdeeOptions = snapshot.data!;
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 50,
                              height: 4,
                              decoration: BoxDecoration(
                                color: TColor.gray.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: media.width * 0.05),
                        Text(
                          "Your Calorie Goals",
                          style: TextStyle(
                            color: TColor.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: media.width * 0.05),
                        _buildTdeeSection(context, "Maintain Weight", tdeeOptions['maintain']!),
                        _buildTdeeSection(context, "Weight Loss", tdeeOptions['loss_250g']!, tdeeOptions['loss_500g']!),
                        _buildTdeeSection(context, "Weight Gain", tdeeOptions['gain_250g']!, tdeeOptions['gain_500g']!),
                        SizedBox(height: media.width * 0.05),
                        Center(
                          child: SizedBox(
                            width: 200,
                            height: 50,
                            child: RoundButton(
                              title: "Create Diet Plan",
                              type: RoundButtonType.bgGradient,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              onPressed: () {
                                _showDietPlanDialog(context);
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: media.width * 0.25),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showDietPlanDialog(BuildContext context) {
    String? dietPreference = 'Veg';
    int? mealsPerDay = 3;
    String? dietGoal;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text("Create Your Diet Plan"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Diet Preference"),
                    Row(
                      children: [
                        Radio<String>(
                          value: 'Veg',
                          groupValue: dietPreference,
                          onChanged: (value) => setState(() => dietPreference = value),
                        ),
                        const Text("Veg"),
                        Radio<String>(
                          value: 'Non-Veg',
                          groupValue: dietPreference,
                          onChanged: (value) => setState(() => dietPreference = value),
                        ),
                        const Text("Non-Veg"),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text("Meals Per Day"),
                    DropdownButton<int>(
                      value: mealsPerDay,
                      items: [3, 5, 6].map((value) => DropdownMenuItem(value: value, child: Text("$value Meals"))).toList(),
                      onChanged: (value) => setState(() => mealsPerDay = value),
                    ),
                    const SizedBox(height: 16),
                    const Text("Diet Goal"),
                    DropdownButton<String>(
                      hint: const Text("Select a Diet Goal"),
                      value: dietGoal,
                      items: const [
                        DropdownMenuItem(value: 'High-Protein', child: Text('High-Protein')),
                        DropdownMenuItem(value: 'Low-Carb', child: Text('Low-Carb')),
                        DropdownMenuItem(value: 'Low-Sugar', child: Text('Low-Sugar')),
                        DropdownMenuItem(value: 'Low-Calorie', child: Text('Low-Calorie')),
                        DropdownMenuItem(value: 'Balanced', child: Text('Balanced')),
                      ],
                      onChanged: (value) => setState(() => dietGoal = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (dietPreference == null || mealsPerDay == null || dietGoal == null) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text("Please select all options")),
                      );
                      return;
                    }
                    try {
                      showDialog(context: dialogContext, builder: (_) => const Center(child: CircularProgressIndicator()));
                      final user = await UserService.fetchUserData();
                      final dietService = DietService();
                      final dietPlan = await dietService.createDietPlan(
                        username: user.username,
                        dietPreference: dietPreference!,
                        mealsPerDay: mealsPerDay!,
                        targetCalories: widget.maintainTdee,
                        dietGoal: dietGoal!,
                        context: context,
                      );
                      Navigator.pop(dialogContext); // Close loading
                      Navigator.pop(dialogContext); // Close dialog
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Diet Plan Created: ${dietPlan['id']}")));
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const MealScheduleView()));
                    } catch (e) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text("Failed: $e")));
                    }
                  },
                  child: const Text("Create"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTdeeSection(BuildContext context, String title, double value1, [double? value2]) {
    var media = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [TColor.primaryColor1.withOpacity(0.2), TColor.primaryColor2.withOpacity(0.2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: TColor.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _buildTdeeRow(title == "Maintain Weight" ? "Maintain" : "250g/Week", value1),
              if (value2 != null) ...[
                const SizedBox(height: 8),
                _buildTdeeRow("500g/Week", value2),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTdeeRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: TColor.black, fontSize: 14),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: TColor.secondaryColor1,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${value.toStringAsFixed(1)} kcal',
            style: TextStyle(
              color: TColor.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
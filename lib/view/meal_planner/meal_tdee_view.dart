import 'package:flutter/material.dart';
import 'package:fitglide_mobile_application/services/diet_service.dart';
import 'package:fitglide_mobile_application/services/user_service.dart';
import 'package:fitglide_mobile_application/common/colo_extension.dart';
import 'package:fitglide_mobile_application/common_widget/round_button.dart';
import 'package:fitglide_mobile_application/view/meal_planner/meal_planner_view.dart';

class MealTdeeView extends StatefulWidget {
  final double maintainTdee;

  const MealTdeeView({super.key, required this.maintainTdee});

  @override
  State<MealTdeeView> createState() => _MealTdeeViewState();
}

class _MealTdeeViewState extends State<MealTdeeView> {
  String? dietPreference = 'Veg';
  int? mealsPerDay = 3;
  String? dietGoal;

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.backgroundLight,
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
          "Create Diet Plan",
          style: TextStyle(color: TColor.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      backgroundColor: TColor.backgroundLight,
      body: SingleChildScrollView(
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
                      color: TColor.textSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
              SizedBox(height: media.width * 0.05),
              Text(
                "Customize Your Diet Plan",
                style: TextStyle(
                  color: TColor.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: media.width * 0.05),
              // Diet Preference
              Text(
                "Diet Preference",
                style: TextStyle(color: TColor.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  Radio<String>(
                    value: 'Veg',
                    groupValue: dietPreference,
                    onChanged: (value) => setState(() => dietPreference = value),
                    activeColor: TColor.primary,
                  ),
                  Text("Veg", style: TextStyle(color: TColor.textPrimary)),
                  Radio<String>(
                    value: 'Non-Veg',
                    groupValue: dietPreference,
                    onChanged: (value) => setState(() => dietPreference = value),
                    activeColor: TColor.primary,
                  ),
                  Text("Non-Veg", style: TextStyle(color: TColor.textPrimary)),
                ],
              ),
              SizedBox(height: media.width * 0.05),
              // Meals Per Day
              Text(
                "Meals Per Day",
                style: TextStyle(color: TColor.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              DropdownButton<int>(
                value: mealsPerDay,
                items: [3, 5, 6].map((value) => DropdownMenuItem(value: value, child: Text("$value Meals", style: TextStyle(color: TColor.textPrimary)))).toList(),
                onChanged: (value) => setState(() => mealsPerDay = value),
                underline: Container(),
                isExpanded: true,
                dropdownColor: TColor.cardLight,
              ),
              SizedBox(height: media.width * 0.05),
              // Diet Goal
              Text(
                "Diet Goal",
                style: TextStyle(color: TColor.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              DropdownButton<String>(
                hint: Text("Select a Diet Goal", style: TextStyle(color: TColor.textSecondary)),
                value: dietGoal,
                items: const [
                  DropdownMenuItem(value: 'High-Protein', child: Text('High-Protein')),
                  DropdownMenuItem(value: 'Low-Carb', child: Text('Low-Carb')),
                  DropdownMenuItem(value: 'Low-Sugar', child: Text('Low-Sugar')),
                  DropdownMenuItem(value: 'Low-Calorie', child: Text('Low-Calorie')),
                  DropdownMenuItem(value: 'Balanced', child: Text('Balanced')),
                ],
                onChanged: (value) => setState(() => dietGoal = value),
                underline: Container(),
                isExpanded: true,
                dropdownColor: TColor.cardLight,
              ),
              SizedBox(height: media.width * 0.05),
              // Create Button
              Center(
                child: SizedBox(
                  width: 200,
                  height: 50,
                  child: RoundButton(
                    title: "Create Diet Plan",
                    type: RoundButtonType.bgGradient,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    onPressed: () async {
                      if (dietPreference == null || mealsPerDay == null || dietGoal == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please select all options")),
                        );
                        return;
                      }
                      try {
                        showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));
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
                        Navigator.pop(context); // Close loading dialog
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Diet Plan Created: ${dietPlan['id']}")));
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MealPlannerView()));
                      } catch (e) {
                        Navigator.pop(context); // Close loading dialog
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
                      }
                    },
                  ),
                ),
              ),
              SizedBox(height: media.width * 0.25),
            ],
          ),
        ),
      ),
    );
  }
}
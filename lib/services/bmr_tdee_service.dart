import 'package:flutter/material.dart';
import 'package:fitglide_mobile_application/services/user_service.dart';

class BmrTdeeService extends StatelessWidget {
  const BmrTdeeService({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Fitness App")),
        body: FutureBuilder<UserData>(
          future: UserService.fetchUserData(),
          builder: (BuildContext context, AsyncSnapshot<UserData> snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final user = snapshot.data!;
            final bmr = calculateBMR(user);
            // Calculate all TDEE options for display
            final tdeeOptions = calculateTDEEOptions(bmr, "sedentary"); // Default activity level

            return MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text('BMR: ${bmr.toStringAsFixed(1)} kcal'),
                    // Maintaining weight TDEE
                    Text('TDEE (Maintain Weight): ${tdeeOptions['maintain']!.toStringAsFixed(1)} kcal'),
                    // Weight loss options
                    Text('TDEE (Loss 250g/week): ${tdeeOptions['loss_250g']!.toStringAsFixed(1)} kcal'),
                    Text('TDEE (Loss 500g/week): ${tdeeOptions['loss_500g']!.toStringAsFixed(1)} kcal'),
                    // Weight gain options
                    Text('TDEE (Gain 250g/week): ${tdeeOptions['gain_250g']!.toStringAsFixed(1)} kcal'),
                    Text('TDEE (Gain 500g/week): ${tdeeOptions['gain_500g']!.toStringAsFixed(1)} kcal'),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Calculates Basal Metabolic Rate (BMR) using Mifflin-St Jeor equation
  double calculateBMR(UserData user) {
    if (user.heightCm == null || user.weightKg == null || user.age == 0) {
      return 0.0; // Return 0 if required data is missing
    }
    double bmr = (10 * user.weightKg!) + (6.25 * user.heightCm!) - (5 * user.age);
    if (user.gender?.toLowerCase() == 'male') {
      bmr += 5; // Male adjustment
    } else if (user.gender?.toLowerCase() == 'female') {
      bmr -= 161; // Female adjustment
    } else {
      bmr -= 78; // Average adjustment for unknown gender
    }
    return bmr;
  }

  // Calculates base TDEE based on activity level
  double calculateTDEE(double bmr, String activityLevel) {
    if (bmr == 0) return 0.0;
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        return bmr * 1.2;
      case 'light':
        return bmr * 1.375;
      case 'moderate':
        return bmr * 1.55;
      case 'active':
        return bmr * 1.725;
      case 'very active':
        return bmr * 1.9;
      default:
        return bmr * 1.2; // Default to sedentary if unknown
    }
  }

  // Calculates TDEE options for maintaining weight, weight loss, and weight gain
  Map<String, double> calculateTDEEOptions(double bmr, String activityLevel) {
    if (bmr == 0) {
      return {
        'maintain': 0.0,
        'loss_250g': 0.0,
        'loss_500g': 0.0,
        'gain_250g': 0.0,
        'gain_500g': 0.0,
      };
    }
    // Base TDEE for maintaining weight
    final tdee = calculateTDEE(bmr, activityLevel);
    return {
      'maintain': tdee,              // TDEE to maintain current weight
      'loss_250g': tdee - 275,       // 250g/week loss ≈ 275 kcal/day deficit
      'loss_500g': tdee - 550,       // 500g/week loss ≈ 550 kcal/day deficit
      'gain_250g': tdee + 275,       // 250g/week gain ≈ 275 kcal/day surplus
      'gain_500g': tdee + 550,       // 500g/week gain ≈ 550 kcal/day surplus
    };
  }

  Future<Map<String, double>> fetchTdeeOptions() async {
    final user = await UserService.fetchUserData();
    final bmr = calculateBMR(user);
    // Assuming activity level defaults to 'sedentary' if not provided
    // Replace with actual user activity level if available in UserData
    const activityLevel = 'sedentary'; // Adjust based on your data model
    return calculateTDEEOptions(bmr, activityLevel);
  }
}
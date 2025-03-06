import 'dart:math';

import 'package:fitglide_mobile_application/view/main_tab/main_screen.dart';
import 'package:flutter/material.dart';

class BMICalculator {
  final DataService dataService; // Make dataService final
BMICalculator(this.dataService);

  /// Fetches user data from the API service and calculates BMI.
  Future<double?> calculateBMI() async {
    try {
      final response = await dataService.fetchUserDetails();

      if (response == null ||
          !response.containsKey('weight') ||
          !response.containsKey('height') ||
          !response.containsKey('date_of_birth')) {
        debugPrint('Error: Missing required user data in API response.');
        return null;
      }

      final weightKg = response['weight'] as double;
      final heightCm = response['height'] as double;
      final dateOfBirth = response['date_of_birth'] as String;

      final bmi = calculateBMIValue(heightCm, weightKg);
      final age = calculateAge(dateOfBirth);
      final bmiCategory = interpretBMI(bmi, age);

      debugPrint('BMI: $bmi, Category: $bmiCategory');
      return bmi;
    } catch (e) {
      debugPrint('Error fetching user data or calculating BMI: $e');
      return null;
    }
  }


  /// Calculate BMI given height (cm) and weight (kg).
  static double calculateBMIValue(double heightCm, double weightKg) {
    double heightM = heightCm / 100.0; // Convert cm to meters
    return weightKg / pow(heightM, 2);
  }

  /// Inject DataService if needed (optional method)
  void injectDataService(DataService dataService) {
    dataService = dataService;
  }

  /// Calculate age from the date of birth.
  static int calculateAge(String dateOfBirth) {
    DateTime dob = DateTime.parse(dateOfBirth);
    DateTime today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  /// Interpret BMI category considering age (optional).
  static String interpretBMI(double bmi, [int? age]) {
    if (age != null && age < 18) {
      // Handle BMI interpretation for children/teenagers (if data service available)
      // You might need a different interpretation logic for this case
      return 'BMI interpretation for children/teenagers not implemented yet.';
    } else {
      if (bmi < 18.5) {
        return 'Underweight';
      } else if (bmi >= 18.5 && bmi < 24.9) {
        return 'Normal';
      } else if (bmi >= 25 && bmi < 29.9) {
        return 'Overweight';
      } else {
        return 'Obese';
      }
    }
  }
}
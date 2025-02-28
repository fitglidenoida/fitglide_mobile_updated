import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:fitglide_mobile_application/services/user_service.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class DietService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> createDietPlan({
    required String username,
    required String dietPreference,
    required int mealsPerDay,
    required double targetCalories,
    required String dietGoal,
    required BuildContext context,
    bool isPremium = false,
  }) async {
    try {
      final Random rand = Random();

      // Fetch diet template
      final templatesResponse = await ApiService.get(
        'diet-templates?populate=meals.diet_components'
        '&filters[diet_preference][\$eq]=$dietPreference'
        '&filters[diet_template_id][\$eq]=${dietGoal.toLowerCase().replaceAll('-', '_')}_${mealsPerDay}'
      );
      final List<dynamic>? allTemplates = templatesResponse['data'];
      if (allTemplates == null || allTemplates.isEmpty) {
        throw Exception('No diet templates found for $dietGoal, $dietPreference, and $mealsPerDay meals');
      }

      debugPrint('Templates fetched: ${allTemplates.length}');
      final template = allTemplates[rand.nextInt(allTemplates.length)]['attributes'];
      final templateMeals = (template['meals']?['data'] as List<dynamic>?) ?? [];

      if (templateMeals.isEmpty || templateMeals.length < mealsPerDay) {
        throw Exception('Insufficient meals in template for $mealsPerDay meals/day');
      }

      // Select and scale meals
      final selectedMeals = <Map<String, dynamic>>[];
      final mealCalorieTarget = targetCalories / mealsPerDay;
      final shuffledMeals = List<Map<String, dynamic>>.from(templateMeals.map((m) => m['attributes']))..shuffle(rand);

      for (int i = 0; i < mealsPerDay; i++) {
        final meal = shuffledMeals[i];
        final components = meal['diet_components']['data'] as List<dynamic>;
        final baseCalories = components.fold(0, (sum, c) => sum + (c['attributes']['calories'] as int? ?? 0));
        final scaleFactor = baseCalories > 0 ? mealCalorieTarget / baseCalories : 1.0;

        selectedMeals.add({
          'id': meal['id'],
          'name': meal['name'],
          'category': meal['name'],
          'calculatedCalories': (baseCalories * scaleFactor).round(),
          'diet_components': components.map((c) => c['attributes']).toList(),
          'base_portion': scaleFactor,
        });
      }

      // Add gamification
      final gamifiedMeals = selectedMeals.map((meal) {
        int points = _calculateMealPoints(meal);
        String? badge = _awardBadge(meal, points);
        if (badge != null && context.mounted) {
          _notifyBadgeEarned(context, badge);
        }
        return {
          ...meal,
          'points': points,
          'badge': badge,
          'challenge': _getChallenge(dietGoal),
        };
      }).toList();

      final userIdString = await UserService.getUserId();
      final userId = int.parse(userIdString);

      final totalCalories = gamifiedMeals.fold(0, (sum, meal) => sum + (meal['calculatedCalories'] as int));
      final dietPlanData = {
        'data': {
          'diet_preference': dietPreference,
          'total_calories': totalCalories,
          'meals': gamifiedMeals.map((meal) => meal['id']).toList(),
          'users_permissions_user': userId,
          'diet_goal': dietGoal,
        }
      };

      final dietPlanResponse = await ApiService.post('diet-plans', dietPlanData);
      final dietPlan = Map<String, dynamic>.from(dietPlanResponse['data'])..['meals'] = gamifiedMeals;
      return dietPlan;
    } catch (e) {
      debugPrint('Error creating diet plan: $e');
      throw Exception('Failed to create diet plan: $e');
    }
  }

  int _calculateMealPoints(Map<String, dynamic> meal) {
    int points = 0;
    final components = meal['diet_components'] as List<dynamic>? ?? [];
    for (var component in components) {
      final protein = double.tryParse(component['protein']?.replaceAll('g', '') ?? '0') ?? 0;
      final fiber = double.tryParse(component['fiber']?.replaceAll('g', '') ?? '0') ?? 0;
      final sugar = double.tryParse(component['sugar']?.replaceAll('g', '') ?? '0') ?? 0;
      final calories = component['calories'] as int? ?? 0;
      points += (protein > 5 ? 10 : 5) + (fiber > 2 ? 5 : 0) + (sugar < 5 ? 5 : 0) + (calories < 200 ? 5 : 3);
    }
    return components.isEmpty ? 0 : points ~/ components.length;
  }

  String? _awardBadge(Map<String, dynamic> meal, int points) {
    final components = meal['diet_components'] as List<dynamic>? ?? [];
    if (points > 25) return "Healthy Champion";
    if (components.any((c) => double.parse(c['protein']?.replaceAll('g', '') ?? '0') > 10)) return "Protein Power";
    if (components.any((c) => double.parse(c['fiber']?.replaceAll('g', '') ?? '0') > 5)) return "Fiber Fighter";
    if (components.any((c) => double.parse(c['sugar']?.replaceAll('g', '') ?? '0') < 5)) return "Sugar Slayer";
    if (meal['category'].contains('Snack')) return "Snack Master";
    return null;
  }

  String _getChallenge(String dietGoal) {
    switch (dietGoal.toLowerCase()) {
      case 'high-protein':
        return "Boost your protein intake!";
      case 'low-carb':
        return "Keep carbs low today!";
      case 'low-sugar':
        return "Avoid sugary treats!";
      case 'low-calorie':
        return "Stay under your calorie goal!";
      case 'balanced':
        return "Maintain a balanced diet!";
      default:
        return "Eat well today!";
    }
  }

  void _notifyBadgeEarned(BuildContext context, String badge) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Badge Earned: $badge!"),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
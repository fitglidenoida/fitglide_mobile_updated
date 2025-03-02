import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AiService {
  static const String _baseUrl = 'https://api.grok.com'; // Grok API URL
  static const String _apiKey = 'xai-ky4bcLrDppnXo3ugqeuTEXl7nc0FPIinSSH2szi1yREfjw61MepdjSL6QPapHadLfMKwbNbs4NCqOytq'; // Your Grok API key
  static const String _strapiUrl = 'https://admin.fitglide.in/api'; // Replace with your Strapi URL

  static Future<List<Map<String, dynamic>>> fetchExercisesFromDatabase() async {
    final response = await http.get(
      Uri.parse('$_strapiUrl/exercises?populate=*'),
      headers: {'Authorization': 'Bearer YOUR_STRAPI_API_TOKEN'}, // Replace with your Strapi token
    );

    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body)['data'];
      if (data is List) {
        return data.map((item) {
          if (item is Map) {
            return Map<String, dynamic>.fromEntries(
              item.entries.map((entry) {
                final key = entry.key.toString();
                return MapEntry<String, dynamic>(key, entry.value);
              }),
            );
          }
          debugPrint('Unexpected exercise item type: $item');
          return <String, dynamic>{};
        }).whereType<Map<String, dynamic>>().toList();
      }
      return [];
    } else {
      throw Exception('Failed to fetch exercises: ${response.statusCode}');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchMealsFromDatabase() async {
    final response = await http.get(
      Uri.parse('$_strapiUrl/meals?populate=*'),
      headers: {'Authorization': 'Bearer YOUR_STRAPI_API_TOKEN'}, // Replace with your Strapi token
    );

    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body)['data'];
      if (data is List) {
        return data.map((item) {
          if (item is Map) {
            return Map<String, dynamic>.fromEntries(
              item.entries.map((entry) {
                final key = entry.key.toString();
                return MapEntry<String, dynamic>(key, entry.value);
              }),
            );
          }
          debugPrint('Unexpected meal item type: $item');
          return <String, dynamic>{};
        }).whereType<Map<String, dynamic>>().toList();
      }
      return [];
    } else {
      throw Exception('Failed to fetch meals: ${response.statusCode}');
    }
  }

  static Future<String> getMaxRecommendation(String inputText, {Map<String, dynamic>? contextData, bool useDatabase = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'max_recommendation_${inputText.hashCode}_${contextData?.hashCode ?? 0}';
    
    // Check if cached data exists and is not expired
    final cachedData = prefs.getString('${key}_data');
    final cachedExpiry = prefs.getInt('${key}_expiry');
    final now = DateTime.now().millisecondsSinceEpoch;

    if (cachedData != null && cachedExpiry != null && now < cachedExpiry) {
      return cachedData;
    }

    String recommendation;
    if (useDatabase) {
      final exercises = await fetchExercisesFromDatabase();
      final meals = await fetchMealsFromDatabase();
      final filteredData = _filterRecommendations(exercises, meals, contextData ?? {});
      if (filteredData.isNotEmpty) {
        recommendation = _generateDatabaseRecommendation(filteredData);
      } else {
        recommendation = await _fetchFromGrok(inputText, contextData);
      }
    } else {
      recommendation = await _fetchFromGrok(inputText, contextData);
    }

    final String maxRecommendation = _formatAsMax(recommendation);
    // Cache with 24-hour expiration
    await prefs.setString('${key}_data', maxRecommendation);
    await prefs.setInt('${key}_expiry', DateTime.now().add(Duration(hours: 24)).millisecondsSinceEpoch);
    return maxRecommendation;
  }

  static Future<String> _fetchFromGrok(String inputText, Map<String, dynamic>? contextData) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/v1/grok-beta'), // Use grok-beta endpoint for cost efficiency
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'prompt': inputText,
        'context': contextData ?? {},
        'max_tokens': 50, // Limit output to 50 tokens to control costs
        'temperature': 0.7,
        'character': 'Max',
        'tone': 'friendly, motivational, fitness-focused',
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['response'] ?? 'No response from Grok.';
    } else {
      throw Exception('Failed to get recommendation from Grok: ${response.statusCode} - ${response.body}');
    }
  }

  static String _generateDatabaseRecommendation(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 'No recommendations available.';
    final exercise = data.firstWhere((item) => item['category'] == 'Workout', orElse: () => data.first);
    return 'Try ${exercise['name']} for ${exercise['duration']} minutes to boost your fitness!';
  }

  static List<Map<String, dynamic>> _filterRecommendations(List<Map<String, dynamic>> exercises, List<Map<String, dynamic>> meals, Map<String, dynamic> context) {
    final goals = context['fitness_goals'] as List? ?? [];
    return [
      ...exercises.where((exercise) => goals.contains(exercise['goal'] ?? 'general')),
      ...meals.where((meal) => goals.contains(meal['goal'] ?? 'general')),
    ].toList();
  }

  static String _formatAsMax(String recommendation) {
    return "Hey, I’m Max—$recommendation Let’s crush your fitness goals together!";
  }

  static Future<List<String>> getBatchMaxRecommendations(List<String> inputTexts, List<Map<String, dynamic>> contextDataList, {bool useDatabase = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> recommendations = [];
    for (int i = 0; i < inputTexts.length; i++) {
      final input = inputTexts[i];
      final context = contextDataList[i] ?? {};
      final key = 'max_recommendation_${input.hashCode}_${context.hashCode ?? 0}';
      
      // Check if cached data exists and is not expired
      final cachedData = prefs.getString('${key}_data');
      final cachedExpiry = prefs.getInt('${key}_expiry');
      final now = DateTime.now().millisecondsSinceEpoch;

      if (cachedData != null && cachedExpiry != null && now < cachedExpiry) {
        recommendations.add(cachedData);
      } else {
        String recommendation;
        if (useDatabase) {
          final exercises = await fetchExercisesFromDatabase();
          final meals = await fetchMealsFromDatabase();
          final filteredData = _filterRecommendations(exercises, meals, context);
          if (filteredData.isNotEmpty) {
            recommendation = _generateDatabaseRecommendation(filteredData);
          } else {
            recommendation = await _fetchFromGrok(input, context);
          }
        } else {
          recommendation = await _fetchFromGrok(input, context);
        }
        final maxRecommendation = _formatAsMax(recommendation);
        await prefs.setString('${key}_data', maxRecommendation);
        await prefs.setInt('${key}_expiry', DateTime.now().add(Duration(hours: 24)).millisecondsSinceEpoch); // Cache for 24 hours
        recommendations.add(maxRecommendation);
      }
    }
    return recommendations;
  }
}
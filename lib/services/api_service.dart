import 'dart:convert';
import 'package:fitglide_mobile_application/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://admin.fitglide.in/api';

static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
  final url = Uri.parse('$baseUrl/$endpoint');
  final headers = endpoint == 'auth/local' ? {'Content-Type': 'application/json'} : await _getHeaders();

  try {
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(data),
    );

    debugPrint('Response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception('API Error: ${response.statusCode} - $error');
    }
  } catch (e) {
    debugPrint('Error during API call: $e');
    throw Exception('Error: $e');
  }
}


  static Future<Map<String, dynamic>> get(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final headers = await _getHeaders();

    final response = await http.get(url, headers: headers);
    return _handleResponse(response);
  }

static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data, {bool raw = false}) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final headers = await _getHeaders();
  debugPrint('PUT request to: $url');
  debugPrint('Body: ${jsonEncode(raw ? data : {'data': data})}');
  final response = await http.put(
    url,
    headers: headers,
    body: jsonEncode(raw ? data : {'data': data}),
  );
  debugPrint('PUT response: ${response.statusCode} - ${response.body}');
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        // Directly decode the response body and return it as a Future
        return jsonDecode(response.body); // This will return a Map<String, dynamic>
      } catch (e) {
        // Handle JSON decoding errors
        debugPrint('JSON decoding error: $e');
        debugPrint('Response body: ${response.body}'); // Print the raw response body for debugging
        throw Exception('Failed to decode JSON: $e');
      }
    } else {
      debugPrint('API Error: ${response.statusCode} - ${response.body}'); // Log the error response
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await StorageService.getToken(); // Replace with your token retrieval logic
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    return ApiService.post('auth/local/register', data);
  }

  updateHealthVital(int i, Map<String, String?> data) {}

  static Future<List<Map<String, dynamic>>> getSleepLogs(String username) async {
    final response = await get('sleeplogs?populate=*&filters[username][username][\$eq]=$username');
    
    if (response.containsKey('data') && response['data'] is List) {
      return List<Map<String, dynamic>>.from(response['data']);
    } else {
      throw Exception('Unexpected format for sleep logs response');
    }
  }

  static Future<Map<String, dynamic>> addSleepLog(Map<String, dynamic> data) async {
    return post('sleeplogs', {'data': data});
  }

  static Future<Map<String, dynamic>> updateSleepLog(String logId, Map<String, dynamic> data) async {
    return put('sleeplogs/$logId', {'data': data});
  }

static Future<Map<String, dynamic>> fetchDietComponents(String dietPreference) async {
    return get('diet-components?populate=*&filters[food_type][\$eq]=$dietPreference');
  }

static Future<Map<String, dynamic>> getDietComponents() async {
    return get('diet-components?populate=*');
  }

  static Future<Map<String, dynamic>> addDietComponent(Map<String, dynamic> data) async {
    return post('diet-components', {'data': data});
  }

static Future<Map<String, dynamic>> updateDietComponent(String documentId, Map<String, dynamic> data) async {
  return put('diet-components/$documentId', data); // Default wraps in {"data": ...}
}

  // Meals Methods
  static Future<Map<String, dynamic>> fetchMeals() async {
    return get('meals?populate=*');
  }

  static Future<Map<String, dynamic>> createMeals(Map<String, dynamic> data) async {
    return post('meals', {'data': data});
  }

  static Future<Map<String, dynamic>> updateMeal(String documentId, Map<String, dynamic> data) async {
    return put('meals/$documentId', {'data': data});
  }

  // Diet Plans Methods
  static Future<Map<String, dynamic>> fetchDietPlans(String username) async {
    return get('diet-plans?populate=*&filters[users_permissions_user][username][\$eq]=$username');
  }

  static Future<Map<String, dynamic>> addDietPlan(Map<String, dynamic> data) async {
    return post('diet-plans', {'data': data});
  }

  static Future<Map<String, dynamic>> updateDietPlan(String documentId, Map<String, dynamic> data) async {
    return put('diet-plans/$documentId', {'data': data});
  }


  static Future<Map<String, dynamic>> fetchDietTemplates(String dietPreference) async {
    return get('diet-templates?populate=*&filters[diet_preference][\$eq]=$dietPreference');
  }

static Future<List<Map<String, dynamic>>> fetchAllExercises() async {
    try {
      List<Map<String, dynamic>> allExercises = [];
      int page = 1;
      const int pageSize = 100;
      bool hasMore = true;

      while (hasMore) {
        final response = await ApiService.get(
          'exercises?populate=*&pagination[page]=$page&pagination[pageSize]=$pageSize',
        );
        final exerciseData = response['data'] as List<dynamic>? ?? [];
        allExercises.addAll(exerciseData.map((e) => Map<String, dynamic>.from(e)));

        final total = response['meta']['pagination']['total'] as int? ?? 0;
        final fetched = allExercises.length;
        debugPrint('Fetched: $fetched, Total: $total');
        hasMore = fetched < total;
        page++;
      }

      return allExercises;
    } catch (e) {
      debugPrint('Error in fetchAllExercises: $e');
      rethrow;
    }
  }

  // Fetch workout plans for a specific user
static Future<Map<String, dynamic>> fetchWorkoutPlans(String username) async {
    return get('workout-plans?populate=*&filters[username][username][\$eq]=$username');
  }

  // Add a new workout plan
static Future<Map<String, dynamic>> addWorkoutPlan(Map<String, dynamic> data) async {
    return post('workout-plans', data);
  }

// In ApiService.dart, update the updateWorkoutPlan method
static Future<Map<String, dynamic>> updateWorkoutPlan(String documentId, Map<String, dynamic> data) async {
    final payload = {
      'data': {
        'Completed': 'TRUE', // Match Strapi's field name and string value
      },
    };
    return put('workout-plans/$documentId', payload); // Use documentId instead of numeric id
  }

static Future<bool> validateToken(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      debugPrint('Validate token response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200 && jsonDecode(response.body).containsKey('username');
    } catch (e) {
      debugPrint('Token validation error: $e');
      return false;
    }
  }
  }


class AuthService {

 

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiService.post('auth/local', {
      'identifier': email,
      'password': password,
    });

    // Save the JWT token in shared preferences
    if (response.containsKey('jwt')) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt', response['jwt']);
    }

    return response;
  }

  final String baseUrl = "https://admin.fitglide.in/api";

  Future<void> saveHealthVitals(String jwt, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/healthvitals'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $jwt',
      },
      body: json.encode({"data": data}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to save healthvitals: ${response.body}');
    }
  }

    void updateHealthVital(int i, Map<String, String?> data) {}

    

}


class DataService {
Future<Map<String, dynamic>> fetchUserDetails() async {
  return ApiService.get('users/me?populate=*');
}

  Future<Map<String, dynamic>> updateUserDetails(Map<String, dynamic> data) async {
    return ApiService.put('users/me', data);
  }

  Future<Map<String, dynamic>> fetchWorkoutPlans() async {
    return ApiService.get('workout-plans?populate=*');
  }

  Future<Map<String, dynamic>> fetchDietPlans() async {
    return ApiService.get('diet-plans?populate=*');
  }

  Future<Map<String, dynamic>> fetchSubPlans() async {
    return ApiService.get('plans?populate=*');
  }

  Future<Map<String, dynamic>> fetchOrders() async {
    return ApiService.get('create-order?populate=*');
  }

Future<List<dynamic>> fetchHealthVitals(String username) async {
  String encodedUsername = Uri.encodeQueryComponent(username);
  final response = await ApiService.get(
    // Here we use double quotes and escape $ with a backslash
    'health-vitals?populate=*&filters[username][username][\$eq]=$encodedUsername',
  );

  if (response.containsKey('data') && response['data'] is List) {
    return response['data'] as List<dynamic>;
  } else {
    throw Exception('Unexpected API response format: $response');
  }
}

  Future<Map<String, dynamic>> fetchWeightLogs(String username) async {
    return ApiService.get('weightlogs?filters[username][username][\$eq]=$username&sort=logdate:DESC');
  }

  Future<void> updateWeightLog(int logId, Map<String, dynamic> data) async {
    await ApiService.put('weightlogs/$logId', data);
  }

  Future<void> addWeightLog(Map<String, dynamic> data) async {
    await ApiService.post('weightlogs', data);
  }

  Future<Map<String, dynamic>> fetchSubscriptionPlans(String username) async {
    return ApiService.get('subscriptions?populate=*&filters[username][username][\$eq]=$username');
  }

  Future<void> updateSubscriptionPlan(int planId, Map<String, dynamic> data) async {
    await ApiService.put('plans/$planId', data);
  }

  // New Endpoints
  Future<Map<String, dynamic>> fetchStravaInputs(String athleteId) async {
    return ApiService.get('strava-inputs?filters[activity_id][\$eq]=$athleteId');
  }

  Future<Map<String, dynamic>> syncStravaData(Map<String, dynamic> data) async {
    return ApiService.post('strava-inputs', data);
  }

  Future<Map<String, dynamic>> fetchStravaAthlete(String athleteId) async {
    return ApiService.get('strava-bindings?athlete_id=$athleteId');
  }

  Future<Map<String, dynamic>> fetchStravaData(String username) async {
    return ApiService.get('strava-inputs?populate=*&filters[username][username][\$eq]=$username');
  }

  Future<void> updateHealthVital(int documentId, Map<String, dynamic> data) async {
    // PUT request to update the health vitals in the database
    await ApiService.put('health-vitals/$documentId', data);
  }

    Future<void> updateHealthVitals( documentId, Map<String, dynamic> data) async {
    try {
      await ApiService.put('health-vitals/$documentId', data);
      debugPrint('Health vitals updated successfully for ID: $documentId');
    } catch (e) {
      debugPrint('Error updating health vitals: $e');
      throw Exception('Failed to update health vitals');
    }
  }

  Future<void> postHealthVitals(Map<String, dynamic> data) async {
    try {
      await ApiService.post('health-vitals', data);
      debugPrint('New health vitals added successfully');
    } catch (e) {
      debugPrint('Error adding health vitals: $e');
      throw Exception('Failed to add health vitals');
    }
  }
   
Future<Map<String, dynamic>> getSleepLogs(String username) async {
  return ApiService.get('sleeplogs?populate=*&filters[username][username][\$eq]=$username');
}

  Future<Map<String, dynamic>> postSleepLogs(Map<String, dynamic> data) async {
    return ApiService.post('sleeplogs', data);
  }

Future<List<dynamic>> fetchUserSleepLogs(String username) async {
  final response = await ApiService.get('sleeplogs?populate=*&filters[username][username][\$eq]=$username');
  
  if (response.containsKey('data') && response['data'] is List) {
    List<dynamic> logs = response['data'];

    // Ensure only entries linked to the correct username are returned
    List<dynamic> filteredLogs = logs.where((log) {
      return log['username'] != null && log['username']['username'] == username;
    }).toList();

    return filteredLogs;
  } else {
    throw Exception('Failed to load sleep logs: Unexpected response format');
  }
}


    Future<void> updateSleepLogForUser(String logId, Map<String, dynamic> data) async {
    try {
      await ApiService.updateSleepLog(logId, data);
      // Any additional logic here, like updating local state, logging, etc.
      debugPrint('Sleep log updated successfully for ID: $logId');
    } catch (e) {
      debugPrint('Error updating sleep log: $e');
      // Handle error in a way that's meaningful for your app's flow
      throw Exception('Failed to update sleep log');
    }
  }
}




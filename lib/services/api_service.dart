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

  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final headers = await _getHeaders();

    final response = await http.put(url, headers: headers, body: jsonEncode({'data': data}));
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
}




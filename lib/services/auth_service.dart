import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class AuthService {
  static const String baseUrl = 'https://admin.fitglide.in/api';

  /// Regular email/password login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/local');
    final headers = {
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'identifier': email,
      'password': password,
    });

    debugPrint('Login request URL: $url');
    debugPrint('Login request headers: $headers');
    debugPrint('Login request body: $body');

    try {
      final response = await http.post(url, headers: headers, body: body);
      debugPrint('Login response status code: ${response.statusCode}');
      debugPrint('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

 Future<Map<String, dynamic>> googleLogin(String idToken) async {
  final response = await http.post(
    Uri.parse("$baseUrl/auth/google/callback"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"id_token": idToken}),
  );

  debugPrint("Response status: ${response.statusCode}");
  debugPrint("Response body: ${response.body}");

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Google authentication failed: ${response.body}");
  }
}

Future<Map<String, dynamic>?> getUserProfile(String token) async {
  final url = Uri.parse("https://admin.fitglide.in/api/users/me"); // Strapi's user info endpoint

  final response = await http.get(
    url,
    headers: {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    },
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    debugPrint("Failed to fetch user data: ${response.body}");
    return null;
  }
}



}



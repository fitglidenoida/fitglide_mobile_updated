import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class AuthService {
  static const String baseUrl = 'https://admin.fitglide.in/api';

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
    debugPrint('Login request body: $body'); // Log the body to ensure it matches what Postman sends

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
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleSignInService {
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // Load client ID from JSON
      final String jsonString = await rootBundle.loadString('assets/google_oauth_client.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final clientId = jsonData['web']['client_id'];

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: clientId,
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Now you have the ID token and access token
        final String idToken = googleAuth.idToken!;
        final String accessToken = googleAuth.accessToken!;

        // Send these tokens to your backend for validation
        final response = await _validateGoogleToken(idToken, accessToken);

        if (response.statusCode == 200) {
          final Map<String, dynamic> userData = jsonDecode(response.body);
          return userData;
        } else {
          debugPrint('Failed to validate Google token: ${response.body}');
          return null;
        }
      } else {
        // User canceled sign-in
        return null;
      }
    } catch (error) {
      debugPrint('Error during Google sign-in: $error');
      return null;
    }
  }

  Future<http.Response> _validateGoogleToken(String idToken, String accessToken) async {
    // Here, you would send the tokens to your server for validation
    // This is just an example endpoint; replace with your actual server endpoint
    final Uri url = Uri.parse('https://admmin.fitglide.in/google-login');
    final headers = {
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'idToken': idToken,
      'accessToken': accessToken
    });

    return await http.post(url, headers: headers, body: body);
  }
}
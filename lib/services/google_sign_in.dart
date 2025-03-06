import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GoogleSignInHelper {
  // Configure GoogleSignIn based on platform
  static GoogleSignIn getGoogleSignIn() {
    return GoogleSignIn(
      scopes: ['email', 'profile', 'openid'],
    );
  }

  // Sign-in and authenticate with Strapi
  static Future<Map<String, dynamic>?> signInAndFetchUserData
() async {
    try {
      final GoogleSignIn googleSignIn = getGoogleSignIn();
      await googleSignIn.signOut(); // Force fresh sign-in
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint("User canceled the login");
        return null;
      }

      debugPrint("User signed in: ${googleUser.email}");

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Fetch ID Token manually if missing
      final String? idToken = googleAuth.idToken;
      if (idToken == null) {
        debugPrint("Failed to retrieve Google ID token.");
        return null;
      }

      debugPrint("Google ID Token: $idToken");

      // Authenticate with Strapi
final String? jwtToken = await authenticateWithStrapi(idToken);
      if (jwtToken == null) {
        debugPrint("Failed to authenticate with Strapi.");
        return null;
      }

      return {'jwt': jwtToken}; // Return Strapi JWT token
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      return null;
    }
  }

static Future<String?> authenticateWithStrapi(String idToken, [String strapiUrl = 'https://admin.fitglide.in/api/auth/google/callback']) async {
  try {
    final response = await http.post(
      Uri.parse(strapiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'access_token': idToken}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['jwt']; 
    } else {
      print('Strapi Auth Error: ${response.statusCode} - ${response.body}'); 

      if (response.statusCode == 400) {
        print("Strapi returned 400 Bad Request. Check Google Token validity.");
      } else if (response.statusCode == 500) {
        print("Strapi server error. Check Strapi logs.");
      }

      return null;
    }
  } catch (e) {
    print('Strapi Auth Exception: $e');
    return null;
  }
}



}
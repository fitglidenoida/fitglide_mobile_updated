import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInHelper {
  // Create a GoogleSignIn instance based on the platform
  static GoogleSignIn getGoogleSignIn() {
    GoogleSignIn googleSignIn;

    if (kIsWeb || Platform.isAndroid) {
      // Web or Android: No clientId needed, only scopes
      googleSignIn = GoogleSignIn(
        scopes: ['email'],
      );
    } else if (Platform.isIOS || Platform.isMacOS) {
      // iOS or macOS: Specify the clientId
      googleSignIn = GoogleSignIn(
        clientId: "535964172976-a4gv0s1stdf99mukbeeq12scp5r04dio.apps.googleusercontent.com",
        scopes: ['email'],
      );
    } else {
      throw UnsupportedError("This platform is not supported for Google Sign-In");
    }

    return googleSignIn;
  }

  // Method to handle Google Sign-In
  static Future<GoogleSignInAccount?> signIn() async {
    try {
      final GoogleSignIn googleSignIn = getGoogleSignIn();
      final GoogleSignInAccount? googleAccount = await googleSignIn.signIn();
      return googleAccount;
    } catch (e) {
      print("Error during Google Sign-In: $e");
      return null;
    }
  }

  // Method to fetch authentication details
  static Future<GoogleSignInAuthentication?> getAuthentication(
      GoogleSignInAccount? googleAccount) async {
    if (googleAccount == null) return null;
    try {
      final GoogleSignInAuthentication googleAuthentication =
          await googleAccount.authentication;
      return googleAuthentication;
    } catch (e) {
      print("Error retrieving Google authentication details: $e");
      return null;
    }
  }
}
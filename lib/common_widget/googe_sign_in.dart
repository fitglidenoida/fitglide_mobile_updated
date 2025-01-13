import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInScreen extends StatefulWidget {
  const GoogleSignInScreen({super.key});

  @override
  State<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
   final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  String? clientId;

  @override
  void initState() {
    super.initState();
    _loadClientIdFromJson();
  }

  Future<void> _loadClientIdFromJson() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/google_oauth_client.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      setState(() {
        clientId = jsonData['web']['client_id'];
      });
      debugPrint('Client ID: $clientId');
    } catch (e) {
      debugPrint('Error loading client ID: $e');
    }
  }

  Future<void> _handleSignIn() async {
    try {
      final GoogleSignInAccount? user = await _googleSignIn.signIn();
      if (user != null) {
        final GoogleSignInAuthentication googleAuth =
            await user.authentication;

        Navigator.pop(context, {
          'idToken': googleAuth.idToken,
          'accessToken': googleAuth.accessToken,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-in canceled')),
        );
      }
    } catch (error) {
      debugPrint('Error during sign-in: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-in failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Sign-In')),
      body: Center(
        child: ElevatedButton(
          onPressed: clientId == null ? null : _handleSignIn,
          child: const Text('Authorize via Google'),
        ),
      ),
    );
  }
}

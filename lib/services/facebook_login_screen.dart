import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class FacebookLoginScreen extends StatefulWidget {
  const FacebookLoginScreen({Key? key}) : super(key: key); // Add key

  @override
  State<FacebookLoginScreen> createState() => _FacebookLoginScreenState();
}

class _FacebookLoginScreenState extends State<FacebookLoginScreen> {
  bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;
  String? _errorMessage; // To display error messages

  Future<void> _handleFacebookLogin() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData();
        setState(() {
          _isLoggedIn = true;
          _userData = userData;
          _errorMessage = null; // Clear any previous error
        });
        print(_userData);
      } else {
        setState(() {
          _errorMessage = result.message; // Store the error message
        });
        debugPrint('Facebook login failed: ${result.message}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString(); // Store the error message
      });
      debugPrint('Error during Facebook login: $e');
    }
  }

  Future<void> _handleFacebookLogout() async {
    await FacebookAuth.instance.logOut();
    setState(() {
      _isLoggedIn = false;
      _userData = null;
      _errorMessage = null; // Clear any previous error
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facebook Login'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_isLoggedIn) ...[
              CircleAvatar(
                backgroundImage: NetworkImage(
                    _userData!['picture']['data']['url']), // Null check is necessary
              ),
              Text('Welcome, ${_userData!['name']}!'), // Null check is necessary
              ElevatedButton(
                onPressed: _handleFacebookLogout,
                child: const Text('Logout'),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: _handleFacebookLogin,
                child: const Text('Login with Facebook'),
              ),
              if (_errorMessage != null) // Display error message if any
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
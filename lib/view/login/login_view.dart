import 'package:fitglide_mobile_application/common/colo_extension.dart';
import 'package:fitglide_mobile_application/common_widget/round_button.dart';
import 'package:fitglide_mobile_application/common_widget/round_textfield.dart';
import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:fitglide_mobile_application/services/storage_service.dart';
import 'package:fitglide_mobile_application/view/login/signup_view.dart';
import 'package:fitglide_mobile_application/view/main_tab/main_tab_view.dart';
import 'package:flutter/material.dart';
import 'package:fitglide_mobile_application/services/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool isCheck = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
    bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;
  String? _errorMessage;
  
  Future<void> handleLogin() async {
    try {
      final authService = AuthService();
      final response = await authService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (response.containsKey('jwt')) {
        final token = response['jwt'];
        await StorageService.saveToken(token);

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainTabView()),
          );
        }
      } else {
        throw Exception('Invalid login response: Missing token.');
      }
    } catch (e) {
      debugPrint('Login Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      }
    }
  }

   final GoogleSignInService _googleSignInService = GoogleSignInService();

  Future<void> _handleGoogleSignIn() async {
    final Map<String, dynamic>? userData = await _googleSignInService.signInWithGoogle();
    if (userData != null) {
      // Here you could save the user data or token, etc.
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainTabView()),
        );
      }
    }
  }

 // To display error messages

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



  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: TColor.white,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Container(
            height: media.height * 0.9,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Hey there,",
                  style: TextStyle(color: TColor.gray, fontSize: 16),
                ),
                Text(
                  "Welcome Back",
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: media.width * 0.05),
                RoundTextField(
                  controller: emailController,
                  hitText: "Email",
                  icon: "assets/img/email.png",
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: media.width * 0.04),
                RoundTextField(
                  controller: passwordController,
                  hitText: "Password",
                  icon: "assets/img/lock.png",
                  obscureText: true,
                  rigtIcon: TextButton(
                    onPressed: () {},
                    child: Container(
                      alignment: Alignment.center,
                      width: 20,
                      height: 20,
                      child: Image.asset(
                        "assets/img/show_password.png",
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                        color: TColor.gray,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: media.width * 0.04),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Forgot your password?",
                      style: TextStyle(
                        color: TColor.gray,
                        fontSize: 10,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                RoundButton(
                  title: "Login",
                  onPressed: handleLogin,
                ),
                SizedBox(height: media.width * 0.04),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: TColor.gray.withOpacity(0.5),
                      ),
                    ),
                    Text(
                      "  Or  ",
                      style: TextStyle(color: TColor.black, fontSize: 12),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: TColor.gray.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: media.width * 0.04),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _handleGoogleSignIn,
                      child: Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: TColor.white,
                          border: Border.all(
                            width: 1,
                            color: TColor.gray.withOpacity(0.4),
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Image.asset(
                          "assets/img/google.png",
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ),
                    SizedBox(width: media.width * 0.04),
                    GestureDetector(
                      onTap: _handleFacebookLogin,
                      child: Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: TColor.white,
                          border: Border.all(
                            width: 1,
                            color: TColor.gray.withOpacity(0.4),
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Image.asset(
                          "assets/img/facebook.png",
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: media.width * 0.04),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignUpView()),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Don’t have an account yet? ",
                        style: TextStyle(
                          color: TColor.black,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "Register",
                        style: TextStyle(
                          color: TColor.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: media.width * 0.04),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

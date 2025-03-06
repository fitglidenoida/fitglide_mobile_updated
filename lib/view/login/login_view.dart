import 'package:fitglide_mobile_application/common/colo_extension.dart';
import 'package:fitglide_mobile_application/common_widget/password_text_field.dart';
import 'package:fitglide_mobile_application/common_widget/round_button.dart';
import 'package:fitglide_mobile_application/common_widget/round_textfield.dart';
import 'package:fitglide_mobile_application/common_widget/spalsh_screen.dart';
import 'package:fitglide_mobile_application/view/login/signup_view.dart';
import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:fitglide_mobile_application/services/storage_service.dart';
import 'package:fitglide_mobile_application/view/main_tab/main_screen.dart';
import 'package:flutter/material.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool isCheck = false; // For "Remember Me" checkbox
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool isPasswordVisible = false; // For password toggle

  // Existing login and persistent login methods remain unchanged
Future<void> handleLogin() async {
    try {
      final authService = AuthService();
      final response = await authService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (response.containsKey('jwt')) {
        final token = response['jwt'] as String;
        await StorageService.saveToken(token);
        debugPrint('Token saved: $token');

        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SplashScreen(
                onLoadComplete: () async {
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainScreen()),
                    );
                  }
                },
              ),
            ),
          );
        }
      } else {
        throw Exception('Invalid login response: Missing token.');
      }
    } catch (e) {
      debugPrint('Login Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

Future<void> _checkPersistentLogin() async {
    debugPrint('Checking persistent login...');
    final token = await StorageService.getToken();
    debugPrint('Retrieved token: $token');
    if (token != null && token.isNotEmpty) {
      try {
        final isValid = await ApiService.validateToken(token);
        debugPrint('Token validation result: $isValid');
        if (isValid && mounted) {
          debugPrint('Navigating to MainTabView due to valid token');
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SplashScreen(
                onLoadComplete: () async {
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainScreen()),
                    );
                  }
                },
              ),
            ),
          );
        } else {
          debugPrint('Token invalid, clearing...');
          await StorageService.clearToken();
        }
      } catch (e) {
        debugPrint('Token validation failed: $e');
        await StorageService.clearToken();
      }
    } else {
      debugPrint('No token found, staying on LoginView');
    }
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPersistentLogin(); // Run after the build completes
    });
  }

@override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: TColor.backgroundLight, // Use light background
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [TColor.backgroundLight, TColor.backgroundLight.withOpacity(0.9)], // Subtle light gradient, no red strip
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Enhanced FitGlide Logo (larger, centered, no background box)
                        Padding(
                          padding: EdgeInsets.only(top: media.width * 0.05),
                          child: Image.asset(
                            "assets/img/fitglide_logo.png", // Replace with your logo path
                            width: 200, // Prominent size
                            height: 60, // Balanced height
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: media.width * 0.1),
                        // Headline and Subhead
                        Text(
                          "Ready to Glide Back In?",
                          style: TextStyle(
                            color: TColor.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          "Log in to unlock your fitness journey.",
                          style: TextStyle(
                            color: TColor.textSecondary,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: media.width * 0.1),
                        // Email Field (using RoundTextField)
                        RoundTextField(
                          controller: emailController,
                          hitText: "Email",
                          icon: "assets/img/email.png", // Use custom icon in primary red
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: media.width * 0.04),
                        // Password Field with Toggle (using PasswordTextField)
                        PasswordTextField(
                          controller: passwordController,
                          hitText: "Password",
                          icon: "assets/img/lock.png", // Use custom icon in primary red
                          obscureText: !isPasswordVisible,
                          onToggleVisibility: (visible) {
                            setState(() {
                              isPasswordVisible = visible;
                            });
                          },
                        ),
                        // Remember Me Checkbox
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: isCheck,
                              onChanged: (value) {
                                setState(() {
                                  isCheck = value!;
                                });
                              },
                              activeColor: TColor.primary, // Red checkmark
                              checkColor: TColor.textPrimaryDark,
                            ),
                            Text(
                              "Remember Me",
                              style: TextStyle(
                                color: TColor.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: media.width * 0.02),
                        // Forgot Password
                        TextButton(
                          onPressed: () {
                            // Implement forgot password logic here
                          },
                          child: Text(
                            "Forgot your password? Reset it here!",
                            style: TextStyle(
                              color: TColor.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        SizedBox(height: media.width * 0.06),
                        // Login Button (using updated RoundButton with custom styling)
                        RoundButton(
                          title: "Login",
                          onPressed: handleLogin,
                          backgroundColor: TColor.primary, // Red button
                          textColor: TColor.textPrimaryDark, // White text
                          gradient: LinearGradient(
                            colors: [TColor.primaryLight, TColor.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        SizedBox(height: media.width * 0.04),
                        // Signup Nudge with "Or" separator and single-line text
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: TColor.grayWithOpacity(0.5),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text(
                                    "  Or  ",
                                    style: TextStyle(
                                      color: TColor.textPrimary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: TColor.grayWithOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: media.width * 0.02),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const SignUpView()),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "New to FitGlide? Join 5,000+ Gliders",
                                    style: TextStyle(
                                      color: TColor.secondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward,
                                    color: TColor.accent1,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
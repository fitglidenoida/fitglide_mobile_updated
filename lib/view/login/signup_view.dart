import 'package:fitglide_mobile_application/common/colo_extension.dart';
import 'package:fitglide_mobile_application/common_widget/password_text_field.dart';
import 'package:fitglide_mobile_application/common_widget/round_button.dart';
import 'package:fitglide_mobile_application/common_widget/round_textfield.dart';
import 'package:fitglide_mobile_application/common_widget/spalsh_screen.dart';
import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:fitglide_mobile_application/view/login/login_view.dart';
import 'package:fitglide_mobile_application/view/main_tab/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isPrivacyPolicyAccepted = false;
  String? documentId; // To store the document ID from the response
  bool isPasswordVisible = false; // For password toggle

void _registerUser() async {
    final String firstName = _firstNameController.text.trim();
    final String lastName = _lastNameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all the fields")),
      );
      return;
    }

    if (!isPrivacyPolicyAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please accept the Privacy Policy")),
      );
      return;
    }

    try {
      final data = {
        'email': email,
        'username': email,
        'password': password,
        'First_name': firstName,
        'Last_name': lastName,
      };

      debugPrint('Sending Data: $data');

      final response = await ApiService.register(data);

      if (response.containsKey('jwt')) {
        final prefs = await SharedPreferences.getInstance();
        if (response.containsKey('user') && response['user']['id'] != null) {
          await prefs.setString('documentId', response['user']['id'].toString());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User ID not found in response")),
          );
          return;
        }

        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SplashScreen(
                onLoadComplete: () async {
                  if (mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => MainScreen()),
                    );
                  }
                },
              ),
            ),
          );
        }
      } else {
        String errorMessage = "Registration failed. Please try again.";
        if (response.containsKey('message')) {
          errorMessage = response['message'];
        }
        debugPrint('Registration Error: ${response.toString()}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      debugPrint('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: TColor.backgroundLight, // Use light background
      body: SingleChildScrollView(
        child: SafeArea(
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
                    width: 200, // Match LoginView size for prominence
                    height: 60, // Balanced height
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: media.width * 0.1),
                // Headline and Subhead
                Text(
                  "Start Your FitGlide Journey!",
                  style: TextStyle(
                    color: TColor.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  "Join 5,000+ Gliders and glide to your goals.",
                  style: TextStyle(
                    color: TColor.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: media.width * 0.1),
                // First Name Field (using RoundTextField)
                RoundTextField(
                  controller: _firstNameController,
                  hitText: "First Name",
                  icon: "assets/img/user_text.png", // Use existing icon
                  keyboardType: TextInputType.name,
                ),
                SizedBox(height: media.width * 0.04),
                // Last Name Field (using RoundTextField)
                RoundTextField(
                  controller: _lastNameController,
                  hitText: "Last Name",
                  icon: "assets/img/user_text.png", // Use existing icon
                  keyboardType: TextInputType.name,
                ),
                SizedBox(height: media.width * 0.04),
                // Email Field (using RoundTextField)
                RoundTextField(
                  controller: _emailController,
                  hitText: "Email",
                  icon: "assets/img/email.png", // Use existing icon
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: media.width * 0.04),
                // Password Field with Toggle (using PasswordTextField)
                PasswordTextField(
                  controller: _passwordController,
                  hitText: "Password",
                  icon: "assets/img/lock.png", // Use custom icon in primary red
                  obscureText: !isPasswordVisible,
                  onToggleVisibility: (visible) {
                    setState(() {
                      isPasswordVisible = visible;
                    });
                  },
                ),
                // Privacy Policy Checkbox
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          isPrivacyPolicyAccepted = !isPrivacyPolicyAccepted;
                        });
                      },
                      icon: Icon(
                        isPrivacyPolicyAccepted
                            ? Icons.check_box_outlined
                            : Icons.check_box_outline_blank_outlined,
                        color: TColor.gray,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        "By continuing you accept our Privacy Policy and\nTerms of Use",
                        style: TextStyle(color: TColor.textSecondary, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: media.width * 0.1), // Reduced gap from 0.4 to 0.1
                // Register Button (using updated RoundButton with custom styling)
                RoundButton(
                  title: "Register",
                  onPressed: _registerUser,
                  backgroundColor: TColor.primary, // Red button
                  textColor: TColor.textPrimaryDark, // White text
                  gradient: LinearGradient(
                    colors: [TColor.primaryLight, TColor.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                SizedBox(height: media.width * 0.04),
                // Improved "Or" separator and login nudge layout
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
                      MaterialPageRoute(builder: (context) => const LoginView()),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Already a Glider? Log In Here!",
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
          ),
        ),
      ),
    );
  }
}
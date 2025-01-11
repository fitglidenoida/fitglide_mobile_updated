import 'package:fitglide_mobile_application/view/login/complete_profile_view.dart';
import 'package:fitglide_mobile_application/view/login/login_view.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../common_widget/round_textfield.dart';
import '../../services/api_service.dart';
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

  void _registerUser() async {
    final String firstName = _firstNameController.text.trim();
    final String lastName = _lastNameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    // Field validation
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
        'username': email, // Assuming email is used as username
        'password': password,
        'First_name': firstName,
        'Last_name': lastName,
      };

      debugPrint('Sending Data: $data');

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const Center(child: CircularProgressIndicator()),
      );

    final response = await ApiService.register(data);
    Navigator.pop(context);

    if (response != null && response.containsKey('jwt')) {
      // Registration successful
      final prefs = await SharedPreferences.getInstance();
      if (response.containsKey('user') && response['user']['id'] != null) {
        await prefs.setString('documentId', response['user']['id'].toString());
      }else{
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User ID not found in response")),
        );
         return;
      }

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CompleteProfileView()),
        );
      }

      } else {
        // Log and display server error message if available
        String errorMessage = "Registration failed. Please try again.";
        if (response != null && response.containsKey('message')) {
          errorMessage = response['message'];
        }
        debugPrint('Registration Error: ${response.toString()}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Ensure the dialog is hidden
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
      backgroundColor: TColor.white,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Hey there,",
                  style: TextStyle(color: TColor.gray, fontSize: 16),
                ),
                Text(
                  "Create an Account",
                  style: TextStyle(
                      color: TColor.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w700),
                ),
                SizedBox(height: media.width * 0.05),
                RoundTextField(
                  hitText: "First Name",
                  icon: "assets/img/user_text.png",
                  controller: _firstNameController,
                    keyboardType: TextInputType.name,
                ),
                SizedBox(height: media.width * 0.04),
                RoundTextField(
                  hitText: "Last Name",
                  icon: "assets/img/user_text.png",
                  controller: _lastNameController,
                    keyboardType: TextInputType.name,
                ),
                SizedBox(height: media.width * 0.04),
                RoundTextField(
                  hitText: "Email",
                  icon: "assets/img/email.png",
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: media.width * 0.04),
                RoundTextField(
                  hitText: "Password",
                  icon: "assets/img/lock.png",
                  obscureText: true,
                  controller: _passwordController,
                    keyboardType: TextInputType.visiblePassword,
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
                        style: TextStyle(color: TColor.gray, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: media.width * 0.4),
                RoundButton(title: "Register", onPressed: _registerUser),
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
                        "Already have an account? ",
                        style: TextStyle(
                          color: TColor.black,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "Login",
                        style: TextStyle(
                            color: TColor.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
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

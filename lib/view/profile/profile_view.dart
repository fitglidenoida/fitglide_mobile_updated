import 'package:fitglide_mobile_application/common_widget/strava_connect_button.dart';
import 'package:fitglide_mobile_application/common_widget/title_subtitle_cell.dart';
import 'package:fitglide_mobile_application/services/user_service.dart';
import 'package:fitglide_mobile_application/view/login/login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:intl/intl.dart';
import '../../common/common.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool positive = false;
  bool stravaConnected = false;
  bool isFitnessBridgeExpanded = false;
  bool isPersonalDataExpanded = false;
  bool isChangePasswordExpanded = false;
  bool isHealthVitalsExpanded = false;
  bool isPersonalEditing = false;
  bool isVitalsEditing = false;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  UserData? userData;
  String bmiCategory = "Loading...";
  String fitnessProgram = "No program set";
  bool isLoading = true;

  // Personal Data
  String? firstName;
  String? lastName;
  String? mobile;
  String? email;

  // Health Vitals
  double? currentWeight;
  String? dob;
  double? bmi;
  double? bmr;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      isLoading = true;
    });
    try {
      userData = await UserService.fetchUserData();
      if (userData != null) {
        final userDetails = await DataService().fetchUserDetails();
        firstName = userDetails['first_name'] ?? userData!.firstName;
        lastName = userDetails['last_name'] ?? 'N/A';
        mobile = userDetails['mobile'] ?? 'N/A';
        email = userDetails['email'] ?? 'N/A';

        _firstNameController.text = firstName ?? '';
        _lastNameController.text = lastName ?? '';
        _mobileController.text = mobile ?? '';
        _emailController.text = email ?? '';

        final healthResponse = await DataService().fetchHealthVitals(userData!.username);
        if (healthResponse.isNotEmpty) {
          final vitalData = healthResponse[0]['attributes'] ?? healthResponse[0];
          fitnessProgram = vitalData['fitness_program'] as String? ?? "No program set";
          currentWeight = (vitalData['WeightInKilograms'] as num?)?.toDouble() ?? 0.0;
          final heightCm = (vitalData['height'] as num?)?.toDouble() ?? 0.0;
          dob = vitalData['date_of_birth'] as String? ?? 'N/A';

          _weightController.text = currentWeight?.toStringAsFixed(1) ?? '';
          _dobController.text = dob ?? '';

          // Calculate BMI
          final heightM = heightCm / 100.0;
          bmi = heightM > 0 ? currentWeight! / (heightM * heightM) : null;
          bmiCategory = userData!.interpretBMI(bmi ?? 0);

          // Calculate BMR (Mifflin-St Jeor Equation, assuming male)
          final age = dob != 'N/A' ? calculateAge(dob!) : 30;
          bmr = bmi != null ? 10 * currentWeight! + 6.25 * heightCm - 5 * age + 5 : null;
        }
      } else {
        bmiCategory = "User data not found.";
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      bmiCategory = "Error fetching data.";
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _secureStorage.deleteAll();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginView()),
          (route) => false,
        );
      }
    } catch (error) {
      debugPrint("Error during logout: $error");
    }
  }

  Future<void> _updatePersonalData() async {
    try {
      await DataService().updateUserDetails({
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'mobile': _mobileController.text,
        'email': _emailController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Personal data updated successfully')),
      );
      setState(() {
        isPersonalEditing = false;
      });
      _fetchUserData();
    } catch (e) {
      debugPrint('Error updating personal data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update personal data: $e')),
      );
    }
  }

  Future<void> _updateHealthVitals() async {
    try {
      final healthVitalsList = await DataService().fetchHealthVitals(userData!.username);
      final documentId = healthVitalsList.isNotEmpty ? healthVitalsList[0]['id'].toString() : null;
      final data = {
        'WeightInKilograms': double.tryParse(_weightController.text) ?? 0,
        'height': userData!.heightCm ?? 0, // Assuming heightCm is fixed or fetched elsewhere
        'date_of_birth': _dobController.text,
      };
      if (documentId != null) {
        await DataService().updateHealthVitals(documentId, data);
      } else {
        await DataService().postHealthVitals({
          ...data,
          'users_permissions_user': {'connect': [{'id': await UserService.getUserId()}]},
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Health vitals updated successfully')),
      );
      setState(() {
        isVitalsEditing = false;
      });
      _fetchUserData();
    } catch (e) {
      debugPrint('Error updating health vitals: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update health vitals: $e')),
      );
    }
  }

  Future<void> _changePassword() async {
    try {
      await ApiService.post(
        'auth/change-password',
        {
          'currentPassword': _oldPasswordController.text,
          'password': _newPasswordController.text,
          'passwordConfirmation': _newPasswordController.text,
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully')),
      );
      _oldPasswordController.clear();
      _newPasswordController.clear();
    } catch (e) {
      debugPrint('Error changing password: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to change password: $e')),
      );
    }
  }

  int calculateAge(String dateOfBirth) {
    DateTime dob = DateTime.parse(dateOfBirth);
    DateTime today = DateTime.now().toLocal();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  Widget buildCollapsibleSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget content,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          color: TColor.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: TColor.black,
                ),
              ],
            ),
            const SizedBox(height: 8),
            AnimatedCrossFade(
              firstChild: Container(),
              secondChild: content,
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEditableRow(String label, String? value, TextEditingController controller, bool isEditing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        isEditing
            ? Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: label,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              )
            : Text(
                "$label: ${value ?? "N/A"}",
                style: TextStyle(color: TColor.black, fontSize: 14),
              ),
        IconButton(
          icon: Icon(isEditing ? Icons.check : Icons.edit, color: TColor.primaryColor1),
          onPressed: () {
            if (label == "First Name" || label == "Last Name" || label == "Mobile" || label == "Email") {
              setState(() {
                isPersonalEditing = !isPersonalEditing;
              });
            } else {
              setState(() {
                isVitalsEditing = !isVitalsEditing;
              });
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.white,
        centerTitle: true,
        elevation: 0,
        leadingWidth: 0,
        title: Text(
          "Profile",
          style: TextStyle(
            color: TColor.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Container(
              margin: const EdgeInsets.all(8),
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TColor.lightGray,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                "assets/img/more_btn.png",
                width: 15,
                height: 15,
                fit: BoxFit.contain,
              ),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: TColor.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.asset(
                            "assets/img/u2.png",
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                firstName ?? "Guest",
                                style: TextStyle(
                                  color: TColor.black,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                fitnessProgram,
                                style: TextStyle(
                                  color: TColor.gray,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: TitleSubtitleCell(
                            title: "${currentWeight?.toStringAsFixed(1) ?? "N/A"} kg",
                            subtitle: "Weight",
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TitleSubtitleCell(
                            title: "${bmi?.toStringAsFixed(1) ?? "N/A"}",
                            subtitle: "BMI",
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TitleSubtitleCell(
                            title: "${bmr?.toStringAsFixed(0) ?? "N/A"} kcal",
                            subtitle: "BMR",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      decoration: BoxDecoration(
                        color: TColor.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Notification",
                            style: TextStyle(
                              color: TColor.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(
                            height: 30,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Image.asset(
                                  "assets/img/p_notification.png",
                                  height: 15,
                                  width: 15,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    "Pop-up Notification",
                                    style: TextStyle(
                                      color: TColor.black,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                CustomAnimatedToggleSwitch<bool>(
                                  current: positive,
                                  values: const [false, true],
                                  indicatorSize: const Size.square(30.0),
                                  animationDuration: const Duration(milliseconds: 200),
                                  animationCurve: Curves.linear,
                                  onChanged: (b) => setState(() => positive = b),
                                  iconBuilder: (context, local, global) => const SizedBox(),
                                  wrapperBuilder: (context, global, child) {
                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Positioned(
                                          left: 10.0,
                                          right: 10.0,
                                          height: 30.0,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(colors: TColor.secondaryG),
                                              borderRadius: const BorderRadius.all(Radius.circular(50.0)),
                                            ),
                                          ),
                                        ),
                                        child,
                                      ],
                                    );
                                  },
                                  foregroundIndicatorBuilder: (context, global) {
                                    return SizedBox.fromSize(
                                      size: const Size(10, 10),
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: TColor.white,
                                          borderRadius: const BorderRadius.all(Radius.circular(50.0)),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black38,
                                              spreadRadius: 0.05,
                                              blurRadius: 1.1,
                                              offset: Offset(0.0, 0.8),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    buildCollapsibleSection(
                      title: "Fitness Bridge",
                      isExpanded: isFitnessBridgeExpanded,
                      onTap: () {
                        setState(() {
                          isFitnessBridgeExpanded = !isFitnessBridgeExpanded;
                        });
                      },
                      content: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Strava Connect",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: TColor.black,
                            ),
                          ),
                          CustomAnimatedToggleSwitch<bool>(
                            current: stravaConnected,
                            values: const [false, true],
                            indicatorSize: const Size.square(30.0),
                            animationDuration: const Duration(milliseconds: 200),
                            animationCurve: Curves.linear,
                            onChanged: (b) {
                              setState(() {
                                stravaConnected = b;
                                if (b) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => Dialog(
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        child: StravaConnectButton(),
                                      ),
                                    ),
                                  );
                                }
                              });
                            },
                            iconBuilder: (context, local, global) => const SizedBox(),
                            wrapperBuilder: (context, global, child) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned(
                                    left: 10.0,
                                    right: 10.0,
                                    height: 30.0,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: TColor.secondaryG),
                                        borderRadius: const BorderRadius.all(Radius.circular(50.0)),
                                      ),
                                    ),
                                  ),
                                  child,
                                ],
                              );
                            },
                            foregroundIndicatorBuilder: (context, global) {
                              return SizedBox.fromSize(
                                size: const Size(10, 10),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: TColor.white,
                                    borderRadius: const BorderRadius.all(Radius.circular(50.0)),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black38,
                                        spreadRadius: 0.05,
                                        blurRadius: 1.1,
                                        offset: Offset(0.0, 0.8),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    buildCollapsibleSection(
                      title: "Personal Data",
                      isExpanded: isPersonalDataExpanded,
                      onTap: () {
                        setState(() {
                          isPersonalDataExpanded = !isPersonalDataExpanded;
                        });
                      },
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildEditableRow("First Name", firstName, _firstNameController, isPersonalEditing),
                          const SizedBox(height: 8),
                          buildEditableRow("Last Name", lastName, _lastNameController, isPersonalEditing),
                          const SizedBox(height: 8),
                          buildEditableRow("Mobile", mobile, _mobileController, isPersonalEditing),
                          const SizedBox(height: 8),
                          buildEditableRow("Email", email, _emailController, isPersonalEditing),
                          if (isPersonalEditing) ...[
                            const SizedBox(height: 10),
                            RoundButton(
                              title: "Save",
                              onPressed: _updatePersonalData,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    buildCollapsibleSection(
                      title: "Change Password",
                      isExpanded: isChangePasswordExpanded,
                      onTap: () {
                        setState(() {
                          isChangePasswordExpanded = !isChangePasswordExpanded;
                        });
                      },
                      content: Column(
                        children: [
                          TextField(
                            controller: _oldPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: "Old Password",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _newPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: "New Password",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          RoundButton(
                            title: "Change Password",
                            onPressed: _changePassword,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    buildCollapsibleSection(
                      title: "Health Vitals",
                      isExpanded: isHealthVitalsExpanded,
                      onTap: () {
                        setState(() {
                          isHealthVitalsExpanded = !isHealthVitalsExpanded;
                        });
                      },
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildEditableRow("Current Weight", currentWeight?.toStringAsFixed(1), _weightController, isVitalsEditing),
                          const SizedBox(height: 8),
                          buildEditableRow("Date of Birth", dob, _dobController, isVitalsEditing),
                          const SizedBox(height: 8),
                          Text("BMI: ${bmi?.toStringAsFixed(1) ?? "N/A"}", style: TextStyle(color: TColor.black, fontSize: 14)),
                          const SizedBox(height: 8),
                          Text("BMR: ${bmr?.toStringAsFixed(0) ?? "N/A"} kcal", style: TextStyle(color: TColor.black, fontSize: 14)),
                          if (isVitalsEditing) ...[
                            const SizedBox(height: 10),
                            RoundButton(
                              title: "Save",
                              onPressed: _updateHealthVitals,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
import 'package:fitglide_mobile_application/common_widget/strava_connect_button.dart';
import 'package:fitglide_mobile_application/common_widget/title_subtitle_cell.dart';
import 'package:fitglide_mobile_application/services/user_service.dart';
import 'package:fitglide_mobile_application/view/login/login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:intl/intl.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../view/main_tab/main_screen.dart';
import '../../view/meal_planner/meal_planner_view.dart';
import '../../view/sleep_tracker/sleep_tracker_view.dart';
import '../../view/workout_tracker/workout_hub_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool positive = false; // Notifications toggle
  bool stravaConnected = false;
  bool isFitnessBridgeExpanded = false;
  bool isPersonalDataExpanded = false;
  bool isChangePasswordExpanded = false;
  bool isHealthVitalsExpanded = false;
  bool isPersonalEditing = false;
  bool isVitalsEditing = false;
  int selectedTab = 4;

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
  double? heightCm;
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

  List<Map<String, dynamic>> badges = [
    {"icon": "assets/img/step_streak.png", "title": "Step Streak"},
    {"icon": "assets/img/sleep_streak.png", "title": "Sleep Streak"},
    {"icon": "assets/img/meal_goal.png", "title": "Meal Goal"},
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() => isLoading = true);
    try {
      userData = await UserService.fetchUserData();
      if (userData != null) {
        // Fetch personal data
        final userResponse = await ApiService.get('users/me?populate=*');
        firstName = userResponse['first_name'] as String? ?? userData!.firstName;
        lastName = userResponse['last_name'] as String? ?? 'N/A';
        mobile = userResponse['mobile'] as String? ?? 'N/A';
        // email = userResponse['email'] as String? ?? userData!.email;

        _firstNameController.text = firstName ?? '';
        _lastNameController.text = lastName ?? '';
        _mobileController.text = mobile ?? '';
        _emailController.text = email ?? '';

        // Fetch health vitals
        final healthResponse = await ApiService.get('health-vitals?filters[users_permissions_user][username][\$eq]=${userData!.username}');
        final healthVitalsList = healthResponse['data'] as List<dynamic>? ?? [];
        if (healthVitalsList.isNotEmpty) {
          final vitalData = healthVitalsList[0]['attributes'] as Map<String, dynamic>;
          fitnessProgram = vitalData['fitness_program'] as String? ?? "No program set";
          currentWeight = (vitalData['WeightInKilograms'] as num?)?.toDouble() ?? 0.0;
          heightCm = (vitalData['height'] as num?)?.toDouble() ?? 0.0;
          dob = vitalData['date_of_birth'] as String? ?? 'N/A';

          _weightController.text = currentWeight?.toStringAsFixed(1) ?? '';
          _dobController.text = dob ?? '';

          bmi = heightCm! > 0 ? currentWeight! / ((heightCm! / 100) * (heightCm! / 100)) : null;
          bmiCategory = userData!.interpretBMI(bmi ?? 0);

          final age = dob != 'N/A' ? calculateAge(dob!) : 30;
          bmr = bmi != null ? 10 * currentWeight! + 6.25 * heightCm! - 5 * age + 5 : null;
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      bmiCategory = "Error fetching data.";
    } finally {
      if (mounted) setState(() => isLoading = false);
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
      final userId = await UserService.getUserId();
      await ApiService.put('users/$userId', {
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'mobile': _mobileController.text,
        'email': _emailController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Personal data updated successfully')));
      setState(() => isPersonalEditing = false);
      _fetchUserData();
    } catch (e) {
      debugPrint('Error updating personal data: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update personal data: $e')));
    }
  }

  Future<void> _updateHealthVitals() async {
    try {
      final healthResponse = await ApiService.get('health-vitals?filters[users_permissions_user][username][\$eq]=${userData!.username}');
      final healthVitalsList = healthResponse['data'] as List<dynamic>? ?? [];
      final data = {
        'WeightInKilograms': double.tryParse(_weightController.text) ?? 0,
        'height': heightCm ?? 0,
        'date_of_birth': _dobController.text,
        'users_permissions_user': userData!.username,
      };
      if (healthVitalsList.isNotEmpty) {
        final documentId = healthVitalsList[0]['id'].toString();
        await ApiService.put('health-vitals/$documentId', data);
      } else {
        await ApiService.post('health-vitals', {'data': data});
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Health vitals updated successfully')));
      setState(() => isVitalsEditing = false);
      _fetchUserData();
    } catch (e) {
      debugPrint('Error updating health vitals: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update health vitals: $e')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully')));
      _oldPasswordController.clear();
      _newPasswordController.clear();
    } catch (e) {
      debugPrint('Error changing password: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to change password: $e')));
    }
  }

  int calculateAge(String dateOfBirth) {
    DateTime dob = DateTime.parse(dateOfBirth);
    DateTime today = DateTime.now().toLocal();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) age--;
    return age;
  }

  Widget buildCollapsibleSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget content,
  }) {
    return Card(
      color: TColor.cardLight,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: TColor.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: TColor.textPrimary,
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(),
                secondChild: Padding(padding: const EdgeInsets.only(top: 10), child: content),
                crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    ).animate(effects: [FadeEffect(duration: 800.ms)]);
  }

  Widget _buildTrackingBox(String title, String value) {
    return Card(
      color: TColor.cardLight,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: TColor.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            Text(value, style: TextStyle(color: TColor.textPrimary, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Future<void> _selectAvatar() async {
    // Placeholder for avatar upload logic (e.g., image_picker)
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Avatar upload not implemented yet")));
  }

  void _onTabTapped(int index) {
    setState(() => selectedTab = index);
    switch (index) {
      case 0: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen())); break;
      case 1: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const WorkoutHubView())); break;
      case 2: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MealPlannerView())); break;
      case 3: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SleepTrackerView())); break;
      case 4: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileView())); break;
    }
  }

  void _showMaxDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TColor.cardLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: TColor.primary)),
        content: Row(
          children: [
            Image.asset('assets/img/max_avatar.png', width: 50, height: 50, errorBuilder: (context, error, stackTrace) => Icon(Icons.person, color: TColor.primary, size: 50)),
            SizedBox(width: 10),
            Expanded(child: Text("Max says: Keep your profile updated!", style: TextStyle(color: TColor.textPrimary))),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Close", style: TextStyle(color: TColor.primary)))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: TColor.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Banner
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [TColor.primary, TColor.primaryLight]),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: _selectAvatar,
                                    child: Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(40),
                                          child: Image.asset("assets/img/u2.png", width: 80, height: 80, fit: BoxFit.cover),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(color: TColor.white, borderRadius: BorderRadius.circular(12)),
                                          child: Icon(Icons.edit, size: 16, color: TColor.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(firstName ?? "Guest", style: TextStyle(color: TColor.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                        Text(fitnessProgram, style: TextStyle(color: TColor.white.withOpacity(0.8), fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TitleSubtitleCell(title: "${currentWeight?.toStringAsFixed(1) ?? "N/A"} kg", subtitle: "Weight"),
                                  TitleSubtitleCell(title: bmi?.toStringAsFixed(1) ?? "N/A", subtitle: "BMI"),
                                  TitleSubtitleCell(title: "${bmr?.toStringAsFixed(0) ?? "N/A"} kcal", subtitle: "BMR"),
                                ],
                              ),
                            ],
                          ),
                        ).animate(effects: [FadeEffect(duration: 800.ms)]),
                        // Tracking Boxes
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildTrackingBox("Today", "8,500 steps"),
                              _buildTrackingBox("Weekly Avg", "7,200 steps"),
                              _buildTrackingBox("Monthly Avg", "7,000 steps"),
                            ],
                          ),
                        ),
                        // Achievements
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Achievements", style: TextStyle(color: TColor.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: badges.length,
                                  itemBuilder: (context, index) {
                                    final badge = badges[index];
                                    return Container(
                                      margin: const EdgeInsets.only(right: 10),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: TColor.cardLight, borderRadius: BorderRadius.circular(10)),
                                      child: Row(
                                        children: [
                                          Image.asset(badge['icon'] ?? 'assets/img/step_streak.png', width: 50, height: 50, errorBuilder: (context, error, stackTrace) => Icon(Icons.star, color: TColor.primary, size: 50)),
                                          const SizedBox(width: 10),
                                          Text(badge['title'], style: TextStyle(color: TColor.textPrimary, fontSize: 14)),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Collapsible Sections
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Column(
                            children: [
                              buildCollapsibleSection(
                                title: "Personal Data",
                                isExpanded: isPersonalDataExpanded,
                                onTap: () => setState(() => isPersonalDataExpanded = !isPersonalDataExpanded),
                                content: Column(
                                  children: [
                                    _buildEditableRow("First Name", firstName, _firstNameController, isPersonalEditing),
                                    const SizedBox(height: 8),
                                    _buildEditableRow("Last Name", lastName, _lastNameController, isPersonalEditing),
                                    const SizedBox(height: 8),
                                    _buildEditableRow("Mobile", mobile, _mobileController, isPersonalEditing),
                                    const SizedBox(height: 8),
                                    _buildEditableRow("Email", email, _emailController, isPersonalEditing),
                                    if (isPersonalEditing) ...[
                                      const SizedBox(height: 10),
                                      RoundButton(title: "Save", type: RoundButtonType.bgGradient, onPressed: _updatePersonalData),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              buildCollapsibleSection(
                                title: "Health Vitals",
                                isExpanded: isHealthVitalsExpanded,
                                onTap: () => setState(() => isHealthVitalsExpanded = !isHealthVitalsExpanded),
                                content: Column(
                                  children: [
                                    _buildEditableRow("Weight (kg)", currentWeight?.toStringAsFixed(1), _weightController, isVitalsEditing),
                                    const SizedBox(height: 8),
                                    _buildEditableRow("DOB", dob, _dobController, isVitalsEditing),
                                    const SizedBox(height: 8),
                                    Text("BMI: ${bmi?.toStringAsFixed(1) ?? "N/A"}", style: TextStyle(color: TColor.textPrimary, fontSize: 14)),
                                    const SizedBox(height: 8),
                                    Text("BMR: ${bmr?.toStringAsFixed(0) ?? "N/A"} kcal", style: TextStyle(color: TColor.textPrimary, fontSize: 14)),
                                    if (isVitalsEditing) ...[
                                      const SizedBox(height: 10),
                                      RoundButton(title: "Save", type: RoundButtonType.bgGradient, onPressed: _updateHealthVitals),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              buildCollapsibleSection(
                                title: "Fitness Bridge",
                                isExpanded: isFitnessBridgeExpanded,
                                onTap: () => setState(() => isFitnessBridgeExpanded = !isFitnessBridgeExpanded),
                                content: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Strava Connect", style: TextStyle(color: TColor.textPrimary, fontSize: 14)),
                                    CustomAnimatedToggleSwitch<bool>(
                                      current: stravaConnected,
                                      values: const [false, true],
                                      indicatorSize: const Size.square(20.0),
                                      animationDuration: const Duration(milliseconds: 200),
                                      animationCurve: Curves.linear,
                                      onChanged: (b) {
                                        setState(() {
                                          stravaConnected = b;
                                          if (b) showDialog(context: context, builder: (context) => Dialog(child: Container(padding: const EdgeInsets.all(20), child: StravaConnectButton())));
                                        });
                                      },
                                      iconBuilder: (context, local, global) => const SizedBox(),
                                      wrapperBuilder: (context, global, child) => Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Positioned(
                                            left: 5.0,
                                            right: 5.0,
                                            height: 20.0,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(colors: TColor.secondaryG),
                                                borderRadius: const BorderRadius.all(Radius.circular(50.0)),
                                              ),
                                            ),
                                          ),
                                          child,
                                        ],
                                      ),
                                      foregroundIndicatorBuilder: (context, global) => SizedBox.fromSize(
                                        size: const Size(10, 10),
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: TColor.white,
                                            borderRadius: const BorderRadius.all(Radius.circular(50.0)),
                                            boxShadow: const [BoxShadow(color: Colors.black38, spreadRadius: 0.05, blurRadius: 1.1, offset: Offset(0.0, 0.8))],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              buildCollapsibleSection(
                                title: "Settings",
                                isExpanded: isChangePasswordExpanded,
                                onTap: () => setState(() => isChangePasswordExpanded = !isChangePasswordExpanded),
                                content: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Notifications", style: TextStyle(color: TColor.textPrimary, fontSize: 14)),
                                        CustomAnimatedToggleSwitch<bool>(
                                          current: positive,
                                          values: const [false, true],
                                          indicatorSize: const Size.square(20.0),
                                          animationDuration: const Duration(milliseconds: 200),
                                          animationCurve: Curves.linear,
                                          onChanged: (b) => setState(() => positive = b),
                                          iconBuilder: (context, local, global) => const SizedBox(),
                                          wrapperBuilder: (context, global, child) => Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Positioned(
                                                left: 5.0,
                                                right: 5.0,
                                                height: 20.0,
                                                child: DecoratedBox(
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(colors: TColor.secondaryG),
                                                    borderRadius: const BorderRadius.all(Radius.circular(50.0)),
                                                  ),
                                                ),
                                              ),
                                              child,
                                            ],
                                          ),
                                          foregroundIndicatorBuilder: (context, global) => SizedBox.fromSize(
                                            size: const Size(10, 10),
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: TColor.white,
                                                borderRadius: const BorderRadius.all(Radius.circular(50.0)),
                                                boxShadow: const [BoxShadow(color: Colors.black38, spreadRadius: 0.05, blurRadius: 1.1, offset: Offset(0.0, 0.8))],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
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
                                    RoundButton(title: "Change Password", type: RoundButtonType.bgGradient, onPressed: _changePassword),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
                // Bottom Navigation
                BottomNavigationBar(
                  currentIndex: selectedTab,
                  onTap: _onTabTapped,
                  items: [
                    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home, color: TColor.primary), label: "Home"),
                    BottomNavigationBarItem(icon: Icon(Icons.fitness_center_outlined), activeIcon: Icon(Icons.fitness_center, color: TColor.primary), label: "Workout"),
                    BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), activeIcon: Icon(Icons.restaurant, color: TColor.primary), label: "Meal"),
                    BottomNavigationBarItem(icon: Icon(Icons.bedtime), activeIcon: Icon(Icons.nightlight_round, color: TColor.primary), label: "Sleep"),
                    BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person, color: TColor.primary), label: "Profile"),
                  ],
                  selectedItemColor: TColor.primary,
                  unselectedItemColor: TColor.textSecondary,
                  backgroundColor: TColor.backgroundLight,
                  elevation: 0,
                  type: BottomNavigationBarType.fixed,
                  selectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 14),
                ).animate(effects: [FadeEffect(duration: 800.ms)]),
              ],
            ),
            // FAB and Max
            Positioned(
              bottom: 70,
              right: 20,
              child: Row(
                children: [
                  FloatingActionButton(
                    onPressed: _selectAvatar,
                    backgroundColor: TColor.primary,
                    child: Icon(Icons.edit, color: TColor.textPrimaryDark),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _showMaxDialog,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: TColor.cardLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: TColor.primary.withOpacity(0.3))),
                      child: Image.asset('assets/img/max_avatar.png', width: 50, height: 50, errorBuilder: (context, error, stackTrace) => Icon(Icons.person, color: TColor.primary, size: 50)),
                    ),
                  ),
                ],
              ).animate(effects: [FadeEffect(duration: 800.ms), ScaleEffect(duration: 800.ms, begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0))]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableRow(String label, String? value, TextEditingController controller, bool isEditing) {
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
            : Text("$label: ${value ?? "N/A"}", style: TextStyle(color: TColor.textPrimary, fontSize: 14)),
        IconButton(
          icon: Icon(isEditing ? Icons.check : Icons.edit, color: TColor.primary),
          onPressed: () {
            if (label == "First Name" || label == "Last Name" || label == "Mobile" || label == "Email") {
              setState(() => isPersonalEditing = !isPersonalEditing);
            } else {
              setState(() => isVitalsEditing = !isVitalsEditing);
            }
          },
        ),
      ],
    );
  }
}
import '../../common/colo_extension.dart';
import '../../services/api_service.dart';
import '../../view/login/what_your_goal_view.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common_widget/round_button.dart';
import '../../common_widget/round_textfield.dart';
import 'package:intl/intl.dart'; // Import this for date formatting


class CompleteProfileView extends StatefulWidget {
  const CompleteProfileView({super.key});

  @override
  State<CompleteProfileView> createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends State<CompleteProfileView> {
  TextEditingController dateOfBirth = TextEditingController();
  TextEditingController weight = TextEditingController();
  TextEditingController height = TextEditingController();

  String? selectedGender;

Future<void> updateHealthVitals() async {
  final prefs = await SharedPreferences.getInstance();
  final documentId = prefs.getString('documentId');

  if (documentId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User ID not found. Please login again")),
    );
    return;
  }

  // Parse and format the dateOfBirth field
  String? formattedDateOfBirth;
  try {
    if (dateOfBirth.text.isNotEmpty) {
      final parsedDate = DateFormat('dd/MM/yyyy').parse(dateOfBirth.text); // Assuming input is 'dd/MM/yyyy'
      formattedDateOfBirth = DateFormat('yyyy-MM-dd').format(parsedDate); // Convert to 'yyyy-MM-dd'
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Invalid date format. Please use dd/MM/yyyy")),
    );
    return;
  }

  final data = {
    "data": {
      "WeightInKilograms": weight.text,
      "gender": selectedGender,
      "height": height.text,
      "date_of_birth": formattedDateOfBirth,
      "username": {
        "connect": [int.parse(documentId)]
      }
    }
  };

  try {
    final response = await ApiService.post('health-vitals/', data);

    if (response == null || response is Exception) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $response')),
      );
      debugPrint('API Error: $response');
    } else if (response.containsKey('error')) {
      final errorMessage = response['error']['message'] ?? 'Unknown error';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $errorMessage')),
      );
      debugPrint('API Error: $response');
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WhatsYourGoalView()),
      );
    }
  } catch (e) {
    debugPrint('Exception during API call: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exception: $e')),
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
            padding: const EdgeInsets.all(15.0),
            child: Column(
              children: [
                Image.asset(
                  "assets/img/complete_profile.png",
                  width: media.width,
                  fit: BoxFit.fitWidth,
                ),
                SizedBox(height: media.width * 0.05),
                Text(
                  "Build your perfect fitness plan!",
                  style: TextStyle(
                    color: TColor.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "Complete your profile to get started.",
                  style: TextStyle(color: TColor.gray, fontSize: 12),
                ),
                SizedBox(height: media.width * 0.05),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Column(
                    children: [
                      // Gender Selection
                      Container(
                        decoration: BoxDecoration(
                          color: TColor.lightGray,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            Container(
                              alignment: Alignment.center,
                              width: 50,
                              height: 50,
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              child: Image.asset(
                                "assets/img/gender.png",
                                width: 20,
                                height: 20,
                                fit: BoxFit.contain,
                                color: TColor.gray,
                              ),
                            ),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedGender,
                                  items: ["Male", "Female"]
                                      .map((gender) => DropdownMenuItem(
                                            value: gender,
                                            child: Text(
                                              gender,
                                              style: TextStyle(
                                                color: TColor.gray,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedGender = value;
                                    });
                                  },
                                  isExpanded: true,
                                  hint: Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text(
                                      "Choose Gender",
                                      style: TextStyle(
                                        color: TColor.gray,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: media.width * 0.04),

                      // Date of Birth
                      RoundTextField(
                        controller: dateOfBirth,
                        hitText: "Date of Birth",
                        icon: "assets/img/date.png",
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              dateOfBirth.text =
                                  "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                            });
                          }
                        },
                      ),

                      SizedBox(height: media.width * 0.04),

                      // Weight Input
                      Row(
                        children: [
                          Expanded(
                            child: RoundTextField(
                              controller: weight,
                              hitText: "Your Weight",
                              icon: "assets/img/weight.png",
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 50,
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: TColor.secondaryG,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              "KG",
                              style: TextStyle(
                                color: TColor.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: media.width * 0.04),

                      // Height Input
                      Row(
                        children: [
                          Expanded(
                            child: RoundTextField(
                              controller: height,
                              hitText: "Your Height",
                              icon: "assets/img/hight.png",
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 50,
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: TColor.secondaryG,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              "CM",
                              style: TextStyle(
                                color: TColor.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: media.width * 0.07),

                      // Next Button
                      RoundButton(
                        title: "Next >",
                        onPressed: updateHealthVitals,
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

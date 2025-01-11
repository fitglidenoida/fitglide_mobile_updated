// ignore_for_file: unnecessary_null_comparison

import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:flutter/material.dart';

class BmiDisplay extends StatefulWidget {
  final String username;
  final Function(double?) onBmiCalculated;

  const BmiDisplay({
    Key? key,
    required this.username,
    required this.onBmiCalculated,
  }) : super(key: key);

  @override
  State<BmiDisplay> createState() => _BmiDisplayState();
}

final bmiNotifier = ValueNotifier<double?>(null);

class _BmiDisplayState extends State<BmiDisplay> {
  double? _bmi;
  String _bmiCategory = "Calculating BMI...";
  Map<String, dynamic>? _apiResponse;
  double? _weight;
  double? _height;
  String? _dateOfBirth;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAndCalculateBMI();
  }

  int calculateAge(String dateOfBirth) {
    DateTime dob = DateTime.parse(dateOfBirth);
    DateTime today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  String interpretBMI(double bmi, [int? age]) {
    if (age != null && age < 18) {
      return 'BMI interpretation for children/teenagers not implemented yet.';
    } else {
      if (bmi < 18.5) {
        return 'Underweight';
      } else if (bmi >= 18.5 && bmi < 24.9) {
        return 'Normal';
      } else if (bmi >= 25 && bmi < 29.9) {
        return 'Overweight';
      } else {
        return 'Obese';
      }
    }
  }

  Future<void> _fetchAndCalculateBMI() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch data from the API
      final response = await ApiService.get(
        'health-vitals?populate=*&filters[username][\$eq]=${widget.username}',
      );

      if (response == null || response.isEmpty || response['data'] == null) {
        setState(() {
          _bmi = null;
          _bmiCategory = "No health vitals data found.";
          _isLoading = false;
        });
        widget.onBmiCalculated(null);
        return;
      }

      // Parse the first entry in 'data'
      final List<dynamic> data = response['data'];
      if (data.isEmpty) {
        setState(() {
          _bmi = null;
          _bmiCategory = "No health vitals data found.";
          _isLoading = false;
        });
        widget.onBmiCalculated(null);
        return;
      }

      final Map<String, dynamic> vitalData = data[0];

      // Extract necessary fields
      final double? weightKg = (vitalData['WeightInKilograms'] as num?)?.toDouble();
      final double? heightCm = (vitalData['height'] as num?)?.toDouble();
      final String? dateOfBirth = vitalData['date_of_birth'] as String?;

      debugPrint("Weight: $weightKg, Height: $heightCm, DOB: $dateOfBirth");

      if (weightKg == null || heightCm == null || dateOfBirth == null) {
        setState(() {
          _bmi = null;
          _bmiCategory = "Missing vital data for BMI calculation.";
          _isLoading = false;
        });
        widget.onBmiCalculated(null);
        return;
      }

      // Update extracted values for display
      setState(() {
        _weight = weightKg;
        _height = heightCm;
        _dateOfBirth = dateOfBirth;
        _apiResponse = vitalData;
      });

      // Calculate BMI
      final heightM = heightCm / 100.0; // Convert height to meters
      final double bmi = weightKg / (heightM * heightM);

      // Determine BMI category
      final int age = calculateAge(dateOfBirth);
      final String bmiCategory = interpretBMI(bmi, age);

      // Update state
      setState(() {
        _bmi = bmi;
        _bmiCategory = bmiCategory;
        _isLoading = false;
      });

      // Update notifier and callback
      bmiNotifier.value = bmi;
      widget.onBmiCalculated(bmi);
    } catch (e, stackTrace) {
      debugPrint("Error fetching/calculating BMI: $e");
      debugPrint("Stack trace: $stackTrace");
      setState(() {
        _bmi = null;
        _bmiCategory = "An error occurred.";
        _isLoading = false;
      });
      widget.onBmiCalculated(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "BMI (Body Mass Index)",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        if (_isLoading)
          const CircularProgressIndicator()
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _bmi != null
                    ? "Your BMI is ${_bmi!.toStringAsFixed(1)}, $_bmiCategory"
                    : _bmiCategory,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                "Extracted Data:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (_weight != null)
                Text("Weight: ${_weight!.toStringAsFixed(1)} kg"),
              if (_height != null)
                Text("Height: ${_height!.toStringAsFixed(1)} cm"),
              if (_dateOfBirth != null) Text("Date of Birth: $_dateOfBirth"),
            ],
          ),
        if (_apiResponse != null) ...[
          const SizedBox(height: 16),
          const Text(
            "Raw API Data:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ..._apiResponse!.entries.map((entry) {
            return Text(
              "${entry.key}: ${entry.value}",
              style: const TextStyle(fontSize: 12),
            );
          }).toList(),
        ],
      ],
    );
  }
}

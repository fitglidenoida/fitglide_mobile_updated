import 'package:fitglide_mobile_application/services/api_service.dart';


class UserService {
  static Future<UserData> fetchUserData() async {
    final dataService = DataService();
    final userDetails = await dataService.fetchUserDetails();
    final username = userDetails['username'] ?? "";
    final healthVitals = username.isNotEmpty 
      ? await dataService.fetchHealthVitals(username) 
      : [];

    return UserData(
      firstName: userDetails['First_name'] ?? userDetails['first_name'] ?? "Guest",
      username: username,
      heightCm: (healthVitals.isNotEmpty ? healthVitals[0]['height'] as num? : null)?.toDouble(),
      weightKg: (healthVitals.isNotEmpty ? healthVitals[0]['WeightInKilograms'] as num? : null)?.toDouble(),
      dateOfBirth: healthVitals.isNotEmpty ? healthVitals[0]['date_of_birth'] as String? : null,
    );
  }
}

class UserData {
  final String firstName;
  final String username;
  final double? heightCm;
  final double? weightKg;
  final String? dateOfBirth;

  UserData({
    required this.firstName,
    required this.username,
    this.heightCm,
    this.weightKg,
    this.dateOfBirth,
  });

  int get age => dateOfBirth != null ? calculateAge(dateOfBirth!) : 0;

  double? get bmi => heightCm != null && weightKg != null
      ? weightKg! / ((heightCm! / 100) * (heightCm! / 100))
      : null;

  String interpretBMI(double bmi) {
    if (age < 18) {
      return 'BMI interpretation for children/teenagers not implemented yet.';
    } else if (bmi < 18.5) {
      return 'Under Weight';
    } else if (bmi >= 18.5 && bmi < 24.9) {
      return 'Normal Weight';
    } else if (bmi >= 25 && bmi < 29.9) {
      return 'Over Weight';
    } else {
      return 'Obese';
    }
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
}
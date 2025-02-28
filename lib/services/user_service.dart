import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:fitglide_mobile_application/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  static Future<UserData> fetchUserData() async {
    final dataService = DataService();
    final userDetails = await dataService.fetchUserDetails();
    final username = userDetails['username'] ?? "";
    final healthVitals = username.isNotEmpty 
      ? await dataService.fetchHealthVitals(username) 
      : [];

    if (healthVitals.isNotEmpty) {
      await StorageService.saveData('health_vitals_document_id', healthVitals[0]['documentId'].toString());
    } else {
      await StorageService.removeData('health_vitals_document_id');
    }

    return UserData(
      firstName: userDetails['First_name'] ?? userDetails['first_name'] ?? "Guest",
      username: username,
      heightCm: (healthVitals.isNotEmpty ? healthVitals[0]['height'] as num? : null)?.toDouble(),
      weightKg: (healthVitals.isNotEmpty ? healthVitals[0]['WeightInKilograms'] as num? : null)?.toDouble(),
      dateOfBirth: healthVitals.isNotEmpty ? healthVitals[0]['date_of_birth'] as String? : null,
      gender: healthVitals.isNotEmpty ? healthVitals[0]['gender'] as String? : null, // Added gender
    );
  }

  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    
    if (userId == null) {
      try {
        final userDetails = await DataService().fetchUserDetails();
        userId = userDetails['id']?.toString();
        if (userId != null) {
          await prefs.setString('userId', userId);
        } else {
          throw Exception('User ID could not be fetched from the server');
        }
      } catch (e) {
        print('Failed to fetch user ID from server: $e');
        throw Exception('User ID not found');
      }
    }

    return userId;
  }

  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
  }
}

class UserData {
  final String firstName;
  final String username;
  final double? heightCm;
  final double? weightKg;
  final String? dateOfBirth;
  final String? gender; // Added gender field

  UserData({
    required this.firstName,
    required this.username,
    this.heightCm,
    this.weightKg,
    this.dateOfBirth,
    this.gender, // Added to constructor
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
// For UserData

class SleepCalculator {
  static const Map<int, double> recommendedSleepHours = {
    18: 8.0,  // Teens & Young Adults
    30: 7.5,  // Adults
    50: 7.0,  // Middle-aged Adults
    65: 6.5   // Seniors
  };

  // Fetch sleep recommendation based on age & workout data
  static double getRecommendedSleepDuration(int age, double workoutHours) {
    double baseSleep = recommendedSleepHours.entries
        .firstWhere((entry) => age <= entry.key, orElse: () => MapEntry(65, 6.0))
        .value;

    // Adjust sleep based on workout activity
    if (workoutHours > 2) {
      baseSleep += 0.5; // More sleep for high-intensity workout
    } else if (workoutHours < 0.5) {
      baseSleep -= 0.5; // Less sleep for low activity
    }

    return baseSleep;
    
  }

}
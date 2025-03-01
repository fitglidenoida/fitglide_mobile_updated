import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:fitglide_mobile_application/common_widget/round_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/colo_extension.dart';

class WorkoutDetailView extends StatefulWidget {
  final Map<String, dynamic> dObj;

  const WorkoutDetailView({super.key, required this.dObj});

  @override
  State<WorkoutDetailView> createState() => _WorkoutDetailViewState();
}

class _WorkoutDetailViewState extends State<WorkoutDetailView> {
  List<Map<String, dynamic>> exercises = [];
  Map<String, dynamic>? stravaData;
  Map<String, dynamic>? rentalBike;
  bool isCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      // Fetch exercises for the workout
      final exerciseResponse = await ApiService.get('exercises?filters[workout_plan][id][\$eq]=${widget.dObj['id']}');
      final dynamic exerciseData = exerciseResponse['data'];
      if (exerciseData is List) {
        setState(() {
          exercises = exerciseData.map((item) {
            if (item is Map) {
              return Map<String, dynamic>.fromEntries(
                item.entries.map((entry) {
                  final key = entry.key.toString(); // Convert key to string
                  return MapEntry<String, dynamic>(key, entry.value);
                }),
              );
            }
            debugPrint('Unexpected exercise item type: $item');
            return <String, dynamic>{}; // Default empty map for non-Map items
          }).whereType<Map<String, dynamic>>().toList();
        });
      }

      // Fetch Strava data if available
      final stravaResponse = await ApiService.get('strava-inputs?filters[workout_plan][id][\$eq]=${widget.dObj['id']}');
      if (stravaResponse['data'] != null && (stravaResponse['data'] as List).isNotEmpty) {
        final dynamic stravaItem = (stravaResponse['data'] as List).first;
        if (stravaItem is Map) {
          setState(() {
            stravaData = Map<String, dynamic>.fromEntries(
              stravaItem.entries.map((entry) {
                final key = entry.key.toString(); // Convert key to string
                return MapEntry<String, dynamic>(key, entry.value);
              }),
            );
          });
        }
      }

      // Fetch rental bike info if outdoor sport and premium
      if (widget.dObj['sport_type'] == 'Cycling' || widget.dObj['sport_type'] == 'Running') {
        final bikeResponse = await ApiService.get('rental-bikes?filters[location][\$eq]=${widget.dObj['location'] ?? 'Default'}');
        if (bikeResponse['data'] != null && (bikeResponse['data'] as List).isNotEmpty) {
          final dynamic bikeItem = (bikeResponse['data'] as List).first;
          if (bikeItem is Map) {
            setState(() {
              rentalBike = Map<String, dynamic>.fromEntries(
                bikeItem.entries.map((entry) {
                  final key = entry.key.toString(); // Convert key to string
                  return MapEntry<String, dynamic>(key, entry.value);
                }),
              );
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading workout details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load details: $e')),
      );
    }
  }

  Future<void> _toggleCompletion() async {
    setState(() => isCompleted = !isCompleted);
    try {
      await ApiService.updateWorkoutPlan('workout-plans/${widget.dObj['id']}', {'completed': isCompleted});
      if (isCompleted && stravaData != null) {
        _saveBadge(); // Award badge for completion
      }
    } catch (e) {
      debugPrint('Error updating completion: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update completion: $e')),
      );
    }
  }

  Future<void> _saveBadge() async {
    final prefs = await SharedPreferences.getInstance();
    final badges = prefs.getStringList('badges') ?? [];
    badges.add('Workout Completed: ${widget.dObj['title']}');
    await prefs.setStringList('badges', badges);
  }

  void _shareWorkout() {
    final String text = 'Completed ${widget.dObj['title']} - Distance: ${stravaData?['distance'] ?? widget.dObj['distance_planned']} km, Calories: ${stravaData?['calories'] ?? widget.dObj['calories']} kcal';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: TColor.white, // White background
      appBar: AppBar(
        title: Text(widget.dObj['title'] ?? 'Workout Details'),
        backgroundColor: TColor.white, // White
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: TColor.black), // Black
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isCompleted)
            IconButton(
              icon: Icon(Icons.share, color: TColor.darkRose), // Darker dusty rose
              onPressed: _shareWorkout,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Workout Overview',
              style: TextStyle(color: TColor.black, fontSize: 22, fontWeight: FontWeight.bold),
            ).animate(
              effects: [
                FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
              ],
            ),
            SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: TColor.lightGray, // Light gray
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: TColor.darkRose.withOpacity(0.3)), // Darker dusty rose
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sport Type: ${widget.dObj['sport_type'] ?? 'N/A'}', style: TextStyle(color: TColor.black, fontSize: 16)),
                  Text('Difficulty: ${widget.dObj['difficulty'] ?? 'N/A'}', style: TextStyle(color: TColor.black, fontSize: 16)),
                  Text('Duration: ${widget.dObj['duration'] ?? 'N/A'} min', style: TextStyle(color: TColor.black, fontSize: 16)),
                  Text('Calories: ${widget.dObj['calories'] ?? 'N/A'} kcal', style: TextStyle(color: TColor.black, fontSize: 16)),
                  if (widget.dObj['sport_type'] == 'Cycling' || widget.dObj['sport_type'] == 'Running')
                    Text('Distance Planned: ${widget.dObj['distance_planned'] ?? 'N/A'} km', style: TextStyle(color: TColor.black, fontSize: 16)),
                  if (widget.dObj['sport_type'] == 'Cycling' || widget.dObj['sport_type'] == 'Running')
                    Text('Elevation Planned: ${widget.dObj['elevation_planned'] ?? 'N/A'} m', style: TextStyle(color: TColor.black, fontSize: 16)),

                ],
              ),
            ).animate(
              effects: [
                FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Exercises',
              style: TextStyle(color: TColor.black, fontSize: 22, fontWeight: FontWeight.bold),
            ).animate(
              effects: [
                FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
              ],
            ),
            SizedBox(height: 10),
            ...exercises.map((exercise) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: TColor.lightGray, // Light gray
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: TColor.darkRose.withOpacity(0.3)), // Darker dusty rose
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Exercise: ${exercise['name'] ?? 'N/A'}', style: TextStyle(color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700)),
                  Text('Category: ${exercise['category'] ?? 'N/A'}', style: TextStyle(color: TColor.black, fontSize: 16)),
                  Text('Duration: ${exercise['duration'] ?? 'N/A'} min', style: TextStyle(color: TColor.black, fontSize: 16)),
                  Text('Calories/Min: ${exercise['calories_per_minute'] ?? 'N/A'} kcal', style: TextStyle(color: TColor.black, fontSize: 16)),
                  if (widget.dObj['sport_type'] == 'Gym')
                    Text('Reps: ${exercise['reps'] ?? 'N/A'}, Sets: ${exercise['sets'] ?? 'N/A'}', style: TextStyle(color: TColor.black, fontSize: 16)),
                  if (widget.dObj['sport_type'] == 'Cycling' || widget.dObj['sport_type'] == 'Running')
                    Text('Distance Planned: ${exercise['distance_planned'] ?? 'N/A'} km', style: TextStyle(color: TColor.black, fontSize: 16)),
                  if (widget.dObj['sport_type'] == 'Cycling' || widget.dObj['sport_type'] == 'Running')
                    Text('Elevation Planned: ${exercise['elevation_planned'] ?? 'N/A'} m', style: TextStyle(color: TColor.black, fontSize: 16)),
                ],
              ),
            ).animate(
              effects: [
                FadeEffect(duration: 700.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 700.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                ShakeEffect(duration: 300.ms, curve: Curves.easeOut),
              ],
            )),
            SizedBox(height: 20),
            Text(
              'Strava Performance',
              style: TextStyle(color: TColor.black, fontSize: 22, fontWeight: FontWeight.bold),
            ).animate(
              effects: [
                FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
              ],
            ),
            SizedBox(height: 10),
            if (stravaData != null)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: TColor.lightGray, // Light gray
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: TColor.darkRose.withOpacity(0.3)), // Darker dusty rose
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Distance: ${stravaData?['distance'] ?? 'N/A'} km', style: TextStyle(color: TColor.black, fontSize: 16)),
                    Text('Elevation: ${stravaData?['total_elevation_gain'] ?? 'N/A'} m', style: TextStyle(color: TColor.black, fontSize: 16)),
                    Text('Heart Rate: ${stravaData?['heart_rate'] ?? 'N/A'} BPM', style: TextStyle(color: TColor.black, fontSize: 16)),
                    Text('Cadence: ${stravaData?['cadence'] ?? 'N/A'} rpm', style: TextStyle(color: TColor.black, fontSize: 16)),
                  ],
                ),
              ).animate(
                effects: [
                  FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
                  ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                  ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
                ],
              )
            else
              Text('No Strava data available', style: TextStyle(color: TColor.gray, fontSize: 16)),
            SizedBox(height: 20),
            SizedBox(
              height: media.width * 0.4,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 7,
                  minY: 0,
                  maxY: 200,
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        FlSpot(0, stravaData?['heart_rate']?.toDouble() ?? 60),
                        FlSpot(1, stravaData?['heart_rate']?.toDouble() ?? 65),
                        FlSpot(2, stravaData?['heart_rate']?.toDouble() ?? 70),
                        FlSpot(3, stravaData?['heart_rate']?.toDouble() ?? 75),
                        FlSpot(4, stravaData?['heart_rate']?.toDouble() ?? 80),
                        FlSpot(5, stravaData?['heart_rate']?.toDouble() ?? 85),
                        FlSpot(6, stravaData?['heart_rate']?.toDouble() ?? 90),
                      ],
                      isCurved: true,
                      color: TColor.lightIndigo, // Lighter indigo
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: TColor.lightIndigo.withOpacity(0.2)),
                    ),
                  ],
                ),
              ),
            ).animate(
              effects: [
                FadeEffect(duration: 1000.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 1000.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                ShakeEffect(duration: 500.ms, curve: Curves.easeOut),
              ],
            ),
            SizedBox(height: 20),
            RoundButton(
              title: isCompleted ? 'Mark as Incomplete' : 'Mark as Completed',
              type: RoundButtonType.bgGradient, // Using primary gradient (lightGray to darkRose)
              onPressed: _toggleCompletion,
              fontSize: 16,
              elevation: 1,
              fontWeight: FontWeight.w700,
            ).animate(
              effects: [
                FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'AI Recommendation',
              style: TextStyle(color: TColor.black, fontSize: 22, fontWeight: FontWeight.bold),
            ).animate(
              effects: [
                FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
              ],
            ),
            SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: TColor.lightGray, // Light gray
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: TColor.darkRose.withOpacity(0.3)), // Darker dusty rose
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'Based on your Strava data, increase elevation by 10% for better calorie burn. Maintain heart rate 120-140 BPM for optimal performance.',
                style: TextStyle(color: TColor.black, fontSize: 16),
              ),
            ).animate(
              effects: [
                FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
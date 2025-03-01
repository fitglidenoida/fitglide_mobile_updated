import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:fitglide_mobile_application/common_widget/round_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/colo_extension.dart';

class ExercisesStepDetails extends StatefulWidget {
  final Map<String, dynamic> exercise;

  const ExercisesStepDetails({super.key, required this.exercise});

  @override
  State<ExercisesStepDetails> createState() => _ExercisesStepDetailsState();
}

class _ExercisesStepDetailsState extends State<ExercisesStepDetails> {
  Map<String, dynamic>? stravaData;
  bool isCompleted = false;
  String? notes;

  @override
  void initState() {
    super.initState();
    _loadStravaData();
  }

  Future<void> _loadStravaData() async {
    try {
      final response = await ApiService.get('strava-inputs?filters[exercise][id][\$eq]=${widget.exercise['id']}');
      if (response['data'] != null && (response['data'] as List).isNotEmpty) {
        final dynamic stravaItem = (response['data'] as List).first;
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
    } catch (e) {
      debugPrint('Error loading Strava data: $e');
    }
  }

  Future<void> _toggleCompletion() async {
    setState(() => isCompleted = !isCompleted);
    try {
      await ApiService.updateWorkoutPlan('exercises/${widget.exercise['id']}', {'completed': isCompleted});
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
    badges.add('Exercise Completed: ${widget.exercise['name']}');
    await prefs.setStringList('badges', badges);
  }

  void _shareExercise() {
    final String text = 'Completed ${widget.exercise['name']} - Distance: ${stravaData?['distance'] ?? widget.exercise['distance_planned']} km, Calories: ${stravaData?['calories'] ?? widget.exercise['calories_per_minute'] * widget.exercise['duration']} kcal';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: TColor.white, // White background
      appBar: AppBar(
        title: Text(widget.exercise['name'] ?? 'Exercise Details'),
        backgroundColor: TColor.white, // White
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: TColor.black), // Black
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isCompleted)
            IconButton(
              icon: Icon(Icons.share, color: TColor.darkRose), // Darker dusty rose
              onPressed: _shareExercise,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exercise Overview',
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
                  Text('Duration: ${widget.exercise['duration'] ?? 'N/A'} min', style: TextStyle(color: TColor.black, fontSize: 16)),
                  Text('Calories/Min: ${widget.exercise['calories_per_minute'] ?? 'N/A'} kcal', style: TextStyle(color: TColor.black, fontSize: 16)),
                  if (widget.exercise['sport_type'] == 'Gym')
                    Text('Reps: ${widget.exercise['reps'] ?? 'N/A'}, Sets: ${widget.exercise['sets'] ?? 'N/A'}', style: TextStyle(color: TColor.black, fontSize: 16)),
                  if (widget.exercise['sport_type'] == 'Cycling' || widget.exercise['sport_type'] == 'Running')
                    Text('Distance Planned: ${widget.exercise['distance_planned'] ?? 'N/A'} km', style: TextStyle(color: TColor.black, fontSize: 16)),
                  if (widget.exercise['sport_type'] == 'Cycling' || widget.exercise['sport_type'] == 'Running')
                    Text('Elevation Planned: ${widget.exercise['elevation_planned'] ?? 'N/A'} m', style: TextStyle(color: TColor.black, fontSize: 16)),
                  Text('Category: ${widget.exercise['category'] ?? 'N/A'}', style: TextStyle(color: TColor.black, fontSize: 16)),
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
            TextField(
              decoration: InputDecoration(
                labelText: 'Notes',
                filled: true,
                fillColor: TColor.lightGray, // Light gray
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: 'Add notes about your performance...',
              ),
              onChanged: (value) => notes = value,
            ).animate(
              effects: [
                FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
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
                'Increase cadence to 90 rpm for better performance. Maintain heart rate 120-140 BPM for optimal fat burn.',
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
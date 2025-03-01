import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:fitglide_mobile_application/view/workout_tracker/workout_schedule_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/colo_extension.dart';

class WorkoutDetailView extends StatefulWidget {
  final Map dObj;

  const WorkoutDetailView({super.key, required this.dObj});

  @override
  State<WorkoutDetailView> createState() => _WorkoutDetailViewState();
}

class _WorkoutDetailViewState extends State<WorkoutDetailView> {
  List<Map> exercises = [];
  Map? stravaData;
  bool isCompleted = false;
  String _documentId = ''; // Store documentId from dObj

  @override
  void initState() {
    super.initState();
    _documentId = widget.dObj['documentId'] ?? ''; // Extract documentId from dObj, default to empty if not found
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      // Fetch exercises for the workout using documentId
      final exerciseResponse = await ApiService.get('exercises?filters[workout_plan][documentId][\$eq]=$_documentId');
      setState(() {
        exercises = List<Map>.from(exerciseResponse['data'] ?? []);
      });

      // Fetch Strava data if available, using documentId
      final stravaResponse = await ApiService.get('strava-inputs?filters[workout_plan][documentId][\$eq]=$_documentId');
      if (stravaResponse['data'] != null && (stravaResponse['data'] as List).isNotEmpty) {
        setState(() {
          stravaData = (stravaResponse['data'] as List).first as Map;
        });
      }
    } catch (e) {
      debugPrint('Error loading workout details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load details: $e', style: TextStyle(color: TColor.black))),
      );
    }
  }

  Future<void> _toggleCompletion() async {
    setState(() => isCompleted = !isCompleted);
    try {
      if (_documentId.isNotEmpty) {
        await ApiService.updateWorkoutPlan(_documentId, {'Completed': isCompleted ? 'TRUE' : 'FALSE'});
        if (isCompleted) {
          await _saveBadge(); // Award badge for completion
        }
      } else {
        throw Exception('Document ID is missing or empty');
      }
    } catch (e) {
      debugPrint('Error updating completion: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update completion: $e', style: TextStyle(color: TColor.black))),
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

  void _navigateToSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WorkoutScheduleView()), // Use const for StatefulWidget if no parameters
    );
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: TColor.white, // Clean white background
      appBar: AppBar(
        title: Text(widget.dObj['title'] ?? 'Workout Details', style: TextStyle(color: TColor.black, fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: TColor.white, // White
        elevation: 0, // No shadow for modern look
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
          IconButton(
            icon: Icon(Icons.calendar_today, color: TColor.darkRose), // Darker dusty rose for schedule navigation
            onPressed: _navigateToSchedule, // Use the method to navigate
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: TColor.lightGray, // Light gray with subtle gradient
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: TColor.darkRose.withOpacity(0.2)), // Subtle darker dusty rose border
                gradient: LinearGradient(
                  colors: [TColor.lightGray, TColor.lightIndigo.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Workout Overview',
                    style: TextStyle(color: TColor.black, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 15),
                  Text('Sport Type: ${widget.dObj['sport_type'] ?? 'N/A'}', style: TextStyle(color: TColor.black, fontSize: 16)),
                  Text('Difficulty: ${widget.dObj['difficulty'] ?? 'N/A'}', style: TextStyle(color: TColor.black, fontSize: 16)),
                  Text('Duration: ${widget.dObj['duration'] ?? 'N/A'} min', style: TextStyle(color: TColor.black, fontSize: 16)),
                  Text('Calories: ${widget.dObj['calories'] ?? 'N/A'} kcal', style: TextStyle(color: TColor.black, fontSize: 16)),
                  if (widget.dObj['sport_type'] == 'Cycling' || widget.dObj['sport_type'] == 'Running')
                    Column(
                      children: [
                        Text('Distance Planned: ${widget.dObj['distance_planned'] ?? 'N/A'} km', style: TextStyle(color: TColor.black, fontSize: 16)),
                        Text('Elevation Planned: ${widget.dObj['elevation_planned'] ?? 'N/A'} m', style: TextStyle(color: TColor.black, fontSize: 16)),
                      ],
                    ),
                ],
              ),
            ).animate(
              effects: [
                FadeEffect(duration: 1200.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 1200.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                ShakeEffect(duration: 600.ms, curve: Curves.easeOut),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'Exercises',
              style: TextStyle(color: TColor.black, fontSize: 24, fontWeight: FontWeight.bold),
            ).animate(
              effects: [
                FadeEffect(duration: 1200.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 1200.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                ShakeEffect(duration: 600.ms, curve: Curves.easeOut),
              ],
            ),
            SizedBox(height: 15),
            ...exercises.map((exercise) => Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: TColor.lightGray, // Light gray
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TColor.darkRose.withOpacity(0.2)), // Subtle border
                gradient: LinearGradient(
                  colors: [TColor.lightGray, TColor.lightIndigo.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Exercise: ${exercise['name'] ?? 'N/A'}', style: TextStyle(color: TColor.black, fontSize: 18, fontWeight: FontWeight.w600)),
                  Text('Duration: ${exercise['duration'] ?? 'N/A'} min', style: TextStyle(color: TColor.black, fontSize: 16)),
                  if (widget.dObj['sport_type'] == 'Gym')
                    Text('Reps: ${exercise['reps'] ?? 'N/A'}, Sets: ${exercise['sets'] ?? 'N/A'}', style: TextStyle(color: TColor.black, fontSize: 16)),
                  Text('Calories/Min: ${exercise['calories_per_minute'] ?? 'N/A'} kcal', style: TextStyle(color: TColor.black, fontSize: 16)),
                ],
              ),
            ).animate(
              effects: [
                FadeEffect(duration: 1000.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 1000.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                ShakeEffect(duration: 500.ms, curve: Curves.easeOut),
              ],
            )),
            SizedBox(height: 20),
            Text(
              'Strava Performance',
              style: TextStyle(color: TColor.black, fontSize: 24, fontWeight: FontWeight.bold),
            ).animate(
              effects: [
                FadeEffect(duration: 1200.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 1200.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                ShakeEffect(duration: 600.ms, curve: Curves.easeOut),
              ],
            ),
            SizedBox(height: 15),
            if (stravaData != null)
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: TColor.lightGray, // Light gray
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TColor.darkRose.withOpacity(0.2)), // Subtle border
                  gradient: LinearGradient(
                    colors: [TColor.lightGray, TColor.lightIndigo.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
                  FadeEffect(duration: 1200.ms, curve: Curves.easeInOut),
                  ScaleEffect(duration: 1200.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                  ShakeEffect(duration: 600.ms, curve: Curves.easeOut),
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
                FadeEffect(duration: 1200.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 1200.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                ShakeEffect(duration: 600.ms, curve: Curves.easeOut),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _toggleCompletion,
              style: ElevatedButton.styleFrom(
                backgroundColor: TColor.darkRose, // Darker dusty rose
                foregroundColor: TColor.white, // White
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4, // Subtle shadow
              ),
              child: Text(isCompleted ? 'Mark as Incomplete' : 'Mark as Completed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ).animate(
              effects: [
                FadeEffect(duration: 1200.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 1200.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                ShakeEffect(duration: 600.ms, curve: Curves.easeOut),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'AI Insights',
              style: TextStyle(color: TColor.black, fontSize: 24, fontWeight: FontWeight.bold),
            ).animate(
              effects: [
                FadeEffect(duration: 1200.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 1200.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                ShakeEffect(duration: 600.ms, curve: Curves.easeOut),
              ],
            ),
            SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: TColor.lightGray, // Light gray
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TColor.darkRose.withOpacity(0.2)), // Subtle border
                gradient: LinearGradient(
                  colors: [TColor.lightGray, TColor.lightIndigo.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Text(
                'Based on your Strava data, increase elevation by 10% for better calorie burn. Maintain heart rate 120-140 BPM for optimal performance.',
                style: TextStyle(color: TColor.black, fontSize: 16),
              ),
            ).animate(
              effects: [
                FadeEffect(duration: 1200.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 1200.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                ShakeEffect(duration: 600.ms, curve: Curves.easeOut),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/colo_extension.dart';

class ExercisesStepDetails extends StatefulWidget {
  final Map exercise;

  const ExercisesStepDetails({super.key, required this.exercise});

  @override
  State<ExercisesStepDetails> createState() => _ExercisesStepDetailsState();
}

class _ExercisesStepDetailsState extends State<ExercisesStepDetails> with SingleTickerProviderStateMixin {
  Map? stravaData;
  bool isFavorited = false;
  int badgesEarned = 0;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _loadStravaData();
    _loadBadges();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadStravaData() async {
    try {
      // Create a DataService instance to call fetchStravaData
      final dataService = DataService();
      final stravaResponse = await dataService.fetchStravaData('username'); // Replace with actual username
      if (stravaResponse['data'] != null && (stravaResponse['data'] as List).isNotEmpty) {
        setState(() {
          stravaData = (stravaResponse['data'] as List).firstWhere((d) => d['sport_type'] == widget.exercise['sport_type'], orElse: () => null) as Map?;
        });
      }
    } catch (e) {
      debugPrint('Error loading Strava data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load Strava data: $e', style: TextStyle(color: TColor.black))),
      );
    }
  }

  Future<void> _loadBadges() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      badgesEarned = (prefs.getStringList('badges') ?? []).length;
    });
  }

  Future<void> _toggleFavorite() async {
    setState(() => isFavorited = !isFavorited);
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favorites') ?? [];
    if (isFavorited) {
      favorites.add(widget.exercise['name']);
    } else {
      favorites.remove(widget.exercise['name']);
    }
    await prefs.setStringList('favorites', favorites);
    if (isFavorited) {
      setState(() => badgesEarned++);
      await prefs.setStringList('badges', [...prefs.getStringList('badges') ?? [], 'Exercise Favorited: ${widget.exercise['name']}']);
    }
  }

  void _shareExercise() {
    final String text = 'Completed ${widget.exercise['name']} - Duration: ${widget.exercise['duration']} min, Calories: ${widget.exercise['calories_per_minute']} kcal';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white, // Clean white background
      appBar: AppBar(
        title: Text(widget.exercise['name'] ?? 'Exercise Details', style: TextStyle(color: TColor.black, fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: TColor.white, // White
        elevation: 0, // No shadow for modern look
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: TColor.black), // Black
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(isFavorited ? Icons.favorite : Icons.favorite_border, color: TColor.darkRose), // Darker dusty rose
            onPressed: _toggleFavorite,
          ),
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: TColor.lightGray, // Light gray with subtle gradient
                borderRadius: BorderRadius.circular(15),
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
                  Text(
                    'Exercise Details',
                    style: TextStyle(color: TColor.black, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 15),
                  Text('Sport Type: ${widget.exercise['sport_type'] ?? 'N/A'}', style: TextStyle(color: TColor.black, fontSize: 16)),
                  Text('Duration: ${widget.exercise['duration'] ?? 'N/A'} min', style: TextStyle(color: TColor.black, fontSize: 16)),
                  Text('Calories/Min: ${widget.exercise['calories_per_minute'] ?? 'N/A'} kcal', style: TextStyle(color: TColor.black, fontSize: 16)),
                  if (widget.exercise['sport_type'] == 'Gym')
                    Text('Reps: ${widget.exercise['reps'] ?? 'N/A'}, Sets: ${widget.exercise['sets'] ?? 'N/A'}', style: TextStyle(color: TColor.black, fontSize: 16)),
                  Text('Steps:', style: TextStyle(color: TColor.black, fontSize: 18, fontWeight: FontWeight.w600)),
                  SizedBox(height: 10),
                  Text(
                    '1. Warm up with 5-min stretches.\n2. Perform ${widget.exercise['duration']} min of ${widget.exercise['name']}.\n3. Cool down with 5-min breathing exercises.',
                    style: TextStyle(color: TColor.black, fontSize: 16),
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
            Text(
              'Gamification',
              style: TextStyle(color: TColor.black, fontSize: 24, fontWeight: FontWeight.bold),
            ).animate(
              effects: [
                FadeEffect(duration: 1200.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 1200.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                ShakeEffect(duration: 600.ms, curve: Curves.easeOut),
              ],
            ),
            SizedBox(height: 15),
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
                  Text('Badges Earned: $badgesEarned', style: TextStyle(color: TColor.black, fontSize: 16)),
                  Text('Level Up by completing more exercises!', style: TextStyle(color: TColor.black, fontSize: 16)),
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
                'Boost performance by increasing reps by 10% for ${widget.exercise['name']}. Sync Strava for real-time feedback.',
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
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

class _WorkoutDetailViewState extends State<WorkoutDetailView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> exercises = [];
  Map<String, dynamic>? stravaData;
  bool isCompleted = false;
  String? maxRecommendation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDetails();
    _loadMaxRecommendation();
  }

  Future<void> _loadDetails() async {
    try {
      final exerciseResponse = await ApiService.get('exercises?filters[workout_plan][id][\$eq]=${widget.dObj['id']}');
      if (exerciseResponse['data'] is List) {
        setState(() {
          exercises = (exerciseResponse['data'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
      final stravaResponse = await ApiService.get('strava-inputs?filters[workout_plan][id][\$eq]=${widget.dObj['id']}');
      if (stravaResponse['data']?.isNotEmpty ?? false) {
        setState(() {
          stravaData = Map<String, dynamic>.from(stravaResponse['data'].first);
        });
      }
      setState(() => isCompleted = widget.dObj['completed'] == true);
    } catch (e) {
      debugPrint('Error loading details: $e');
    }
  }

  Future<void> _loadMaxRecommendation() async {
    setState(() {
      maxRecommendation = stravaData != null
          ? "Max says: Increase elevation by 10% next time for better calorie burn!"
          : "Max says: Complete this workout to get personalized tips!";
    });
  }

  Future<void> _toggleCompletion() async {
    setState(() => isCompleted = !isCompleted);
    try {
      await ApiService.updateWorkoutPlan('workout-plans/${widget.dObj['id']}', {'completed': isCompleted});
      if (isCompleted) _saveBadge("Workout Completed: ${widget.dObj['title']}"); // Fixed: Pass badge name
      _loadMaxRecommendation();
    } catch (e) {
      debugPrint('Error updating completion: $e');
    }
  }

  Future<void> _saveBadge(String badgeName) async { // Fixed: Added parameter
    final prefs = await SharedPreferences.getInstance();
    final badges = prefs.getStringList('badges') ?? [];
    badges.add(badgeName);
    await prefs.setStringList('badges', badges);
  }

  void _shareWorkout() {
    final text = 'Completed ${widget.dObj['title']} - Distance: ${stravaData?['distance'] ?? widget.dObj['distance_planned']} km, Calories: ${stravaData?['calories'] ?? widget.dObj['calories']} kcal';
    Share.share(text);
  }

  void _showMaxDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TColor.cardLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: TColor.primary)),
        content: Row(
          children: [
            Image.asset('assets/img/max_avatar.png', width: 50, height: 50),
            SizedBox(width: 10),
            Expanded(child: Text(maxRecommendation ?? "Max is thinking...", style: TextStyle(color: TColor.textPrimary))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: TextStyle(color: TColor.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: TColor.backgroundLight,
      appBar: AppBar(
        title: Text(widget.dObj['title'] ?? 'Workout Details', style: TextStyle(color: TColor.textPrimary)),
        backgroundColor: TColor.backgroundLight,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: TColor.textPrimary), onPressed: () => Navigator.pop(context)),
        actions: [
          if (isCompleted) IconButton(icon: Icon(Icons.share, color: TColor.primary), onPressed: _shareWorkout),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: TColor.primary,
          unselectedLabelColor: TColor.textSecondary,
          indicatorColor: TColor.primary,
          tabs: const [
            Tab(text: "Overview"),
            Tab(text: "Exercises"),
            Tab(text: "Performance"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: TColor.cardLight,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sport Type: ${widget.dObj['sport_type'] ?? 'N/A'}', style: TextStyle(color: TColor.textPrimary)),
                        Text('Difficulty: ${widget.dObj['difficulty'] ?? 'N/A'}', style: TextStyle(color: TColor.textPrimary)),
                        Text('Duration: ${widget.dObj['duration'] ?? 'N/A'} min', style: TextStyle(color: TColor.textPrimary)),
                        Text('Calories: ${widget.dObj['calories'] ?? 'N/A'} kcal', style: TextStyle(color: TColor.textPrimary)),
                        if (widget.dObj['sport_type'] == 'Cycling' || widget.dObj['sport_type'] == 'Running') ...[
                          Text('Distance Planned: ${widget.dObj['distance_planned'] ?? 'N/A'} km', style: TextStyle(color: TColor.textPrimary)),
                          Text('Elevation Planned: ${widget.dObj['elevation_planned'] ?? 'N/A'} m', style: TextStyle(color: TColor.textPrimary)),
                        ],
                      ],
                    ),
                  ),
                ).animate(effects: [FadeEffect(duration: 800.ms)]),
                SizedBox(height: 20),
                RoundButton(
                  title: isCompleted ? 'Mark as Incomplete' : 'Mark as Completed',
                  type: RoundButtonType.bgGradient, // Fixed: Removed gradientColors (assuming bgGradient uses TColor.primaryG internally)
                  onPressed: _toggleCompletion,
                ).animate(effects: [FadeEffect(duration: 800.ms), ScaleEffect(duration: 800.ms, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0))]),
              ],
            ),
          ),
          ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              var exercise = exercises[index];
              return Card(
                color: TColor.cardLight,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Exercise: ${exercise['name'] ?? 'N/A'}', style: TextStyle(color: TColor.textPrimary, fontWeight: FontWeight.w700)),
                      Text('Category: ${exercise['category'] ?? 'N/A'}', style: TextStyle(color: TColor.textPrimary)),
                      Text('Duration: ${exercise['duration'] ?? 'N/A'} min', style: TextStyle(color: TColor.textPrimary)),
                      Text('Calories/Min: ${exercise['calories_per_minute'] ?? 'N/A'} kcal', style: TextStyle(color: TColor.textPrimary)),
                      if (widget.dObj['sport_type'] == 'Gym')
                        Text('Reps: ${exercise['reps'] ?? 'N/A'}, Sets: ${exercise['sets'] ?? 'N/A'}', style: TextStyle(color: TColor.textPrimary)),
                    ],
                  ),
                ),
              ).animate(effects: [FadeEffect(duration: 700.ms)]);
            },
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (stravaData != null)
                  Card(
                    color: TColor.cardLight,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Distance: ${stravaData!['distance'] ?? 'N/A'} km vs ${widget.dObj['distance_planned'] ?? 'N/A'} planned', style: TextStyle(color: TColor.textPrimary)),
                          Text('Elevation: ${stravaData!['total_elevation_gain'] ?? 'N/A'} m vs ${widget.dObj['elevation_planned'] ?? 'N/A'} planned', style: TextStyle(color: TColor.textPrimary)),
                          Text('Heart Rate: ${stravaData!['heart_rate'] ?? 'N/A'} BPM', style: TextStyle(color: TColor.textPrimary)),
                          Text('Cadence: ${stravaData!['cadence'] ?? 'N/A'} rpm', style: TextStyle(color: TColor.textPrimary)),
                        ],
                      ),
                    ),
                  ).animate(effects: [FadeEffect(duration: 800.ms)])
                else
                  Text('No Strava data available', style: TextStyle(color: TColor.textSecondary)),
                SizedBox(height: 20),
                SizedBox(
                  height: MediaQuery.of(context).size.width * 0.4,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                      maxY: 200,
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(7, (i) => FlSpot(i.toDouble(), stravaData?['heart_rate']?.toDouble() ?? 60 + i * 5)),
                          isCurved: true,
                          color: TColor.accent2,
                          belowBarData: BarAreaData(show: true, color: TColor.accent2.withOpacity(0.2)),
                        ),
                      ],
                    ),
                  ),
                ).animate(effects: [FadeEffect(duration: 1000.ms)]),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: GestureDetector(
        onTap: _showMaxDialog,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: TColor.cardLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: TColor.primary.withOpacity(0.3))),
          child: Image.asset('assets/img/max_avatar.png', width: 50, height: 50),
        ),
      ).animate(effects: [FadeEffect(duration: 800.ms), ScaleEffect(duration: 800.ms, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0))]),
    );
  }
}
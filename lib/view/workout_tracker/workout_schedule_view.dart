import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../common/colo_extension.dart';

class WorkoutScheduleView extends StatefulWidget {
  const WorkoutScheduleView({super.key});

  @override
  State<WorkoutScheduleView> createState() => _WorkoutScheduleViewState();
}

class _WorkoutScheduleViewState extends State<WorkoutScheduleView> with SingleTickerProviderStateMixin {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map>> _events = {};
  Map? stravaData;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _loadSchedule();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSchedule() async {
    try {
      final response = await ApiService.fetchWorkoutPlans('username'); // Replace with actual username
      setState(() {
        _events = {};
        for (var plan in (response['data'] as List? ?? [])) {
          final date = DateTime.parse(plan['scheduled_date']).toLocal();
          final eventDate = DateTime(date.year, date.month, date.day);
          _events[eventDate] = _events[eventDate] ?? [];
          _events[eventDate]!.add(Map<String, dynamic>.from(plan));
        }
      });

      // Create a DataService instance to call fetchStravaData
      final dataService = DataService();
      final stravaResponse = await dataService.fetchStravaData('username'); // Replace with actual username
      if (stravaResponse['data'] != null && (stravaResponse['data'] as List).isNotEmpty) {
        setState(() {
          stravaData = (stravaResponse['data'] as List).first as Map;
        });
      }
    } catch (e) {
      debugPrint('Error loading schedule: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load schedule: $e', style: TextStyle(color: TColor.black))),
      );
    }
  }

  List<Map> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white, // Clean white background
      appBar: AppBar(
        title: const Text('Workout Schedule', style: TextStyle(color: TColor.black, fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: TColor.white, // White
        elevation: 0, // No shadow for modern look
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: TColor.black), // Black
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
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
              child: TableCalendar(
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                onDaySelected: _onDaySelected,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(color: TColor.darkRose, shape: BoxShape.circle),
                  selectedDecoration: BoxDecoration(color: TColor.lightIndigo, shape: BoxShape.circle),
                  markerDecoration: BoxDecoration(color: TColor.darkRose, shape: BoxShape.circle),
                  outsideDaysVisible: false,
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(color: TColor.black, fontSize: 18, fontWeight: FontWeight.bold),
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
            Text(
              'Scheduled Workouts',
              style: TextStyle(color: TColor.black, fontSize: 24, fontWeight: FontWeight.bold),
            ).animate(
              effects: [
                FadeEffect(duration: 1200.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 1200.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                ShakeEffect(duration: 600.ms, curve: Curves.easeOut),
              ],
            ),
            SizedBox(height: 15),
            ..._getEventsForDay(_selectedDay ?? _focusedDay).map((plan) => Container(
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
              child: ListTile(
                title: Text(plan['title'] ?? 'Untitled Workout', style: TextStyle(color: TColor.black, fontSize: 18, fontWeight: FontWeight.w600)),
                subtitle: Text('Duration: ${plan['duration'] ?? 'N/A'} min, Calories: ${plan['calories'] ?? 'N/A'} kcal', style: TextStyle(color: TColor.black, fontSize: 16)),
                trailing: Icon(Icons.chevron_right, color: TColor.darkRose), // Darker dusty rose
                onTap: () => Navigator.pushNamed(context, '/workout-detail', arguments: plan),
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
              'Strava Sync',
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
                    Text('Last Activity: ${stravaData?['name'] ?? 'N/A'}', style: TextStyle(color: TColor.black, fontSize: 16)),
                    Text('Distance: ${stravaData?['distance'] ?? 'N/A'} km', style: TextStyle(color: TColor.black, fontSize: 16)),
                    Text('Elevation: ${stravaData?['total_elevation_gain'] ?? 'N/A'} m', style: TextStyle(color: TColor.black, fontSize: 16)),
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
              Text('No Strava data synced', style: TextStyle(color: TColor.gray, fontSize: 16)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _loadSchedule(), // Refresh schedule and Strava data
              style: ElevatedButton.styleFrom(
                backgroundColor: TColor.darkRose, // Darker dusty rose
                foregroundColor: TColor.white, // White
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4, // Subtle shadow
              ),
              child: Text('Sync with Strava', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                'Schedule a 30-min cycling session tomorrow for optimal recovery. Sync Strava for personalized tips.',
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
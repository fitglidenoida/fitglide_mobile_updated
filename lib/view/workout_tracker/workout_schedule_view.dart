import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:fitglide_mobile_application/view/workout_tracker/add_schedule_view.dart';
import 'package:fitglide_mobile_application/view/workout_tracker/workout_detail_view.dart';
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

class _WorkoutScheduleViewState extends State<WorkoutScheduleView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> workouts = [];
  bool _isPremium = false; // Assume user status check here

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    try {
      final response = await ApiService.get('workout-plans?populate=*');
      debugPrint('Workouts Response: $response'); // Debug log to inspect data
      final dynamic data = response['data'];
      if (data is List) {
        setState(() {
          workouts = data.map((item) {
            if (item is Map) {
              return Map<String, dynamic>.fromEntries(
                item.entries.map((entry) {
                  final key = entry.key.toString(); // Convert key to string
                  return MapEntry<String, dynamic>(key, entry.value);
                }),
              );
            }
            debugPrint('Unexpected workout item type: $item');
            return <String, dynamic>{}; // Default empty map for non-Map items
          }).whereType<Map<String, dynamic>>().toList();
        });
      } else {
        debugPrint('Unexpected data type for "data" in workouts: $data');
        setState(() {
          workouts = [];
        });
      }
    } catch (e) {
      debugPrint('Error loading workouts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load workouts: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return workouts.where((workout) {
      final scheduledDate = DateTime.parse(workout['scheduled_date'] as String).toLocal();
      return scheduledDate.year == day.year &&
             scheduledDate.month == day.month &&
             scheduledDate.day == day.day;
    }).toList();
  }

  Future<void> _awardBadge(String badgeName) async {
    final prefs = await SharedPreferences.getInstance();
    final badges = prefs.getStringList('badges') ?? [];
    badges.add(badgeName);
    await prefs.setStringList('badges', badges);
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: TColor.white, // White background
      appBar: AppBar(
        title: const Text('Workout Schedule'),
        backgroundColor: TColor.white, // White
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: TColor.black), // Black
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: TColor.darkRose, // Darker dusty rose
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: TColor.darkRose, // Darker dusty rose
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(color: TColor.white), // White
              selectedTextStyle: TextStyle(color: TColor.white), // White
              defaultTextStyle: TextStyle(color: TColor.black), // Black
              weekendTextStyle: TextStyle(color: TColor.black), // Black
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonDecoration: BoxDecoration(
                color: TColor.lightGray, // Light gray
                borderRadius: BorderRadius.circular(12),
              ),
              formatButtonTextStyle: TextStyle(color: TColor.black), // Black
              titleTextStyle: TextStyle(color: TColor.black, fontSize: 20), // Black
            ),
            eventLoader: _getEventsForDay,
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _getEventsForDay(_selectedDay ?? _focusedDay).length,
              itemBuilder: (context, index) {
                final workout = _getEventsForDay(_selectedDay ?? _focusedDay)[index];
                final isCompleted = workout['completed'] == true;
                return Container(
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
                  child: InkWell(
                    onTap: isCompleted
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WorkoutDetailView(dObj: workout),
                              ),
                            )
                        : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset(
                          workout["image"] ?? "assets/img/img_1.png",
                          width: 50,
                          height: 50,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.error, color: TColor.gray); // Gray
                          },
                        ).animate(
                          effects: [
                            FadeEffect(duration: 700.ms, curve: Curves.easeInOut),
                            ScaleEffect(duration: 700.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                            ShakeEffect(duration: 300.ms, curve: Curves.easeOut),
                          ],
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                workout["title"] ?? 'Untitled Workout',
                                style: TextStyle(color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700), // Black
                              ).animate(
                                effects: [
                                  FadeEffect(duration: 700.ms, curve: Curves.easeInOut),
                                  SlideEffect(duration: 700.ms, curve: Curves.easeInOut, begin: Offset(10, 0), end: Offset(0, 0)),
                                  ShakeEffect(duration: 300.ms, curve: Curves.easeOut),
                                ],
                              ),
                              Text(
                                "${workout["time"] ?? 'N/A'} | ${workout["calories"] ?? 'N/A'} Calories Burn",
                                style: TextStyle(color: TColor.gray, fontSize: 14), // Gray
                              ).animate(
                                effects: [
                                  FadeEffect(duration: 600.ms, curve: Curves.easeInOut),
                                  SlideEffect(duration: 600.ms, curve: Curves.easeInOut, begin: Offset(10, 0), end: Offset(0, 0)),
                                ],
                              ),
                              if (isCompleted)
                                Text(
                                  'Completed',
                                  style: TextStyle(color: TColor.darkRose, fontSize: 14, fontWeight: FontWeight.w600), // Darker dusty rose
                                ).animate(
                                  effects: [
                                    FadeEffect(duration: 600.ms, curve: Curves.easeInOut),
                                    ScaleEffect(duration: 600.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                                    ShakeEffect(duration: 300.ms, curve: Curves.easeOut),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        Icon(
                          isCompleted ? Icons.check_circle : Icons.schedule,
                          color: isCompleted ? TColor.darkRose : TColor.gray, // Darker dusty rose or gray
                          size: 20,
                        ).animate(
                          effects: [
                            FadeEffect(duration: 600.ms, curve: Curves.easeInOut),
                            ScaleEffect(duration: 600.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                            ShakeEffect(duration: 300.ms, curve: Curves.easeOut),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddScheduleView(date: _focusedDay)),
          );
        },
        backgroundColor: TColor.darkRose, // Darker dusty rose
        child: Icon(Icons.add, color: TColor.white), // White
      ).animate(
        effects: [
          FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
          ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
          ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
        ],
      ),
    );
  }
}
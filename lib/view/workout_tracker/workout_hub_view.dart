import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:fitglide_mobile_application/view/main_tab/main_screen.dart';
import 'package:fitglide_mobile_application/view/meal_planner/meal_planner_view.dart';
import 'package:fitglide_mobile_application/view/profile/profile_view.dart';
import 'package:fitglide_mobile_application/view/sleep_tracker/sleep_tracker_view.dart';
import 'package:fitglide_mobile_application/view/workout_tracker/add_schedule_view.dart';
import 'package:fitglide_mobile_application/view/workout_tracker/workout_detail_view.dart';
import 'package:fitglide_mobile_application/view/workout_tracker/workout_tracker_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../common/colo_extension.dart';

class WorkoutHubView extends StatefulWidget {
  const WorkoutHubView({super.key});

  @override
  State<WorkoutHubView> createState() => _WorkoutHubViewState();
}

class _WorkoutHubViewState extends State<WorkoutHubView> {
  int selectedTab = 1;
  DateTime? _selectedDay;
  List<Map<String, dynamic>> workouts = [];
  int streakDays = 0;
  final TextEditingController _dateController = TextEditingController();
  List<int> showingTooltipOnSpots = [];

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  Future<void> _loadWorkouts() async {
    try {
      final response = await ApiService.get('workout-plans?populate=*');
      final dynamic data = response['data'];
      if (data is List) {
        setState(() {
          workouts = data.map((item) => Map<String, dynamic>.from(item)).toList();
          _calculateStreak();
        });
      }
    } catch (e) {
      debugPrint('Error loading workouts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load workouts: $e', style: TextStyle(color: TColor.textPrimary))),
      );
    }
  }

  void _calculateStreak() {
    workouts.sort((a, b) => DateTime.parse(b['scheduled_date']).compareTo(DateTime.parse(a['scheduled_date'])));
    int streak = 0;
    DateTime? lastDate;
    for (var workout in workouts) {
      if (workout['completed'] == true) {
        DateTime currentDate = DateTime.parse(workout['scheduled_date']).toLocal();
        if (lastDate == null || lastDate.difference(currentDate).inDays == 1) {
          streak++;
          lastDate = currentDate;
        } else if (lastDate.difference(currentDate).inDays > 1) {
          break;
        }
      }
    }
    setState(() => streakDays = streak);
  }

  void _onTabTapped(int index) {
    setState(() => selectedTab = index);
    _navigateToTab(index);
  }

  void _navigateToTab(int index) {
    switch (index) {
      case 0: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen())); break;
      case 1: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const WorkoutHubView())); break;
      case 2: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MealPlannerView())); break;
      case 3: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SleepTrackerView())); break;
      case 4: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileView())); break;
    }
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
            Expanded(
              child: Text(
                "Max says: Your streak is $streakDays days! ${_selectedDay != null ? 'Check today’s progress!' : 'Plan a workout for tomorrow!'}",
                style: TextStyle(color: TColor.textPrimary),
              ),
            ),
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

  List<Map<String, dynamic>> _getEventsForDay(DateTime? day) {
    if (day == null) return workouts;
    return workouts.where((w) {
      final scheduledDate = DateTime.parse(w['scheduled_date']).toLocal();
      return scheduledDate.day == day.day && scheduledDate.month == day.month && scheduledDate.year == day.year;
    }).toList();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDay = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Map<String, Map<String, double>> _getWeeklyCalorieData() {
    final Map<String, Map<String, double>> weeklyData = {};
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final dayKey = DateFormat('yyyy-MM-dd').format(day);
      weeklyData[dayKey] = {'planned': 0.0, 'actual': 0.0};
    }

    for (var workout in workouts) {
      final scheduledDate = DateTime.parse(workout['scheduled_date']).toLocal();
      final dayKey = DateFormat('yyyy-MM-dd').format(scheduledDate);
      if (weeklyData.containsKey(dayKey)) {
        final calories = (workout['calories'] ?? 0).toDouble();
        weeklyData[dayKey]!['planned'] = weeklyData[dayKey]!['planned']! + calories;
        if (workout['completed'] == true) {
          weeklyData[dayKey]!['actual'] = weeklyData[dayKey]!['actual']! + calories;
        }
      }
    }

    debugPrint('Weekly calorie data: $weeklyData');
    return weeklyData;
  }

  List<LineChartBarData> _getWeeklyChartData() {
    final weeklyData = _getWeeklyCalorieData();
    final plannedSpots = <FlSpot>[];
    final actualSpots = <FlSpot>[];
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    weeklyData.forEach((dayKey, data) {
      final day = DateFormat('yyyy-MM-dd').parse(dayKey);
      final dayIndex = day.difference(startOfWeek).inDays.toDouble();
      plannedSpots.add(FlSpot(dayIndex + 1, data['planned']!));
      actualSpots.add(FlSpot(dayIndex + 1, data['actual']!));
    });

    return [
      LineChartBarData(
        spots: plannedSpots,
        isCurved: true,
        color: TColor.primary,
        barWidth: 4,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [TColor.primary.withOpacity(0.3), Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      LineChartBarData(
        spots: actualSpots,
        isCurved: true,
        color: TColor.accent2,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [TColor.accent2.withOpacity(0.3), Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    final filteredWorkouts = _getEventsForDay(_selectedDay);
    final maxCalories = workouts.isNotEmpty
        ? workouts.map((w) => (w['calories'] ?? 0).toDouble()).reduce((a, b) => a > b ? a : b) * 1.5
        : 1000.0; // Fallback max value
    final interval = maxCalories > 0 ? maxCalories / 5 : 200.0; // Fallback interval if maxCalories is 0

    return Scaffold(
      backgroundColor: TColor.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Workout Hub",
                        style: TextStyle(color: TColor.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                      ).animate(effects: [FadeEffect(duration: 800.ms), ScaleEffect(duration: 800.ms, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0))]),
                      Text(
                        "Streak: $streakDays days",
                        style: TextStyle(color: TColor.accent1, fontSize: 16, fontWeight: FontWeight.w600),
                      ).animate(effects: [FadeEffect(duration: 800.ms), ShakeEffect(duration: 400.ms)]),
                    ],
                  ),
                ),
                // Enhanced Chart
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Container(
                    padding: const EdgeInsets.only(left: 15),
                    height: media.width * 0.5,
                    width: double.maxFinite,
                    child: LineChart(
                      LineChartData(
                        lineTouchData: LineTouchData(
                          enabled: true,
                          handleBuiltInTouches: false,
                          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                            if (response == null || response.lineBarSpots == null) {
                              return;
                            }
                            setState(() {
                              showingTooltipOnSpots = response.lineBarSpots!.map((spot) => spot.spotIndex).toList();
                            });
                          },
                          mouseCursorResolver: (FlTouchEvent event, LineTouchResponse? response) {
                            return (response == null || response.lineBarSpots == null) ? SystemMouseCursors.basic : SystemMouseCursors.click;
                          },
                          getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                            return spotIndexes.map((index) {
                              return TouchedSpotIndicatorData(
                                const FlLine(color: Colors.transparent),
                                FlDotData(
                                  show: true,
                                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                                    radius: 3,
                                    color: Colors.white,
                                    strokeWidth: 3,
                                    strokeColor: barData.color!,
                                  ),
                                ),
                              );
                            }).toList();
                          },
                          touchTooltipData: LineTouchTooltipData(
                            tooltipRoundedRadius: 20,
                            // getTooltipColor: Color.black,
                            getTooltipItems: (List<LineBarSpot> lineBarsSpot) {
                              return lineBarsSpot.map((spot) {
                                final label = spot.barIndex == 0 ? 'Planned' : 'Actual';
                                return LineTooltipItem(
                                  "$label: ${spot.y.toInt()} kcal",
                                  TextStyle(
                                    color: spot.barIndex == 0 ? TColor.primary : TColor.accent2,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        lineBarsData: _getWeeklyChartData(),
                        minY: 0,
                        maxY: maxCalories.ceilToDouble(),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(),
                          topTitles: const AxisTitles(),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() > 0 && value.toInt() <= 7) {
                                  final day = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)).add(Duration(days: value.toInt() - 1));
                                  return Text(
                                    DateFormat.E().format(day),
                                    style: TextStyle(color: TColor.textSecondary, fontSize: 12),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: interval, // Use calculated interval with fallback
                              getTitlesWidget: (value, meta) => Text(
                                '${value.toInt()}',
                                style: TextStyle(color: TColor.textSecondary, fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawHorizontalLine: true,
                          horizontalInterval: interval, // Use calculated interval with fallback
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: TColor.textSecondary.withOpacity(0.15),
                            strokeWidth: 2,
                          ),
                        ),
                        borderData: FlBorderData(show: true, border: Border.all(color: Colors.transparent)),
                      ),
                    ),
                  ).animate(effects: [FadeEffect(duration: 1000.ms), ScaleEffect(duration: 1000.ms, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0))]),
                ),
                // Legend
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem("Planned", TColor.primary),
                      SizedBox(width: 20),
                      _buildLegendItem("Actual", TColor.accent2),
                    ],
                  ),
                ),
                // Date Filter
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: ExpansionTile(
                    title: Text("Select Date", style: TextStyle(color: TColor.textPrimary, fontWeight: FontWeight.bold)),
                    children: [
                      TextField(
                        controller: _dateController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: "Date",
                          fillColor: TColor.cardLight,
                          filled: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          suffixIcon: Icon(Icons.calendar_today, color: TColor.primary),
                        ),
                        onTap: _selectDate,
                      ),
                    ],
                  ),
                ).animate(effects: [FadeEffect(duration: 800.ms)]),
                // Workout List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: filteredWorkouts.length,
                    itemBuilder: (context, index) {
                      var wObj = filteredWorkouts[index];
                      bool isCompleted = wObj['completed'] == true;
                      return Card(
                        color: TColor.cardLight,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          leading: Image.asset(wObj['image'] ?? "assets/img/img_1.png", width: 50, height: 50),
                          title: Text(wObj['title'] ?? 'Unnamed', style: TextStyle(color: TColor.textPrimary, fontWeight: FontWeight.w700)),
                          subtitle: Text("${wObj['time'] ?? 'N/A'} min | ${isCompleted ? 'Completed' : 'Pending'}", style: TextStyle(color: TColor.textSecondary)),
                          trailing: Icon(isCompleted ? Icons.check_circle : Icons.schedule, color: isCompleted ? TColor.accent1 : TColor.textSecondary),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => WorkoutDetailView(dObj: wObj))),
                        ),
                      ).animate(effects: [FadeEffect(duration: 700.ms), SlideEffect(duration: 700.ms, begin: Offset(0, 20), end: Offset(0, 0))]);
                    },
                  ),
                ),
                // Bottom Navigation
                BottomNavigationBar(
                  currentIndex: selectedTab,
                  onTap: _onTabTapped,
                  items: [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined, size: 28),
                      activeIcon: Icon(Icons.home, color: TColor.primary, size: 28),
                      label: "Home",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.fitness_center_outlined, size: 28),
                      activeIcon: Icon(Icons.fitness_center, color: TColor.primary, size: 28),
                      label: "Workout",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.restaurant_menu, size: 28),
                      activeIcon: Icon(Icons.restaurant, color: TColor.primary, size: 28),
                      label: "Meal",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.bedtime, size: 28),
                      activeIcon: Icon(Icons.nightlight_round, color: TColor.primary, size: 28),
                      label: "Sleep",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline, size: 28),
                      activeIcon: Icon(Icons.person, color: TColor.primary, size: 28),
                      label: "Profile",
                    ),
                  ],
                  selectedItemColor: TColor.primary,
                  unselectedItemColor: TColor.textSecondary,
                  backgroundColor: TColor.backgroundLight,
                  elevation: 0,
                  type: BottomNavigationBarType.fixed,
                  selectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: TColor.primary),
                  unselectedLabelStyle: TextStyle(fontSize: 14, color: TColor.textSecondary),
                ).animate(effects: [FadeEffect(duration: 800.ms)]),
              ],
            ),
            // FAB and Max
            Positioned(
              bottom: 70,
              right: 20,
              child: Row(
                children: [
                  FloatingActionButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddScheduleView(date: DateTime.now()))),
                    backgroundColor: TColor.primary,
                    child: Icon(Icons.add, color: TColor.textPrimaryDark),
                  ),
                  SizedBox(width: 10),
                  GestureDetector(
                    onTap: _showMaxDialog,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: TColor.cardLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: TColor.primary.withOpacity(0.3)),
                      ),
                      child: Image.asset('assets/img/max_avatar.png', width: 50, height: 50),
                    ),
                  ),
                ],
              ).animate(effects: [FadeEffect(duration: 800.ms), ScaleEffect(duration: 800.ms, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0))]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        SizedBox(width: 5),
        Text(label, style: TextStyle(color: TColor.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:fitglide_mobile_application/view/meal_planner/meal_planner_view.dart';
import 'package:fitglide_mobile_application/view/profile/profile_view.dart';
import 'package:fitglide_mobile_application/view/workout_tracker/workout_tracker_view.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fitglide_mobile_application/common/colo_extension.dart';
import 'package:fitglide_mobile_application/common_widget/round_button.dart';
import 'package:fitglide_mobile_application/common_widget/today_sleep_schedule_row.dart';
import 'package:fitglide_mobile_application/view/main_tab/main_screen.dart';
import 'package:fitglide_mobile_application/view/workout_tracker/workout_hub_view.dart';
import 'package:fitglide_mobile_application/view/sleep_tracker/sleep_add_alarm_view.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class SleepTrackerView extends StatefulWidget {
  const SleepTrackerView({super.key});

  @override
  State<SleepTrackerView> createState() => _SleepTrackerViewState();
}

class _SleepTrackerViewState extends State<SleepTrackerView> {
  String selectedView = 'Weekly';
  DateTime selectedDate = DateTime.now();
  List<int> showingTooltipOnSpots = [4];
  int selectedTab = 3;
  TimeOfDay? newAlarmTime;
  bool vibrateEnabled = false;

  // Static data for demo
  List<Map<String, dynamic>> sleepSchedule = [
    {
      "name": "Bedtime",
      "image": "assets/img/bed.png",
      "time": "01/06/2023 09:00 PM",
      "duration": "in 6hours 22minutes"
    },
    {
      "name": "Alarm",
      "image": "assets/img/alarm.png",
      "time": "02/06/2023 05:10 AM",
      "duration": "in 14hours 30minutes"
    },
  ];

  List<Map<String, dynamic>> badges = [
    {"icon": "assets/img/sleep_streak.png", "title": "Sleep Streak"},
  ];

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    final displayDate = DateFormat('MMM d, yyyy').format(selectedDate);

    return Scaffold(
      backgroundColor: TColor.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Sleep Tracker", style: TextStyle(color: TColor.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)).animate(effects: [FadeEffect(duration: 800.ms)]),
                              Container(
                                height: 30,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(gradient: LinearGradient(colors: [TColor.primary, TColor.primaryLight]), borderRadius: BorderRadius.circular(15)),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedView,
                                    items: ["Daily", "Weekly", "Monthly"].map((name) => DropdownMenuItem(value: name, child: Text(name, style: TextStyle(color: TColor.textSecondary, fontSize: 14)))).toList(),
                                    onChanged: (value) => setState(() => selectedView = value!),
                                    icon: Icon(Icons.expand_more, color: TColor.textSecondary),
                                    hint: Text("Weekly", style: TextStyle(color: TColor.textSecondary, fontSize: 12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Graph
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
                                    if (response == null || response.lineBarSpots == null) return;
                                    setState(() => showingTooltipOnSpots = response.lineBarSpots!.map((spot) => spot.spotIndex).toList());
                                  },
                                  mouseCursorResolver: (FlTouchEvent event, LineTouchResponse? response) => (response == null || response.lineBarSpots == null) ? SystemMouseCursors.basic : SystemMouseCursors.click,
                                  getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) => spotIndexes.map((index) => TouchedSpotIndicatorData(
                                    const FlLine(color: Colors.transparent),
                                    FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 3, color: Colors.white, strokeWidth: 3, strokeColor: barData.color!)),
                                  )).toList(),
                                  touchTooltipData: LineTouchTooltipData(
                                    // tooltipBgColor: TColor.cardLight.withOpacity(0.9),
                                    tooltipRoundedRadius: 20,
                                    getTooltipItems: (List<LineBarSpot> lineBarsSpot) => lineBarsSpot.map((spot) => LineTooltipItem(
                                      "${spot.barIndex == 0 ? 'Sleep' : 'Deep Sleep'}: ${spot.y.toInt()}h",
                                      TextStyle(color: spot.barIndex == 0 ? TColor.primary : TColor.accent2, fontSize: 10, fontWeight: FontWeight.bold),
                                    )).toList(),
                                  ),
                                ),
                                lineBarsData: [lineChartBarDataSleep, lineChartBarDataDeepSleep],
                                minY: 0,
                                maxY: 10,
                                titlesData: FlTitlesData(
                                  leftTitles: const AxisTitles(),
                                  topTitles: const AxisTitles(),
                                  bottomTitles: AxisTitles(sideTitles: bottomTitles),
                                  rightTitles: AxisTitles(sideTitles: rightTitles),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawHorizontalLine: true,
                                  horizontalInterval: 2,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (value) => FlLine(color: TColor.textSecondary.withOpacity(0.15), strokeWidth: 2),
                                ),
                                borderData: FlBorderData(show: true, border: Border.all(color: Colors.transparent)),
                              ),
                            ),
                          ).animate(effects: [FadeEffect(duration: 1000.ms)]),
                        ),
                        // Tracking Boxes
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildTrackingBox("Today", "8h 20m", "8h 30m"),
                              _buildTrackingBox("Weekly Avg", "7h 50m", "8h 30m"),
                              _buildTrackingBox("Monthly Avg", "7h 40m", "8h 30m"),
                            ],
                          ),
                        ),
                        // Sleep Debt
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Card(
                            color: TColor.cardLight,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            child: Padding(
                              padding: const EdgeInsets.all(15),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Sleep Debt", style: TextStyle(color: TColor.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                                      SizedBox(height: 5),
                                      Text("2h 30m", style: TextStyle(color: TColor.accent1, fontSize: 14)),
                                    ],
                                  ),
                                  Icon(Icons.warning, color: TColor.accent1, size: 24),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Schedule Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Sleep Schedule", style: TextStyle(color: TColor.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                                  GestureDetector(
                                    onTap: () => _selectDate(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: TColor.primary),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.calendar_today, color: TColor.primary, size: 16),
                                          const SizedBox(width: 5),
                                          Text(displayDate, style: TextStyle(color: TColor.textPrimary, fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ListView.builder(
                                padding: EdgeInsets.zero,
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: sleepSchedule.length,
                                itemBuilder: (context, index) {
                                  var sObj = sleepSchedule[index];
                                  return TodaySleepScheduleRow(sObj: sObj);
                                },
                              ),
                              const SizedBox(height: 10),
                              // Inline Add Alarm
                              Card(
                                color: TColor.cardLight,
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Add Alarm", style: TextStyle(color: TColor.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          GestureDetector(
                                            onTap: () async {
                                              final TimeOfDay? picked = await showTimePicker(
                                                context: context,
                                                initialTime: TimeOfDay.now(),
                                              );
                                              if (picked != null) setState(() => newAlarmTime = picked);
                                            },
                                            child: Text(
                                              newAlarmTime != null ? newAlarmTime!.format(context) : "Set Time",
                                              style: TextStyle(color: newAlarmTime != null ? TColor.textPrimary : TColor.textSecondary, fontSize: 14),
                                            ),
                                          ),
                                          CustomAnimatedToggleSwitch<bool>(
                                            current: vibrateEnabled,
                                            values: const [false, true],
                                            indicatorSize: const Size.square(20.0),
                                            animationDuration: const Duration(milliseconds: 200),
                                            animationCurve: Curves.linear,
                                            onChanged: (b) => setState(() => vibrateEnabled = b),
                                            iconBuilder: (context, local, global) => const SizedBox(),
                                            wrapperBuilder: (context, global, child) => Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Positioned(
                                                  left: 5.0,
                                                  right: 5.0,
                                                  height: 20.0,
                                                  child: DecoratedBox(
                                                    decoration: BoxDecoration(
                                                      gradient: vibrateEnabled ? LinearGradient(colors: TColor.secondaryG) : LinearGradient(colors: [Colors.grey, Colors.grey]),
                                                      borderRadius: const BorderRadius.all(Radius.circular(50.0)),
                                                    ),
                                                  ),
                                                ),
                                                child,
                                              ],
                                            ),
                                            foregroundIndicatorBuilder: (context, global) => SizedBox.fromSize(
                                              size: const Size(10, 10),
                                              child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                  color: TColor.white,
                                                  borderRadius: const BorderRadius.all(Radius.circular(50.0)),
                                                  boxShadow: const [BoxShadow(color: Colors.black38, spreadRadius: 0.05, blurRadius: 1.1, offset: Offset(0.0, 0.8))],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        width: double.maxFinite,
                                        height: 40,
                                        child: RoundButton(
                                          title: "Add",
                                          type: RoundButtonType.bgGradient,
                                          fontSize: 14,
                                          onPressed: () {
                                            if (newAlarmTime != null) {
                                              final now = DateTime.now();
                                              final alarmDateTime = DateTime(now.year, now.month, now.day, newAlarmTime!.hour, newAlarmTime!.minute);
                                              final duration = alarmDateTime.difference(now);
                                              setState(() {
                                                sleepSchedule.add({
                                                  "name": "Alarm",
                                                  "image": "assets/img/alarm.png",
                                                  "time": DateFormat('dd/MM/yyyy hh:mm a').format(alarmDateTime),
                                                  "duration": "in ${_formatDuration(duration)}",
                                                });
                                                newAlarmTime = null; // Reset after adding
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Badges
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Achievements", style: TextStyle(color: TColor.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 80,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: badges.length,
                                  itemBuilder: (context, index) {
                                    final badge = badges[index];
                                    return Container(
                                      margin: const EdgeInsets.only(right: 10),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: TColor.cardLight, borderRadius: BorderRadius.circular(10)),
                                      child: Row(
                                        children: [
                                          Image.asset(badge['icon'] ?? 'assets/img/salad.png', width: 40, height: 40, errorBuilder: (context, error, stackTrace) => Icon(Icons.star, color: TColor.primary, size: 40)),
                                          const SizedBox(width: 10),
                                          Text(badge['title'], style: TextStyle(color: TColor.textPrimary, fontSize: 14)),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 80), // Space for FAB and Max
                      ],
                    ),
                  ),
                ),
                // Bottom Navigation
                BottomNavigationBar(
                  currentIndex: selectedTab,
                  onTap: _onTabTapped,
                  items: [
                    BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home, color: TColor.primary), label: "Home"),
                    BottomNavigationBarItem(icon: Icon(Icons.fitness_center_outlined), activeIcon: Icon(Icons.fitness_center, color: TColor.primary), label: "Workout"),
                    BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), activeIcon: Icon(Icons.restaurant, color: TColor.primary), label: "Meal"),
                    BottomNavigationBarItem(icon: Icon(Icons.bedtime), activeIcon: Icon(Icons.nightlight_round, color: TColor.primary), label: "Sleep"),
                    BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person, color: TColor.primary), label: "Profile"),
                  ],
                  selectedItemColor: TColor.primary,
                  unselectedItemColor: TColor.textSecondary,
                  backgroundColor: TColor.backgroundLight,
                  elevation: 0,
                  type: BottomNavigationBarType.fixed,
                  selectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 14),
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
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SleepAddAlarmView(date: selectedDate))).then((_) => setState(() {})),
                    backgroundColor: TColor.primary,
                    child: Icon(Icons.add, color: TColor.textPrimaryDark),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _showMaxDialog,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: TColor.cardLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: TColor.primary.withOpacity(0.3))),
                      child: Image.asset('assets/img/max_avatar.png', width: 50, height: 50, errorBuilder: (context, error, stackTrace) => Icon(Icons.person, color: TColor.primary, size: 50)),
                    ),
                  ),
                ],
              ).animate(effects: [FadeEffect(duration: 800.ms), ScaleEffect(duration: 800.ms, begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0))]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingBox(String title, String hours, String goal) {
    return Card(
      color: TColor.cardLight,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: TColor.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            Text(hours, style: TextStyle(color: TColor.textPrimary, fontSize: 14)),
            Text("Goal: $goal", style: TextStyle(color: TColor.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  LineChartBarData get lineChartBarDataSleep => LineChartBarData(
    isCurved: true,
    color: TColor.primary,
    barWidth: 4,
    isStrokeCapRound: true,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(
      show: true,
      gradient: LinearGradient(colors: [TColor.primary.withOpacity(0.3), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    ),
    spots: const [
      FlSpot(1, 7), FlSpot(2, 8), FlSpot(3, 6), FlSpot(4, 8), FlSpot(5, 7), FlSpot(6, 9), FlSpot(7, 7),
    ],
  );

  LineChartBarData get lineChartBarDataDeepSleep => LineChartBarData(
    isCurved: true,
    color: TColor.accent2,
    barWidth: 2,
    isStrokeCapRound: true,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(
      show: true,
      gradient: LinearGradient(colors: [TColor.accent2.withOpacity(0.3), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter),
    ),
    spots: const [
      FlSpot(1, 2), FlSpot(2, 3), FlSpot(3, 1.5), FlSpot(4, 2.5), FlSpot(5, 2), FlSpot(6, 3.5), FlSpot(7, 2),
    ],
  );

  SideTitles get rightTitles => SideTitles(
    getTitlesWidget: (value, meta) => Text('${value.toInt()}h', style: TextStyle(color: TColor.textSecondary, fontSize: 12)),
    showTitles: true,
    interval: 2,
    reservedSize: 40,
  );

  SideTitles get bottomTitles => SideTitles(
    showTitles: true,
    reservedSize: 32,
    interval: 1,
    getTitlesWidget: (value, meta) {
      const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      if (value.toInt() >= 1 && value.toInt() <= 7) {
        return Text(days[value.toInt() - 1], style: TextStyle(color: TColor.textSecondary, fontSize: 12));
      }
      return const Text('');
    },
  );

  void _onTabTapped(int index) {
    setState(() => selectedTab = index);
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
            Image.asset('assets/img/max_avatar.png', width: 50, height: 50, errorBuilder: (context, error, stackTrace) => Icon(Icons.person, color: TColor.primary, size: 50)),
            SizedBox(width: 10),
            Expanded(child: Text("Max says: Aim for 8 hours tonight!", style: TextStyle(color: TColor.textPrimary))),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Close", style: TextStyle(color: TColor.primary)))],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
      // Placeholder for fetching schedule data
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return "$hours h $minutes min";
  }
}
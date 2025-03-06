// lib/view/sleep_tracker/sleep_tracker_view.dart
import 'package:fitglide_mobile_application/services/sleep_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fitglide_mobile_application/common/colo_extension.dart';
import 'package:fitglide_mobile_application/common_widget/round_button.dart';
import 'package:fitglide_mobile_application/common_widget/today_sleep_schedule_row.dart';
import 'package:fitglide_mobile_application/view/main_tab/main_screen.dart';
import 'package:fitglide_mobile_application/view/workout_tracker/workout_hub_view.dart';
import 'package:fitglide_mobile_application/view/meal_planner/meal_planner_view.dart';
import 'package:fitglide_mobile_application/view/profile/profile_view.dart';
import 'package:fitglide_mobile_application/view/sleep_tracker/sleep_add_alarm_view.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class SleepTrackerView extends ConsumerWidget {
  const SleepTrackerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleepState = ref.watch(sleepTrackerProvider);
    final sleepNotifier = ref.read(sleepTrackerProvider.notifier);

    return Scaffold(
      backgroundColor: TColor.backgroundLight,
      body: SafeArea(
        child: sleepState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : sleepState.error != null
                ? Center(child: Text('Error: ${sleepState.error}'))
                : Stack(
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHeader(context, ref),
                                  _buildGraph(context, sleepState),
                                  _buildTrackingBoxes(context, sleepState),
                                  _buildSleepDebt(context, sleepState),
                                  _buildScheduleSection(context, sleepState, sleepNotifier),
                                  _buildBadges(context),
                                  const SizedBox(height: 80),
                                ],
                              ),
                            ),
                          ),
                          _buildBottomNavigation(context, ref),
                        ],
                      ),
                      _buildFAB(context),
                    ],
                  ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final sleepNotifier = ref.read(sleepTrackerProvider.notifier);
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Sleep Tracker", style: TextStyle(color: TColor.textPrimary, fontSize: 20, fontWeight: FontWeight.bold))
              .animate(effects: [FadeEffect(duration: 800.ms)]),
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [TColor.primary, TColor.primaryLight]), borderRadius: BorderRadius.circular(15)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: 'Weekly',
                items: ["Daily", "Weekly", "Monthly"].map((name) => DropdownMenuItem(value: name, child: Text(name, style: TextStyle(color: TColor.textSecondary, fontSize: 14)))).toList(),
                onChanged: (value) => sleepNotifier.fetchSleepData(DateTime.now()),
                icon: Icon(Icons.expand_more, color: TColor.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraph(BuildContext context, SleepTrackerState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        height: MediaQuery.of(context).size.width * 0.5,
        child: LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(spots: state.sleepSpots, isCurved: true, color: TColor.primary, barWidth: 4),
              LineChartBarData(spots: state.deepSleepSpots, isCurved: true, color: TColor.accent2, barWidth: 2),
            ],
            minY: 0,
            maxY: 12,
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(),
              topTitles: const AxisTitles(),
              bottomTitles: AxisTitles(sideTitles: _bottomTitles()),
              rightTitles: AxisTitles(sideTitles: _rightTitles()),
            ),
            gridData: FlGridData(show: true, horizontalInterval: 2),
          ),
        ),
      ).animate(effects: [FadeEffect(duration: 1000.ms)]),
    );
  }

  Widget _buildTrackingBoxes(BuildContext context, SleepTrackerState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTrackingBox(context, "Today", state.sleepStats['today']!, "8h 0m"),
          _buildTrackingBox(context, "Weekly Avg", state.sleepStats['weekly']!, "8h 0m"),
          _buildTrackingBox(context, "Monthly Avg", state.sleepStats['monthly']!, "8h 0m"),
        ],
      ),
    );
  }

  Widget _buildSleepDebt(BuildContext context, SleepTrackerState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Card(
        color: TColor.cardLight,
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
                  Text(state.sleepDebt.toString().split('.')[0], style: TextStyle(color: TColor.accent1, fontSize: 14)),
                ],
              ),
              Icon(Icons.warning, color: TColor.accent1, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleSection(BuildContext context, SleepTrackerState state, SleepTrackerNotifier notifier) {
    final currentDate = DateTime.now();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Sleep Schedule", style: TextStyle(color: TColor.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () => _selectDate(context, notifier),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(border: Border.all(color: TColor.primary), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: TColor.primary, size: 16),
                      const SizedBox(width: 5),
                      Text(DateFormat('MMM d, yyyy').format(currentDate), style: TextStyle(color: TColor.textPrimary, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.sleepSchedule.length,
            itemBuilder: (context, index) => TodaySleepScheduleRow(sObj: state.sleepSchedule[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildBadges(BuildContext context) {
    return Padding(
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
              itemCount: 1,
              itemBuilder: (context, index) => Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: TColor.cardLight, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/img/sleep_streak.png',
                      width: 40,
                      height: 40,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.star, color: TColor.primary, size: 40),
                    ),
                    const SizedBox(width: 10),
                    Text("Sleep Streak", style: TextStyle(color: TColor.textPrimary, fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, WidgetRef ref) {
    return BottomNavigationBar(
      currentIndex: 3,
      onTap: (index) {
        switch (index) {
          case 0: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen())); break;
          case 1: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const WorkoutHubView())); break;
          case 2: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MealPlannerView())); break;
          case 3: break;
          case 4: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfileView())); break;
        }
      },
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
    ).animate(effects: [FadeEffect(duration: 800.ms)]);
  }

  Widget _buildFAB(BuildContext context) {
    return Positioned(
      bottom: 70,
      right: 20,
      child: Row(
        children: [
          FloatingActionButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SleepAddAlarmView(date: DateTime.now()))),
            backgroundColor: TColor.primary,
            child: Icon(Icons.add, color: TColor.textPrimaryDark),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _showMaxDialog(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: TColor.cardLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: TColor.primary.withOpacity(0.3))),
              child: Image.asset(
                'assets/img/max_avatar.png',
                width: 50,
                height: 50,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.person, color: TColor.primary, size: 50),
              ),
            ),
          ),
        ],
      ).animate(effects: [FadeEffect(duration: 800.ms), ScaleEffect(duration: 800.ms, begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0))]),
    );
  }

  Widget _buildTrackingBox(BuildContext context, String title, String hours, String goal) {
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

  SideTitles _bottomTitles() => SideTitles(
    showTitles: true,
    reservedSize: 32,
    interval: 1,
    getTitlesWidget: (value, meta) {
      const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      final index = value.toInt();
      if (index >= 0 && index < 7) {
        return Text(days[index], style: TextStyle(color: TColor.textSecondary, fontSize: 12));
      }
      return const Text('');
    },
  );

  SideTitles _rightTitles() => SideTitles(
    getTitlesWidget: (value, meta) => Text('${value.toInt()}h', style: TextStyle(color: TColor.textSecondary, fontSize: 12)),
    showTitles: true,
    interval: 2,
    reservedSize: 40,
  );

  Future<void> _selectDate(BuildContext context, SleepTrackerNotifier notifier) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      notifier.fetchSleepData(picked);
    }
  }

  void _showMaxDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: TColor.cardLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: TColor.primary)),
        content: Row(
          children: [
            Image.asset(
              'assets/img/max_avatar.png',
              width: 50,
              height: 50,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.person, color: TColor.primary, size: 50),
            ),
            SizedBox(width: 10),
            Expanded(child: Text("Max says: Aim for 8 hours tonight!", style: TextStyle(color: TColor.textPrimary))),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Close", style: TextStyle(color: TColor.primary)))],
      ),
    );
  }
}
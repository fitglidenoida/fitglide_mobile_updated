import 'package:fitglide_mobile_application/common_widget/icon_title_next_row.dart';
import 'package:fitglide_mobile_application/common_widget/round_button.dart';
import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:fitglide_mobile_application/view/main_tab/main_screen.dart';
import 'package:fitglide_mobile_application/view/meal_planner/meal_schedule_view.dart';
import 'package:fitglide_mobile_application/view/sleep_tracker/sleep_schedule_view.dart';
import 'package:fitglide_mobile_application/view/workout_tracker/add_schedule_view.dart';
import 'package:fitglide_mobile_application/view/workout_tracker/workout_detail_view.dart';
import 'package:fitglide_mobile_application/view/workout_tracker/workout_schedule_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../common/colo_extension.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: TColor.white, // Changed from TColor.white (already correct)
      ),
      backgroundColor: TColor.white, // Changed from TColor.white (already correct)
      body: const Center(
        child: Text('Profile View - To be implemented', style: TextStyle(color: TColor.black)),
      ),
    );
  }
}

class WorkoutTrackerView extends StatefulWidget {
  const WorkoutTrackerView({super.key});

  @override
  State<WorkoutTrackerView> createState() => _WorkoutTrackerViewState();
}

class _WorkoutTrackerViewState extends State<WorkoutTrackerView> {
  List<Map> workoutArr = [];
  int selectedTab = 1; // Default to Workout tab (index 1 in MainScreen)

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    try {
      final response = await ApiService.get('workout-plans?populate=*');
      setState(() {
        workoutArr = List<Map>.from(response['data'] ?? []);
      });
    } catch (e) {
      debugPrint('Error loading workouts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load workouts: $e')),
      );
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      selectedTab = index;
    });
    _navigateToTab(index, context);
  }

  void _navigateToTab(int index, BuildContext context) {
    switch (index) {
      case 0: // Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
        break;
      case 1: // Workout
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WorkoutTrackerView()),
        );
        break;
      case 2: // Meal
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MealScheduleView()),
        );
        break;
      case 3: // Sleep
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SleepScheduleView()),
        );
        break;
      case 4: // Profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileView()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: TColor.white, // Changed from Color(0xFF2C2C2C) to white background
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      backgroundColor: TColor.white, // Changed from Color(0xFF2C2C2C) to white
                      centerTitle: true,
                      elevation: 0,
                      leading: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          height: 40,
                          width: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: TColor.lightGray, // Changed from Color(0xFF3C3C3C) to light gray
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.asset(
                            "assets/img/black_btn.png",
                            width: 15,
                            height: 15,
                            fit: BoxFit.contain,
                          ).animate(
                            effects: [
                              FadeEffect(duration: 600.ms, curve: Curves.easeInOut),
                              ScaleEffect(duration: 600.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                              ShakeEffect(duration: 300.ms, curve: Curves.easeOut),
                            ],
                          ),
                        ),
                      ),
                      title: Text(
                        "Workout Tracker",
                        style: TextStyle(color: TColor.black, fontSize: 20, fontWeight: FontWeight.bold), // Changed from Colors.white to black
                      ).animate(
                        effects: [
                          FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
                          ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                          ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
                        ],
                      ),
                      actions: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AddScheduleView(date: DateTime.now())),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            height: 40,
                            width: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: TColor.lightGray, // Changed from Color(0xFF3C3C3C) to light gray
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Image.asset(
                              "assets/img/more_btn.png",
                              width: 15,
                              height: 15,
                              fit: BoxFit.contain,
                            ).animate(
                              effects: [
                                FadeEffect(duration: 600.ms, curve: Curves.easeInOut),
                                ScaleEffect(duration: 600.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                                ShakeEffect(duration: 300.ms, curve: Curves.easeOut),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        color: TColor.white, // Changed from Color(0xFF2C2C2C) to white
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Today, ${DateTime.now().day} ${DateFormat('MMMM').format(DateTime.now())}",
                              style: TextStyle(color: TColor.black, fontSize: 16, fontWeight: FontWeight.w500), // Changed from Colors.white to black
                            ).animate(
                              effects: [
                                FadeEffect(duration: 700.ms, curve: Curves.easeInOut),
                                SlideEffect(duration: 700.ms, curve: Curves.easeInOut, begin: Offset(20, 0), end: Offset(0, 0)),
                                ShakeEffect(duration: 300.ms, curve: Curves.easeOut),
                              ],
                            ),
                            Text(
                              "0/0 Completed",
                              style: TextStyle(color: TColor.gray, fontSize: 14), // Changed from Colors.white70 to gray
                            ).animate(
                              effects: [
                                FadeEffect(duration: 700.ms, curve: Curves.easeInOut),
                                SlideEffect(duration: 700.ms, curve: Curves.easeInOut, begin: Offset(20, 0), end: Offset(0, 0)),
                                ShakeEffect(duration: 300.ms, curve: Curves.easeOut),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: TColor.white, // Changed from Color(0xFF2C2C2C) to white
                  child: Column(
                    children: [
                      SizedBox(height: media.width * 0.05),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: TColor.lightGray, // Changed from Color(0xFF3C3C3C) to light gray
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            colors: TColor.primaryG, // Using TColor.primaryG for gradient [lightGray, darkRose]
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Weekly Progress",
                              style: TextStyle(color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700), // Changed from Colors.white to black
                            ).animate(
                              effects: [
                                FadeEffect(duration: 700.ms, curve: Curves.easeInOut),
                                SlideEffect(duration: 700.ms, curve: Curves.easeInOut, begin: Offset(20, 0), end: Offset(0, 0)),
                                ShakeEffect(duration: 300.ms, curve: Curves.easeOut),
                              ],
                            ),
                            Icon(Icons.arrow_forward_ios, color: TColor.darkRose, size: 16), // Changed from Color(0xFF8B4B4B) to TColor.darkRose
                          ],
                        ),
                      ).animate(
                        effects: [
                          FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
                          ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                          ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
                        ],
                      ),
                      SizedBox(height: media.width * 0.05),
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
                            maxY: 100,
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  FlSpot(0, 20),
                                  FlSpot(1, 40),
                                  FlSpot(2, 60),
                                  FlSpot(3, 50),
                                  FlSpot(4, 70),
                                  FlSpot(5, 80),
                                  FlSpot(6, 90),
                                ],
                                isCurved: true,
                                color: TColor.lightIndigo, // Changed from Color(0xFF4A6D4A) to TColor.lightIndigo
                                dotData: FlDotData(show: false),
                                belowBarData: BarAreaData(show: false),
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
                      SizedBox(height: media.width * 0.05),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Workouts",
                            style: TextStyle(color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700), // Changed from Colors.white to black
                          ).animate(
                            effects: [
                              FadeEffect(duration: 700.ms, curve: Curves.easeInOut),
                              SlideEffect(duration: 700.ms, curve: Curves.easeInOut, begin: Offset(20, 0), end: Offset(0, 0)),
                              ShakeEffect(duration: 300.ms, curve: Curves.easeOut),
                            ],
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              "${workoutArr.length} Items",
                              style: TextStyle(color: TColor.gray, fontSize: 14), // Changed from Colors.white70 to gray
                            ).animate(
                              effects: [
                                FadeEffect(duration: 600.ms, curve: Curves.easeInOut),
                                ScaleEffect(duration: 600.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                                ShakeEffect(duration: 300.ms, curve: Curves.easeOut),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: workoutArr.length,
                          itemBuilder: (context, index) {
                            var wObj = workoutArr[index] as Map<String, dynamic>? ?? {};
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: TColor.lightGray, // Changed from Color(0xFF3C3C3C) to light gray
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: TColor.darkRose.withOpacity(0.3)), // Changed from Color(0xFF8B4B4B) to TColor.darkRose
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    wObj["image"] ?? "assets/img/img_1.png",
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.error, color: TColor.gray); // Changed from Colors.white70 to gray
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
                                          wObj["title"] ?? 'Unnamed Workout',
                                          style: TextStyle(color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700), // Changed from Colors.white to black
                                        ).animate(
                                          effects: [
                                            FadeEffect(duration: 700.ms, curve: Curves.easeInOut),
                                            SlideEffect(duration: 700.ms, curve: Curves.easeInOut, begin: Offset(10, 0), end: Offset(0, 0)),
                                            ShakeEffect(duration: 300.ms, curve: Curves.easeOut),
                                          ],
                                        ),
                                        Text(
                                          "${wObj["time"] ?? 'N/A'} | ${wObj["calories"] ?? 'N/A'} Calories Burn",
                                          style: TextStyle(color: TColor.gray, fontSize: 14), // Changed from Colors.white70 to gray
                                        ).animate(
                                          effects: [
                                            FadeEffect(duration: 600.ms, curve: Curves.easeInOut),
                                            SlideEffect(duration: 600.ms, curve: Curves.easeInOut, begin: Offset(10, 0), end: Offset(0, 0)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => WorkoutDetailView(dObj: wObj),
                                        ),
                                      );
                                    },
                                    child: Icon(Icons.arrow_forward_ios, color: TColor.lightIndigo, size: 16), // Changed from Color(0xFF4A6D4A) to TColor.lightIndigo
                                  ).animate(
                                    effects: [
                                      FadeEffect(duration: 600.ms, curve: Curves.easeInOut),
                                      ScaleEffect(duration: 600.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                                      ShakeEffect(duration: 300.ms, curve: Curves.easeOut),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ).animate(
                          effects: [
                            FadeEffect(duration: 1000.ms, curve: Curves.easeInOut),
                            SlideEffect(duration: 1000.ms, curve: Curves.easeInOut, begin: Offset(0, 20), end: Offset(0, 0)),
                            ShakeEffect(duration: 500.ms, curve: Curves.easeOut),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Add bottom navigation bar
            BottomNavigationBar(
              currentIndex: selectedTab,
              onTap: _onTabTapped,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined, size: 28).animate(
                    target: selectedTab == 0 ? 1.0 : 0.0,
                    effects: [
                      ScaleEffect(
                        duration: 400.ms,
                        curve: Curves.easeInOut,
                        begin: Offset(1.0, 1.0),
                        end: Offset(1.2, 1.2),
                      ),
                      FadeEffect(
                        duration: 400.ms,
                        curve: Curves.easeInOut,
                      ),
                      ShakeEffect(duration: 200.ms, curve: Curves.easeOut),
                    ],
                  ),
                  activeIcon: Icon(Icons.home, color: TColor.darkRose, size: 28).animate( // Changed from Color(0xFF8B4B4B) to TColor.darkRose
                    effects: [
                      FadeEffect(duration: 300.ms, curve: Curves.easeInOut),
                      ScaleEffect(duration: 300.ms, curve: Curves.easeInOut, begin: Offset(1.0, 1.0), end: Offset(1.1, 1.1)),
                      ShakeEffect(duration: 200.ms, curve: Curves.easeOut),
                    ],
                  ),
                  label: "Home",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.fitness_center_outlined, size: 28).animate(
                    target: selectedTab == 1 ? 1.0 : 0.0,
                    effects: [
                      ScaleEffect(
                        duration: 400.ms,
                        curve: Curves.easeInOut,
                        begin: Offset(1.0, 1.0),
                        end: Offset(1.2, 1.2),
                      ),
                      FadeEffect(
                        duration: 400.ms,
                        curve: Curves.easeInOut,
                      ),
                      ShakeEffect(duration: 200.ms, curve: Curves.easeOut),
                    ],
                  ),
                  activeIcon: Icon(Icons.fitness_center, color: TColor.darkRose, size: 28).animate( // Changed from Color(0xFF8B4B4B) to TColor.darkRose
                    effects: [
                      FadeEffect(duration: 300.ms, curve: Curves.easeInOut),
                      ScaleEffect(duration: 300.ms, curve: Curves.easeInOut, begin: Offset(1.0, 1.0), end: Offset(1.1, 1.1)),
                      ShakeEffect(duration: 200.ms, curve: Curves.easeOut),
                    ],
                  ),
                  label: "Workout",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.restaurant_menu, size: 28).animate(
                    target: selectedTab == 2 ? 1.0 : 0.0,
                    effects: [
                      ScaleEffect(
                        duration: 400.ms,
                        curve: Curves.easeInOut,
                        begin: Offset(1.0, 1.0),
                        end: Offset(1.2, 1.2),
                      ),
                      FadeEffect(
                        duration: 400.ms,
                        curve: Curves.easeInOut,
                      ),
                      ShakeEffect(duration: 200.ms, curve: Curves.easeOut),
                    ],
                  ),
                  activeIcon: Icon(Icons.restaurant, color: TColor.darkRose, size: 28).animate( // Changed from Color(0xFF8B4B4B) to TColor.darkRose
                    effects: [
                      FadeEffect(duration: 300.ms, curve: Curves.easeInOut),
                      ScaleEffect(duration: 300.ms, curve: Curves.easeInOut, begin: Offset(1.0, 1.0), end: Offset(1.1, 1.1)),
                      ShakeEffect(duration: 200.ms, curve: Curves.easeOut),
                    ],
                  ),
                  label: "Meal",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bedtime, size: 28).animate(
                    target: selectedTab == 3 ? 1.0 : 0.0,
                    effects: [
                      ScaleEffect(
                        duration: 400.ms,
                        curve: Curves.easeInOut,
                        begin: Offset(1.0, 1.0),
                        end: Offset(1.2, 1.2),
                      ),
                      FadeEffect(
                        duration: 400.ms,
                        curve: Curves.easeInOut,
                      ),
                      ShakeEffect(duration: 200.ms, curve: Curves.easeOut),
                    ],
                  ),
                  activeIcon: Icon(Icons.nightlight_round, color: TColor.darkRose, size: 28).animate( // Changed from Color(0xFF8B4B4B) to TColor.darkRose
                    effects: [
                      FadeEffect(duration: 300.ms, curve: Curves.easeInOut),
                      ScaleEffect(duration: 300.ms, curve: Curves.easeInOut, begin: Offset(1.0, 1.0), end: Offset(1.1, 1.1)),
                      ShakeEffect(duration: 200.ms, curve: Curves.easeOut),
                    ],
                  ),
                  label: "Sleep",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline, size: 28).animate(
                    target: selectedTab == 4 ? 1.0 : 0.0,
                    effects: [
                      ScaleEffect(
                        duration: 400.ms,
                        curve: Curves.easeInOut,
                        begin: Offset(1.0, 1.0),
                        end: Offset(1.2, 1.2),
                      ),
                      FadeEffect(
                        duration: 400.ms,
                        curve: Curves.easeInOut,
                      ),
                      ShakeEffect(duration: 200.ms, curve: Curves.easeOut),
                    ],
                  ),
                  activeIcon: Icon(Icons.person, color: TColor.darkRose, size: 28).animate( // Changed from Color(0xFF8B4B4B) to TColor.darkRose
                    effects: [
                      FadeEffect(duration: 300.ms, curve: Curves.easeInOut),
                      ScaleEffect(duration: 300.ms, curve: Curves.easeInOut, begin: Offset(1.0, 1.0), end: Offset(1.1, 1.1)),
                      ShakeEffect(duration: 200.ms, curve: Curves.easeOut),
                    ],
                  ),
                  label: "Profile",
                ),
              ],
              selectedItemColor: TColor.darkRose, // Changed from Color(0xFF8B4B4B) to TColor.darkRose
              unselectedItemColor: TColor.gray, // Changed from Colors.white70 to gray
              backgroundColor: TColor.white, // Changed from Color(0xFF2C2C2C) to white
              elevation: 0, // Remove elevation to avoid white strip
              type: BottomNavigationBarType.fixed,
              selectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: TColor.darkRose), // Changed from Color(0xFF8B4B4B) to TColor.darkRose
              unselectedLabelStyle: TextStyle(fontSize: 14, color: TColor.gray), // Changed from Colors.white70 to gray
            ).animate(
              effects: [
                FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
                ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.95, 0.95), end: Offset(1.0, 1.0)),
                ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
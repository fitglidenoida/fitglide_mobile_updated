import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:fitglide_mobile_application/view/profile/profile_view.dart';
import 'package:fitglide_mobile_application/view/sleep_tracker/sleep_tracker_view.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fitglide_mobile_application/services/bmr_tdee_service.dart';
import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:fitglide_mobile_application/services/user_service.dart';
import 'package:fitglide_mobile_application/view/main_tab/main_screen.dart';
import 'package:fitglide_mobile_application/view/workout_tracker/workout_hub_view.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../common/colo_extension.dart';
import 'meal_tdee_view.dart';
import 'food_info_details_view.dart';

class MealPlannerView extends StatefulWidget {
  const MealPlannerView({super.key});

  @override
  State<MealPlannerView> createState() => _MealPlannerViewState();
}

class _MealPlannerViewState extends State<MealPlannerView> {
  String selectedView = 'Weekly';
  String selectedMealCategory = 'Breakfast';
  List<int> showingTooltipOnSpots = [];
  DateTime today = DateTime.now();
  DateTime? selectedDate = DateTime.now();
  Map<String, List<Map<String, dynamic>>> groupedMeals = {};
  bool isLoadingMeals = true;
  double tdeeMaintain = 0.0;
  Map<String, double> tdeeOptions = {};
  bool isLoadingTdee = true;
  int selectedTab = 2;
  final PageController _tdeePageController = PageController();

  static const List<String> mealCategories = [
    'Breakfast',
    'Morning Snack',
    'Lunch',
    'Afternoon Snack',
    'Evening Snack',
    'Dinner',
  ];

  List<Map<String, dynamic>> badges = [];

  @override
  void initState() {
    super.initState();
    _fetchTdee();
    _fetchMealData();
  }

  Future<void> _fetchTdee() async {
    try {
      final tdeeService = BmrTdeeService();
      final options = await tdeeService.fetchTdeeOptions();
      setState(() {
        tdeeMaintain = options['maintain'] ?? 0.0;
        tdeeOptions = tdeeService.calculateTDEEOptions(tdeeMaintain, 'moderately active');
        isLoadingTdee = false;
      });
    } catch (e) {
      debugPrint("Error fetching TDEE: $e");
      setState(() {
        tdeeMaintain = 0.0;
        tdeeOptions = {'maintain': 0.0, 'loss_250g': 0.0, 'loss_500g': 0.0, 'gain_250g': 0.0, 'gain_500g': 0.0};
        isLoadingTdee = false;
      });
    }
  }

  Future<void> _fetchMealData({DateTime? specificDate}) async {
    debugPrint('Fetching meal data for MealPlannerView...');
    try {
      final user = await UserService.fetchUserData();
      final username = user.username;
      final targetDate = specificDate ?? (selectedDate ?? today);
      final dateStart = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final dateEnd = dateStart.add(const Duration(days: 1));

      final response = await ApiService.get(
        'diet-plans?populate=meals.diet_components&filters[users_permissions_user][username][\$eq]=$username',
      );
      
      final plans = response['data'] as List<dynamic>;
      if (plans.isNotEmpty) {
        final dietPlan = plans.first as Map<String, dynamic>;
        final meals = (dietPlan['meals'] as List<dynamic>? ?? []).where((meal) {
          final mealDate = DateTime.tryParse(meal['meal_date'] as String? ?? '') ?? DateTime.now();
          return mealDate.isAfter(dateStart) && mealDate.isBefore(dateEnd);
        }).toList();
        groupedMeals = _groupMealsByCategory(meals);
        _updateBadges();
        debugPrint('Grouped meals for $targetDate: $groupedMeals');
      } else {
        throw Exception('No diet plans found for user');
      }
      setState(() {
        isLoadingMeals = false;
      });
    } catch (e) {
      debugPrint('Error fetching meal data: $e');
      setState(() {
        isLoadingMeals = false;
      });
    }
  }

  void _updateBadges() {
    setState(() {
      badges = [
        if (groupedMeals.isNotEmpty) {"icon": "assets/img/meal_streak.png", "title": "Meal Streak"},
        if (tdeeMaintain > 0 && groupedMeals.values.any((meals) => meals.any((meal) => (meal['diet_components'] as List<dynamic>).any((comp) => comp['consumed'] == true))))
          {"icon": "assets/img/calorie_goal.png", "title": "Calorie Goal Met"},
      ];
    });
  }

  Map<String, List<Map<String, dynamic>>> _groupMealsByCategory(List<dynamic> meals) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var meal in meals) {
      final mealData = meal as Map<String, dynamic>;
      final category = mealData['name'] as String? ?? 'Unknown';
      grouped.putIfAbsent(category, () => []).add(mealData);
    }
    return grouped;
  }

  Future<void> _toggleConsumed(String documentId, bool currentStatus) async {
    debugPrint('Toggling consumed status for document ID: $documentId, current status: $currentStatus');
    try {
      final now = DateTime.now();
      final mealResponse = await ApiService.get('diet-components/$documentId?populate=*');
      final mealData = mealResponse['data'] as Map<String, dynamic>?;

      if (mealData != null) {
        final mealDate = DateTime.tryParse(mealData['meal_date'] as String? ?? '') ?? DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayEnd = todayStart.add(const Duration(days: 1));

        if (mealDate.isAfter(todayStart) && mealDate.isBefore(todayEnd)) {
          await ApiService.updateDietComponent(documentId, {'consumed': !currentStatus, 'meal_date': DateFormat('yyyy-MM-dd').format(now)});
          await _fetchMealData(specificDate: selectedDate);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Can only update today\'s meals')));
        }
      }
    } catch (e) {
      debugPrint('Error updating consumed status: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }

  Future<void> _editMealComponent(String documentId, Map<String, dynamic> currentComponent) async {
    debugPrint('Editing component: $documentId');
    // Placeholder for swapping logic
  }

  Map<String, Map<String, double>> _getWeeklyCalorieData() {
    final Map<String, Map<String, double>> weeklyData = {};
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final dayKey = DateFormat('yyyy-MM-dd').format(day);
      weeklyData[dayKey] = {'planned': 0.0, 'consumed': 0.0};
    }

    groupedMeals.forEach((category, meals) {
      for (var meal in meals) {
        final dietComponents = meal['diet_components'] as List<dynamic>? ?? [];
        final totalCalories = dietComponents.fold<double>(
          0,
          (sum, component) => sum + ((component as Map<String, dynamic>)['calories'] as int? ?? 0).toDouble(),
        );
        final consumedCalories = dietComponents.fold<double>(
          0,
          (sum, component) => sum + ((component as Map<String, dynamic>)['consumed'] == true ? (component['calories'] as int? ?? 0) : 0).toDouble(),
        );
        final dayKey = DateFormat('yyyy-MM-dd').format(now);
        weeklyData[dayKey]!['planned'] = weeklyData[dayKey]!['planned']! + totalCalories;
        weeklyData[dayKey]!['consumed'] = weeklyData[dayKey]!['consumed']! + consumedCalories;
      }
    });

    debugPrint('Weekly calorie data: $weeklyData');
    return weeklyData;
  }

  List<LineChartBarData> _getWeeklyChartData() {
    final weeklyData = _getWeeklyCalorieData();
    final plannedSpots = <FlSpot>[];
    final consumedSpots = <FlSpot>[];
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    weeklyData.forEach((dayKey, data) {
      final day = DateFormat('yyyy-MM-dd').parse(dayKey);
      final dayIndex = day.difference(startOfWeek).inDays.toDouble();
      plannedSpots.add(FlSpot(dayIndex + 1, data['planned']!));
      consumedSpots.add(FlSpot(dayIndex + 1, data['consumed']!));
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
          gradient: LinearGradient(colors: [TColor.primary.withOpacity(0.3), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
      ),
      LineChartBarData(
        spots: consumedSpots,
        isCurved: true,
        color: TColor.accent2,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(colors: [TColor.accent2.withOpacity(0.3), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
      ),
    ];
  }

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
            Expanded(child: Text("Max says: Try a balanced meal today!", style: TextStyle(color: TColor.textPrimary))),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("Close", style: TextStyle(color: TColor.primary)))],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? today,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _fetchMealData(specificDate: picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    final maxCalories = tdeeMaintain > 0 ? (tdeeMaintain * 1.5).ceilToDouble() : 2000.0;
    final interval = maxCalories / 5;
    final displayDate = DateFormat('MMM d, yyyy').format(selectedDate ?? today);

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
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Meal Planner", style: TextStyle(color: TColor.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)).animate(effects: [FadeEffect(duration: 800.ms)]),
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
                        // Chart
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
                                    tooltipRoundedRadius: 20,
                                    // tooltipBgColor: TColor.cardLight.withOpacity(0.9),
                                    getTooltipItems: (List<LineBarSpot> lineBarsSpot) => lineBarsSpot.map((spot) => LineTooltipItem(
                                      "${spot.barIndex == 0 ? 'Planned' : 'Consumed'}: ${spot.y.toInt()} kcal",
                                      TextStyle(color: spot.barIndex == 0 ? TColor.primary : TColor.accent2, fontSize: 10, fontWeight: FontWeight.bold),
                                    )).toList(),
                                  ),
                                ),
                                lineBarsData: _getWeeklyChartData(),
                                minY: 0,
                                maxY: maxCalories,
                                titlesData: FlTitlesData(
                                  leftTitles: const AxisTitles(),
                                  topTitles: const AxisTitles(),
                                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: 1, getTitlesWidget: (value, meta) {
                                    if (value.toInt() > 0 && value.toInt() <= 7) {
                                      final day = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)).add(Duration(days: value.toInt() - 1));
                                      return Text(DateFormat.E().format(day), style: TextStyle(color: TColor.textSecondary, fontSize: 12));
                                    }
                                    return const Text('');
                                  })),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, interval: interval, getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: TextStyle(color: TColor.textSecondary, fontSize: 12)))),
                                ),
                                gridData: FlGridData(show: true, drawHorizontalLine: true, horizontalInterval: interval, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: TColor.textSecondary.withOpacity(0.15), strokeWidth: 2)),
                                borderData: FlBorderData(show: true, border: Border.all(color: Colors.transparent)),
                              ),
                            ),
                          ).animate(effects: [FadeEffect(duration: 1000.ms)]),
                        ),
                        // Calories to Consume
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Calories to Consume", style: TextStyle(color: TColor.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                              SizedBox(
                                height: 150,
                                child: PageView(
                                  controller: _tdeePageController,
                                  children: [
                                    _buildTdeeCard("Maintain Weight", tdeeMaintain),
                                    _buildTdeeCard("Lose Weight", tdeeOptions['loss_250g'] ?? 0.0, tdeeOptions['loss_500g'] ?? 0.0),
                                    _buildTdeeCard("Gain Weight", tdeeOptions['gain_250g'] ?? 0.0, tdeeOptions['gain_500g'] ?? 0.0),
                                  ],
                                ),
                              ).animate(effects: [FadeEffect(duration: 800.ms)]),
                            ],
                          ),
                        ),
                        // Meal Schedule with Date Picker
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Meal Schedule", style: TextStyle(color: TColor.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Category", style: TextStyle(color: TColor.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                                  Container(
                                    height: 30,
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(gradient: LinearGradient(colors: [TColor.primary, TColor.primaryLight]), borderRadius: BorderRadius.circular(15)),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedMealCategory,
                                        items: mealCategories.map((name) => DropdownMenuItem(value: name, child: Text(name, style: TextStyle(color: TColor.textSecondary, fontSize: 14)))).toList(),
                                        onChanged: (value) => setState(() => selectedMealCategory = value!),
                                        icon: Icon(Icons.expand_more, color: TColor.textSecondary),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Card(
                                color: TColor.cardLight,
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(selectedMealCategory, style: TextStyle(color: TColor.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 10),
                                      if (groupedMeals[selectedMealCategory]?.isEmpty ?? true)
                                        Text("No meals scheduled", style: TextStyle(color: TColor.textSecondary, fontSize: 14))
                                      else
                                        ...?groupedMeals[selectedMealCategory]?.expand((meal) => (meal['diet_components'] as List<dynamic>? ?? []).map((component) {
                                          final comp = component as Map<String, dynamic>;
                                          final documentId = comp['documentId'] as String? ?? comp['id'].toString();
                                          final consumed = comp['consumed'] as bool? ?? false;
                                          final timeStr = _formatTime(meal['meal_time'] as String? ?? 'N/A');
                                          final calories = comp['calories'] as int? ?? 0;
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                                            child: Row(
                                              children: [
                                                SizedBox(
                                                  width: 50,
                                                  height: 50,
                                                  child: Image.asset(
                                                    _getImageForMeal(comp['name'] as String? ?? ''),
                                                    width: 50,
                                                    height: 50,
                                                    errorBuilder: (context, error, stackTrace) => Icon(Icons.fastfood, color: TColor.textSecondary),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(comp['name'] as String? ?? 'Unnamed', style: TextStyle(color: TColor.textPrimary, fontWeight: FontWeight.w600)),
                                                      Row(
                                                        children: [
                                                          Text("$timeStr | $calories kcal", style: TextStyle(color: TColor.textSecondary, fontSize: 12)),
                                                          const SizedBox(width: 10),
                                                          GestureDetector(
                                                            onTap: () => _editMealComponent(documentId, comp),
                                                            child: Icon(Icons.edit, size: 16, color: TColor.accent1),
                                                          ),
                                                          const SizedBox(width: 10),
                                                          GestureDetector(
                                                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FoodInfoDetailsView(dObj: comp, mObj: meal))),
                                                            child: Icon(Icons.info_outline, size: 16, color: TColor.secondary),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                CustomAnimatedToggleSwitch<bool>(
                                                  current: consumed,
                                                  values: const [false, true],
                                                  indicatorSize: const Size.square(20.0),
                                                  animationDuration: const Duration(milliseconds: 200),
                                                  animationCurve: Curves.linear,
                                                  onChanged: (b) async => await _toggleConsumed(documentId, consumed),
                                                  iconBuilder: (context, local, global) => const SizedBox(),
                                                  onTap: null,
                                                  iconsTappable: false,
                                                  wrapperBuilder: (context, global, child) => Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      Positioned(
                                                        left: 5.0,
                                                        right: 5.0,
                                                        height: 20.0,
                                                        child: DecoratedBox(
                                                          decoration: BoxDecoration(
                                                            gradient: consumed ? LinearGradient(colors: [TColor.accent2, TColor.accent2]) : LinearGradient(colors: [Colors.grey, Colors.grey]),
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
                                          );
                                        })),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Badging and Gamification
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
                                          Image.asset(
                                            badge['icon'] ?? 'assets/img/salad.png',
                                            width: 40,
                                            height: 40,
                                            errorBuilder: (context, error, stackTrace) => Icon(Icons.star, color: TColor.primary, size: 40),
                                          ),
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
                // Bottom Navigation (Fixed)
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
            // FAB and Max (Positioned within Stack)
            Positioned(
              bottom: 70,
              right: 20,
              child: Row(
                children: [
                  FloatingActionButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MealTdeeView(maintainTdee: tdeeMaintain))),
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

  Widget _buildTdeeCard(String title, double value1, [double? value2]) {
    return Card(
      color: TColor.cardLight,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: TextStyle(color: TColor.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value2 == null ? "Maintain" : "250g/Week", style: TextStyle(color: TColor.textSecondary, fontSize: 12)),
                Text("${value1.toStringAsFixed(0)} kcal", style: TextStyle(color: TColor.textPrimary, fontSize: 14)),
              ],
            ),
            if (value2 != null) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("500g/Week", style: TextStyle(color: TColor.textSecondary, fontSize: 12)),
                  Text("${value2.toStringAsFixed(0)} kcal", style: TextStyle(color: TColor.textPrimary, fontSize: 14)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(String mealTime) {
    try {
      final time = DateFormat('HH:mm:ss.SSS').parse(mealTime);
      return DateFormat('h a').format(time).toLowerCase();
    } catch (e) {
      debugPrint('Error parsing time: $e');
      return mealTime;
    }
  }

  String _getImageForMeal(String name) {
    switch (name.toLowerCase()) {
      case 'poha':
      case 'honey pancake':
        return 'assets/img/honey_pan.png';
      case 'chicken steak':
        return 'assets/img/chicken.png';
      case 'salad':
      case 'oatmeal':
        return 'assets/img/salad.png';
      case 'orange':
      case 'apple pie':
        return 'assets/img/orange.png';
      default:
        return 'assets/img/salad.png'; // Fallback to an existing asset
    }
  }
}
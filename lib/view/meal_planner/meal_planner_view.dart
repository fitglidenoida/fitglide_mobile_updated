import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fitglide_mobile_application/services/bmr_tdee_service.dart';
import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:fitglide_mobile_application/services/user_service.dart';
import 'package:intl/intl.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/find_eat_cell.dart';
import '../../common_widget/round_button.dart';
import '../../common_widget/today_meal_row.dart';
import 'meal_food_details_view.dart';
import 'meal_schedule_view.dart';
import 'meal_tdee_view.dart';

class MealPlannerView extends StatefulWidget {
  const MealPlannerView({super.key});

  @override
  State<MealPlannerView> createState() => _MealPlannerViewState();
}

class _MealPlannerViewState extends State<MealPlannerView> {
  String selectedMealCategory = 'Breakfast';
  Map<String, List<Map<String, dynamic>>> groupedMeals = {};
  bool isLoadingMeals = true;
  String selectedView = 'Weekly';
  List<int> showingTooltipOnSpots = [];
  DateTime today = DateTime.now(); // Track today's date

  static const List<String> mealCategories = [
    'Breakfast',
    'Morning Snack',
    'Lunch',
    'Afternoon Snack',
    'Evening Snack',
    'Dinner',
  ];

  double tdeeMaintain = 0.0;
  bool isLoadingTdee = true;

  List findEatArr = [
    {"name": "Breakfast", "image": "assets/img/m_3.png", "number": "120+ Foods"},
    {"name": "Lunch", "image": "assets/img/m_4.png", "number": "130+ Foods"},
  ];

  @override
  void initState() {
    super.initState();
    _fetchTdee();
    _fetchMealData();
  }

  Future<void> _fetchTdee() async {
    try {
      final tdeeService = BmrTdeeService();
      final tdeeOptions = await tdeeService.fetchTdeeOptions();
      setState(() {
        tdeeMaintain = tdeeOptions['maintain'] ?? 0.0;
        isLoadingTdee = false;
      });
    } catch (e) {
      print("Error fetching TDEE: $e");
      setState(() {
        tdeeMaintain = 0.0;
        isLoadingTdee = false;
      });
    }
  }

  Future<void> _fetchMealData() async {
    debugPrint('Fetching meal data for MealPlannerView...');
    try {
      final user = await UserService.fetchUserData();
      final username = user.username;
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final response = await ApiService.get(
        'diet-plans?populate=meals.diet_components&filters[users_permissions_user][username][\$eq]=$username',
      );
      
      final plans = response['data'] as List<dynamic>;
      if (plans.isNotEmpty) {
        final dietPlan = plans.first as Map<String, dynamic>;
        final meals = (dietPlan['meals'] as List<dynamic>? ?? []).where((meal) {
          final mealDate = DateTime.tryParse(meal['meal_date'] as String? ?? '') ?? DateTime.now();
          return mealDate.isAfter(todayStart) && mealDate.isBefore(todayEnd);
        }).toList();
        groupedMeals = _groupMealsByCategory(meals);
        debugPrint('Grouped meals for today: $groupedMeals');
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
      // Ensure we update only today's meal component
      final now = DateTime.now();
      final mealResponse = await ApiService.get(
        'diet-components/$documentId?populate=*',
      );
      final mealData = mealResponse['data'] as Map<String, dynamic>?;

      if (mealData != null) {
        final mealDate = DateTime.tryParse(mealData['meal_date'] as String? ?? '') ?? DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayEnd = todayStart.add(const Duration(days: 1));

        if (mealDate.isAfter(todayStart) && mealDate.isBefore(todayEnd)) {
          final response = await ApiService.updateDietComponent(
            documentId,
            {'consumed': !currentStatus, 'meal_date': DateFormat('yyyy-MM-dd').format(now)},
          );
          debugPrint('Update response for today: $response');
          await _fetchMealData(); // Refresh only today's data
        } else {
          debugPrint('Meal not from today, skipping update');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Can only update today\'s meals')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating consumed status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update consumption status: $e')),
      );
    }
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
          (sum, component) {
            final consumed = (component as Map<String, dynamic>)['consumed'] as bool? ?? false;
            return sum + (consumed ? (component['calories'] as int? ?? 0) : 0).toDouble();
          },
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
        color: TColor.primaryColor1,
        barWidth: 4,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [TColor.primaryColor1.withOpacity(0.3), Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
      LineChartBarData(
        spots: consumedSpots,
        isCurved: true,
        color: TColor.secondaryColor1,
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [TColor.secondaryColor1.withOpacity(0.3), Colors.transparent],
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

    return isLoadingTdee || isLoadingMeals
        ? const Center(child: CircularProgressIndicator())
        : Material(
            color: TColor.white,
            child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                            Expanded(
                              child: Text(
                        "Meal Nutritions",
                        style: TextStyle(
                            color: TColor.black,
                            fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      Container(
                          height: 30,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: TColor.primaryG),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedView,
                                  items: ["Daily", "Weekly", "Monthly"]
                                  .map((name) => DropdownMenuItem(
                                        value: name,
                                        child: Text(
                                          name,
                                              style: TextStyle(color: TColor.gray, fontSize: 14),
                                        ),
                                      ))
                                  .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedView = value!;
                                    });
                                  },
                                  icon: Icon(Icons.expand_more, color: TColor.white),
                              hint: Text(
                                "Weekly",
                                    style: TextStyle(color: TColor.white, fontSize: 12),
                              ),
                            ),
                              ),
                            ),
                    ],
                  ),
                        SizedBox(height: media.width * 0.05),
                  Container(
                      padding: const EdgeInsets.only(left: 15),
                      height: media.width * 0.5,
                      width: double.maxFinite,
                      child: LineChart(
                            LineChartData(                            lineTouchData: LineTouchData(
                            enabled: true,
                            handleBuiltInTouches: false,
                              touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                                if (response == null || response.lineBarSpots == null) {
                                  return;
                                }
                                setState(() {
                                  showingTooltipOnSpots =
                                      response.lineBarSpots!.map((spot) => spot.spotIndex).toList();
                                });
                            },
                              mouseCursorResolver: (FlTouchEvent event, LineTouchResponse? response) {
                                return (response == null || response.lineBarSpots == null)
                                    ? SystemMouseCursors.basic
                                    : SystemMouseCursors.click;
                            },
                              getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                              return spotIndexes.map((index) {
                                return TouchedSpotIndicatorData(
                                    const FlLine(color: Colors.transparent),
                                  FlDotData(
                                    show: true,
                                      getDotPainter: (spot, percent, barData, index) =>
                                            FlDotCirclePainter(
                                      radius: 3,
                                      color: Colors.white,
                                      strokeWidth: 3,
                                      strokeColor: TColor.secondaryColor1,
                                    ),
                                  ),
                                );
                              }).toList();
                            },
                            touchTooltipData: LineTouchTooltipData(
                              tooltipRoundedRadius: 20,
                                getTooltipItems: (List<LineBarSpot> lineBarsSpot) {
                                  return lineBarsSpot.map((spot) {
                                    final label = spot.barIndex == 0 ? 'Planned' : 'Consumed';
                                  return LineTooltipItem(
                                      "$label: ${spot.y.toInt()}",
                                    const TextStyle(
                                      color: Colors.white,
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
                            maxY: (tdeeMaintain * 1.5).ceilToDouble(),
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
                                      final day = DateTime.now()
                                          .subtract(Duration(days: DateTime.now().weekday - 1))
                                          .add(Duration(days: value.toInt() - 1));
                                      return Text(
                                        DateFormat.E().format(day),
                                        style: TextStyle(color: TColor.gray, fontSize: 12),
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
                                  interval: 1000,
                                  getTitlesWidget: (value, meta) => Text(
                                    '${value.toInt()}',
                                    style: TextStyle(color: TColor.gray, fontSize: 12),
                                  ),
                                ),
                              ),
                            ),
                          gridData: FlGridData(
                            show: true,
                            drawHorizontalLine: true,
                              horizontalInterval: 500,
                            drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: TColor.gray.withOpacity(0.15),
                                strokeWidth: 2,
                              ),
                            ),
                            borderData: FlBorderData(show: true, border: Border.all(color: Colors.transparent)),
                          ),
                        ),
                      ),
SizedBox(height: media.width * 0.05),
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: TColor.primaryG),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Maintain Weight",
                                  style: TextStyle(
                                    color: TColor.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Calories: ${tdeeMaintain.toStringAsFixed(0)} kcal",
                                      style: TextStyle(color: TColor.white, fontSize: 16),
                                    ),
                                    SizedBox(
                                      width: 100,
                                      height: 35,
                                      child: RoundButton(
                                        title: "Know More",
                                        type: RoundButtonType.bgGradient,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => MealTdeeView(maintainTdee: tdeeMaintain),
                                            ),
                              );
                            },
                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: media.width * 0.05),
                  Container(
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                    decoration: BoxDecoration(
                      color: TColor.primaryColor2.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Daily Meal Schedule",
                          style: TextStyle(
                              color: TColor.black,
                              fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                        ),
                        SizedBox(
                          width: 75,
                          height: 30,
                          child: RoundButton(
                            title: "Check",
                            type: RoundButtonType.bgGradient,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            onPressed: () {
                               Navigator.push(
                                context,
                                MaterialPageRoute(
                                        builder: (context) => const MealScheduleView(),
                                ),
                              );
                            },
                          ),
                              ),
                      ],
                    ),
                  ),
                        SizedBox(height: media.width * 0.05),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                            Expanded(
                              child: Text(
                        "Today Meals",
                        style: TextStyle(
                            color: TColor.black,
                            fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                      Container(
                          height: 30,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: TColor.primaryG),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedMealCategory,
                                  items: mealCategories
                                  .map((name) => DropdownMenuItem(
                                        value: name,
                                        child: Text(
                                          name,
                                              style: TextStyle(color: TColor.gray, fontSize: 14),
                                        ),
                                      ))
                                  .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedMealCategory = value!;
                                    });
                                  },
                                  icon: Icon(Icons.expand_more, color: TColor.white),
                              hint: Text(
                                "Breakfast",
                                    style: TextStyle(color: TColor.white, fontSize: 12),
                              ),
                            ),
                              ),
                            ),
                    ],
                  ),
                        SizedBox(height: media.width * 0.05),
                        _buildTodayMealComponents(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "Find Something to Eat",
                style: TextStyle(
                    color: TColor.black,
                    fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
              ),
            ),
            SizedBox(
              height: media.width * 0.55,
              child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  scrollDirection: Axis.horizontal,
                  itemCount: findEatArr.length,
                  itemBuilder: (context, index) {
                    var fObj = findEatArr[index] as Map? ?? {};
                    return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MealFoodDetailsView(eObj: fObj),
                              ),
                            );
                      },
                          child: FindEatCell(fObj: fObj, index: index),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: media.width * 0.05),
                ],
              ),
                      ),
          );  }

  Widget _buildTodayMealComponents() {
    if (isLoadingMeals) {
      return const Center(child: CircularProgressIndicator());
    }

    final meals = groupedMeals[selectedMealCategory] ?? [];
    if (meals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Text(
          'No meals available for $selectedMealCategory',
          style: TextStyle(color: TColor.gray, fontSize: 14),
        ),
      );
    }

    final components = meals.expand((meal) {
      final dietComponents = meal['diet_components'] as List<dynamic>? ?? [];
      debugPrint('Diet components for $selectedMealCategory meal: $dietComponents');
      return dietComponents.map((component) => {
            'component': component as Map<String, dynamic>,
            'meal_time': meal['meal_time'] as String? ?? 'N/A',
          });
    }).toList();

    debugPrint('Components for $selectedMealCategory: $components');

    return ListView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: components.length,
      itemBuilder: (context, index) {
        final componentData = components[index];
        final component = componentData['component'] as Map<String, dynamic>;
        final documentId = component['documentId'] as String? ?? component['id'].toString();
        final consumed = component['consumed'] as bool? ?? false;
        final mObj = _mapComponentToRowFormat(component, componentData['meal_time'] as String);
        return TodayMealRow(
          mObj: mObj,
          toggleWidget: CustomAnimatedToggleSwitch<bool>(
            current: consumed,
            values: const [false, true],
            indicatorSize: const Size.square(20.0),
            animationDuration: const Duration(milliseconds: 200),
            animationCurve: Curves.linear,
            onChanged: (b) async {
              await _toggleConsumed(documentId, consumed);
            },
            iconBuilder: (context, local, global) => const SizedBox(),
            onTap: null,
            iconsTappable: false,
            wrapperBuilder: (context, global, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 5.0,
                    right: 5.0,
                    height: 20.0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: consumed
                            ? LinearGradient(colors: TColor.secondaryG)
                            : LinearGradient(colors: [Colors.grey, Colors.grey]),
                        borderRadius: const BorderRadius.all(Radius.circular(50.0)),
                      ),
                    ),
                  ),
                  child,
                ],
              );
            },
            foregroundIndicatorBuilder: (context, global) {
              return SizedBox.fromSize(
                size: const Size(10, 10),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: TColor.white,
                    borderRadius: const BorderRadius.all(Radius.circular(50.0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black38,
                        spreadRadius: 0.05,
                        blurRadius: 1.1,
                        offset: Offset(0.0, 0.8),
            ),
          ],
        ),
      ),
    );
            },
          ),
        );
      },
    );
  }

  Map<String, dynamic> _mapComponentToRowFormat(Map<String, dynamic> component, String mealTime) {
    String timeStr = mealTime;
    try {
      final time = DateFormat('HH:mm:ss.SSS').parse(mealTime);
      timeStr = DateFormat('h a').format(time).toLowerCase();
    } catch (e) {
      debugPrint('Error parsing time: $e');
      timeStr = mealTime;
    }

    return {
      'name': component['name'] as String? ?? 'Unnamed Component',
      'time': timeStr,
    };
  }
}

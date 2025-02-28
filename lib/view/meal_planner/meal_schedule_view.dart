// lib/view/meal_schedule_view.dart
import 'package:flutter/material.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/meal_food_schedule_row.dart';
import '../../common_widget/custom_calendar.dart';
import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:fitglide_mobile_application/services/user_service.dart';
import 'package:intl/intl.dart';

class MealScheduleView extends StatefulWidget {
  final Map<String, dynamic>? dietPlan;

  const MealScheduleView({super.key, this.dietPlan});

  @override
  State<MealScheduleView> createState() => _MealScheduleViewState();
}

class _MealScheduleViewState extends State<MealScheduleView> {
  DateTime _selectedDate = DateTime.now();
  late Map<String, dynamic> dietPlan;
  Map<String, List<Map<String, dynamic>>> groupedMeals = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeDietPlan();
  }

  Future<void> _initializeDietPlan() async {
    debugPrint('Initializing diet plan...');
    try {
      if (widget.dietPlan != null && widget.dietPlan!.isNotEmpty) {
        dietPlan = widget.dietPlan!;
        debugPrint('Passed diet plan: $dietPlan');
      } else {
        final user = await UserService.fetchUserData();
        final username = user.username;
        debugPrint('Fetching diet plans for $username');
        final response = await ApiService.get(
          'diet-plans?populate=meals.diet_components&filters[users_permissions_user][username][\$eq]=$username',
        );
        final plans = response['data'] as List<dynamic>;
        if (plans.isNotEmpty) {
          dietPlan = plans.first as Map<String, dynamic>;
          debugPrint('Fetched diet plan: $dietPlan');
        } else {
          throw Exception('No diet plans found for user');
        }
      }

      final meals = dietPlan['meals'] as List<dynamic>? ?? [];
      debugPrint('Meals from diet plan: $meals');

      groupedMeals = _groupMealsByCategory(meals);
      debugPrint('Grouped meals: $groupedMeals');

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing diet plan: $e');
      setState(() {
        isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: TColor.white,
        centerTitle: true,
        elevation: 0,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: TColor.lightGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset(
              "assets/img/black_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          "Meal Schedule",
          style: TextStyle(
            color: TColor.black,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          InkWell(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(8),
              height: 40,
              width: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: TColor.lightGray,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                "assets/img/more_btn.png",
                width: 15,
                height: 15,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: TColor.white,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                Container(
                  color: TColor.white,
                  child: CustomCalendar(
            onDateSelected: (date) {
              setState(() {
                        _selectedDate = date;
              });
            },
                    initialDate: _selectedDate,
            ),
          ),
          Expanded(
              child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildMealSections(media),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildMealSections(Size media) {
    final sections = <Widget>[];

    groupedMeals.forEach((category, meals) {
      final subtotalCalories = meals.fold<int>(
        0,
        (sum, meal) => sum + (meal['calculatedCalories'] as int? ?? 0),
      );
      sections.add(_buildMealSection(category, meals, "$subtotalCalories calories"));
    });

    return sections;
  }

Widget _buildMealSection(String title, List<Map<String, dynamic>> meals, String subtitle) {
  final components = meals.expand((meal) {
    final dietComponents = meal['diet_components'] as List<dynamic>? ?? [];
    debugPrint('Diet components for $title meal: $dietComponents');
    return dietComponents.map((component) => {
      'component': component as Map<String, dynamic>,
      'meal_time': meal['meal_time'] as String? ?? 'N/A',
    });
  }).toList();

  debugPrint('Components for $title: $components');

  // Calculate total calories from components with explicit cast
  final totalCalories = components.fold<int>(
    0,
    (sum, componentData) => sum + ((componentData['component'] as Map<String, dynamic>)['calories'] as int? ?? 0),
  );

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
              title,
                        style: TextStyle(
                            color: TColor.black,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                "${components.length} Items | $totalCalories cal",
                style: TextStyle(
                  color: TColor.gray,
                  fontSize: 14,
                ),
                        ),
                      ),
                    ],
                  ),
                ),
      components.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                'No components available',
                style: TextStyle(color: TColor.gray, fontSize: 14),
              ),
            )
          : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
              itemCount: components.length,
                    itemBuilder: (context, index) {
                final componentData = components[index];
                final mObj = _mapComponentToRowFormat(
                  componentData['component'] as Map<String, dynamic>,
                  componentData['meal_time'] as String,
                );
                debugPrint('Mapped component: $mObj');
                return MealFoodScheduleRow(mObj: mObj, index: index);
              },
            ),
    ],
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
    'calories': component['calories'] as int? ?? 0, // Fetch calories, default to 0 if missing
    'image': _getImageForMeal(component['food_type'] as String? ?? component['name'] as String? ?? ''),
  };
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
        return 'assets/img/default_meal.png';
  }
}
}
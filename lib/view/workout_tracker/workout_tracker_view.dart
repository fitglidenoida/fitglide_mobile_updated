import 'package:fitglide_mobile_application/common/common.dart';
import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:fitglide_mobile_application/view/workout_tracker/exercises_stpe_details.dart';
import 'package:fitglide_mobile_application/view/workout_tracker/workout_schedule_view.dart';
import '../../common/colo_extension.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../common_widget/round_button.dart';
import '../../common_widget/what_train_row.dart';

class WorkoutTrackerView extends StatefulWidget {
  const WorkoutTrackerView({super.key});

  @override
  State<WorkoutTrackerView> createState() => _WorkoutTrackerViewState();
}

class _WorkoutTrackerViewState extends State<WorkoutTrackerView> {
  List<Map<String, dynamic>> upcomingWorkouts = [];
  bool isLoading = true;
  double todayCompletionPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final now = DateTime.now().toLocal();
      final todayStart = DateTime(now.year, now.month, now.day).toLocal();
      final response = await ApiService.get(
          'workout-plans?populate=exercises&filters[scheduled_date][\$gte]=${todayStart.toIso8601String()}&sort[0]=scheduled_date:asc');
      final scheduledData = response['data'] as List<dynamic>? ?? [];

      setState(() {
        upcomingWorkouts = scheduledData.map((workout) {
          final exercises = workout['exercises'] as List<dynamic>? ?? [];
          final stepsList = exercises.isNotEmpty
              ? (exercises.first['steps'] as String?)?.split('\n').where((step) => step.trim().isNotEmpty).toList() ?? []
              : [];
          final totalTime = exercises.fold<int>(0, (sum, e) => sum + (e['duration'] as int? ?? 0));
          final totalCalories = exercises.fold<int>(
              0, (sum, e) => sum + (e['calories_per_minute'] as int? ?? 0) * (e['duration'] as int? ?? 0));
          final completed = workout['completed'] as bool? ?? false;
          final scheduledDateStr = workout['scheduled_date'] as String? ?? '';
          final scheduledDate = stringToDate(scheduledDateStr, formatStr: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",).toLocal();
          return {
            "documentId": workout['id'].toString(),
            "image": "assets/img/what_${(scheduledData.indexOf(workout) % 3) + 1}.png",
            "title": exercises.isNotEmpty ? (exercises.first['name'] as String? ?? 'Unnamed Exercise') : 'Unnamed Workout',
            "exercises": "${exercises.length} Exercises",
            "time": "$totalTime mins",
            "calories": "$totalCalories kcal",
            "set": stepsList.map((step) => {
                  "image": "assets/img/img_${stepsList.indexOf(step) % 2 + 1}.png",
                  "title": step.trim(),
                  "value": totalTime > 0 ? '${totalTime ~/ stepsList.length} min' : 'Unknown',
                }).toList(),
            "difficulty": exercises.isNotEmpty ? (exercises.first['difficulty'] as String? ?? 'N/A') : 'N/A',
            "completed": completed,
            "scheduled_date": dateToString(scheduledDate, formatStr: "dd/MM/yyyy hh:mm aa"),
          };
        }).toList();

        final todayWorkouts = scheduledData.where((w) {
          final scheduledDateStr = w['scheduled_date'] as String? ?? '';
          final scheduledDate = stringToDate(scheduledDateStr, formatStr: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", ).toLocal();
          return scheduledDate.isAfter(todayStart) && scheduledDate.isBefore(todayStart.add(const Duration(days: 1)));
        }).toList();
        int totalToday = todayWorkouts.length;
        int completedToday = todayWorkouts.where((w) => w['completed'] == true).length;
        todayCompletionPercentage = totalToday > 0 ? (completedToday / totalToday) * 100 : 0.0;

        isLoading = false;
        debugPrint('WorkoutTrackerView - Fetched ${upcomingWorkouts.length} workouts');
      });
    } catch (e) {
      debugPrint('Error fetching data in WorkoutTrackerView: $e');
      setState(() {
        isLoading = false;
        todayCompletionPercentage = 0.0;
        upcomingWorkouts = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load workouts: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: TColor.primaryG)),
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              centerTitle: true,
              elevation: 0,
              leadingWidth: 0,
              leading: const SizedBox(),
              expandedHeight: media.width * 0.5,
              flexibleSpace: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                height: media.width * 0.5,
                width: double.maxFinite,
                child: LineChart(
                  LineChartData(
                    lineTouchData: lineTouchData1,
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        color: TColor.white,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true,),
                        belowBarData: BarAreaData(show: false),
                        spots: [
                          const FlSpot(1, 0),
                          const FlSpot(2, 0),
                          const FlSpot(3, 0),
                          FlSpot(4, todayCompletionPercentage.clamp(0, 100)),
                          const FlSpot(5, 0),
                          const FlSpot(6, 0),
                          const FlSpot(7, 0),
                        ],
                      ),
                    ],
                    minY: 0,
                    maxY: 100,
                    titlesData: FlTitlesData(
                      show: true,
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(),
                      bottomTitles: AxisTitles(sideTitles: bottomTitles),
                      rightTitles: AxisTitles(sideTitles: rightTitles),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      horizontalInterval: 25,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: TColor.white.withOpacity(0.15),
                          strokeWidth: 2,
                        );
                      },
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.transparent),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: Material( // Ensure Material widget for proper theming
          color: TColor.white,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 50,
                          height: 4,
                          decoration: BoxDecoration(
                              color: TColor.gray.withOpacity(0.3), borderRadius: BorderRadius.circular(3)),
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
                                "Daily Workout Schedule",
                                style: TextStyle(
                                    color: TColor.black, fontSize: 14, fontWeight: FontWeight.w700),
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
                                        builder: (context) => const WorkoutScheduleView(),
                                      ),
                                    ).then((_) => _fetchData());
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
                            Text(
                              "Upcoming Workouts",
                              style: TextStyle(
                                  color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            if (upcomingWorkouts.isEmpty)
                              Text(
                                "No upcoming workouts",
                                style: TextStyle(color: TColor.gray, fontSize: 12),
                              ),
                          ],
                        ),
                        SizedBox(height: media.width * 0.02),
                        if (upcomingWorkouts.isNotEmpty)
                          ListView.builder(
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: upcomingWorkouts.length,
                            itemBuilder: (context, index) {
                              var wObj = upcomingWorkouts[index];
                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ExercisesStepDetails(
                                        eObj: wObj,
                                        documentId: wObj['documentId'],
                                      ),
                                    ),
                                  );
                                },
                                child: WhatTrainRow(wObj: wObj),
                              );
                            },
                          ),
                        SizedBox(height: media.width * 0.1),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  LineTouchData get lineTouchData1 => LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (LineBarSpot touchedSpot) => TColor.primaryColor2.withOpacity(0.8),
          tooltipRoundedRadius: 10,
          tooltipPadding: const EdgeInsets.all(8),
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.y.toStringAsFixed(1)}%',
                TextStyle(color: TColor.black, fontSize: 12),
              );
            }).toList();
          },
        ),
      );

  SideTitles get rightTitles => SideTitles(
        getTitlesWidget: rightTitleWidgets,
        showTitles: true,
        interval: 25,
        reservedSize: 40,
      );

  Widget rightTitleWidgets(double value, TitleMeta meta) {
    String text;
    switch (value.toInt()) {
      case 0:
        text = '0%';
        break;
      case 25:
        text = '25%';
        break;
      case 50:
        text = '50%';
        break;
      case 75:
        text = '75%';
        break;
      case 100:
        text = '100%';
        break;
      default:
        return Container();
    }
    return Text(text, style: TextStyle(color: TColor.white, fontSize: 12), textAlign: TextAlign.center);
  }

  SideTitles get bottomTitles => SideTitles(
        showTitles: true,
        reservedSize: 32,
        interval: 1,
        getTitlesWidget: bottomTitleWidgets,
      );

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    var style = TextStyle(color: TColor.white, fontSize: 12);
    Widget text;
    switch (value.toInt()) {
      case 1:
        text = Text('Sun', style: style);
        break;
      case 2:
        text = Text('Mon', style: style);
        break;
      case 3:
        text = Text('Tue', style: style);
        break;
      case 4:
        text = Text('Wed', style: style);
        break;
      case 5:
        text = Text('Thu', style: style);
        break;
      case 6:
        text = Text('Fri', style: style);
        break;
      case 7:
        text = Text('Sat', style: style);
        break;
      default:
        text = const Text('');
        break;
    }
    return SideTitleWidget(space: 10, meta: meta, child: text);
  }
}
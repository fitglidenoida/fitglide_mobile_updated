import 'dart:convert';

import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:intl/intl.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/icon_title_next_row.dart';
import '../../common_widget/round_button.dart';
import '../../view/workout_tracker/workout_schedule_view.dart';
import 'package:flutter/material.dart';

class WorkoutDetailView extends StatefulWidget {
  final Map<String, dynamic> dObj;
  const WorkoutDetailView({super.key, required this.dObj});

  @override
  State<WorkoutDetailView> createState() => _WorkoutDetailViewState();
}

class _WorkoutDetailViewState extends State<WorkoutDetailView> {
  List<Map<String, dynamic>> equipmentArr = [];
  List<Map<String, dynamic>> exercisesArr = [];
  bool isLoading = true;
  int totalCaloriesBurned = 0;

  @override
  void initState() {
    super.initState();
    _fetchWorkoutDetails();
  }

  Future<void> _fetchWorkoutDetails() async {
    try {
      final String id = widget.dObj['id'].toString();
      final response = await ApiService.get('workout-plans/$id?populate[exercises][populate]=*');
      final workoutData = response['data'] as Map<String, dynamic>? ?? widget.dObj;

      setState(() {
        _processWorkoutData(workoutData);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching workout details: $e');
      setState(() {
        _processWorkoutData(widget.dObj); // Fallback to passed data
        isLoading = false;
      });
    }
  }

  void _processWorkoutData(Map<String, dynamic> workoutData) {
    final exercises = workoutData['exercises'] as List<dynamic>? ?? [];
    equipmentArr = exercises
        .expand<Map<String, dynamic>>((e) {
          final equipment = e['equipment'];
          if (equipment is List<dynamic>) {
            return equipment.map((equip) => {
                  'image': 'assets/img/${equip['name']?.toLowerCase().replaceAll(' ', '_') ?? 'default'}.png',
                  'title': equip['name'] as String? ?? 'Unknown',
                });
          } else if (equipment is Map<String, dynamic>) {
            return [
              {
                'image': 'assets/img/${equipment['name']?.toLowerCase().replaceAll(' ', '_') ?? 'default'}.png',
                'title': equipment['name'] as String? ?? 'Unknown',
              }
            ];
          } else if (equipment is String) {
            return [
              {
                'image': 'assets/img/${equipment.toLowerCase().replaceAll(' ', '_')}.png',
                'title': equipment,
              }
            ];
          }
          return [];
        })
        .toSet()
        .toList();

    exercisesArr = exercises.map((exercise) {
      final stepsRaw = exercise['steps'];
      List<String> stepsList = [];
      if (stepsRaw is String) {
        stepsList = stepsRaw.split('\n').where((step) => step.trim().isNotEmpty).toList();
      } else if (stepsRaw is List<dynamic>) {
        stepsList = stepsRaw.map((s) => s.toString()).toList();
      }

      // Calculate calories for this exercise
      final duration = exercise['duration'] as int? ?? 0;
      final caloriesPerMinute = exercise['calories_per_minute'] as int? ?? 0;
      totalCaloriesBurned += duration * caloriesPerMinute;

      return {
        'name': exercise['name'] as String? ?? 'Unnamed Exercise',
        'set': stepsList.map((step) => {
              'image': 'assets/img/img_${stepsList.indexOf(step) % 2 + 1}.png',
              'title': step.trim(),
              'value': exercise['duration'] != null ? '${exercise['duration']} min' : 'Unknown',
            }).toList(),
        'difficulty': exercise['difficulty'] as String? ?? 'N/A',
      };
    }).toList();

    debugPrint('Equipment count: ${equipmentArr.length}');
    debugPrint('Exercises count: ${exercisesArr.length}');
    debugPrint('Total calories burned: $totalCaloriesBurned');
    if (exercisesArr.isNotEmpty) {
      debugPrint('First exercise: ${jsonEncode(exercisesArr[0])}');
    }
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    final scheduledDate = DateTime.tryParse(widget.dObj['scheduled_date'] as String? ?? '') ?? DateTime.now();
    final formatter = DateFormat('dd/MM/yyyy hh:mm aa');

    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: TColor.primaryG)),
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: Colors.transparent,
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
                      color: TColor.lightGray, borderRadius: BorderRadius.circular(10)),
                  child: Image.asset(
                    "assets/img/black_btn.png",
                    width: 15,
                    height: 15,
                    fit: BoxFit.contain,
                  ),
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
                        color: TColor.lightGray, borderRadius: BorderRadius.circular(10)),
                    child: Image.asset(
                      "assets/img/more_btn.png",
                      width: 15,
                      height: 15,
                      fit: BoxFit.contain,
                    ),
                  ),
                )
              ],
            ),
            SliverAppBar(
              backgroundColor: Colors.transparent,
              centerTitle: true,
              elevation: 0,
              leadingWidth: 0,
              leading: Container(),
              expandedHeight: media.width * 0.5,
              flexibleSpace: Align(
                alignment: Alignment.center,
                child: Image.asset(
                  "assets/img/detail_top.png",
                  width: media.width * 0.75,
                  height: media.width * 0.8,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ];
        },
        body: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
              color: TColor.white,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25))),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            Container(
                              width: 50,
                              height: 4,
                              decoration: BoxDecoration(
                                  color: TColor.gray.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(3)),
                            ),
                            SizedBox(height: media.width * 0.05),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.dObj["Title"]?.toString() ?? "Untitled",
                                        style: TextStyle(
                                            color: TColor.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700),
                                      ),
                                      Text(
                                        "Exercise count: ${exercisesArr.length} | Number of Exercises: ${exercisesArr.length} | Calories Burned: $totalCaloriesBurned",
                                        style: TextStyle(color: TColor.gray, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: Image.asset(
                                    "assets/img/fav.png",
                                    width: 15,
                                    height: 15,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: media.width * 0.05),
                            IconTitleNextRow(
                              icon: "assets/img/time.png",
                              title: "Schedule Workout",
                              time: formatter.format(scheduledDate),
                              color: TColor.primaryColor2.withOpacity(0.3),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const WorkoutScheduleView(),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: media.width * 0.02),
                            IconTitleNextRow(
                              icon: "assets/img/difficulity.png",
                              title: "Difficulty",
                              time: exercisesArr.isNotEmpty ? exercisesArr[0]['difficulty'] ?? "N/A" : "N/A",
                              color: TColor.secondaryColor2.withOpacity(0.3),
                              onPressed: () {},
                            ),
                            SizedBox(height: media.width * 0.05),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "You'll Need",
                                  style: TextStyle(
                                      color: TColor.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    "${equipmentArr.length} Items",
                                    style: TextStyle(color: TColor.gray, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: media.width * 0.5,
                              child: equipmentArr.isEmpty
                                  ? const Center(child: Text("No equipment needed"))
                                  : ListView.builder(
                                      padding: EdgeInsets.zero,
                                      scrollDirection: Axis.horizontal,
                                      shrinkWrap: true,
                                      itemCount: equipmentArr.length,
                                      itemBuilder: (context, index) {
                                        var yObj = equipmentArr[index];
                                        return Container(
                                          margin: const EdgeInsets.all(8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                height: media.width * 0.35,
                                                width: media.width * 0.35,
                                                decoration: BoxDecoration(
                                                    color: TColor.lightGray,
                                                    borderRadius: BorderRadius.circular(15)),
                                                alignment: Alignment.center,
                                                child: Image.asset(
                                                  yObj["image"].toString(),
                                                  width: media.width * 0.2,
                                                  height: media.width * 0.2,
                                                  fit: BoxFit.contain,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      const Icon(Icons.fitness_center),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Text(
                                                  yObj["title"].toString(),
                                                  style: TextStyle(color: TColor.black, fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            SizedBox(height: media.width * 0.05),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Exercises",
                                  style: TextStyle(
                                      color: TColor.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    "${exercisesArr.length} Exercises",
                                    style: TextStyle(color: TColor.gray, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            exercisesArr.isEmpty
                                ? const Center(child: Text("No exercises available"))
                                : ListView.builder(
                                    padding: EdgeInsets.zero,
                                    physics: const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: exercisesArr.length,
                                    itemBuilder: (context, index) {
                                      var exercise = exercisesArr[index];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              exercise['name'],
                                              style: TextStyle(
                                                  color: TColor.black,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(height: 8),
                                            ...exercise['set'].map<Widget>((step) => Padding(
                                                  padding: const EdgeInsets.only(bottom: 4.0),
                                                  child: Row(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text("• ",
                                                          style: TextStyle(color: TColor.black, fontSize: 14)),
                                                      Expanded(
                                                        child: Text(
                                                          step['title'],
                                                          style: TextStyle(
                                                              color: TColor.black, fontSize: 14),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )).toList(),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                            SizedBox(height: media.width * 0.1),
                          ],
                        ),
                      ),
                      SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            RoundButton(
                              title: "Start Workout",
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
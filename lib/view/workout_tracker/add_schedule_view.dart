import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../common/colo_extension.dart';
import '../../common/common.dart';
import '../../common_widget/icon_title_next_row.dart';
import '../../common_widget/round_button.dart';
import '../../services/api_service.dart';

class AddScheduleView extends StatefulWidget {
  final DateTime date;
  const AddScheduleView({super.key, required this.date});

  @override
  State<AddScheduleView> createState() => _AddScheduleViewState();
}

class _AddScheduleViewState extends State<AddScheduleView> {
  DateTime _selectedDateTime = DateTime.now();
  String? _selectedWorkout;
  String? _selectedDifficulty;
  int? _customRepetitions;
  double? _customWeights;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = widget.date;
  }

  Future<void> _saveSchedule() async {
    try {
      final response = await ApiService.addWorkoutPlan({
        'Title': _selectedWorkout ?? 'New Workout',
        'scheduled_date': _selectedDateTime.toUtc().toIso8601String(),
        'difficulty': _selectedDifficulty ?? 'Beginner',
        'repetitions': _customRepetitions ?? 15,
        'weights': _customWeights ?? 0.0,
        'exercises': [], // Add default or dynamic exercises as needed
        'completed': false,
      });
      debugPrint('Workout schedule created: $response');
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout schedule saved successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error saving workout schedule: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save workout schedule: $e')),
        );
      }
    }
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
          onTap: () {
            Navigator.pop(context);
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            height: 40,
            width: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: TColor.lightGray,
                borderRadius: BorderRadius.circular(10)),
            child: Image.asset(
              "assets/img/closed_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          "Add Schedule",
          style: TextStyle(
              color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700),
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
                  borderRadius: BorderRadius.circular(10)),
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
      backgroundColor: TColor.white,
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset(
                  "assets/img/date.png",
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  dateToString(_selectedDateTime, formatStr: "E, dd MMMM yyyy"),
                  style: TextStyle(color: TColor.gray, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              "Time",
              style: TextStyle(
                  color: TColor.black, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            SizedBox(
              height: media.width * 0.35,
              child: CupertinoDatePicker(
                onDateTimeChanged: (newDateTime) {
                  setState(() {
                    _selectedDateTime = newDateTime;
                  });
                },
                initialDateTime: _selectedDateTime,
                use24hFormat: false,
                minuteInterval: 1,
                mode: CupertinoDatePickerMode.time,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Details Workout",
              style: TextStyle(
                  color: TColor.black, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            IconTitleNextRow(
              icon: "assets/img/choose_workout.png",
              title: "Choose Workout",
              time: _selectedWorkout ?? "Select Workout",
              color: TColor.lightGray,
              onPressed: () async {
                // Mock workout selection (replace with actual data or navigation)
                final selected = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Select Workout'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text('Upperbody Workout'),
                          onTap: () => Navigator.pop(context, 'Upperbody Workout'),
                        ),
                        ListTile(
                          title: const Text('Fullbody Workout'),
                          onTap: () => Navigator.pop(context, 'Fullbody Workout'),
                        ),
                      ],
                    ),
                  ),
                );
                if (selected != null) {
                  setState(() {
                    _selectedWorkout = selected;
                  });
                }
              },
            ),
            const SizedBox(height: 10),
            IconTitleNextRow(
              icon: "assets/img/difficulity.png",
              title: "Difficulty",
              time: _selectedDifficulty ?? "Select Difficulty",
              color: TColor.lightGray,
              onPressed: () async {
                final selected = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Select Difficulty'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text('Beginner'),
                          onTap: () => Navigator.pop(context, 'Beginner'),
                        ),
                        ListTile(
                          title: const Text('Intermediate'),
                          onTap: () => Navigator.pop(context, 'Intermediate'),
                        ),
                        ListTile(
                          title: const Text('Advanced'),
                          onTap: () => Navigator.pop(context, 'Advanced'),
                        ),
                      ],
                    ),
                  ),
                );
                if (selected != null) {
                  setState(() {
                    _selectedDifficulty = selected;
                  });
                }
              },
            ),
            const SizedBox(height: 10),
            IconTitleNextRow(
              icon: "assets/img/repetitions.png",
              title: "Custom Repetitions",
              time: _customRepetitions != null ? "$_customRepetitions times" : "Select Repetitions",
              color: TColor.lightGray,
              onPressed: () async {
                final selected = await showDialog<int>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Select Repetitions'),
                    content: CupertinoPicker(
                      itemExtent: 40,
                      onSelectedItemChanged: (index) {},
                      scrollController: FixedExtentScrollController(initialItem: _customRepetitions ?? 0),
                      children: List.generate(60, (index) => Center(
                        child: Text("${index + 1} times", style: TextStyle(color: TColor.black, fontSize: 16)),
                      )),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, _customRepetitions ?? 1),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
                if (selected != null) {
                  setState(() {
                    _customRepetitions = selected;
                  });
                }
              },
            ),
            const SizedBox(height: 10),
            IconTitleNextRow(
              icon: "assets/img/repetitions.png",
              title: "Custom Weights",
              time: _customWeights != null ? "$_customWeights kg" : "Select Weights",
              color: TColor.lightGray,
              onPressed: () async {
                final selected = await showDialog<double>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Select Weights'),
                    content: CupertinoPicker(
                      itemExtent: 40,
                      onSelectedItemChanged: (index) {},
                      scrollController: FixedExtentScrollController(initialItem: (_customWeights ?? 0).toInt()),
                      children: List.generate(100, (index) => Center(
                        child: Text("${index + 1} kg", style: TextStyle(color: TColor.black, fontSize: 16)),
                      )),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, (_customWeights ?? 1).toDouble()),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
                if (selected != null) {
                  setState(() {
                    _customWeights = selected;
                  });
                }
              },
            ),
            const Spacer(),
            RoundButton(
              title: "Save",
              onPressed: _saveSchedule,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:fitglide_mobile_application/common_widget/round_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../common/colo_extension.dart';

class AddScheduleView extends StatefulWidget {
  final DateTime date;

  const AddScheduleView({super.key, required this.date});

  @override
  State<AddScheduleView> createState() => _AddScheduleViewState();
}

class _AddScheduleViewState extends State<AddScheduleView> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  String? _sportType;
  String? _difficulty;
  int? _duration;
  double? _distancePlanned;
  double? _elevationPlanned;
  DateTime _scheduledDate = DateTime.now();
  List<Map<String, dynamic>> exercises = [];
  String? maxTip;

  @override
  void initState() {
    super.initState();
    _scheduledDate = widget.date;
    _loadMaxTip();
  }

  Future<void> _loadMaxTip() async {
    setState(() => maxTip = "Max says: Start with a ${_sportType ?? 'Gym'} workout for ${_duration ?? 30} minutes!");
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
            Expanded(child: Text(maxTip ?? "Max is thinking...", style: TextStyle(color: TColor.textPrimary))),
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

  void _showAddExerciseDialog({Map<String, dynamic>? updateExercise}) {
    String? exerciseName = updateExercise?['name'];
    int? duration = updateExercise?['duration'];
    int? caloriesPerMinute = updateExercise?['calories_per_minute'];
    int? reps = updateExercise?['reps'];
    int? sets = updateExercise?['sets'];
    String? category = updateExercise?['category'] ?? 'Warmup';

    showDialog(
      context: context,
      builder: (context) {
        final formKey = GlobalKey<FormState>();
        return AlertDialog(
          title: Text(updateExercise == null ? 'Add Exercise' : 'Edit Exercise', style: TextStyle(color: TColor.textPrimary)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: exerciseName,
                    decoration: InputDecoration(labelText: 'Exercise Name', fillColor: TColor.cardLight, filled: true, border: OutlineInputBorder()),
                    onSaved: (value) => exerciseName = value,
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    initialValue: duration?.toString(),
                    decoration: InputDecoration(labelText: 'Duration (min)', fillColor: TColor.cardLight, filled: true, border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => duration = int.tryParse(value ?? '0'),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    initialValue: caloriesPerMinute?.toString(),
                    decoration: InputDecoration(labelText: 'Calories/Min', fillColor: TColor.cardLight, filled: true, border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => caloriesPerMinute = int.tryParse(value ?? '0'),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  if (_sportType == 'Gym') ...[
                    SizedBox(height: 10),
                    TextFormField(
                      initialValue: reps?.toString(),
                      decoration: InputDecoration(labelText: 'Reps', fillColor: TColor.cardLight, filled: true, border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onSaved: (value) => reps = int.tryParse(value ?? '0'),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      initialValue: sets?.toString(),
                      decoration: InputDecoration(labelText: 'Sets', fillColor: TColor.cardLight, filled: true, border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onSaved: (value) => sets = int.tryParse(value ?? '0'),
                    ),
                  ],
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: InputDecoration(labelText: 'Category', fillColor: TColor.cardLight, filled: true, border: OutlineInputBorder()),
                    items: ['Warmup', 'Workout', 'Stretching'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                    onChanged: (value) => category = value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: TColor.textSecondary))),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  setState(() {
                    final newExercise = {
                      'name': exerciseName ?? 'New Exercise',
                      'duration': duration ?? 0,
                      'calories_per_minute': caloriesPerMinute ?? 0,
                      'reps': reps ?? 0,
                      'sets': sets ?? 0,
                      'category': category ?? 'Warmup',
                    };
                    if (updateExercise != null) {
                      exercises[exercises.indexOf(updateExercise)] = newExercise;
                    } else {
                      exercises.add(newExercise);
                    }
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: TColor.primary, foregroundColor: TColor.textPrimaryDark),
              child: Text(updateExercise == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitSchedule() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        final workoutData = {
          'title': 'New Workout ${_scheduledDate.toIso8601String()}',
          'sport_type': _sportType,
          'difficulty': _difficulty,
          'duration': _duration,
          'distance_planned': _distancePlanned,
          'elevation_planned': _elevationPlanned,
          'calories': _duration! * (exercises.fold(0, (sum, e) => sum + (e['calories_per_minute'] as int? ?? 0))),
          'scheduled_date': _scheduledDate.toIso8601String(),
          'exercises': exercises,
        };
        final response = await ApiService.post('workout-plans', workoutData);
        debugPrint('Workout created: $response');
        Navigator.pop(context);
      } catch (e) {
        debugPrint('Error creating workout: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create workout: $e')));
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(context: context, initialDate: _scheduledDate, firstDate: DateTime(2023), lastDate: DateTime(2030));
    if (picked != null) setState(() => _scheduledDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.backgroundLight,
      appBar: AppBar(
        title: Text('Add Workout', style: TextStyle(color: TColor.textPrimary)),
        backgroundColor: TColor.backgroundLight,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios, color: TColor.textPrimary), onPressed: () => Navigator.pop(context)),
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2 && _formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              setState(() => _currentStep++);
              _loadMaxTip();
            } else if (_currentStep == 2) {
              _submitSchedule();
            }
          },
          onStepCancel: () => _currentStep > 0 ? setState(() => _currentStep--) : Navigator.pop(context),
          steps: [
            Step(
              title: Text("Basics", style: TextStyle(color: TColor.textPrimary)),
              content: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _sportType,
                    decoration: InputDecoration(labelText: 'Sport Type', fillColor: TColor.cardLight, filled: true, border: OutlineInputBorder()),
                    items: ['Cycling', 'Running', 'Gym'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                    onChanged: (value) => setState(() => _sportType = value),
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _difficulty,
                    decoration: InputDecoration(labelText: 'Difficulty', fillColor: TColor.cardLight, filled: true, border: OutlineInputBorder()),
                    items: ['Easy', 'Medium', 'Hard'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                    onChanged: (value) => setState(() => _difficulty = value),
                    validator: (value) => value == null ? 'Required' : null,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Duration (min)', fillColor: TColor.cardLight, filled: true, border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => _duration = int.tryParse(value ?? '0'),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  if (_sportType == 'Cycling' || _sportType == 'Running') ...[
                    SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Distance (km)', fillColor: TColor.cardLight, filled: true, border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onSaved: (value) => _distancePlanned = double.tryParse(value ?? '0'),
                    ),
                    SizedBox(height: 10),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Elevation (m)', fillColor: TColor.cardLight, filled: true, border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      onSaved: (value) => _elevationPlanned = double.tryParse(value ?? '0'),
                    ),
                  ],
                ],
              ).animate(effects: [FadeEffect(duration: 800.ms)]),
            ),
            Step(
              title: Text("Exercises", style: TextStyle(color: TColor.textPrimary)),
              content: Column(
                children: [
                  ...exercises.map((e) => ListTile(
                    title: Text("${e['category']} - ${e['name']}", style: TextStyle(color: TColor.textPrimary)),
                    subtitle: Text("Duration: ${e['duration']} min", style: TextStyle(color: TColor.textSecondary)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: Icon(Icons.edit, color: TColor.primary), onPressed: () => _showAddExerciseDialog(updateExercise: e)),
                        IconButton(icon: Icon(Icons.delete, color: TColor.primary), onPressed: () => setState(() => exercises.remove(e))),
                      ],
                    ),
                  )),
                  SizedBox(height: 10),
                  RoundButton(
                    title: "Add Exercise",
                    type: RoundButtonType.bgGradient, // Fixed: Removed gradientColors
                    onPressed: _showAddExerciseDialog,
                  ),
                ],
              ).animate(effects: [FadeEffect(duration: 800.ms)]),
            ),
            Step(
              title: Text("Schedule", style: TextStyle(color: TColor.textPrimary)),
              content: Column(
                children: [
                  InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: InputDecoration(labelText: 'Scheduled Date', fillColor: TColor.cardLight, filled: true, border: OutlineInputBorder()),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('dd/MM/yyyy').format(_scheduledDate), style: TextStyle(color: TColor.textPrimary)),
                          Icon(Icons.calendar_today, color: TColor.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ).animate(effects: [FadeEffect(duration: 800.ms)]),
            ),
          ],
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: _showMaxDialog,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: TColor.cardLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: TColor.primary.withOpacity(0.3))),
          child: Image.asset('assets/img/max_avatar.png', width: 50, height: 50),
        ),
      ).animate(effects: [FadeEffect(duration: 800.ms), ScaleEffect(duration: 800.ms, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0))]),
    );
  }
}
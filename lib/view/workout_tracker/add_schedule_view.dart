import 'package:fitglide_mobile_application/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../../common/colo_extension.dart';

class AddScheduleView extends StatefulWidget {
  final DateTime date;

  const AddScheduleView({super.key, required this.date});

  @override
  State<AddScheduleView> createState() => _AddScheduleViewState();
}

class _AddScheduleViewState extends State<AddScheduleView> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String? _sportType;
  String? _difficulty;
  int? _duration;
  double? _distancePlanned;
  double? _elevationPlanned;
  int? _reps;
  int? _sets;
  DateTime _scheduledDate = DateTime.now();
  List<Map<String, dynamic>> warmUpExercises = [];
  List<Map<String, dynamic>> workoutExercises = [];
  List<Map<String, dynamic>> postWorkoutExercises = [];
  List<Map<String, dynamic>> availableExercises = [];
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _loadExercises();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    try {
      final response = await ApiService.get('exercises?populate=*');
      setState(() {
        availableExercises = List<Map<String, dynamic>>.from(response['data'] ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
      });
    } catch (e) {
      debugPrint('Error loading exercises: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load exercises: $e', style: TextStyle(color: TColor.black))),
      );
    }
  }

  void _addExercise(String section) {
    setState(() {
      final newExercise = {
        'name': availableExercises.isNotEmpty ? availableExercises.first['name'] ?? 'New Exercise' : 'New Exercise',
        'duration': 0,
        'calories_per_minute': 0,
        'reps': 0,
        'sets': 0,
        'sport_type': _sportType,
      };
      switch (section) {
        case 'warmUp':
          warmUpExercises.add(newExercise);
          break;
        case 'workout':
          workoutExercises.add(newExercise);
          break;
        case 'postWorkout':
          postWorkoutExercises.add(newExercise);
          break;
      }
    });
  }

  Future<void> _submitSchedule() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        final workoutData = {
          'title': 'New Structured Workout ${_scheduledDate.toIso8601String()}',
          'sport_type': _sportType,
          'difficulty': _difficulty,
          'duration': _duration,
          'distance_planned': _distancePlanned,
          'elevation_planned': _elevationPlanned,
          'calories': _duration! * ([
            ...warmUpExercises,
            ...workoutExercises,
            ...postWorkoutExercises
          ].fold(0, (sum, e) => sum + (e['calories_per_minute'] as int? ?? 0))),
          'scheduled_date': _scheduledDate.toIso8601String(),
          'warm_up_exercises': warmUpExercises,
          'workout_exercises': workoutExercises,
          'post_workout_exercises': postWorkoutExercises,
        };
        final response = await ApiService.post('workout-plans', workoutData);
        debugPrint('Workout created: $response');
        Navigator.pop(context);
      } catch (e) {
        debugPrint('Error creating workout: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create workout: $e', style: TextStyle(color: TColor.black))),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: TColor.darkRose, // Darker dusty rose for date picker
              onPrimary: TColor.white, // White text on buttons
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: TColor.darkRose),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _scheduledDate) {
      setState(() {
        _scheduledDate = picked;
      });
    }
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise, String section) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: TColor.lightGray, // Light gray
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TypeAheadField<Map<String, dynamic>>(
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Exercise',
                    filled: true,
                    fillColor: TColor.lightGray.withOpacity(0.8), // Slightly transparent light gray
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: Icon(Icons.fitness_center, color: TColor.darkRose), // Darker dusty rose
                  ),
                  style: TextStyle(color: TColor.black),
                );
              },
              suggestionsCallback: (pattern) {
                return availableExercises.where((e) => e['name'].toString().toLowerCase().contains(pattern.toLowerCase())).toList();
              },
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion['name'], style: TextStyle(color: TColor.black)),
                );
              },
              onSelected: (suggestion) {
                setState(() {
                  exercise['name'] = suggestion['name'];
                  exercise['duration'] = suggestion['duration'] ?? 0;
                  exercise['calories_per_minute'] = suggestion['calories_per_minute'] ?? 0;
                  exercise['reps'] = suggestion['reps'] ?? 0;
                  exercise['sets'] = suggestion['sets'] ?? 0;
                  exercise['sport_type'] = suggestion['sport_type'] ?? _sportType;
                });
              },
            ),
            SizedBox(height: 10),
            TextFormField(
              initialValue: exercise['duration'].toString(),
              decoration: InputDecoration(
                labelText: 'Duration (min)',
                filled: true,
                fillColor: TColor.lightGray.withOpacity(0.8), // Slightly transparent
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: Icon(Icons.timer, color: TColor.darkRose), // Darker dusty rose
              ),
              keyboardType: TextInputType.number,
              onSaved: (value) => exercise['duration'] = int.tryParse(value ?? '0') ?? exercise['duration'],
              validator: (value) => value == null || value.isEmpty ? 'Enter duration' : null,
            ),
            SizedBox(height: 10),
            TextFormField(
              initialValue: exercise['calories_per_minute'].toString(),
              decoration: InputDecoration(
                labelText: 'Calories/min',
                filled: true,
                fillColor: TColor.lightGray.withOpacity(0.8), // Slightly transparent
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: Icon(Icons.local_dining, color: TColor.darkRose), // Darker dusty rose
              ),
              keyboardType: TextInputType.number,
              onSaved: (value) => exercise['calories_per_minute'] = int.tryParse(value ?? '0') ?? exercise['calories_per_minute'],
              validator: (value) => value == null || value.isEmpty ? 'Enter calories/min' : null,
            ),
            if (_sportType == 'Gym')
              Column(
                children: [
                  SizedBox(height: 10),
                  TextFormField(
                    initialValue: exercise['reps'].toString(),
                    decoration: InputDecoration(
                      labelText: 'Reps',
                      filled: true,
                      fillColor: TColor.lightGray.withOpacity(0.8), // Slightly transparent
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: Icon(Icons.repeat, color: TColor.darkRose), // Darker dusty rose
                    ),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => exercise['reps'] = int.tryParse(value ?? '0') ?? exercise['reps'],
                    validator: (value) => value == null || value.isEmpty ? 'Enter reps' : null,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    initialValue: exercise['sets'].toString(),
                    decoration: InputDecoration(
                      labelText: 'Sets',
                      filled: true,
                      fillColor: TColor.lightGray.withOpacity(0.8), // Slightly transparent
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: Icon(Icons.layers, color: TColor.darkRose), // Darker dusty rose
                    ),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => exercise['sets'] = int.tryParse(value ?? '0') ?? exercise['sets'],
                    validator: (value) => value == null || value.isEmpty ? 'Enter sets' : null,
                  ),
                ],
              ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.delete, color: TColor.darkRose), // Darker dusty rose
                  onPressed: () => setState(() {
                    switch (section) {
                      case 'warmUp':
                        warmUpExercises.remove(exercise);
                        break;
                      case 'workout':
                        workoutExercises.remove(exercise);
                        break;
                      case 'postWorkout':
                        postWorkoutExercises.remove(exercise);
                        break;
                    }
                  }),
                ),
              ],
            ),
          ],
        ),
      ).animate(
        effects: [
          FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
          ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
          ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
        ],
    ));
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> exercises, String section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(color: TColor.black, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(Icons.add, color: TColor.darkRose), // Darker dusty rose
              onPressed: () => _addExercise(section),
            ),
          ],
        ).animate(
          effects: [
            FadeEffect(duration: 900.ms, curve: Curves.easeInOut),
            ScaleEffect(duration: 900.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
            ShakeEffect(duration: 450.ms, curve: Curves.easeOut),
          ],
        ),
        SizedBox(height: 15),
        ...exercises.map((exercise) => _buildExerciseCard(exercise, section)).toList(),
        SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColor.white, // Clean white background
      appBar: AppBar(
        title: const Text('Create Workout Plan', style: TextStyle(color: TColor.black, fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: TColor.white, // White
        elevation: 0, // No shadow for modern look
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: TColor.black), // Black
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: TColor.lightGray, // Light gray with subtle gradient
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: TColor.darkRose.withOpacity(0.2)), // Subtle darker dusty rose border
                  gradient: LinearGradient(
                    colors: [TColor.lightGray, TColor.lightIndigo.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workout Basics',
                      style: TextStyle(color: TColor.black, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _sportType,
                      decoration: InputDecoration(
                        labelText: 'Sport Type',
                        filled: true,
                        fillColor: TColor.lightGray.withOpacity(0.9), // Slightly transparent
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: Icon(Icons.directions_run, color: TColor.darkRose), // Darker dusty rose
                      ),
                      items: ['Cycling', 'Running', 'Gym'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: TextStyle(color: TColor.black, fontSize: 16)),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _sportType = value),
                      validator: (value) => value == null ? 'Select a sport type' : null,
                    ),
                    SizedBox(height: 15),
                    DropdownButtonFormField<String>(
                      value: _difficulty,
                      decoration: InputDecoration(
                        labelText: 'Difficulty',
                        filled: true,
                        fillColor: TColor.lightGray.withOpacity(0.9), // Slightly transparent
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: Icon(Icons.fitness_center, color: TColor.darkRose), // Darker dusty rose
                      ),
                      items: ['Easy', 'Medium', 'Hard'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: TextStyle(color: TColor.black, fontSize: 16)),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _difficulty = value),
                      validator: (value) => value == null ? 'Select difficulty' : null,
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Duration (min)',
                        filled: true,
                        fillColor: TColor.lightGray.withOpacity(0.9), // Slightly transparent
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: Icon(Icons.timer, color: TColor.darkRose), // Darker dusty rose
                      ),
                      keyboardType: TextInputType.number,
                      onSaved: (value) => _duration = int.tryParse(value ?? ''),
                      validator: (value) => value == null || value.isEmpty ? 'Enter duration' : null,
                    ),
                    if (_sportType == 'Cycling' || _sportType == 'Running')
                      Column(
                        children: [
                          SizedBox(height: 15),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Distance (km)',
                              filled: true,
                              fillColor: TColor.lightGray.withOpacity(0.9), // Slightly transparent
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: Icon(Icons.map, color: TColor.darkRose), // Darker dusty rose
                            ),
                            keyboardType: TextInputType.number,
                            onSaved: (value) => _distancePlanned = double.tryParse(value ?? ''),
                            validator: (value) => value == null || value.isEmpty ? 'Enter distance' : null,
                          ),
                          SizedBox(height: 15),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Elevation (m)',
                              filled: true,
                              fillColor: TColor.lightGray.withOpacity(0.9), // Slightly transparent
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: Icon(Icons.landscape, color: TColor.darkRose), // Darker dusty rose
                            ),
                            keyboardType: TextInputType.number,
                            onSaved: (value) => _elevationPlanned = double.tryParse(value ?? ''),
                            validator: (value) => value == null || value.isEmpty ? 'Enter elevation' : null,
                          ),
                        ],
                      ),
                    if (_sportType == 'Gym')
                      Column(
                        children: [
                          SizedBox(height: 15),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Reps',
                              filled: true,
                              fillColor: TColor.lightGray.withOpacity(0.9), // Slightly transparent
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: Icon(Icons.repeat, color: TColor.darkRose), // Darker dusty rose
                            ),
                            keyboardType: TextInputType.number,
                            onSaved: (value) => _reps = int.tryParse(value ?? ''),
                            validator: (value) => value == null || value.isEmpty ? 'Enter reps' : null,
                          ),
                          SizedBox(height: 15),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Sets',
                              filled: true,
                              fillColor: TColor.lightGray.withOpacity(0.9), // Slightly transparent
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: Icon(Icons.layers, color: TColor.darkRose), // Darker dusty rose
                            ),
                            keyboardType: TextInputType.number,
                            onSaved: (value) => _sets = int.tryParse(value ?? ''),
                            validator: (value) => value == null || value.isEmpty ? 'Enter sets' : null,
                          ),
                        ],
                      ),
                  ],
                ),
              ).animate(
                effects: [
                  FadeEffect(duration: 1200.ms, curve: Curves.easeInOut),
                  ScaleEffect(duration: 1200.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                  ShakeEffect(duration: 600.ms, curve: Curves.easeOut),
                ],
              ),
              SizedBox(height: 20),
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  decoration: BoxDecoration(
                    color: TColor.lightGray, // Light gray
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: TColor.darkRose.withOpacity(0.2)), // Subtle border
                    gradient: LinearGradient(
                      colors: [TColor.lightGray, TColor.lightIndigo.withOpacity(0.1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(_scheduledDate),
                        style: TextStyle(color: TColor.black, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      Icon(Icons.calendar_today, color: TColor.darkRose), // Darker dusty rose
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
              SizedBox(height: 30),
              _buildSection('Warm-Up', warmUpExercises, 'warmUp'),
              _buildSection('Workout', workoutExercises, 'workout'),
              _buildSection('Post-Workout', postWorkoutExercises, 'postWorkout'),
              SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: TColor.lightGray, // Light gray
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: TColor.darkRose.withOpacity(0.2)), // Subtle border
                  gradient: LinearGradient(
                    colors: [TColor.lightGray, TColor.lightIndigo.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workout Preview',
                      style: TextStyle(color: TColor.black, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Total Duration: ${_duration ?? 0} min',
                      style: TextStyle(color: TColor.black, fontSize: 16),
                    ),
                    Text(
                      'Estimated Calories: ${_duration != null ? (_duration! * [
                        ...warmUpExercises,
                        ...workoutExercises,
                        ...postWorkoutExercises
                      ].fold(0, (sum, e) => sum + (e['calories_per_minute'] as int? ?? 0))) : 0} kcal',
                      style: TextStyle(color: TColor.black, fontSize: 16),
                    ),
                  ],
                ),
              ).animate(
                effects: [
                  FadeEffect(duration: 1200.ms, curve: Curves.easeInOut),
                  ScaleEffect(duration: 1200.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                  ShakeEffect(duration: 600.ms, curve: Curves.easeOut),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitSchedule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColor.darkRose, // Darker dusty rose
                  foregroundColor: TColor.white, // White
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4, // Subtle shadow for modern elevation
                ),
                child: Text('Save Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ).animate(
                effects: [
                  FadeEffect(duration: 1200.ms, curve: Curves.easeInOut),
                  ScaleEffect(duration: 1200.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                  ShakeEffect(duration: 600.ms, curve: Curves.easeOut),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'AI Insights',
                style: TextStyle(color: TColor.black, fontSize: 22, fontWeight: FontWeight.bold),
              ).animate(
                effects: [
                  FadeEffect(duration: 1200.ms, curve: Curves.easeInOut),
                  ScaleEffect(duration: 1200.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                  ShakeEffect(duration: 600.ms, curve: Curves.easeOut),
                ],
              ),
              SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: TColor.lightGray, // Light gray
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TColor.darkRose.withOpacity(0.2)), // Subtle border
                  gradient: LinearGradient(
                    colors: [TColor.lightGray, TColor.lightIndigo.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Text(
                  'Optimize your plan with a 10-min warm-up jog, 30-min intense cycling, and 5-min stretching post-workout for peak performance.',
                  style: TextStyle(color: TColor.black, fontSize: 16),
                ),
              ).animate(
                effects: [
                  FadeEffect(duration: 1200.ms, curve: Curves.easeInOut),
                  ScaleEffect(duration: 1200.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                  ShakeEffect(duration: 600.ms, curve: Curves.easeOut),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
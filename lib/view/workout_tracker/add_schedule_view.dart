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
  final _formKey = GlobalKey<FormState>();
  String? _sportType;
  String? _difficulty;
  int? _duration;
  double? _distancePlanned;
  double? _elevationPlanned;
  int? _reps;
  int? _sets;
  bool _isPremium = false; // Assume user status check here
  Map<String, dynamic>? _selectedBike; // Updated to Map<String, dynamic>
  DateTime _scheduledDate = DateTime.now();
  List<Map<String, dynamic>> exercises = []; // Explicitly typed as Map<String, dynamic>

  @override
  void initState() {
    super.initState();
    _loadRentalBikes();
  }

  Future<void> _loadRentalBikes() async {
    try {
      final response = await ApiService.get('rental-bikes');
      debugPrint('Rental Bikes Response: $response'); // Debug log to inspect data
      final dynamic data = response['data'];
      if (data is List) {
        setState(() {
          // Safely cast each bike to Map<String, dynamic>
          final bikes = data.map((item) {
            if (item is Map) {
              return Map<String, dynamic>.fromEntries(
                item.entries.map((entry) {
                  final key = entry.key.toString(); // Convert key to string
                  return MapEntry<String, dynamic>(key, entry.value);
                }),
              );
            }
            debugPrint('Unexpected bike item type: $item');
            return <String, dynamic>{}; // Default empty map for non-Map items
          }).whereType<Map<String, dynamic>>().toList();
          _selectedBike = bikes.isNotEmpty ? bikes.first : null;
        });
      } else {
        debugPrint('Unexpected data type for "data" in rental-bikes: $data');
        setState(() {
          _selectedBike = null;
        });
      }
    } catch (e) {
      debugPrint('Error loading rental bikes: $e');
    }
  }

  void _showAddExerciseDialog({Map<String, dynamic>? updateExercise}) {
    String? exerciseName = updateExercise?['name'] ?? '';
    int? duration = updateExercise?['duration'] ?? 0;
    int? caloriesPerMinute = updateExercise?['calories_per_minute'] ?? 0;
    int? reps = updateExercise?['reps'] ?? 0;
    int? sets = updateExercise?['sets'] ?? 0;
    String? category = updateExercise?['category'] ?? 'Warmup';

    showDialog(
      context: context,
      builder: (context) {
        final formKey = GlobalKey<FormState>(); // Create a new form key for the dialog
        return AlertDialog(
          title: Text(updateExercise == null ? 'Add Exercise' : 'Edit Exercise', style: TextStyle(color: TColor.black)),
          content: Form(
            key: formKey, // Use the new form key
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: exerciseName,
                  decoration: InputDecoration(
                    labelText: 'Exercise Name',
                    filled: true,
                    fillColor: TColor.lightGray, // Light gray
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onSaved: (value) => exerciseName = value,
                  validator: (value) => value == null || value.isEmpty ? 'Please enter exercise name' : null,
                ),
                SizedBox(height: 10),
                TextFormField(
                  initialValue: duration.toString(),
                  decoration: InputDecoration(
                    labelText: 'Duration (minutes)',
                    filled: true,
                    fillColor: TColor.lightGray, // Light gray
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => duration = int.tryParse(value ?? '0'),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter duration' : null,
                ),
                SizedBox(height: 10),
                TextFormField(
                  initialValue: caloriesPerMinute.toString(),
                  decoration: InputDecoration(
                    labelText: 'Calories/Min',
                    filled: true,
                    fillColor: TColor.lightGray, // Light gray
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => caloriesPerMinute = int.tryParse(value ?? '0'),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter calories/min' : null,
                ),
                SizedBox(height: 10),
                if (_sportType == 'Gym')
                  Column(
                    children: [
                      TextFormField(
                        initialValue: reps.toString(),
                        decoration: InputDecoration(
                          labelText: 'Reps',
                          filled: true,
                          fillColor: TColor.lightGray, // Light gray
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                        onSaved: (value) => reps = int.tryParse(value ?? '0') ?? 0, // Handle null case
                        validator: (value) => value == null || value.isEmpty ? 'Please enter reps' : null,
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        initialValue: sets.toString(),
                        decoration: InputDecoration(
                          labelText: 'Sets',
                          filled: true,
                          fillColor: TColor.lightGray, // Light gray
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                        onSaved: (value) => sets = int.tryParse(value ?? '0') ?? 0, // Handle null case
                        validator: (value) => value == null || value.isEmpty ? 'Please enter sets' : null,
                      ),
                    ],
                  ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    filled: true,
                    fillColor: TColor.lightGray, // Light gray
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ['Warmup', 'Workout', 'Stretching'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: TextStyle(color: TColor.black)),
                    );
                  }).toList(),
                  onChanged: (value) => category = value,
                  validator: (value) => value == null ? 'Please select a category' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: TColor.gray)),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();
                  setState(() {
                    if (updateExercise != null) {
                      final index = exercises.indexOf(updateExercise);
                      exercises[index] = {
                        'name': exerciseName ?? 'New Exercise',
                        'duration': duration ?? 0,
                        'calories_per_minute': caloriesPerMinute ?? 0,
                        'reps': reps ?? 0,
                        'sets': sets ?? 0,
                        'category': category ?? 'Warmup',
                      };
                    } else {
                      exercises.add({
                        'name': exerciseName ?? 'New Exercise',
                        'duration': duration ?? 0,
                        'calories_per_minute': caloriesPerMinute ?? 0,
                        'reps': reps ?? 0,
                        'sets': sets ?? 0,
                        'category': category ?? 'Warmup',
                      });
                    }
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TColor.darkRose, // Darker dusty rose
                foregroundColor: TColor.white, // White
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(updateExercise == null ? 'Submit' : 'Update'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create workout: $e')),
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
    );
    if (picked != null && picked != _scheduledDate) {
      setState(() {
        _scheduledDate = picked;
      });
    }
  }

  void _removeExercise(int index) {
    setState(() {
      exercises.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: TColor.white, // White background
      appBar: AppBar(
        title: const Text('Add Schedule'),
        backgroundColor: TColor.white, // White
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
              Text(
                'Workout Details',
                style: TextStyle(color: TColor.black, fontSize: 22, fontWeight: FontWeight.bold),
              ).animate(
                effects: [
                  FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
                  ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                  ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
                ],
              ),
              SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                color: TColor.lightGray, // Light gray
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _sportType,
                        decoration: InputDecoration(
                          labelText: 'Sport Type',
                          border: InputBorder.none,
                        ),
                        items: ['Cycling', 'Running', 'Gym'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: TextStyle(color: TColor.black)),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _sportType = value),
                        validator: (value) => value == null ? 'Please select a sport type' : null,
                      ),
                      SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: _difficulty,
                        decoration: InputDecoration(
                          labelText: 'Difficulty',
                          border: InputBorder.none,
                        ),
                        items: ['Easy', 'Medium', 'Hard'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: TextStyle(color: TColor.black)),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _difficulty = value),
                        validator: (value) => value == null ? 'Please select a difficulty' : null,
                      ),
                      SizedBox(height: 15),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Duration (minutes)',
                          border: InputBorder.none,
                        ),
                        keyboardType: TextInputType.number,
                        onSaved: (value) => _duration = int.tryParse(value ?? '') ?? 0, // Handle null case
                        validator: (value) => value == null || value.isEmpty ? 'Please enter duration' : null,
                      ),
                      if (_sportType == 'Cycling' || _sportType == 'Running')
                        Column(
                          children: [
                            SizedBox(height: 15),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Distance Planned (km)',
                                border: InputBorder.none,
                              ),
                              keyboardType: TextInputType.number,
                              onSaved: (value) => _distancePlanned = double.tryParse(value ?? '') ?? 0.0, // Handle null case
                              validator: (value) => value == null || value.isEmpty ? 'Please enter distance' : null,
                            ),
                            SizedBox(height: 15),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Elevation Planned (m)',
                                border: InputBorder.none,
                              ),
                              keyboardType: TextInputType.number,
                              onSaved: (value) => _elevationPlanned = double.tryParse(value ?? '') ?? 0.0, // Handle null case
                              validator: (value) => value == null || value.isEmpty ? 'Please enter elevation' : null,
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
                                border: InputBorder.none,
                              ),
                              keyboardType: TextInputType.number,
                              onSaved: (value) => _reps = int.tryParse(value ?? '') ?? 0, // Handle null case
                              validator: (value) => value == null || value.isEmpty ? 'Please enter reps' : null,
                            ),
                            SizedBox(height: 15),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Sets',
                                border: InputBorder.none,
                              ),
                              keyboardType: TextInputType.number,
                              onSaved: (value) => _sets = int.tryParse(value ?? '') ?? 0, // Handle null case
                              validator: (value) => value == null || value.isEmpty ? 'Please enter sets' : null,
                            ),
                          ],
                        ),
                      SizedBox(height: 15),
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Scheduled Date',
                            border: InputBorder.none,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd/MM/yyyy').format(_scheduledDate),
                                style: TextStyle(color: TColor.black),
                              ),
                              Icon(Icons.calendar_today, color: TColor.darkRose), // Darker dusty rose
                            ],
                          ),
                        ),
                      ),
                      if (_sportType == 'Cycling' || _sportType == 'Running')
                        if (_isPremium)
                          Column(
                            children: [
                              SizedBox(height: 15),
                              DropdownButtonFormField<Map<String, dynamic>>(
                                value: _selectedBike,
                                decoration: InputDecoration(
                                  labelText: 'Rental Bike',
                                  border: InputBorder.none,
                                ),
                                items: (_selectedBike != null ? [_selectedBike] : []).map((bike) {
                                  return DropdownMenuItem<Map<String, dynamic>>(
                                    value: bike,
                                    child: Text(bike['name'] ?? 'N/A', style: TextStyle(color: TColor.black)),
                                  );
                                }).toList(),
                                onChanged: (value) => setState(() => _selectedBike = value),
                                validator: (value) => value == null ? 'Please select a bike' : null,
                              ),
                            ],
                          ),
                    ],
                  ),
                ),
              ).animate(
                effects: [
                  FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
                  ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                  ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'Exercises',
                style: TextStyle(color: TColor.black, fontSize: 22, fontWeight: FontWeight.bold),
              ).animate(
                effects: [
                  FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
                  ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                  ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
                ],
              ),
              SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: TColor.lightGray, // Light gray
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: TColor.darkRose.withOpacity(0.3)), // Darker dusty rose
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ...exercises.map((exercise) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      decoration: BoxDecoration(
                        color: TColor.white, // White for contrast within the box
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: TColor.darkRose.withOpacity(0.2)), // Subtle darker dusty rose
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${exercise['category']} - ${exercise['name']}',
                                  style: TextStyle(color: TColor.black, fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  'Duration: ${exercise['duration']} min | Calories/Min: ${exercise['calories_per_minute']}',
                                  style: TextStyle(color: TColor.gray, fontSize: 14),
                                ),
                                if (_sportType == 'Gym')
                                  Text(
                                    'Reps: ${exercise['reps']}, Sets: ${exercise['sets']}',
                                    style: TextStyle(color: TColor.gray, fontSize: 14),
                                  ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: TColor.darkRose), // Darker dusty rose
                                onPressed: () => _showAddExerciseDialog(updateExercise: exercise),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: TColor.darkRose), // Darker dusty rose
                                onPressed: () => _removeExercise(exercises.indexOf(exercise)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ).animate(
                effects: [
                  FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
                  ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                  ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: RoundButton(
                      title: 'Add Exercise',
                      type: RoundButtonType.bgGradient, // Using primary gradient (lightGray to darkRose)
                      onPressed: _showAddExerciseDialog,
                      fontSize: 16,
                      elevation: 1,
                      fontWeight: FontWeight.w700,
                    ).animate(
                      effects: [
                        FadeEffect(duration: 700.ms, curve: Curves.easeInOut),
                        ScaleEffect(duration: 700.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                        ShakeEffect(duration: 300.ms, curve: Curves.easeOut),
                      ],
                    ),
                  ),
                  SizedBox(width: 10), // Spacing between buttons
                  Expanded(
                    child: RoundButton(
                      title: 'Save Schedule',
                      type: RoundButtonType.bgGradient, // Using primary gradient (lightGray to darkRose)
                      onPressed: _submitSchedule,
                      fontSize: 16,
                      elevation: 1,
                      fontWeight: FontWeight.w700,
                    ).animate(
                      effects: [
                        FadeEffect(duration: 800.ms, curve: Curves.easeInOut),
                        ScaleEffect(duration: 800.ms, curve: Curves.easeInOut, begin: Offset(0.9, 0.9), end: Offset(1.0, 1.0)),
                        ShakeEffect(duration: 400.ms, curve: Curves.easeOut),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
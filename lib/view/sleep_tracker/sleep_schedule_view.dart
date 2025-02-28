import 'package:fitglide_mobile_application/common_widget/custom_calendar.dart';
import 'package:fitglide_mobile_application/services/sleep_calculator.dart';
import 'package:fitglide_mobile_application/services/user_service.dart';
import 'package:fitglide_mobile_application/view/sleep_tracker/sleep_add_alarm_view.dart';
import 'package:flutter/material.dart';
import 'package:simple_animation_progress_bar/simple_animation_progress_bar.dart';
import '../../common/colo_extension.dart';
import '../../common_widget/round_button.dart';
import '../../common_widget/today_sleep_schedule_row.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SleepScheduleView extends ConsumerStatefulWidget {
  const SleepScheduleView({super.key});

  @override
  ConsumerState<SleepScheduleView> createState() => _SleepScheduleViewState();
}

class _SleepScheduleViewState extends ConsumerState<SleepScheduleView> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _sleepSchedule = [];
  static const platform = MethodChannel('fitglide/alarm');
    double _idealSleepHours = 8.5; // Default value, will be updated


  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _fetchSleepSchedule();
    
  }

  Future<void> _fetchSleepSchedule() async {
    List<Map<String, dynamic>> alarms = await getAlarmsFromDevice();
    setState(() {
      _sleepSchedule = alarms;
      // Assuming you still want to add bedtime here but now using sleepProvider
      _addBedtimeToSleepSchedule();
    });
  }


  Future<List<Map<String, dynamic>>> getAlarmsFromDevice() async {
    try {
      final List<dynamic> alarms = await platform.invokeMethod('getAlarms');
      List<Map<String, dynamic>> filteredAlarms = [];

      DateTime now = DateTime.now();
      for (var alarm in alarms) {
        try {
          var alarmTime = DateTime.parse(alarm['time']);
          var localAlarmTime = alarmTime.toLocal();
          
          if (localAlarmTime.isAfter(now)) {
            String formattedDisplayTime = DateFormat("hh:mm a").format(localAlarmTime);
            Duration durationUntilAlarm = localAlarmTime.difference(now);
            String durationText = _formatDuration(durationUntilAlarm);

            filteredAlarms.add({
              "name": "Alarm",
              "image": "assets/img/alarm.png",
              "time": formattedDisplayTime,
              "duration": durationText,
            });
          }
        } catch (e) {
          print("Error parsing alarm time: ${alarm['time']} - $e");
        }
      }
      filteredAlarms.sort((a, b) => DateFormat("hh:mm a").parse(a['time']).compareTo(DateFormat("hh:mm a").parse(b['time'])));
      return filteredAlarms;
    } catch (e) {
      print("Error fetching alarms: $e");
      return [];
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    return "$hours h $minutes min";
  }

  void _addBedtimeToSleepSchedule() {
    UserService.fetchUserData().then((user) {
      int userAge = user.age;
      double workoutHours = 1.0; // Example value, should be dynamically fetched
      double idealSleepDuration = SleepCalculator.getRecommendedSleepDuration(userAge, workoutHours);
      
      DateTime now = DateTime.now();
      
      if (_sleepSchedule.isNotEmpty) {
        DateTime? wakeUpTime;
        try {
          wakeUpTime = DateFormat('hh:mm a').parse(_sleepSchedule.first['time']);
        } catch (e) {
          print("Error parsing time: $e with string: ${_sleepSchedule.first['time']}");
          return;
        }

        DateTime bedtime = _calculateBedtime(wakeUpTime, idealSleepDuration, now);
        Duration durationUntilBed = bedtime.difference(now);
        String durationText = _formatDuration(durationUntilBed);

        setState(() {
          _idealSleepHours = idealSleepDuration; // Update ideal sleep hours
          _sleepSchedule.insert(0, {
            "name": "Bedtime",
            "image": "assets/img/bed.png",
            "time": DateFormat("hh:mm a").format(bedtime),
            "duration": durationText
          });
        });
      }
        });
  }

  DateTime _calculateBedtime(DateTime wakeUpTime, double sleepHours, DateTime now) {
    DateTime baseBedtime = wakeUpTime.subtract(Duration(
      hours: sleepHours.toInt(),
      minutes: ((sleepHours % 1) * 60).toInt()
    ));

    if (baseBedtime.isBefore(now)) {
      return DateTime(now.year, now.month, now.day + 1, baseBedtime.hour, baseBedtime.minute);
    }
    return baseBedtime;
  }

  DateTime _adjustScheduleTimeToSelectedDate(String time, DateTime selectedDate) {
    DateTime parsedTime = DateFormat("hh:mm a").parse(time);
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      parsedTime.hour,
      parsedTime.minute,
    );
  }

  String _calculateDurationText(DateTime scheduleTime, DateTime now) {
    Duration duration = scheduleTime.difference(now);
    return _formatDuration(duration);
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
              "assets/img/black_btn.png",
              width: 15,
              height: 15,
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: Text(
          "Sleep Schedule",
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Container(
                    width: double.maxFinite,
                    padding: const EdgeInsets.all(20),
                    height: media.width * 0.4,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          TColor.primaryColor2.withOpacity(0.4),
                          TColor.primaryColor1.withOpacity(0.4)
                        ]),
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                        const SizedBox(height: 15),
                              Text(
                                "Ideal Hours for Sleep",
                          style: TextStyle(color: TColor.black, fontSize: 14),
                              ),
                              Text(
                          "${_idealSleepHours.toStringAsFixed(1)} hours",
                                style: TextStyle(
                            color: TColor.secondaryColor1,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: 110,
                                height: 35,
                                child: RoundButton(
                                    title: "Learn More",
                                    fontSize: 12,
                            onPressed: () {},
                          ),
                              )
                      ],
                    ),
                        Image.asset(
                          "assets/img/sleep_schedule.png",
                          width: media.width * 0.35,
                        )
                      ],
                    ),
                  ),
                ),
            SizedBox(height: media.width * 0.05),
                Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  child: Text(
                    "Your Schedule",
                    style: TextStyle(
                        color: TColor.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                ),
            CustomCalendar(
                  onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                  // Refetch schedule when date changes
                  _fetchSleepSchedule();
                });
              },
            initialDate: DateTime.now(), // Ensure this is correct
 // This ensures the calendar starts from today

                ),
             SizedBox(height: media.width * 0.03),
                ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
              itemCount: _sleepSchedule.length,
                    itemBuilder: (context, index) {
                var sObj = _sleepSchedule[index];
                DateTime scheduleDateTime = _adjustScheduleTimeToSelectedDate(sObj['time'], _selectedDate);
                
                // Show only future schedules or schedules for today
                if (scheduleDateTime.isAfter(DateTime.now()) || 
                    (scheduleDateTime.day == DateTime.now().day && 
                     scheduleDateTime.month == DateTime.now().month && 
                     scheduleDateTime.year == DateTime.now().year)) {
                  return TodaySleepScheduleRow(sObj: {
                    ...sObj,
                    'time': DateFormat("hh:mm a").format(scheduleDateTime), 
                    'duration': _calculateDurationText(scheduleDateTime, DateTime.now()),
                  });
                }
                return SizedBox.shrink();
              },
            ),

                Container(
                    width: double.maxFinite,
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          TColor.secondaryColor2.withOpacity(0.4),
                          TColor.secondaryColor1.withOpacity(0.4)
                        ]),
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "You will get 8hours 10minutes\nfor tonight",
                    style: TextStyle(color: TColor.black, fontSize: 12),
                        ),
                  const SizedBox(height: 15),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SimpleAnimationProgressBar(
                              height: 15,
                              width: media.width - 80,
                              backgroundColor: Colors.grey.shade100,
                              foregrondColor: Colors.purple,
                              ratio: 0.96,
                              direction: Axis.horizontal,
                              curve: Curves.fastLinearToSlowEaseIn,
                              duration: const Duration(seconds: 3),
                              borderRadius: BorderRadius.circular(7.5),
                              gradientColor: LinearGradient(
                                  colors: TColor.secondaryG,
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight),
                            ),
                            Text(
                              "96%",
                        style: TextStyle(color: TColor.black, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
            ),
            ),
            SizedBox(height: media.width * 0.05),
          ],
        ),
      ),
      floatingActionButton: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SleepAddAlarmView(date: _selectedDate),
            ),
          ).then((value) {
            _fetchSleepSchedule(); // Refresh after adding an alarm
          });
        },
        child: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: TColor.secondaryG),
              borderRadius: BorderRadius.circular(27.5),
              boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))
              ]),
          alignment: Alignment.center,
          child: Icon(
            Icons.add,
            size: 20,
            color: TColor.white,
          ),
        ),
      ),
    );
  }
}
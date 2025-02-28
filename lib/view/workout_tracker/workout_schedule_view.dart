import 'package:fitglide_mobile_application/common_widget/custom_calendar.dart';
import 'package:flutter/material.dart';
import 'package:fitglide_mobile_application/services/api_service.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../common/colo_extension.dart';
import '../../common/common.dart';
import 'add_schedule_view.dart';
import '../workout_tracker/workout_detail_view.dart';

class WorkoutScheduleView extends StatefulWidget {
  const WorkoutScheduleView({super.key});

  @override
  State<WorkoutScheduleView> createState() => _WorkoutScheduleViewState();
}

class _WorkoutScheduleViewState extends State<WorkoutScheduleView> {
  DateTime _selectedDate = DateTime.now().toLocal();
  List<Map<String, dynamic>> eventArr = [];
  List<Map<String, dynamic>> selectDayEventArr = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWorkouts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchWorkouts();
  }

  Future<void> _fetchWorkouts() async {
    try {
      List<Map<String, dynamic>> allWorkouts = [];
      int page = 1;
      const int pageSize = 100;
      bool hasMore = true;

      while (hasMore) {
        final response = await ApiService.get(
          'workout-plans?populate=*&pagination[page]=$page&pagination[pageSize]=$pageSize',
        );
        final workoutData = response['data'] as List<dynamic>? ?? [];
        allWorkouts.addAll(workoutData.map((e) => Map<String, dynamic>.from(e as Map)));

        final meta = response['meta'] as Map<String, dynamic>? ?? {};
        final pagination = meta['pagination'] as Map<String, dynamic>? ?? {};
        final total = pagination['total'] as int? ?? 0;
        final fetched = allWorkouts.length;
        hasMore = fetched < total;
        page++;

        // Prevent infinite loop with a maximum page limit
        if (page > 10) {
          debugPrint('Reached pagination limit, stopping fetch');
          break;
        }
      }

      setState(() {
        eventArr = allWorkouts.map((workout) {
          final scheduledDateStr = workout['scheduled_date'] as String? ?? '';
          final scheduledDate = stringToDate(scheduledDateStr, formatStr: "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", ).toLocal();
          final formatter = DateFormat('dd/MM/yyyy hh:mm aa');
          return {
            "name": workout['Title'] as String? ?? 'Untitled',
            "start_time": formatter.format(scheduledDate),
            "date": scheduledDate,
            "documentId": workout['id'].toString(),
            "workout": Map<String, dynamic>.from(workout),
          };
        }).toList();
        debugPrint('Event count: ${eventArr.length}');
        setDayEventWorkoutList();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching workouts: $e');
      setState(() {
        isLoading = false;
        eventArr = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load workouts: $e')),
        );
      }
    }
  }

  void setDayEventWorkoutList() {
    final date = dateToStartDate(_selectedDate);
    selectDayEventArr = eventArr.where((wObj) {
      final eventDate = wObj["date"] as DateTime;
      final isSameDay = dateToStartDate(eventDate) == date;
      return isSameDay;
    }).toList();
    selectDayEventArr.sort((a, b) => (a["date"] as DateTime).compareTo(b["date"] as DateTime));
    if (mounted) {
      setState(() {});
    }
    debugPrint('Selected day events: ${selectDayEventArr.length} for ${_selectedDate.toIso8601String()}');
  }

  String getTime(int minutes) {
    final hour = minutes ~/ 60;
    final min = minutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
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
          "Workout Schedule",
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
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                CustomCalendar(
                  onDateSelected: (date) {
                    setState(() {
                      _selectedDate = date;
                      setDayEventWorkoutList();
                    });
                  },
                  initialDate: _selectedDate,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: media.width * 1.5,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final double padding = 80 + 40;
                          final double availWidth = media.width * 1.2 - padding;

                          final slotArr = selectDayEventArr.where((wObj) {
                            final eventDate = wObj["date"] as DateTime;
                            return eventDate.hour == index;
                          }).toList();

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            height: 40,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    getTime(index * 60),
                                    style: TextStyle(
                                      color: TColor.black,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                if (slotArr.isNotEmpty)
                                  Expanded(
                                    child: Stack(
                                      alignment: Alignment.centerLeft,
                                      children: slotArr.map((sObj) {
                                        final eventDate = sObj["date"] as DateTime;
                                        final min = eventDate.minute;
                                        final pos = (min / 60) * 2 - 1;

                                        return Align(
                                          alignment: Alignment(pos, 0),
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => WorkoutDetailView(
                                                    dObj: Map<String, dynamic>.from(sObj["workout"] as Map),
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              height: 35,
                                              width: availWidth * 0.5,
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              alignment: Alignment.centerLeft,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(colors: TColor.secondaryG),
                                                borderRadius: BorderRadius.circular(17.5),
                                              ),
                                              child: Text(
                                                "${sObj["name"]}, ${getStringDateToOtherFormate(sObj["start_time"] as String, outFormatStr: "h:mm aa")}",
                                                maxLines: 1,
                                                style: TextStyle(color: TColor.white, fontSize: 12),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (context, index) => Divider(
                          color: TColor.gray.withOpacity(0.2),
                          height: 1,
                        ),
                        itemCount: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddScheduleView(date: _selectedDate),
            ),
          ).then((_) => _fetchWorkouts());
        },
        child: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: TColor.secondaryG),
            borderRadius: BorderRadius.circular(27.5),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))
            ],
          ),
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
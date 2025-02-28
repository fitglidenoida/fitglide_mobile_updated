import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CustomCalendar extends StatefulWidget {
  final Function(DateTime) onDateSelected;
  final DateTime initialDate;

  const CustomCalendar({super.key, required this.onDateSelected, required this.initialDate});

  @override
  _CustomCalendarState createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  late DateTime _selectedDate;
  late DateTime _focusedDay;
  final List<DateTime> _dates = [];
  int? _daySelectedIndex;
  final ItemScrollController _scrollController = ItemScrollController();
  final double _scrollAlignment = 0.15;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _focusedDay = widget.initialDate;
    _generateDates();
    _selectedDay();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_daySelectedIndex != null) {
        _moveToDayIndex(_daySelectedIndex!);
      }
    });
  }


  void _generateDates() {
    _dates.clear();
    DateTime first = widget.initialDate.subtract(const Duration(days: 140));
    DateTime last = widget.initialDate.add(const Duration(days: 60));

    for (int i = 0; i < 201; i++) {
      _dates.add(first.add(Duration(days: i)));
    }
  }

  void _selectedDay() {
    _daySelectedIndex = _dates.indexWhere((dayDate) => isSameDay(dayDate, _selectedDate));
  }

  void _goToActualDay(int index) {
    _moveToDayIndex(index);
    setState(() {
      _daySelectedIndex = index;
      _selectedDate = _dates[index];
      _focusedDay = _selectedDate;
    });
    widget.onDateSelected(_selectedDate);
  }

  void _moveToDayIndex(int index) {
    _scrollController.scrollTo(
      index: index,
      alignment: _scrollAlignment,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _showYearPicker() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: YearPicker(
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            selectedDate: _focusedDay,
            onChanged: (DateTime newDate) {
              setState(() {
                _focusedDay = DateTime(newDate.year, _focusedDay.month);
              });
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  Future<void> _showMonthPicker() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = DateTime(0, index + 1);
              return ListTile(
                title: Text(DateFormat.MMMM().format(month)),
                onTap: () {
                  setState(() {
                    _focusedDay = DateTime(_focusedDay.year, month.month);
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

@override
Widget build(BuildContext context) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.grey, size: 24),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                });
              },
              padding: EdgeInsets.zero, // Remove default padding
            ),
            GestureDetector(
              onTap: _showYearPicker,
              child: Text(
                DateFormat.y().format(_focusedDay),
                style: const TextStyle(color: Colors.grey, fontSize: 16.0, fontWeight: FontWeight.normal),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.0), // Small gap between year and month
              child: Text(
                DateFormat.MMMM().format(_focusedDay),
                style: const TextStyle(color: Colors.grey, fontSize: 16.0, fontWeight: FontWeight.normal),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.grey, size: 24),
              onPressed: () {
                setState(() {
                  _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                });
              },
              padding: EdgeInsets.zero, // Remove default padding
            ),
          ],
        ),
      ),
      _dayView(context),
    ],
  );
}

  Widget _dayView(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 110,
      padding: const EdgeInsets.symmetric(vertical: 5),
      alignment: Alignment.bottomCenter,
      child: ScrollablePositionedList.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _dates.length,
        itemScrollController: _scrollController,
        itemBuilder: (context, index) {
          DateTime date = _dates[index];
          bool isSelected = _daySelectedIndex == index;

          return GestureDetector(
            onTap: () => _goToActualDay(index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              height: 100.0,
              width: MediaQuery.of(context).size.width / 5 - 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xff9DCEFF), Color(0xff92A3FD)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                color: isSelected ? null : Colors.grey.shade200,
                boxShadow: [
                  isSelected
                      ? BoxShadow(color: Colors.black.withOpacity(0.2), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 1))
                      : BoxShadow(color: Colors.grey.withOpacity(0.0), spreadRadius: 5, blurRadius: 20, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat.E().format(date),
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    DateFormat.d().format(date),
                    style: TextStyle(
                      fontSize: 16,
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

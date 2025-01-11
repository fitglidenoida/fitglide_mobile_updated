import 'calendar.dart';

// CalendarController
class CalendarAgendaController {
  CalendarAgendaState? state;

  void bindState(CalendarAgendaState state) {
    this.state = state;
  }

  void goToDay(DateTime date) {
    if (state != null) {
      state!.getDate(date);
    } else {
      throw Exception("CalendarAgendaState is not bound to the controller.");
    }
  }

  void dispose() {
    state = null;
  }
}

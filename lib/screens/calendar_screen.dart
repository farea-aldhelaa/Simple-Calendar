import 'package:dual_calendar/models/calendar_event.dart';
import 'package:dual_calendar/models/calendar_type.dart';
import 'package:dual_calendar/providers/calendar_provider.dart';
import 'package:dual_calendar/screens/event_details_screen.dart';
import 'package:dual_calendar/widgets/add_event_dialog.dart';
import 'package:dual_calendar/widgets/app_drawer.dart';
import 'package:dual_calendar/widgets/calendar_header.dart';
import 'package:dual_calendar/widgets/event_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hijri/hijri_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  String _formatHijriDate(HijriCalendar hijri) {
    return '${hijri.hDay} ${hijri.getLongMonthName()} ${hijri.hYear}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, calendarProvider, child) {
        return Scaffold(
          drawer: const AppDrawer(),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: CalendarHeader(
              onToggleCalendarFormat: () {
                calendarProvider.toggleCalendarType();
              },
            ),
          ),
          body: Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2000, 1, 1),
                lastDay: DateTime.utc(2050, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                eventLoader: (day) => calendarProvider.getEventsForDay(day),
                calendarStyle: const CalendarStyle(
                  markersMaxCount: 1,
                  markerSize:8 ,
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
              if (_selectedDay != null) ...[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    calendarProvider.currentCalendarType ==
                            CalendarType.gregorian
                        ? _selectedDay!.toString().split(' ')[0]
                        : _formatHijriDate(
                            HijriCalendar.fromDate(_selectedDay!)),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(8.0),
                    children: calendarProvider
                        .getEventsForDay(_selectedDay!)
                        .map((event) => EventCard(
                              event: event,
                              onDelete: () =>
                                  calendarProvider.removeEvent(event),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EventDetailsScreen(
                                    event: event,
                                    selectedDay: _selectedDay!,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              if (_selectedDay != null) {
                final event = await showDialog<CalendarEvent>(
                  context: context,
                  builder: (context) => AddEventDialog(
                    selectedDay: _selectedDay!,
                  ),
                );

                if (event != null) {
                  calendarProvider.addEvent(event);
                }
              }
            },
            label: const Text('Add Event'),
            icon: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

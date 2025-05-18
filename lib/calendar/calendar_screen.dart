import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:WanderBite/core/themes/theme_provider.dart';
import 'package:WanderBite/core/constants/app_constants.dart';
import 'package:WanderBite/auth/services/notification_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  Map<DateTime, List<Event>> _events = {};
  late ValueNotifier<List<Event>> _selectedEvents;

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay));
    _loadEvents();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getString('events');

      if (eventsJson != null) {
        final Map<String, List<dynamic>> decoded = jsonDecode(eventsJson);

        final Map<DateTime, List<Event>> events = {};
        decoded.forEach((key, value) {
          final date = DateTime.parse(key);
          events[date] = value.map((e) => Event.fromJson(e)).toList();
        });

        setState(() {
          _events = events;
          _selectedEvents.value = _getEventsForDay(_selectedDay);
        });
      }
    } catch (e) {
      debugPrint('Error loading events: $e');
    }
  }

  Future<void> _saveEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final Map<String, List<dynamic>> eventsMap = {};
      _events.forEach((key, value) {
        final dateStr = DateFormat('yyyy-MM-dd').format(key);
        eventsMap[dateStr] = value.map((e) => e.toJson()).toList();
      });

      await prefs.setString('events', jsonEncode(eventsMap));
    } catch (e) {
      debugPrint('Error saving events: $e');
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });

      _selectedEvents.value = _getEventsForDay(selectedDay);
      // Trigger notification if the selected day has events
      final events = _getEventsForDay(selectedDay);
      if (events.isNotEmpty) {
        Provider.of<NotificationService>(context, listen: false)
            .notifyEventAction(
          'Selected day with ${events.length} event(s): ${DateFormat.yMMMMd().format(selectedDay)}',
        );
      }
    }
  }

  void _addEvent() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final bool isTravelTheme =
        themeProvider.themeType == AppConstants.travelTheme;

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final timeController = TextEditingController(
      text: DateFormat.Hm().format(DateTime.now()),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isTravelTheme ? 'Add Travel Event' : 'Add Recipe/Meal Event',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                ),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
                maxLines: 3,
              ),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'Time (HH:MM)',
                ),
                keyboardType: TextInputType.datetime,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isEmpty) {
                return;
              }

              final normalizedDay = DateTime(
                _selectedDay.year,
                _selectedDay.month,
                _selectedDay.day,
              );

              final event = Event(
                title: titleController.text,
                description: descriptionController.text,
                time: timeController.text,
              );

              setState(() {
                if (_events[normalizedDay] != null) {
                  _events[normalizedDay]!.add(event);
                } else {
                  _events[normalizedDay] = [event];
                }

                _selectedEvents.value = _getEventsForDay(_selectedDay);
              });

              // Trigger notification
              Provider.of<NotificationService>(context, listen: false)
                  .notifyEventAction(
                'Event added: ${event.title} on ${DateFormat.yMMMMd().format(normalizedDay)}',
              );

              _saveEvents();
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteEvent(Event event) {
    final normalizedDay = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );

    setState(() {
      _events[normalizedDay]?.remove(event);
      _selectedEvents.value = _getEventsForDay(_selectedDay);
    });

    // Trigger notification
    Provider.of<NotificationService>(context, listen: false).notifyEventAction(
      'Event deleted: ${event.title} on ${DateFormat.yMMMMd().format(normalizedDay)}',
    );

    _saveEvents();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isTravelTheme =
        themeProvider.themeType == AppConstants.travelTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isTravelTheme ? 'Travel Itinerary' : 'Meal Planner',
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEvent,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              markersMaxCount: 3,
              markerDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor,
                      ),
                      width: 8.0,
                      height: 8.0,
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 8.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  DateFormat.yMMMMd().format(_selectedDay),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  isTravelTheme ? 'Travel Events' : 'Meal Events',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ValueListenableBuilder<List<Event>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                return value.isEmpty
                    ? Center(
                        child: Text(
                          isTravelTheme
                              ? 'No travel events for this day.\nTap the + button to add one.'
                              : 'No meal events for this day.\nTap the + button to add one.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: value.length,
                        itemBuilder: (context, index) {
                          final event = value[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 4.0,
                            ),
                            child: ListTile(
                              leading: Icon(
                                isTravelTheme
                                    ? Icons.travel_explore
                                    : Icons.restaurant,
                                color: Theme.of(context).primaryColor,
                              ),
                              title: Text(event.title),
                              subtitle: Text(
                                '${event.time} - ${event.description}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteEvent(event),
                              ),
                            ),
                          );
                        },
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Event {
  final String title;
  final String description;
  final String time;

  Event({
    required this.title,
    required this.description,
    required this.time,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      title: json['title'],
      description: json['description'],
      time: json['time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'time': time,
    };
  }
}

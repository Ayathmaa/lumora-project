import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/progress_service.dart';

const _kNavy = Color(0xFF1A3A5C);
const _kSubtitle = Color(0xFF4A6FA5);
const _kCardBg = Colors.white;
const _kBlue = Color(0xFF6BAED4);

const _kDotJournal = Colors.blue;
const _kDotErp = Colors.orange;
const _kDotBreathing = Colors.green;
const _kDotHabit = Colors.purple;

class JourneyCalendarWidget extends StatefulWidget {
  final String? userId;

  const JourneyCalendarWidget({super.key, this.userId});

  @override
  State<JourneyCalendarWidget> createState() => _JourneyCalendarWidgetState();
}

class _JourneyCalendarWidgetState extends State<JourneyCalendarWidget> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<ActivityEvent> _allEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    final events = await ProgressService().fetchAllActivities(widget.userId);
    if (mounted) {
      setState(() {
        _allEvents = events;
        _isLoading = false;
      });
    }
  }

  List<ActivityEvent> _getEventsForDay(DateTime day) {
    return _allEvents.where((e) => isSameDay(e.date, day)).toList();
  }

  Widget _buildEventMarker(String type) {
    Color dotColor = Colors.grey;
    if (type == 'Journal') dotColor = _kDotJournal;
    if (type == 'ERP') dotColor = _kDotErp;
    if (type == 'Breathing') dotColor = _kDotBreathing;
    if (type == 'Habit') dotColor = _kDotHabit;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      width: 6,
      height: 6,
      decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
    );
  }

  Widget _buildSelectedDayEvents() {
    if (_selectedDay == null) return const SizedBox();
    final dayEvents = _getEventsForDay(_selectedDay!);

    if (dayEvents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No activities on this day.',
            style: TextStyle(color: _kSubtitle),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: dayEvents.map((e) {
        Color iconColor = Colors.grey;
        IconData icon = Icons.check_circle;
        if (e.type == 'Journal') {
          iconColor = _kDotJournal;
          icon = Icons.menu_book;
        }
        if (e.type == 'ERP') {
          iconColor = _kDotErp;
          icon = Icons.timer;
        }
        if (e.type == 'Breathing') {
          iconColor = _kDotBreathing;
          icon = Icons.air;
        }
        if (e.type == 'Habit') {
          iconColor = _kDotHabit;
          icon = Icons.calendar_today;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _kNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      e.detail,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _kSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${e.date.hour.toString().padLeft(2, '0')}:${e.date.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 12,
                  color: _kSubtitle,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 2),
          child: Text(
            'Journey Calendar',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kNavy,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Color(0x0A000000), blurRadius: 8),
            ],
          ),
          padding: const EdgeInsets.only(bottom: 12),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _getEventsForDay,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return const SizedBox();
                return Positioned(
                  bottom: 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: events.map((e) => _buildEventMarker((e as ActivityEvent).type)).toList(),
                  ),
                );
              },
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kNavy,
              ),
            ),
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: _kNavy,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: _kBlue,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSelectedDayEvents(),
      ],
    );
  }
}

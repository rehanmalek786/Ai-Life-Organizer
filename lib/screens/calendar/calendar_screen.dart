import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _fs = FirestoreService();
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  void _openForm(List<CalendarEventItem> events, {CalendarEventItem? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EventForm(existing: existing, fs: _fs, initialDate: _selectedDay),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm([]), child: const Icon(Icons.add)),
      body: StreamBuilder<List<CalendarEventItem>>(
        stream: _fs.eventsStream(),
        builder: (context, snap) {
          final events = snap.data ?? [];
          final grouped = <DateTime, List<CalendarEventItem>>{};
          for (final e in events) {
            final key = DateTime(e.startTime.year, e.startTime.month, e.startTime.day);
            grouped.putIfAbsent(key, () => []).add(e);
          }
          final dayEvents = events.where((e) => _sameDay(e.startTime, _selectedDay)).toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));

          return Column(
            children: [
              TableCalendar<CalendarEventItem>(
                firstDay: DateTime.now().subtract(const Duration(days: 365 * 2)),
                lastDay: DateTime.now().add(const Duration(days: 365 * 2)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (d) => _sameDay(d, _selectedDay),
                eventLoader: (day) => grouped[DateTime(day.year, day.month, day.day)] ?? [],
                calendarFormat: CalendarFormat.month,
                onDaySelected: (selected, focused) => setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                }),
                onPageChanged: (focused) => _focusedDay = focused,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4), shape: BoxShape.circle),
                  selectedDecoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
                  markerDecoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary, shape: BoxShape.circle),
                ),
                headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
              ),
              const Divider(height: 1),
              Expanded(
                child: dayEvents.isEmpty
                    ? const EmptyState(icon: Icons.event_note, title: 'No events this day', subtitle: 'Tap + to add one.')
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                        itemCount: dayEvents.length,
                        itemBuilder: (context, i) {
                          final e = dayEvents[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              onTap: () => _openForm(events, existing: e),
                              leading: const Icon(Icons.event),
                              title: Text(e.title),
                              subtitle: Text([
                                DateFormat('h:mm a').format(e.startTime),
                                if (e.location.isNotEmpty) e.location,
                              ].join(' • ')),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _fs.deleteEvent(e.id),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EventForm extends StatefulWidget {
  final CalendarEventItem? existing;
  final FirestoreService fs;
  final DateTime initialDate;
  const _EventForm({this.existing, required this.fs, required this.initialDate});

  @override
  State<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<_EventForm> {
  late final _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
  late final _locationCtrl = TextEditingController(text: widget.existing?.location ?? '');
  late final _notesCtrl = TextEditingController(text: widget.existing?.notes ?? '');
  late DateTime _start = widget.existing?.startTime ?? DateTime(widget.initialDate.year, widget.initialDate.month, widget.initialDate.day, 9, 0);

  Future<void> _pickStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_start));
    if (time == null) return;
    setState(() => _start = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) return;
    final event = CalendarEventItem(
      id: widget.existing?.id ?? '',
      title: _titleCtrl.text.trim(),
      startTime: _start,
      location: _locationCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    if (widget.existing == null) {
      widget.fs.addEvent(event);
    } else {
      widget.fs.updateEvent(event);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.existing == null ? 'New event' : 'Edit event', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            AppTextField(controller: _titleCtrl, label: 'Title'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickStart,
              icon: const Icon(Icons.access_time, size: 18),
              label: Text(DateFormat('d MMM yyyy, h:mm a').format(_start)),
            ),
            const SizedBox(height: 12),
            AppTextField(controller: _locationCtrl, label: 'Location (optional)'),
            const SizedBox(height: 12),
            AppTextField(controller: _notesCtrl, label: 'Notes (optional)', maxLines: 2),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}

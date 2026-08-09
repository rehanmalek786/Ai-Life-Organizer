import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});
  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _fs = FirestoreService();
  final _notif = NotificationService();

  void _openForm({ReminderItem? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReminderForm(existing: existing, fs: _fs, notif: _notif),
    );
  }

  Future<void> _delete(ReminderItem r) async {
    await _notif.cancel(r.notificationId);
    await _fs.deleteReminder(r.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
      body: StreamBuilder<List<ReminderItem>>(
        stream: _fs.remindersStream(),
        builder: (context, snap) {
          if (!snap.hasData) return const LoadingView();
          final reminders = snap.data!;
          if (reminders.isEmpty) {
            return const EmptyState(icon: Icons.notifications_none, title: 'No reminders yet', subtitle: 'Tap + to set one, or ask the AI assistant.');
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            itemCount: reminders.length,
            itemBuilder: (context, i) {
              final r = reminders[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  onTap: () => _openForm(existing: r),
                  leading: Icon(r.recurring == 'none' ? Icons.notifications_outlined : Icons.repeat),
                  title: Text(r.title),
                  subtitle: Text(
                    '${DateFormat('EEE, d MMM • h:mm a').format(r.dateTime)}${r.recurring != 'none' ? ' • repeats ${r.recurring}' : ''}',
                  ),
                  trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(r)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ReminderForm extends StatefulWidget {
  final ReminderItem? existing;
  final FirestoreService fs;
  final NotificationService notif;
  const _ReminderForm({this.existing, required this.fs, required this.notif});
  @override
  State<_ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends State<_ReminderForm> {
  late final _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
  late DateTime _dateTime = widget.existing?.dateTime ?? DateTime.now().add(const Duration(hours: 1));
  late String _recurring = widget.existing?.recurring ?? 'none';

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_dateTime));
    if (time == null) return;
    setState(() => _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    final notificationId = widget.existing?.notificationId ?? NotificationService.idFromString(DateTime.now().microsecondsSinceEpoch.toString());

    final reminder = ReminderItem(
      id: widget.existing?.id ?? '',
      title: _titleCtrl.text.trim(),
      dateTime: _dateTime,
      recurring: _recurring,
      notificationId: notificationId,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    if (widget.existing == null) {
      await widget.fs.addReminder(reminder);
    } else {
      await widget.fs.updateReminder(reminder);
    }
    await widget.notif.scheduleReminder(
      id: notificationId,
      title: reminder.title,
      dateTime: reminder.dateTime,
      recurring: reminder.recurring,
    );
    if (mounted) Navigator.pop(context);
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
            Text(widget.existing == null ? 'New reminder' : 'Edit reminder', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            AppTextField(controller: _titleCtrl, label: 'Remind me to...'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDateTime,
              icon: const Icon(Icons.access_time, size: 18),
              label: Text(DateFormat('d MMM yyyy, h:mm a').format(_dateTime)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Repeat:'),
                const SizedBox(width: 12),
                ...['none', 'daily', 'weekly'].map((r) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(label: Text(r), selected: _recurring == r, onSelected: (_) => setState(() => _recurring = r)),
                    )),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});
  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final _fs = FirestoreService();

  void _openForm({HabitItem? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HabitForm(existing: existing, fs: _fs),
    );
  }

  void _markDoneToday(HabitItem h) {
    if (h.doneToday) return;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final wasYesterday = h.lastCompleted != null &&
        h.lastCompleted!.year == yesterday.year &&
        h.lastCompleted!.month == yesterday.month &&
        h.lastCompleted!.day == yesterday.day;
    _fs.updateHabit(HabitItem(
      id: h.id,
      name: h.name,
      frequency: h.frequency,
      streak: wasYesterday ? h.streak + 1 : 1,
      lastCompleted: DateTime.now(),
      createdAt: h.createdAt,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
      body: StreamBuilder<List<HabitItem>>(
        stream: _fs.habitsStream(),
        builder: (context, snap) {
          if (!snap.hasData) return const LoadingView();
          final habits = snap.data!;
          if (habits.isEmpty) {
            return const EmptyState(icon: Icons.repeat_rounded, title: 'No habits yet', subtitle: 'Tap + to start tracking a habit.');
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            itemCount: habits.length,
            itemBuilder: (context, i) {
              final h = habits[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  onTap: () => _openForm(existing: h),
                  onLongPress: () => _fs.deleteHabit(h.id),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.15),
                    child: Text('${h.streak}', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.w700)),
                  ),
                  title: Text(h.name),
                  subtitle: Text('${h.frequency == 'daily' ? 'Daily' : h.frequency} • 🔥 ${h.streak} day streak'),
                  trailing: IconButton(
                    icon: Icon(h.doneToday ? Icons.check_circle : Icons.check_circle_outline,
                        color: h.doneToday ? theme.colorScheme.primary : null),
                    onPressed: () => _markDoneToday(h),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HabitForm extends StatefulWidget {
  final HabitItem? existing;
  final FirestoreService fs;
  const _HabitForm({this.existing, required this.fs});
  @override
  State<_HabitForm> createState() => _HabitFormState();
}

class _HabitFormState extends State<_HabitForm> {
  late final _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
  late String _frequency = widget.existing?.frequency ?? 'daily';

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) return;
    final habit = HabitItem(
      id: widget.existing?.id ?? '',
      name: _nameCtrl.text.trim(),
      frequency: _frequency,
      streak: widget.existing?.streak ?? 0,
      lastCompleted: widget.existing?.lastCompleted,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    if (widget.existing == null) {
      widget.fs.addHabit(habit);
    } else {
      widget.fs.updateHabit(habit);
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
            Text(widget.existing == null ? 'New habit' : 'Edit habit', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            AppTextField(controller: _nameCtrl, label: 'Habit name (e.g. Reading)'),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text('Frequency:'),
                const SizedBox(width: 12),
                ChoiceChip(label: const Text('Daily'), selected: _frequency == 'daily', onSelected: (_) => setState(() => _frequency = 'daily')),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text('Weekdays'), selected: _frequency == 'mon,tue,wed,thu,fri', onSelected: (_) => setState(() => _frequency = 'mon,tue,wed,thu,fri')),
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

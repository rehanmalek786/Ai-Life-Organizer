import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});
  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _fs = FirestoreService();

  void _openForm({GoalItem? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GoalForm(existing: existing, fs: _fs),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Goals')),
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
      body: StreamBuilder<List<GoalItem>>(
        stream: _fs.goalsStream(),
        builder: (context, snap) {
          if (!snap.hasData) return const LoadingView();
          final goals = snap.data!;
          if (goals.isEmpty) {
            return const EmptyState(icon: Icons.flag_outlined, title: 'No goals yet', subtitle: 'Tap + to set your first goal.');
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            itemCount: goals.length,
            itemBuilder: (context, i) {
              final g = goals[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _openForm(existing: g),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(g.title, style: theme.textTheme.titleMedium)),
                            IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _fs.deleteGoal(g.id)),
                          ],
                        ),
                        if (g.description.isNotEmpty) Text(g.description, style: theme.textTheme.bodySmall),
                        if (g.targetDate != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('Target: ${DateFormat('d MMM yyyy').format(g.targetDate!)}', style: theme.textTheme.bodySmall),
                          ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(value: g.progress / 100, minHeight: 8),
                        ),
                        const SizedBox(height: 6),
                        Text('${g.progress}% complete', style: theme.textTheme.bodySmall),
                      ],
                    ),
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

class _GoalForm extends StatefulWidget {
  final GoalItem? existing;
  final FirestoreService fs;
  const _GoalForm({this.existing, required this.fs});
  @override
  State<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends State<_GoalForm> {
  late final _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
  late final _descCtrl = TextEditingController(text: widget.existing?.description ?? '');
  late double _progress = (widget.existing?.progress ?? 0).toDouble();
  late DateTime? _targetDate = widget.existing?.targetDate;

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) setState(() => _targetDate = date);
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) return;
    final goal = GoalItem(
      id: widget.existing?.id ?? '',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      targetDate: _targetDate,
      progress: _progress.round(),
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    if (widget.existing == null) {
      widget.fs.addGoal(goal);
    } else {
      widget.fs.updateGoal(goal);
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
            Text(widget.existing == null ? 'New goal' : 'Edit goal', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            AppTextField(controller: _titleCtrl, label: 'Goal title'),
            const SizedBox(height: 12),
            AppTextField(controller: _descCtrl, label: 'Description (optional)', maxLines: 2),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(_targetDate == null ? 'Set target date (optional)' : DateFormat('d MMM yyyy').format(_targetDate!)),
            ),
            const SizedBox(height: 12),
            Text('Progress: ${_progress.round()}%'),
            Slider(value: _progress, min: 0, max: 100, divisions: 20, onChanged: (v) => setState(() => _progress = v)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}

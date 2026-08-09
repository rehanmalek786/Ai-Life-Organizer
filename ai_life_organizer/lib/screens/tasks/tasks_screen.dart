import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _fs = FirestoreService();
  String _filter = 'all'; // all | pending | completed

  void _openForm({TaskItem? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TaskForm(existing: existing, fs: _fs),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _filter,
            onSelected: (v) => setState(() => _filter = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'all', child: Text('All')),
              PopupMenuItem(value: 'pending', child: Text('Pending')),
              PopupMenuItem(value: 'completed', child: Text('Completed')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _openForm(), child: const Icon(Icons.add)),
      body: StreamBuilder<List<TaskItem>>(
        stream: _fs.tasksStream(),
        builder: (context, snap) {
          if (!snap.hasData) return const LoadingView();
          var tasks = snap.data!;
          if (_filter == 'pending') tasks = tasks.where((t) => !t.completed).toList();
          if (_filter == 'completed') tasks = tasks.where((t) => t.completed).toList();

          if (tasks.isEmpty) {
            return const EmptyState(
              icon: Icons.checklist_rounded,
              title: 'No tasks here yet',
              subtitle: 'Tap + to add one, or ask the AI assistant to add it for you.',
            );
          }

          tasks.sort((a, b) {
            if (a.completed != b.completed) return a.completed ? 1 : -1;
            const order = {'high': 0, 'medium': 1, 'low': 2};
            return (order[a.priority] ?? 1).compareTo(order[b.priority] ?? 1);
          });

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            itemCount: tasks.length,
            itemBuilder: (context, i) {
              final t = tasks[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  onTap: () => _openForm(existing: t),
                  leading: Checkbox(
                    value: t.completed,
                    onChanged: (v) => _fs.updateTask(TaskItem(
                      id: t.id,
                      title: t.title,
                      description: t.description,
                      priority: t.priority,
                      category: t.category,
                      deadline: t.deadline,
                      completed: v ?? false,
                      createdAt: t.createdAt,
                    )),
                  ),
                  title: Text(
                    t.title,
                    style: TextStyle(decoration: t.completed ? TextDecoration.lineThrough : null),
                  ),
                  subtitle: Text([
                    if (t.deadline != null) DateFormat('d MMM, h:mm a').format(t.deadline!),
                    t.category,
                  ].join(' • ')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PriorityBadge(priority: t.priority),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _fs.deleteTask(t.id),
                      ),
                    ],
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

class _TaskForm extends StatefulWidget {
  final TaskItem? existing;
  final FirestoreService fs;
  const _TaskForm({this.existing, required this.fs});

  @override
  State<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<_TaskForm> {
  late final _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
  late final _descCtrl = TextEditingController(text: widget.existing?.description ?? '');
  late final _categoryCtrl = TextEditingController(text: widget.existing?.category ?? 'General');
  late String _priority = widget.existing?.priority ?? 'medium';
  DateTime? _deadline = widget.existing?.deadline;

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_deadline ?? DateTime.now()));
    setState(() {
      _deadline = DateTime(date.year, date.month, date.day, time?.hour ?? 9, time?.minute ?? 0);
    });
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) return;
    final task = TaskItem(
      id: widget.existing?.id ?? '',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      priority: _priority,
      category: _categoryCtrl.text.trim().isEmpty ? 'General' : _categoryCtrl.text.trim(),
      deadline: _deadline,
      completed: widget.existing?.completed ?? false,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );
    if (widget.existing == null) {
      widget.fs.addTask(task);
    } else {
      widget.fs.updateTask(task);
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
            Text(widget.existing == null ? 'New task' : 'Edit task', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            AppTextField(controller: _titleCtrl, label: 'Title'),
            const SizedBox(height: 12),
            AppTextField(controller: _descCtrl, label: 'Description (optional)', maxLines: 2),
            const SizedBox(height: 12),
            AppTextField(controller: _categoryCtrl, label: 'Category'),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Priority:'),
                const SizedBox(width: 12),
                ...['low', 'medium', 'high'].map((p) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(p),
                        selected: _priority == p,
                        onSelected: (_) => setState(() => _priority = p),
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDeadline,
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(_deadline == null ? 'Set deadline (optional)' : DateFormat('d MMM yyyy, h:mm a').format(_deadline!)),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}

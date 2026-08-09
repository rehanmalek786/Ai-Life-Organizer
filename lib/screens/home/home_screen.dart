import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../../services/firestore_service.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';

class HomeScreen extends StatelessWidget {
  final void Function(int tabIndex) onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    final name = context.watch<AuthProvider>().user?.displayName ?? '';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('${_greeting()}${name.isNotEmpty ? ', $name' : ''}')),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            StreamBuilder<List<TaskItem>>(
              stream: fs.tasksStream(),
              builder: (context, snap) {
                final tasks = snap.data ?? [];
                final pending = tasks.where((t) => !t.completed).toList();
                final highPriority = pending.where((t) => t.priority == 'high').length;
                return _SummaryCard(
                  totalPending: pending.length,
                  highPriority: highPriority,
                  onTap: () => onNavigate(1),
                );
              },
            ),
            StreamBuilder<List<CalendarEventItem>>(
              stream: fs.eventsStream(),
              builder: (context, snap) {
                final events = (snap.data ?? []).where((e) => _isToday(e.startTime)).toList();
                if (events.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(title: "Today's schedule", trailing: TextButton(onPressed: () => onNavigate(2), child: const Text('View all'))),
                    ...events.map((e) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.event),
                            title: Text(e.title),
                            subtitle: Text(DateFormat('h:mm a').format(e.startTime)),
                          ),
                        )),
                  ],
                );
              },
            ),
            StreamBuilder<List<ReminderItem>>(
              stream: fs.remindersStream(),
              builder: (context, snap) {
                final upcoming = (snap.data ?? []).where((r) => r.dateTime.isAfter(DateTime.now())).take(3).toList();
                if (upcoming.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(title: 'Upcoming reminders', trailing: TextButton(onPressed: () => onNavigate(4), child: const Text('View all'))),
                    ...upcoming.map((r) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.notifications_outlined),
                            title: Text(r.title),
                            subtitle: Text(DateFormat('EEE, d MMM • h:mm a').format(r.dateTime)),
                          ),
                        )),
                  ],
                );
              },
            ),
            StreamBuilder<List<TaskItem>>(
              stream: fs.tasksStream(),
              builder: (context, snap) {
                final pending = (snap.data ?? []).where((t) => !t.completed).take(5).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(title: "Today's tasks", trailing: TextButton(onPressed: () => onNavigate(1), child: const Text('View all'))),
                    if (pending.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text('No pending tasks. Nice and clear!', style: theme.textTheme.bodyMedium),
                        ),
                      )
                    else
                      ...pending.map((t) => Card(
                            child: ListTile(
                              leading: PriorityBadge(priority: t.priority),
                              title: Text(t.title),
                              subtitle: t.deadline != null ? Text(DateFormat('d MMM, h:mm a').format(t.deadline!)) : null,
                            ),
                          )),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Card(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              child: ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: const Text('Ask the AI Assistant'),
                subtitle: const Text('"Kal 5 baje doctor appointment yaad dilana"'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => onNavigate(3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}

class _SummaryCard extends StatelessWidget {
  final int totalPending;
  final int highPriority;
  final VoidCallback onTap;
  const _SummaryCard({required this.totalPending, required this.highPriority, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$totalPending', style: theme.textTheme.displayLarge?.copyWith(fontSize: 40)),
                    Text(
                      totalPending == 1 ? 'task pending' : 'tasks pending',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (highPriority > 0) ...[
                      const SizedBox(height: 6),
                      Text('$highPriority high priority', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              ),
              Icon(Icons.checklist_rounded, size: 44, color: theme.colorScheme.primary.withValues(alpha: 0.35)),
            ],
          ),
        ),
      ),
    );
  }
}

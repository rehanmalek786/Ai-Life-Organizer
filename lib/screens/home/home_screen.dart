import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_providers.dart';
import '../../services/firestore_service.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';
import '../money/money_screen.dart';
import '../analytics/analytics_screen.dart';
import '../search/search_screen.dart';
import '../vault/vault_screen.dart';
import '../habits/habits_screen.dart';

class HomeScreen extends StatelessWidget {
  final void Function(int tabIndex) onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static const _tips = [
    'Try telling the AI Assistant: "remind me to call mom tomorrow at 6pm".',
    'Set a daily habit and watch your streak grow day by day.',
    'Ask the AI Assistant to summarize a long note in one tap.',
    'Log an expense by just typing it in the AI chat - "spent 200 on food".',
    'Say "remember that..." to the AI and it will use that context later.',
  ];

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    final name = context.watch<AuthProvider>().user?.displayName ?? '';
    final theme = Theme.of(context);
    final tip = _tips[DateTime.now().day % _tips.length];

    return Scaffold(
      appBar: AppBar(
        title: Text('${_greeting()}${name.isNotEmpty ? ', $name' : ''}'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => _push(context, const SearchScreen())),
        ],
      ),
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
                return _SummaryCard(totalPending: pending.length, highPriority: highPriority, onTap: () => onNavigate(1));
              },
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 86,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _QuickAction(icon: Icons.account_balance_wallet_outlined, label: 'Money', onTap: () => _push(context, const MoneyScreen())),
                  const SizedBox(width: 10),
                  _QuickAction(icon: Icons.bar_chart_rounded, label: 'Analytics', onTap: () => _push(context, const AnalyticsScreen())),
                  const SizedBox(width: 10),
                  _QuickAction(icon: Icons.repeat_rounded, label: 'Habits', onTap: () => _push(context, const HabitsScreen())),
                  const SizedBox(width: 10),
                  _QuickAction(icon: Icons.lock_outline, label: 'Vault', onTap: () => _push(context, const VaultScreen())),
                  const SizedBox(width: 10),
                  _QuickAction(icon: Icons.auto_awesome, label: 'AI Chat', onTap: () => onNavigate(3)),
                ],
              ),
            ),
            StreamBuilder<List<HabitItem>>(
              stream: fs.habitsStream(),
              builder: (context, snap) {
                final habits = snap.data ?? [];
                if (habits.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: "Today's habits"),
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: habits.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final h = habits[i];
                          return _HabitChip(habit: h, fs: fs);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            Container(
              margin: const EdgeInsets.only(top: 18),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: theme.colorScheme.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 18, color: theme.colorScheme.secondary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(tip, style: theme.textTheme.bodySmall)),
                ],
              ),
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
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(leading: const Icon(Icons.event), title: Text(e.title), subtitle: Text(DateFormat('h:mm a').format(e.startTime))),
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
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(leading: const Icon(Icons.notifications_outlined), title: Text(r.title), subtitle: Text(DateFormat('EEE, d MMM • h:mm a').format(r.dateTime))),
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
                      Card(child: Padding(padding: const EdgeInsets.all(20), child: Text('No pending tasks. Nice and clear!', style: theme.textTheme.bodyMedium)))
                    else
                      ...pending.map((t) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
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
                subtitle: const Text('"Remind me tomorrow at 5pm to call the doctor"'),
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

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 74,
        decoration: BoxDecoration(color: theme.cardTheme.color, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _HabitChip extends StatelessWidget {
  final HabitItem habit;
  final FirestoreService fs;
  const _HabitChip({required this.habit, required this.fs});

  void _markDone() {
    if (habit.doneToday) return;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final wasYesterday = habit.lastCompleted != null &&
        habit.lastCompleted!.year == yesterday.year &&
        habit.lastCompleted!.month == yesterday.month &&
        habit.lastCompleted!.day == yesterday.day;
    fs.updateHabit(HabitItem(
      id: habit.id,
      name: habit.name,
      frequency: habit.frequency,
      streak: wasYesterday ? habit.streak + 1 : 1,
      lastCompleted: DateTime.now(),
      createdAt: habit.createdAt,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _markDone,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: habit.doneToday ? theme.colorScheme.primary : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(habit.doneToday ? Icons.check_circle : Icons.circle_outlined, size: 16, color: habit.doneToday ? Colors.white : theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(habit.name, style: TextStyle(color: habit.doneToday ? Colors.white : null, fontSize: 13)),
          ],
        ),
      ),
    );
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
                    Text(totalPending == 1 ? 'task pending' : 'tasks pending', style: theme.textTheme.bodyMedium),
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

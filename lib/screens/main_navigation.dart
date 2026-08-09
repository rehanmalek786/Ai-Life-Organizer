import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'tasks/tasks_screen.dart';
import 'calendar/calendar_screen.dart';
import 'ai/ai_screen.dart';
import 'notes/notes_screen.dart';
import 'goals/goals_screen.dart';
import 'habits/habits_screen.dart';
import 'reminders/reminders_screen.dart';
import 'settings/settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  void _goTo(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onNavigate: _goTo),
      const TasksScreen(),
      const CalendarScreen(),
      const AiScreen(),
      const _MoreScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _goTo,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.checklist_outlined), selectedIcon: Icon(Icons.checklist), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome), label: 'AI'),
          NavigationDestination(icon: Icon(Icons.more_horiz), selectedIcon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}

class _MoreScreen extends StatelessWidget {
  const _MoreScreen();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.sticky_note_2_outlined, 'Notes', const NotesScreen()),
      (Icons.flag_outlined, 'Goals', const GoalsScreen()),
      (Icons.repeat_rounded, 'Habits', const HabitsScreen()),
      (Icons.notifications_none, 'Reminders', const RemindersScreen()),
      (Icons.settings_outlined, 'Settings', const SettingsScreen()),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final (icon, label, screen) = items[i];
          return Card(
            child: ListTile(
              leading: Icon(icon),
              title: Text(label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
            ),
          );
        },
      ),
    );
  }
}

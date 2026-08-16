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
import 'money/money_screen.dart';
import 'analytics/analytics_screen.dart';
import 'search/search_screen.dart';
import 'location/location_reminders_screen.dart';
import 'vault/vault_screen.dart';
import '../services/location_service.dart';
import '../widgets/shared_widgets.dart';
import '../theme/app_theme.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with WidgetsBindingObserver {
  int _index = 0;
  final _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locationService.checkNow();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _locationService.checkNow();
    }
  }

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
      (Icons.search, 'Search', const SearchScreen()),
      (Icons.sticky_note_2_outlined, 'Notes', const NotesScreen(), AppColors.priorityMedium),
      (Icons.flag_outlined, 'Goals', const GoalsScreen(), AppColors.priorityLow),
      (Icons.repeat_rounded, 'Habits', const HabitsScreen(), AppColors.accent),
      (Icons.notifications_none, 'Reminders', const RemindersScreen(), AppColors.priorityHigh),
      (Icons.account_balance_wallet_outlined, 'Money Organizer', const MoneyScreen(), AppColors.success),
      (Icons.bar_chart_rounded, 'Analytics', const AnalyticsScreen(), AppColors.primary),
      (Icons.location_on_outlined, 'Location Reminders', const LocationRemindersScreen(), AppColors.priorityLow),
      (Icons.lock_outline, 'Personal Vault', const VaultScreen(), AppColors.priorityMedium),
      (Icons.settings_outlined, 'Settings', const SettingsScreen(), AppColors.subtleLight),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final (icon, label, screen, color) = items[i];
          return Card(
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              title: Text(label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, smoothRoute(screen)),
            ),
          );
        },
      ),
    );
  }
}

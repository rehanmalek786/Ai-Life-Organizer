import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../widgets/shared_widgets.dart';

class _SearchHit {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SearchHit({required this.icon, required this.title, required this.subtitle});
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _fs = FirestoreService();
  final _ctrl = TextEditingController();
  bool _loading = false;
  List<_SearchHit> _results = [];

  Future<void> _search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _loading = true);

    final tasks = await _fs.tasksOnce();
    final notes = await _fs.notesOnce();
    final goals = await _fs.goalsOnce();
    final habits = await _fs.habitsOnce();
    final events = await _fs.eventsOnce();
    final reminders = await _fs.remindersOnce();
    final memories = await _fs.memoriesOnce();

    final hits = <_SearchHit>[
      ...tasks.where((t) => t.title.toLowerCase().contains(q) || t.description.toLowerCase().contains(q))
          .map((t) => _SearchHit(icon: Icons.checklist_rounded, title: t.title, subtitle: 'Task • ${t.category}')),
      ...notes.where((n) => n.title.toLowerCase().contains(q) || n.body.toLowerCase().contains(q))
          .map((n) => _SearchHit(icon: Icons.sticky_note_2_outlined, title: n.title.isEmpty ? '(untitled)' : n.title, subtitle: 'Note')),
      ...goals.where((g) => g.title.toLowerCase().contains(q) || g.description.toLowerCase().contains(q))
          .map((g) => _SearchHit(icon: Icons.flag_outlined, title: g.title, subtitle: 'Goal • ${g.progress}% done')),
      ...habits.where((h) => h.name.toLowerCase().contains(q))
          .map((h) => _SearchHit(icon: Icons.repeat_rounded, title: h.name, subtitle: 'Habit • ${h.streak} day streak')),
      ...events.where((e) => e.title.toLowerCase().contains(q) || e.location.toLowerCase().contains(q))
          .map((e) => _SearchHit(icon: Icons.event, title: e.title, subtitle: 'Event')),
      ...reminders.where((r) => r.title.toLowerCase().contains(q))
          .map((r) => _SearchHit(icon: Icons.notifications_none, title: r.title, subtitle: 'Reminder')),
      ...memories.where((m) => m.content.toLowerCase().contains(q))
          .map((m) => _SearchHit(icon: Icons.psychology_outlined, title: m.content, subtitle: 'Memory')),
    ];

    if (!mounted) return;
    setState(() {
      _results = hits;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          onChanged: _search,
          decoration: const InputDecoration(border: InputBorder.none, hintText: 'Search everything...'),
        ),
      ),
      body: _loading
          ? const LoadingView()
          : _ctrl.text.trim().isEmpty
              ? const EmptyState(icon: Icons.search, title: 'Search across everything', subtitle: 'Tasks, notes, events, goals, habits, reminders, and memories.')
              : _results.isEmpty
                  ? const EmptyState(icon: Icons.search_off, title: 'No matches', subtitle: 'Try a different word.')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _results.length,
                      itemBuilder: (context, i) {
                        final r = _results[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(r.icon),
                            title: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(r.subtitle),
                          ),
                        );
                      },
                    ),
    );
  }
}


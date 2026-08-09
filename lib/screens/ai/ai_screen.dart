import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/ai_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../models/models.dart';

class AiScreen extends StatefulWidget {
  const AiScreen({super.key});
  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  final _ai = AiService();
  final _fs = FirestoreService();
  final _notif = NotificationService();
  final _storage = const FlutterSecureStorage();
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(role: 'model', text: "How can I help? Aap mujhse tasks, reminders, notes, ya goals ke baare mein natural language mein baat kar sakte hain."));
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _inputCtrl.clear();
    setState(() {
      _messages.add(ChatMessage(role: 'user', text: text));
      _sending = true;
    });
    _scrollToBottom();

    final apiKey = await _storage.read(key: 'gemini_api_key') ?? '';
    final memories = (await _fs.memoriesOnce()).map((m) => m.content).toList();
    final history = _messages
        .where((m) => m.action == null)
        .map((m) => {'role': m.role, 'text': m.text})
        .toList();

    final result = await _ai.send(apiKey: apiKey, userMessage: text, history: history, memories: memories);

    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(
        role: 'model',
        text: result.reply,
        action: result.action != null ? ProposedAction(type: result.action!['type'] ?? '', data: Map<String, dynamic>.from(result.action!['data'] ?? {})) : null,
      ));
      _sending = false;
    });
    _scrollToBottom();
  }

  DateTime? _parseIso(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  Future<void> _confirmAction(ProposedAction action) async {
    switch (action.type) {
      case 'create_task':
        await _fs.addTask(TaskItem(
          id: '',
          title: action.data['title']?.toString() ?? '',
          description: action.data['description']?.toString() ?? '',
          priority: action.data['priority']?.toString() ?? 'medium',
          category: action.data['category']?.toString() ?? 'General',
          deadline: _parseIso(action.data['deadline']),
          createdAt: DateTime.now(),
        ));
        break;
      case 'create_reminder':
        final dt = _parseIso(action.data['dateTime']) ?? DateTime.now().add(const Duration(hours: 1));
        final notifId = NotificationService.idFromString(DateTime.now().microsecondsSinceEpoch.toString());
        await _fs.addReminder(ReminderItem(
          id: '',
          title: action.data['title']?.toString() ?? '',
          dateTime: dt,
          recurring: action.data['recurring']?.toString() ?? 'none',
          notificationId: notifId,
          createdAt: DateTime.now(),
        ));
        await _notif.scheduleReminder(id: notifId, title: action.data['title']?.toString() ?? '', dateTime: dt, recurring: action.data['recurring']?.toString() ?? 'none');
        break;
      case 'create_event':
        await _fs.addEvent(CalendarEventItem(
          id: '',
          title: action.data['title']?.toString() ?? '',
          startTime: _parseIso(action.data['startTime']) ?? DateTime.now(),
          endTime: _parseIso(action.data['endTime']),
          location: action.data['location']?.toString() ?? '',
          createdAt: DateTime.now(),
        ));
        break;
      case 'create_note':
        await _fs.addNote(NoteItem(
          id: '',
          title: action.data['title']?.toString() ?? '',
          body: action.data['body']?.toString() ?? '',
          tags: (action.data['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
          createdAt: DateTime.now(),
        ));
        break;
      case 'create_goal':
        await _fs.addGoal(GoalItem(
          id: '',
          title: action.data['title']?.toString() ?? '',
          description: action.data['description']?.toString() ?? '',
          targetDate: _parseIso(action.data['targetDate']),
          createdAt: DateTime.now(),
        ));
        break;
      case 'create_habit':
        await _fs.addHabit(HabitItem(
          id: '',
          name: action.data['name']?.toString() ?? '',
          frequency: action.data['frequency']?.toString() ?? 'daily',
          createdAt: DateTime.now(),
        ));
        break;
      case 'remember':
        await _fs.addMemory(action.data['content']?.toString() ?? '');
        break;
    }
    setState(() => action.resolved = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Done ✓'), duration: Duration(seconds: 1)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('AI Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_sending ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Align(alignment: Alignment.centerLeft, child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))),
                  );
                }
                final m = _messages[i];
                final isUser = m.role == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isUser ? theme.colorScheme.primary : theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(m.text, style: TextStyle(color: isUser ? Colors.white : theme.textTheme.bodyLarge?.color)),
                      ),
                      if (m.action != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ActionCard(action: m.action!, onConfirm: () => _confirmAction(m.action!)),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mic_none),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Voice mode is coming in a future update.')),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(hintText: 'Ask anything...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(icon: const Icon(Icons.arrow_upward), onPressed: _sending ? null : _send),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final ProposedAction action;
  final VoidCallback onConfirm;
  const _ActionCard({required this.action, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (action.resolved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text('Added', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
        ]),
      );
    }
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.secondary.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(action.summary, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton(onPressed: onConfirm, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)), child: const Text('Confirm')),
            ],
          ),
        ],
      ),
    );
  }
}

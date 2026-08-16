import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../models/models.dart';
import '../../services/ai_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

/// The chat screen for talking to the AI assistant. Every reply the model
/// gives can optionally carry a [ProposedAction] - the AI never writes to
/// Firestore directly, the user has to tap "Confirm" on the card first.
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
  final _speech = stt.SpeechToText();

  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  final List<ChatMessage> _messages = [];
  String? _apiKey;
  bool _sending = false;
  bool _speechAvailable = false;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
    _initSpeech();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    if (_listening) _speech.stop();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final key = await _storage.read(key: 'gemini_api_key');
    if (mounted) setState(() => _apiKey = key);
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize();
      if (mounted) setState(() => _speechAvailable = available);
    } catch (_) {
      // Mic permission denied or unsupported - the text field still works.
    }
  }

  Future<void> _toggleListen() async {
    if (!_speechAvailable) return;
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        setState(() => _inputCtrl.text = result.recognizedWords);
        if (result.finalResult) setState(() => _listening = false);
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    if (_listening) {
      await _speech.stop();
      _listening = false;
    }

    final history = _messages
        .map((m) => {'role': m.role, 'text': m.text})
        .toList(growable: false);

    setState(() {
      _messages.add(ChatMessage(role: 'user', text: text));
      _inputCtrl.clear();
      _sending = true;
    });
    _scrollToBottom();

    List<String> memories = const [];
    try {
      final items = await _fs.memoriesOnce();
      memories = items.map((m) => m.content).toList();
    } catch (_) {
      // Not signed in yet or offline - the AI can still chat without memory context.
    }

    final result = await _ai.send(
      apiKey: _apiKey ?? '',
      userMessage: text,
      history: history,
      memories: memories,
    );

    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(
        role: 'model',
        text: result.reply,
        action: result.action == null
            ? null
            : ProposedAction(
                type: result.action!['type']?.toString() ?? '',
                data: Map<String, dynamic>.from(result.action!['data'] ?? {}),
              ),
      ));
      _sending = false;
    });
    _scrollToBottom();
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  Future<void> _confirmAction(ChatMessage msg) async {
    final action = msg.action;
    if (action == null || action.resolved) return;
    final data = action.data;
    String? error;

    try {
      switch (action.type) {
        case 'create_task':
          await _fs.addTask(TaskItem(
            id: '',
            title: (data['title'] ?? '').toString(),
            description: (data['description'] ?? '').toString(),
            priority: (data['priority'] ?? 'medium').toString(),
            category: (data['category'] ?? 'General').toString(),
            deadline: _parseDate(data['deadline']),
            createdAt: DateTime.now(),
          ));
          break;

        case 'create_reminder':
          final when = _parseDate(data['dateTime']);
          if (when == null) {
            error = "Could not work out the reminder's date/time.";
            break;
          }
          final notificationId = NotificationService.idFromString(
              DateTime.now().microsecondsSinceEpoch.toString());
          final reminder = ReminderItem(
            id: '',
            title: (data['title'] ?? '').toString(),
            dateTime: when,
            recurring: (data['recurring'] ?? 'none').toString(),
            notificationId: notificationId,
            createdAt: DateTime.now(),
          );
          await _fs.addReminder(reminder);
          final scheduled = await _notif.scheduleReminder(
            id: notificationId,
            title: reminder.title,
            dateTime: reminder.dateTime,
            recurring: reminder.recurring,
          );
          if (!scheduled) {
            error = 'Reminder saved, but it could not be scheduled on this device.';
          }
          break;

        case 'create_event':
          final start = _parseDate(data['startTime']);
          if (start == null) {
            error = "Could not work out the event's start time.";
            break;
          }
          await _fs.addEvent(CalendarEventItem(
            id: '',
            title: (data['title'] ?? '').toString(),
            startTime: start,
            endTime: _parseDate(data['endTime']),
            location: (data['location'] ?? '').toString(),
            createdAt: DateTime.now(),
          ));
          break;

        case 'create_note':
          await _fs.addNote(NoteItem(
            id: '',
            title: (data['title'] ?? '').toString(),
            body: (data['body'] ?? '').toString(),
            tags: List<String>.from(data['tags'] ?? const []),
            createdAt: DateTime.now(),
          ));
          break;

        case 'create_goal':
          await _fs.addGoal(GoalItem(
            id: '',
            title: (data['title'] ?? '').toString(),
            description: (data['description'] ?? '').toString(),
            targetDate: _parseDate(data['targetDate']),
            createdAt: DateTime.now(),
          ));
          break;

        case 'create_habit':
          await _fs.addHabit(HabitItem(
            id: '',
            name: (data['name'] ?? '').toString(),
            frequency: (data['frequency'] ?? 'daily').toString(),
            createdAt: DateTime.now(),
          ));
          break;

        case 'create_transaction':
          final amount = data['amount'];
          await _fs.addTransaction(TransactionItem(
            id: '',
            type: (data['type'] ?? 'expense').toString(),
            amount: amount is num ? amount.toDouble() : double.tryParse(amount.toString()) ?? 0,
            category: (data['category'] ?? 'Other').toString(),
            note: (data['note'] ?? '').toString(),
            date: DateTime.now(),
            createdAt: DateTime.now(),
          ));
          break;

        case 'remember':
          await _fs.addMemory((data['content'] ?? '').toString());
          break;

        default:
          error = 'Unknown action type.';
      }
    } catch (e) {
      error = 'Could not save that: $e';
    }

    if (!mounted) return;
    setState(() => action.resolved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Done - saved to ${_sectionFor(action.type)}.')),
    );
  }

  String _sectionFor(String type) {
    switch (type) {
      case 'create_task':
        return 'Tasks';
      case 'create_reminder':
        return 'Reminders';
      case 'create_event':
        return 'Calendar';
      case 'create_note':
        return 'Notes';
      case 'create_goal':
        return 'Goals';
      case 'create_habit':
        return 'Habits';
      case 'create_transaction':
        return 'Money';
      case 'remember':
        return 'Memory';
      default:
        return 'the app';
    }
  }

  void _dismissAction(ChatMessage msg) {
    setState(() => msg.action?.resolved = true);
  }

  @override
  Widget build(BuildContext context) {
    final noKey = (_apiKey == null || _apiKey!.trim().isEmpty);
    return Scaffold(
      appBar: AppBar(title: const Text('AI Assistant')),
      body: Column(
        children: [
          if (noKey)
            Container(
              width: double.infinity,
              color: AppColors.accent.withValues(alpha: 0.12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Add your free Gemini API key in Settings to start chatting.',
                style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
              ),
            ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_outlined,
                              size: 56, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
                          const SizedBox(height: 16),
                          Text('Ask me anything', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Text(
                            'Try "remind me to call mom tomorrow at 6pm" or "add a task to pay rent".',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) => _MessageBubble(
                      message: _messages[i],
                      onConfirm: () => _confirmAction(_messages[i]),
                      onDismiss: () => _dismissAction(_messages[i]),
                    ),
                  ),
          ),
          if (_sending)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  if (_speechAvailable)
                    IconButton(
                      icon: Icon(_listening ? Icons.mic : Icons.mic_none,
                          color: _listening ? AppColors.accent : null),
                      onPressed: _toggleListen,
                    ),
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: _listening ? 'Listening...' : 'Message the assistant...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: _sending ? null : _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;
  const _MessageBubble({required this.message, required this.onConfirm, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final theme = Theme.of(context);
    final bubbleColor = isUser
        ? AppColors.primary
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = isUser ? Colors.white : theme.colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(message.text, style: TextStyle(color: textColor)),
            ),
            if (message.action != null && !message.action!.resolved)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(message.action!.summary, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(onPressed: onDismiss, child: const Text('Dismiss')),
                            const SizedBox(width: 4),
                            FilledButton(onPressed: onConfirm, child: const Text('Confirm')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

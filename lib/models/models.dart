import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _toDate(dynamic v) => v is Timestamp ? v.toDate() : null;

class TaskItem {
  final String id;
  final String title;
  final String description;
  final String priority; // low | medium | high
  final String category;
  final DateTime? deadline;
  final bool completed;
  final DateTime createdAt;

  TaskItem({
    required this.id,
    required this.title,
    this.description = '',
    this.priority = 'medium',
    this.category = 'General',
    this.deadline,
    this.completed = false,
    required this.createdAt,
  });

  factory TaskItem.fromMap(String id, Map<String, dynamic> m) => TaskItem(
        id: id,
        title: m['title'] ?? '',
        description: m['description'] ?? '',
        priority: m['priority'] ?? 'medium',
        category: m['category'] ?? 'General',
        deadline: _toDate(m['deadline']),
        completed: m['completed'] ?? false,
        createdAt: _toDate(m['createdAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'priority': priority,
        'category': category,
        'deadline': deadline == null ? null : Timestamp.fromDate(deadline!),
        'completed': completed,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class NoteItem {
  final String id;
  final String title;
  final String body;
  final List<String> tags;
  final DateTime createdAt;

  NoteItem({
    required this.id,
    required this.title,
    this.body = '',
    this.tags = const [],
    required this.createdAt,
  });

  factory NoteItem.fromMap(String id, Map<String, dynamic> m) => NoteItem(
        id: id,
        title: m['title'] ?? '',
        body: m['body'] ?? '',
        tags: List<String>.from(m['tags'] ?? const []),
        createdAt: _toDate(m['createdAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'tags': tags,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class GoalItem {
  final String id;
  final String title;
  final String description;
  final DateTime? targetDate;
  final int progress; // 0-100
  final DateTime createdAt;

  GoalItem({
    required this.id,
    required this.title,
    this.description = '',
    this.targetDate,
    this.progress = 0,
    required this.createdAt,
  });

  factory GoalItem.fromMap(String id, Map<String, dynamic> m) => GoalItem(
        id: id,
        title: m['title'] ?? '',
        description: m['description'] ?? '',
        targetDate: _toDate(m['targetDate']),
        progress: m['progress'] ?? 0,
        createdAt: _toDate(m['createdAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'targetDate': targetDate == null ? null : Timestamp.fromDate(targetDate!),
        'progress': progress,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class HabitItem {
  final String id;
  final String name;
  final String frequency; // 'daily' or comma list e.g. 'mon,wed,fri'
  final int streak;
  final DateTime? lastCompleted;
  final DateTime createdAt;

  HabitItem({
    required this.id,
    required this.name,
    this.frequency = 'daily',
    this.streak = 0,
    this.lastCompleted,
    required this.createdAt,
  });

  bool get doneToday {
    if (lastCompleted == null) return false;
    final now = DateTime.now();
    return lastCompleted!.year == now.year && lastCompleted!.month == now.month && lastCompleted!.day == now.day;
  }

  factory HabitItem.fromMap(String id, Map<String, dynamic> m) => HabitItem(
        id: id,
        name: m['name'] ?? '',
        frequency: m['frequency'] ?? 'daily',
        streak: m['streak'] ?? 0,
        lastCompleted: _toDate(m['lastCompleted']),
        createdAt: _toDate(m['createdAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'frequency': frequency,
        'streak': streak,
        'lastCompleted': lastCompleted == null ? null : Timestamp.fromDate(lastCompleted!),
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class ReminderItem {
  final String id;
  final String title;
  final DateTime dateTime;
  final String recurring; // none | daily | weekly
  final String sound; // alarm | notification | ringtone
  final int notificationId;
  final DateTime createdAt;

  ReminderItem({
    required this.id,
    required this.title,
    required this.dateTime,
    this.recurring = 'none',
    this.sound = 'alarm',
    required this.notificationId,
    required this.createdAt,
  });

  factory ReminderItem.fromMap(String id, Map<String, dynamic> m) => ReminderItem(
        id: id,
        title: m['title'] ?? '',
        dateTime: _toDate(m['dateTime']) ?? DateTime.now(),
        recurring: m['recurring'] ?? 'none',
        sound: m['sound'] ?? 'alarm',
        notificationId: m['notificationId'] ?? 0,
        createdAt: _toDate(m['createdAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'dateTime': Timestamp.fromDate(dateTime),
        'recurring': recurring,
        'sound': sound,
        'notificationId': notificationId,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class CalendarEventItem {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime? endTime;
  final String location;
  final String notes;
  final DateTime createdAt;

  CalendarEventItem({
    required this.id,
    required this.title,
    required this.startTime,
    this.endTime,
    this.location = '',
    this.notes = '',
    required this.createdAt,
  });

  factory CalendarEventItem.fromMap(String id, Map<String, dynamic> m) => CalendarEventItem(
        id: id,
        title: m['title'] ?? '',
        startTime: _toDate(m['startTime']) ?? DateTime.now(),
        endTime: _toDate(m['endTime']),
        location: m['location'] ?? '',
        notes: m['notes'] ?? '',
        createdAt: _toDate(m['createdAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': endTime == null ? null : Timestamp.fromDate(endTime!),
        'location': location,
        'notes': notes,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class TransactionItem {
  final String id;
  final String type; // income | expense
  final double amount;
  final String category;
  final String note;
  final DateTime date;
  final DateTime createdAt;

  TransactionItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    this.note = '',
    required this.date,
    required this.createdAt,
  });

  factory TransactionItem.fromMap(String id, Map<String, dynamic> m) => TransactionItem(
        id: id,
        type: m['type'] ?? 'expense',
        amount: (m['amount'] ?? 0).toDouble(),
        category: m['category'] ?? 'Other',
        note: m['note'] ?? '',
        date: _toDate(m['date']) ?? DateTime.now(),
        createdAt: _toDate(m['createdAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'type': type,
        'amount': amount,
        'category': category,
        'note': note,
        'date': Timestamp.fromDate(date),
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class LocationReminderItem {
  final String id;
  final String title;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final DateTime createdAt;

  LocationReminderItem({
    required this.id,
    required this.title,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 200,
    required this.createdAt,
  });

  factory LocationReminderItem.fromMap(String id, Map<String, dynamic> m) => LocationReminderItem(
        id: id,
        title: m['title'] ?? '',
        latitude: (m['latitude'] ?? 0).toDouble(),
        longitude: (m['longitude'] ?? 0).toDouble(),
        radiusMeters: (m['radiusMeters'] ?? 200).toDouble(),
        createdAt: _toDate(m['createdAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class MemoryItem {
  final String id;
  final String content;
  final DateTime createdAt;

  MemoryItem({required this.id, required this.content, required this.createdAt});

  factory MemoryItem.fromMap(String id, Map<String, dynamic> m) => MemoryItem(
        id: id,
        content: m['content'] ?? '',
        createdAt: _toDate(m['createdAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'content': content,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

/// Local-only (not persisted to Firestore) chat message for the AI screen.
class ChatMessage {
  final String role; // 'user' | 'model'
  final String text;
  final ProposedAction? action;

  ChatMessage({required this.role, required this.text, this.action});
}

/// A structured action the AI proposed, waiting for the user's confirmation
/// before it is written to Firestore. Mirrors the "action layer" from the
/// app plan: the AI never writes data directly.
class ProposedAction {
  final String type; // create_task | create_reminder | create_event | create_note | create_goal | create_habit | remember
  final Map<String, dynamic> data;
  bool resolved;

  ProposedAction({required this.type, required this.data, this.resolved = false});

  String get summary {
    switch (type) {
      case 'create_task':
        return 'Task: ${data['title'] ?? ''}';
      case 'create_reminder':
        return 'Reminder: ${data['title'] ?? ''} — ${data['dateTime'] ?? ''}';
      case 'create_event':
        return 'Event: ${data['title'] ?? ''} — ${data['startTime'] ?? ''}';
      case 'create_note':
        return 'Note: ${data['title'] ?? ''}';
      case 'create_goal':
        return 'Goal: ${data['title'] ?? ''}';
      case 'create_habit':
        return 'Habit: ${data['name'] ?? ''}';
      case 'create_transaction':
        return '${data['type'] == 'income' ? 'Income' : 'Expense'}: ${data['category'] ?? ''} — ${data['amount'] ?? ''}';
      case 'remember':
        return 'Remember: ${data['content'] ?? ''}';
      default:
        return type;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';

/// Every read/write goes through here, scoped to users/{uid}/... so the
/// Firestore security rules (see firestore.rules) can enforce that a user
/// only ever touches their own data.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not signed in');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _col(String name) =>
      _db.collection('users').doc(_uid).collection(name);

  // ---------- Onboarding ----------
  Future<bool> isOnboardingComplete() async {
    try {
      final doc = await _db.collection('users').doc(_uid).get();
      return doc.data()?['onboardingComplete'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> markOnboardingComplete() async {
    await _db.collection('users').doc(_uid).set({'onboardingComplete': true}, SetOptions(merge: true));
  }

  // ---------- Tasks ----------
  Stream<List<TaskItem>> tasksStream() => _col('tasks')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => TaskItem.fromMap(d.id, d.data())).toList());

  Future<void> addTask(TaskItem t) => _col('tasks').add(t.toMap());
  Future<void> updateTask(TaskItem t) => _col('tasks').doc(t.id).update(t.toMap());
  Future<void> deleteTask(String id) => _col('tasks').doc(id).delete();

  // ---------- Notes ----------
  Stream<List<NoteItem>> notesStream() => _col('notes')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => NoteItem.fromMap(d.id, d.data())).toList());

  Future<void> addNote(NoteItem n) => _col('notes').add(n.toMap());
  Future<void> updateNote(NoteItem n) => _col('notes').doc(n.id).update(n.toMap());
  Future<void> deleteNote(String id) => _col('notes').doc(id).delete();

  // ---------- Goals ----------
  Stream<List<GoalItem>> goalsStream() => _col('goals')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => GoalItem.fromMap(d.id, d.data())).toList());

  Future<void> addGoal(GoalItem g) => _col('goals').add(g.toMap());
  Future<void> updateGoal(GoalItem g) => _col('goals').doc(g.id).update(g.toMap());
  Future<void> deleteGoal(String id) => _col('goals').doc(id).delete();

  // ---------- Habits ----------
  Stream<List<HabitItem>> habitsStream() => _col('habits')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => HabitItem.fromMap(d.id, d.data())).toList());

  Future<void> addHabit(HabitItem h) => _col('habits').add(h.toMap());
  Future<void> updateHabit(HabitItem h) => _col('habits').doc(h.id).update(h.toMap());
  Future<void> deleteHabit(String id) => _col('habits').doc(id).delete();

  // ---------- Reminders ----------
  Stream<List<ReminderItem>> remindersStream() => _col('reminders')
      .orderBy('dateTime')
      .snapshots()
      .map((s) => s.docs.map((d) => ReminderItem.fromMap(d.id, d.data())).toList());

  Future<String> addReminder(ReminderItem r) async {
    final doc = await _col('reminders').add(r.toMap());
    return doc.id;
  }

  Future<void> updateReminder(ReminderItem r) => _col('reminders').doc(r.id).update(r.toMap());
  Future<void> deleteReminder(String id) => _col('reminders').doc(id).delete();

  // ---------- Calendar Events ----------
  Stream<List<CalendarEventItem>> eventsStream() => _col('events')
      .orderBy('startTime')
      .snapshots()
      .map((s) => s.docs.map((d) => CalendarEventItem.fromMap(d.id, d.data())).toList());

  Future<void> addEvent(CalendarEventItem e) => _col('events').add(e.toMap());
  Future<void> updateEvent(CalendarEventItem e) => _col('events').doc(e.id).update(e.toMap());
  Future<void> deleteEvent(String id) => _col('events').doc(id).delete();

  // ---------- Location-based Reminders ----------
  Stream<List<LocationReminderItem>> locationRemindersStream() => _col('locationReminders')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => LocationReminderItem.fromMap(d.id, d.data())).toList());

  Future<List<LocationReminderItem>> locationRemindersOnce() async {
    final snap = await _col('locationReminders').get();
    return snap.docs.map((d) => LocationReminderItem.fromMap(d.id, d.data())).toList();
  }

  Future<void> addLocationReminder(LocationReminderItem r) => _col('locationReminders').add(r.toMap());
  Future<void> deleteLocationReminder(String id) => _col('locationReminders').doc(id).delete();

  // ---------- Money (Transactions) ----------
  Stream<List<TransactionItem>> transactionsStream() => _col('transactions')
      .orderBy('date', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => TransactionItem.fromMap(d.id, d.data())).toList());

  Future<void> addTransaction(TransactionItem t) => _col('transactions').add(t.toMap());
  Future<void> deleteTransaction(String id) => _col('transactions').doc(id).delete();

  // ---------- Memories (things the AI has been told to remember) ----------
  Stream<List<MemoryItem>> memoriesStream() => _col('memories')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => MemoryItem.fromMap(d.id, d.data())).toList());

  Future<void> addMemory(String content) =>
      _col('memories').add({'content': content, 'createdAt': Timestamp.now()});
  Future<void> deleteMemory(String id) => _col('memories').doc(id).delete();

  Future<List<MemoryItem>> memoriesOnce() async {
    final snap = await _col('memories').orderBy('createdAt', descending: true).limit(30).get();
    return snap.docs.map((d) => MemoryItem.fromMap(d.id, d.data())).toList();
  }

  // ---------- Dashboard helpers ----------
  Future<int> countPending(String collection) async {
    final snap = await _col(collection).get();
    return snap.docs.length;
  }

  // ---------- One-time fetches (used by Universal Search) ----------
  Future<List<TaskItem>> tasksOnce() async {
    final snap = await _col('tasks').get();
    return snap.docs.map((d) => TaskItem.fromMap(d.id, d.data())).toList();
  }

  Future<List<NoteItem>> notesOnce() async {
    final snap = await _col('notes').get();
    return snap.docs.map((d) => NoteItem.fromMap(d.id, d.data())).toList();
  }

  Future<List<GoalItem>> goalsOnce() async {
    final snap = await _col('goals').get();
    return snap.docs.map((d) => GoalItem.fromMap(d.id, d.data())).toList();
  }

  Future<List<HabitItem>> habitsOnce() async {
    final snap = await _col('habits').get();
    return snap.docs.map((d) => HabitItem.fromMap(d.id, d.data())).toList();
  }

  Future<List<CalendarEventItem>> eventsOnce() async {
    final snap = await _col('events').get();
    return snap.docs.map((d) => CalendarEventItem.fromMap(d.id, d.data())).toList();
  }

  Future<List<ReminderItem>> remindersOnce() async {
    final snap = await _col('reminders').get();
    return snap.docs.map((d) => ReminderItem.fromMap(d.id, d.data())).toList();
  }

  // ---------- Account deletion ----------
  /// Deletes every document across every collection for the current user,
  /// then the user's own root document. Used by "Delete my account" in
  /// Settings, right before the Firebase Auth account itself is deleted.
  Future<void> deleteAllUserData() async {
    const collections = ['tasks', 'notes', 'goals', 'habits', 'reminders', 'events', 'memories', 'transactions'];
    for (final name in collections) {
      final snap = await _col(name).get();
      for (final doc in snap.docs) {
        await doc.reference.delete();
      }
    }
    await _db.collection('users').doc(_uid).delete();
  }

  // ---------- Data export ----------
  Future<Map<String, dynamic>> exportAllData() async {
    final tasks = await tasksOnce();
    final notes = await notesOnce();
    final goals = await goalsOnce();
    final habits = await habitsOnce();
    final events = await eventsOnce();
    final reminders = await remindersOnce();
    final memories = await memoriesOnce();
    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'tasks': tasks.map((t) => {'title': t.title, 'priority': t.priority, 'category': t.category, 'completed': t.completed, 'deadline': t.deadline?.toIso8601String()}).toList(),
      'notes': notes.map((n) => {'title': n.title, 'body': n.body, 'tags': n.tags}).toList(),
      'goals': goals.map((g) => {'title': g.title, 'description': g.description, 'progress': g.progress}).toList(),
      'habits': habits.map((h) => {'name': h.name, 'frequency': h.frequency, 'streak': h.streak}).toList(),
      'events': events.map((e) => {'title': e.title, 'startTime': e.startTime.toIso8601String(), 'location': e.location}).toList(),
      'reminders': reminders.map((r) => {'title': r.title, 'dateTime': r.dateTime.toIso8601String(), 'recurring': r.recurring}).toList(),
      'memories': memories.map((m) => m.content).toList(),
    };
  }
}

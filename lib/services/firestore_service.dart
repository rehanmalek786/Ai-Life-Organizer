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
}

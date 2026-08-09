import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';

/// Wraps flutter_local_notifications so reminders fire even when the app
/// is closed. Uses inexact-while-idle-allowed exact scheduling; on some
/// Android versions the user may need to grant "Alarms & reminders" in
/// system settings for precise timing (requested automatically on init).
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    try {
      final String localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

    if (Platform.isAndroid) {
      final androidImpl =
          _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
      await androidImpl?.requestExactAlarmsPermission();
    }
    _initialized = true;
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required DateTime dateTime,
    String recurring = 'none',
  }) async {
    await init();
    if (dateTime.isBefore(DateTime.now())) return;
    final scheduled = tz.TZDateTime.from(dateTime, tz.local);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders_channel',
        'Reminders',
        channelDescription: 'Task and life reminders from AI Life Organizer',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    DateTimeComponents? match;
    if (recurring == 'daily') match = DateTimeComponents.time;
    if (recurring == 'weekly') match = DateTimeComponents.dayOfWeekAndTime;

    await _plugin.zonedSchedule(
      id,
      title,
      'Reminder from AI Life Organizer',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: match,
    );
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  /// Turns a Firestore doc id into a stable 32-bit int for the plugin.
  static int idFromString(String s) => s.hashCode & 0x7FFFFFFF;
}

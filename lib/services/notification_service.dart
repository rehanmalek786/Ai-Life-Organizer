import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';

/// Which system sound category a reminder should ring with. These map to
/// Android's own system default sounds (whatever the user already has set
/// as their phone's alarm/notification/ringtone sound) - no custom audio
/// files needed, and no extra permission beyond notifications.
enum ReminderSound { alarm, notification, ringtone }

extension ReminderSoundLabel on ReminderSound {
  String get label {
    switch (this) {
      case ReminderSound.alarm:
        return 'Alarm (loud)';
      case ReminderSound.notification:
        return 'Notification';
      case ReminderSound.ringtone:
        return 'Ringtone';
    }
  }

  static ReminderSound fromName(String? name) {
    return ReminderSound.values.firstWhere((s) => s.name == name, orElse: () => ReminderSound.alarm);
  }
}

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
    try {
      await _plugin.initialize(initSettings);
    } catch (_) {
      // Non-fatal - continue so scheduling attempts can still surface a clear error.
    }

    if (Platform.isAndroid) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      try {
        await androidImpl?.requestNotificationsPermission();
      } catch (_) {}
      try {
        await androidImpl?.requestExactAlarmsPermission();
      } catch (_) {}
    }
    _initialized = true;
  }

  /// Whether this device currently allows to-the-second exact scheduling.
  /// If false, reminders still fire (see scheduleReminder's fallback) just
  /// within a short window instead of at the exact minute.
  Future<bool> canScheduleExact() async {
    if (!Platform.isAndroid) return true;
    await init();
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    try {
      return await androidImpl?.canScheduleExactNotifications() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the system screen where the user can grant exact-alarm access.
  Future<void> requestExactAlarmAccess() async {
    if (!Platform.isAndroid) return;
    await init();
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    try {
      await androidImpl?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  String _soundUri(ReminderSound sound) {
    switch (sound) {
      case ReminderSound.alarm:
        return 'content://settings/system/alarm_alert';
      case ReminderSound.ringtone:
        return 'content://settings/system/ringtone';
      case ReminderSound.notification:
        return 'content://settings/system/notification_sound';
    }
  }

  AndroidNotificationDetails _reminderDetails(ReminderSound sound) {
    return AndroidNotificationDetails(
      'reminders_channel_v2',
      'Reminders',
      channelDescription: 'Task and life reminders from AI Life Organizer',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      sound: UriAndroidNotificationSound(_soundUri(sound)),
      playSound: true,
      enableVibration: true,
    );
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required DateTime dateTime,
    String recurring = 'none',
    ReminderSound sound = ReminderSound.alarm,
  }) async {
    await init();
    if (dateTime.isBefore(DateTime.now())) return;
    final scheduled = tz.TZDateTime.from(dateTime, tz.local);
    final details = NotificationDetails(android: _reminderDetails(sound));

    DateTimeComponents? match;
    if (recurring == 'daily') match = DateTimeComponents.time;
    if (recurring == 'weekly') match = DateTimeComponents.dayOfWeekAndTime;

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        'Reminder from AI Life Organizer',
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: match,
      );
      return;
    } catch (_) {
      // Exact alarms need a permission that isn't granted on this device -
      // fall back to inexact so the reminder still fires (within a short
      // window) instead of silently never firing at all.
    }

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        'Reminder from AI Life Organizer',
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: match,
      );
    } catch (_) {
      // If even this fails, there's nothing more we can silently do - the
      // Settings > Notifications > "Send test notification" button is the
      // way to confirm whether notifications work at all on this device.
    }
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  /// Shows a notification immediately (used by location-based reminders
  /// and the Settings test button).
  Future<void> showNow({required int id, required String title, required String body}) async {
    await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'instant_channel',
        'Instant notifications',
        channelDescription: 'Immediate alerts (location reminders, test notification)',
        importance: Importance.max,
        priority: Priority.max,
      ),
    );
    try {
      await _plugin.show(id, title, body, details);
    } catch (_) {}
  }

  Future<void> sendTestNotification() async {
    await showNow(
      id: 999999,
      title: 'Test notification',
      body: 'If you can see this, notifications are working on this phone.',
    );
  }

  /// Turns a Firestore doc id (or any string) into a stable 32-bit int for the plugin.
  static int idFromString(String s) => s.hashCode & 0x7FFFFFFF;
}

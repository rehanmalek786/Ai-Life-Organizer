import 'package:geolocator/geolocator.dart';
import 'firestore_service.dart';
import 'notification_service.dart';
import '../models/models.dart';

/// Checks the user's current position against saved location reminders and
/// fires a local notification when they're within range.
///
/// Note: this checks periodically WHILE THE APP IS OPEN (foreground) and
/// each time the app is resumed - it intentionally does not run a
/// background service, since Android's background-location + foreground-
/// service requirements are the single most failure-prone, OEM-dependent
/// part of the platform to get right without on-device testing. This
/// still covers the common case well (reminders fire when you open the
/// app near the saved place) without risking a flaky background service.
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final FirestoreService _fs = FirestoreService();
  final NotificationService _notif = NotificationService();
  final Set<String> _recentlyTriggered = {};

  Future<bool> ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
      return false;
    }
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    return serviceEnabled;
  }

  Future<Position?> currentPosition() async {
    final ok = await ensurePermission();
    if (!ok) return null;
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> checkNow() async {
    final pos = await currentPosition();
    if (pos == null) return;

    final reminders = await _fs.locationRemindersOnce();
    for (final r in reminders) {
      final distance = Geolocator.distanceBetween(pos.latitude, pos.longitude, r.latitude, r.longitude);
      if (distance <= r.radiusMeters) {
        if (!_recentlyTriggered.contains(r.id)) {
          _recentlyTriggered.add(r.id);
          await _notif.showNow(
            id: NotificationService.idFromString('loc_${r.id}'),
            title: r.title,
            body: 'You are near this place.',
          );
        }
      } else if (distance > r.radiusMeters * 1.5) {
        // far enough away again - allow it to re-trigger next time they arrive
        _recentlyTriggered.remove(r.id);
      }
    }
  }
}


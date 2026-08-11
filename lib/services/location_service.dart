import 'package:geolocator/geolocator.dart';
import 'firestore_service.dart';
import 'notification_service.dart';

/// Foreground-only location reminders: checks the user's current GPS
/// position against saved LocationReminderItems and fires a local
/// notification when they're within range. Not a background service -
/// see the note in LocationRemindersScreen.
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final _fs = FirestoreService();
  final _notif = NotificationService();

  /// Set of reminder ids already notified this app session, so the same
  /// reminder doesn't spam the user every time checkNow() runs while
  /// they're still standing in the same spot.
  final Set<String> _notifiedThisSession = {};

  /// Returns the device's current position, or null if location services
  /// are off, permission is denied, or fetching it fails for any reason.
  Future<Position?> currentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (_) {
      return null;
    }
  }

  /// Checks all saved location reminders against the current position and
  /// notifies for any the user is currently within range of. Safe to call
  /// repeatedly (e.g. on app resume) - silently does nothing if location
  /// isn't available or there are no reminders.
  Future<void> checkNow() async {
    try {
      final pos = await currentPosition();
      if (pos == null) return;

      final reminders = await _fs.locationRemindersOnce();
      for (final r in reminders) {
        final distance = Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          r.latitude,
          r.longitude,
        );
        if (distance <= r.radiusMeters) {
          if (_notifiedThisSession.contains(r.id)) continue;
          _notifiedThisSession.add(r.id);
          await _notif.showNow(
            id: NotificationService.idFromString(r.id),
            title: r.title,
            body: 'You are near this location reminder.',
          );
        } else {
          // Left the radius - allow re-notifying if they come back later.
          _notifiedThisSession.remove(r.id);
        }
      }
    } catch (_) {
      // Non-fatal - a failed check just means no notification this pass.
    }
  }
}


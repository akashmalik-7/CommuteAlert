import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/alarm_model.dart';
import 'notification_service.dart';

class LocationService {
  LocationService._();
  static final instance = LocationService._();
  StreamSubscription<Position>? _subscription;
  String? _activeAlarmId;
  bool _notified = false;

  Future<String?> start(AlarmModel alarm) async {
    if (alarm.latitude == null || alarm.longitude == null) {
      return 'This stop does not have coordinates in Firestore.';
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      return 'Location services are disabled. Enable GPS and try again.';
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return 'Location permission was denied.';
    }
    if (permission == LocationPermission.deniedForever) {
      return 'Location permission is permanently denied. Enable it in Settings.';
    }
    await stop();
    _activeAlarmId = alarm.id;
    _notified = false;
    _subscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 25,
          ),
        ).listen(
          (position) async {
            if (_notified) return;
            final distance = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              alarm.latitude!,
              alarm.longitude!,
            );
            if (distance <= (alarm.thresholdMeters ?? 250)) {
              _notified = true;
              await NotificationService.instance.plugin.show(
                alarm.id.hashCode.abs() % 100000,
                'Bus stop approaching',
                'You are approaching ${alarm.stopName ?? 'your selected bus stop'}.',
                const NotificationDetails(
                  android: AndroidNotificationDetails(
                    'commute_alerts',
                    'Commute alerts',
                    channelDescription: 'Journey and bus stop reminders',
                    importance: Importance.high,
                    priority: Priority.high,
                  ),
                  iOS: DarwinNotificationDetails(),
                ),
              );
            }
          },
          onError: (_) {
            _notified = false;
          },
        );
    return null;
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _activeAlarmId = null;
    _notified = false;
  }

  bool isActive(String id) => _activeAlarmId == id;
}

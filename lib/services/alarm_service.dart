import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_model.dart';
import 'notification_service.dart';

class AlarmService {
  AlarmService._();
  static final instance = AlarmService._();
  static const _key = 'saved_alarms';
  final alarms = <AlarmModel>[];

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_key) ?? [];
    alarms.clear();
    for (final value in values) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          alarms.add(AlarmModel.fromJson(decoded));
        } else if (decoded is Map) {
          alarms.add(AlarmModel.fromJson(Map<String, dynamic>.from(decoded)));
        }
      } catch (_) {
        // Ignore corrupt local entries instead of aborting app startup.
      }
    }
    for (final alarm in alarms.where(
      (alarm) => alarm.type == AlarmType.timer && alarm.enabled,
    )) {
      try {
        await _scheduleTimer(alarm);
      } catch (_) {
        // An unavailable notification scheduler must not prevent app startup.
      }
    }
  }

  Future<void> save(AlarmModel alarm) async {
    final duplicate = alarms.any(
      (old) =>
          old.id != alarm.id &&
          old.type == alarm.type &&
          old.routeId == alarm.routeId &&
          old.hour == alarm.hour &&
          old.minute == alarm.minute &&
          old.stopId == alarm.stopId,
    );
    if (duplicate) throw StateError('A matching alarm already exists.');
    await delete(alarm.id);
    alarms.add(alarm);
    await _persist();
    if (alarm.enabled && alarm.type == AlarmType.timer) {
      await _scheduleTimer(alarm);
    }
  }

  Future<void> update(AlarmModel alarm) => save(alarm);

  Future<void> delete(String id) async {
    final old = alarms.where((alarm) => alarm.id == id).firstOrNull;
    if (old != null) {
      for (var day = 1; day <= 7; day++) {
        await NotificationService.instance.cancel(_notificationId(old, day));
      }
    }
    alarms.removeWhere((alarm) => alarm.id == id);
    await _persist();
  }

  Future<void> setEnabled(AlarmModel alarm, bool enabled) async {
    await update(alarm.copyWith(enabled: enabled));
  }

  Future<void> _scheduleTimer(AlarmModel alarm) async {
    final days = alarm.repeatDays.isEmpty
        ? [DateTime.now().weekday]
        : alarm.repeatDays;
    for (final day in days) {
      final now = DateTime.now();
      var date = DateTime(
        now.year,
        now.month,
        now.day,
        alarm.hour!,
        alarm.minute!,
      );
      while (date.weekday != day || !date.isAfter(now)) {
        date = date.add(const Duration(days: 1));
      }
      await NotificationService.instance.schedule(
        _notificationId(alarm, day),
        date,
        'Journey reminder',
        'Your journey reminder is due for ${alarm.routeName}. Get ready for your selected route.',
        weekly: alarm.repeatDays.isNotEmpty,
      );
    }
  }

  int _notificationId(AlarmModel alarm, int day) =>
      alarm.id.hashCode.abs() % 100000 * 10 + day;

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      alarms.map((alarm) => jsonEncode(alarm.toJson())).toList(),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

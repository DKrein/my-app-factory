import 'package:factory_storage/factory_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Schedules the daily "It's Capytime!" local notification and persists the
/// user's on/off + time choice. A single instance is shared by `main()`
/// (which restores any previously scheduled reminder on app start) and the
/// Settings sheet (which lets the user turn it on/off and pick a time).
class BedtimeReminderService {
  BedtimeReminderService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _notificationId = 1001;
  static const _enabledKey = 'bedtime_reminder_enabled_v1';
  static const _timeKey = 'bedtime_reminder_time_v1';
  static const defaultTime = TimeOfDay(hour: 22, minute: 30);

  Future<void> init() async {
    tz_data.initializeTimeZones();
    // No native timezone lookup: approximate the device's zone from its
    // current UTC offset. Good enough for a daily local reminder; only
    // drifts by an hour on the rare day of a DST transition.
    final offset = DateTime.now().timeZoneOffset;
    final sign = offset.isNegative ? '+' : '-';
    tz.setLocalLocation(tz.getLocation('Etc/GMT$sign${offset.abs().inHours}'));

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings(
          'drawable/ic_launcher_monochrome',
        ),
      ),
    );
  }

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    return await android.requestNotificationsPermission() ?? false;
  }

  Future<void> schedule(TimeOfDay time) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _notificationId,
      "It's Capytime!",
      "It's Capytime! Time to get cozy and sleepy.",
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bedtime_reminder',
          'Bedtime reminder',
          channelDescription: 'Daily reminder to wind down for sleep',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancel() => _plugin.cancel(_notificationId);

  /// Reads the persisted on/off + time choice without scheduling anything.
  Future<(bool enabled, TimeOfDay time)> readState(
    KeyValueStore storage,
  ) async {
    final enabled = await storage.readString(_enabledKey) == '1';
    final stored = await storage.readString(_timeKey);
    final time = _parseTime(stored) ?? defaultTime;
    return (enabled, time);
  }

  Future<void> save(
    KeyValueStore storage, {
    required bool enabled,
    TimeOfDay? time,
  }) async {
    await storage.writeString(_enabledKey, enabled ? '1' : '0');
    if (time != null) {
      await storage.writeString(_timeKey, '${time.hour}:${time.minute}');
    }
  }

  /// Re-schedules the reminder on app start if it was left enabled — local
  /// notifications don't reliably survive a device reboot otherwise.
  Future<void> restore(KeyValueStore storage) async {
    final (enabled, time) = await readState(storage);
    if (enabled) {
      await schedule(time);
    }
  }

  TimeOfDay? _parseTime(String? raw) {
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }
}

final bedtimeReminders = BedtimeReminderService();

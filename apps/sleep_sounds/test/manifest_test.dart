import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards for the things that only fail on a real phone, or at the store.
void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml')
      .readAsStringSync();

  Set<String> permissions() => {
    for (final m in RegExp(
      r'<uses-permission[^>]*android:name="([^"]+)"',
    ).allMatches(manifest))
      m.group(1)!,
  };

  group('permissions', () {
    test('the app asks for exactly these', () {
      expect(permissions(), {
        'android.permission.WAKE_LOCK',
        'android.permission.FOREGROUND_SERVICE',
        'android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK',
        'android.permission.POST_NOTIFICATIONS',
        'android.permission.RECEIVE_BOOT_COMPLETED',
      });
    });

    test('nothing that Google Play restricts or that needs a declaration', () {
      for (final banned in [
        'REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
        'SCHEDULE_EXACT_ALARM',
        'USE_EXACT_ALARM',
        'RECORD_AUDIO',
        'CAMERA',
        'ACCESS_FINE_LOCATION',
        'ACCESS_COARSE_LOCATION',
        'READ_EXTERNAL_STORAGE',
        'WRITE_EXTERNAL_STORAGE',
        'READ_CONTACTS',
        'READ_PHONE_STATE',
        'SYSTEM_ALERT_WINDOW',
      ]) {
        expect(manifest, isNot(contains(banned)), reason: banned);
      }
    });
  });

  group('the bedtime reminder can fire', () {
    test('the scheduled notification receiver is declared', () {
      expect(
        manifest,
        contains(
          'com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver',
        ),
      );
    });

    test('and it is scheduled again after a restart or an update', () {
      final boot = RegExp(
        r'<receiver[^>]*ScheduledNotificationBootReceiver.*?</receiver>',
        dotAll: true,
      ).firstMatch(manifest);

      expect(boot, isNotNull);
      expect(boot!.group(0), contains('android.intent.action.BOOT_COMPLETED'));
      expect(
        boot.group(0),
        contains('android.intent.action.MY_PACKAGE_REPLACED'),
      );
    });

    test('the receivers are private to the app', () {
      final receivers = RegExp(
        r'<receiver[^>]*flutterlocalnotifications[^>]*>',
        dotAll: true,
      ).allMatches(manifest);

      expect(receivers, isNotEmpty);
      for (final r in receivers) {
        expect(r.group(0), contains('android:exported="false"'));
      }
    });
  });

  test('the links the About screen opens can be resolved on Android 11+', () {
    expect(manifest, contains('<queries>'));
    expect(manifest, contains('android:scheme="https"'));
    expect(manifest, contains('android:scheme="mailto"'));
  });
}

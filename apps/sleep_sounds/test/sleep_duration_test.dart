import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_sounds/features/player/sleep_duration.dart';

void main() {
  test('offers Off and 15m to 12h, defaulting to 1h', () {
    expect(sleepDurations.map((d) => d.label), [
      'Off',
      '15m',
      '30m',
      '1h',
      '3h',
      '6h',
      '9h',
      '12h',
    ]);
    expect(defaultSleepMinutes, 60);
  });

  group('formatSleepRemaining', () {
    test('formats hours and minutes at or above one hour', () {
      expect(formatSleepRemaining(43200), equals('12h 00m'));
      expect(formatSleepRemaining(86340), equals('23h 59m'));
      expect(formatSleepRemaining(3600), equals('1h 00m'));
    });

    test('formats minutes and seconds below one hour', () {
      expect(formatSleepRemaining(3599), equals('59:59'));
      expect(formatSleepRemaining(1790), equals('29:50'));
      expect(formatSleepRemaining(0), equals('0:00'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_sounds/features/player/sleep_duration.dart';

void main() {
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

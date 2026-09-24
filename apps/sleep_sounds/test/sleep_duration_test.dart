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

  group('custom labels and carousel choices', () {
    test('a custom duration is written as hours and minutes', () {
      expect(customDurationLabel(45), '45m');
      expect(customDurationLabel(150), '2h 30m');
      expect(customDurationLabel(300), '5h');
      expect(customDurationLabel(1439), '23h 59m');
    });

    test('presets alone when the timer is a preset', () {
      final labels = sleepDurationChoices(timerMinutes: 60).map((d) => d.label);

      expect(labels, sleepDurations.map((d) => d.label));
    });

    test('a custom duration sits in order among the presets', () {
      final labels = sleepDurationChoices(timerMinutes: 150)
          .map((d) => d.label);

      expect(labels, [
        'Off',
        '15m',
        '30m',
        '1h',
        '2h 30m',
        '3h',
        '6h',
        '9h',
        '12h',
      ]);
    });

    test('a custom duration longer than all presets goes last', () {
      final labels = sleepDurationChoices(timerMinutes: 900)
          .map((d) => d.label);

      expect(labels.last, '15h');
    });

    test('a stop-at time is added after everything else', () {
      final choices = sleepDurationChoices(
        timerMinutes: 60,
        stopAtLabel: '6:30 AM',
      );

      expect(choices.last.label, '6:30 AM');
      expect(choices.last.minutes, stopAtMinutes);
      expect(choices, hasLength(sleepDurations.length + 1));
    });

    test('Off never gets a custom item', () {
      expect(
        sleepDurationChoices(timerMinutes: 0),
        hasLength(sleepDurations.length),
      );
    });
  });
}

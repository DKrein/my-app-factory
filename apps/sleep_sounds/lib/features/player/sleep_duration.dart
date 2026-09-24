class SleepDuration {
  const SleepDuration(this.minutes, this.label);
  final int minutes;
  final String label;
}

const sleepDurations = <SleepDuration>[
  SleepDuration(0, 'Off'),
  SleepDuration(15, '15m'),
  SleepDuration(30, '30m'),
  SleepDuration(60, '1h'),
  SleepDuration(180, '3h'),
  SleepDuration(360, '6h'),
  SleepDuration(540, '9h'),
  SleepDuration(720, '12h'),
];

const defaultSleepMinutes = 60;

/// Stands for the "stop at" item of the carousel; it is not a real duration.
const stopAtMinutes = -1;

/// `'2h 30m'`, `'5h'` or `'45m'`, for a custom duration.
String customDurationLabel(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return '${rest}m';
  if (rest == 0) return '${hours}h';
  return '${hours}h ${rest}m';
}

/// What the carousel offers right now: the presets, plus the custom duration
/// (in its place among them) or the "stop at" time (last) when one is active.
List<SleepDuration> sleepDurationChoices({
  required int timerMinutes,
  String? stopAtLabel,
}) {
  final choices = [...sleepDurations];
  if (timerMinutes > 0 && !choices.any((d) => d.minutes == timerMinutes)) {
    final next = choices.indexWhere((d) => d.minutes > timerMinutes);
    choices.insert(
      next == -1 ? choices.length : next,
      SleepDuration(timerMinutes, customDurationLabel(timerMinutes)),
    );
  }
  if (stopAtLabel != null) {
    choices.add(SleepDuration(stopAtMinutes, stopAtLabel));
  }
  return choices;
}

/// Formats remaining sleep-timer seconds for display: `'11h 59m'` at or above
/// one hour, `'M:SS'` below it.
String formatSleepRemaining(int totalSeconds) {
  final hours = totalSeconds ~/ 3600;
  if (hours > 0) {
    final minutes = (totalSeconds % 3600) ~/ 60;
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

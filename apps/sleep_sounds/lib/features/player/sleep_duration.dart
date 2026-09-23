class SleepDuration {
  const SleepDuration(this.minutes, this.label);
  final int minutes;
  final String label;
}

const sleepDurations = <SleepDuration>[
  SleepDuration(30, '30min'),
  SleepDuration(60, '1h'),
  SleepDuration(360, '6h'),
  SleepDuration(720, '12h'),
  SleepDuration(1440, '24h'),
];

const defaultSleepMinutes = 720;

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

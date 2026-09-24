/// A saved combination of sounds: which ones, how loud each is and,
/// optionally, the sleep timer.
class SavedMix {
  const SavedMix({
    required this.name,
    required this.volumes,
    this.timerMinutes,
  });

  final String name;

  /// Volume (0..1) of each sound, by sound id, in the order they were added.
  final Map<String, double> volumes;

  /// Null when the mix does not touch the timer.
  final int? timerMinutes;

  factory SavedMix.fromJson(Map<String, dynamic> json) => SavedMix(
    name: json['name'] as String,
    volumes: {
      for (final entry in (json['volumes'] as Map<String, dynamic>).entries)
        entry.key: (entry.value as num).toDouble(),
    },
    timerMinutes: json['timerMinutes'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'volumes': volumes,
    if (timerMinutes != null) 'timerMinutes': timerMinutes,
  };

  SavedMix withName(String newName) =>
      SavedMix(name: newName, volumes: volumes, timerMinutes: timerMinutes);
}

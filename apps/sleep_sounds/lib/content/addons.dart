class Addon {
  const Addon({
    required this.id,
    required this.name,
    required this.emoji,
    required this.asset,
    this.defaultVolume = 0.5,
  });

  final String id, name, emoji, asset;
  final double defaultVolume;
}

const addons = <Addon>[
  Addon(
    id: 'cat_purring',
    name: 'Cat purring',
    emoji: '🐱',
    asset: 'assets/audio/cat_purring.ogg',
    defaultVolume: 0.45,
  ),
  Addon(
    id: 'birds',
    name: 'Birds',
    emoji: '🐦',
    asset: 'assets/audio/birds.ogg',
    defaultVolume: 0.40,
  ),
  Addon(
    id: 'crickets',
    name: 'Crickets',
    emoji: '🦗',
    asset: 'assets/audio/crickets_chirping.ogg',
    defaultVolume: 0.45,
  ),
  Addon(
    id: 'wind_howling',
    name: 'Wind howling',
    emoji: '🍃',
    asset: 'assets/audio/howling_wind.ogg',
    defaultVolume: 0.40,
  ),
  Addon(
    id: 'wind_chimes',
    name: 'Wind chimes',
    emoji: '🎐',
    asset: 'assets/audio/wind_chimes.ogg',
    defaultVolume: 0.35,
  ),
  Addon(
    id: 'clock',
    name: 'Clock',
    emoji: '🕰️',
    asset: 'assets/audio/clock.ogg',
    defaultVolume: 0.40,
  ),
];

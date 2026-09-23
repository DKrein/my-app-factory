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
    id: 'crickets',
    name: 'Crickets',
    emoji: '🦗',
    asset: 'assets/audio/crickets.ogg',
    defaultVolume: 0.45,
  ),
  Addon(
    id: 'wind',
    name: 'Wind whistle',
    emoji: '🍃',
    asset: 'assets/audio/wind.ogg',
    defaultVolume: 0.40,
  ),
  Addon(
    id: 'thunder',
    name: 'Thunder',
    emoji: '⛈️',
    asset: 'assets/audio/thunder.ogg',
    defaultVolume: 0.35,
  ),
  Addon(
    id: 'fire',
    name: 'Fire',
    emoji: '🔥',
    asset: 'assets/audio/fire.ogg',
    defaultVolume: 0.50,
  ),
  Addon(
    id: 'birds',
    name: 'Birds chirping',
    emoji: '🐦',
    asset: 'assets/audio/birds.ogg',
    defaultVolume: 0.40,
  ),
];

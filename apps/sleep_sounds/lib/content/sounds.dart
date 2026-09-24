import 'package:material_symbols_icons/symbols.dart';

import 'sound_icon.dart';

class Sound {
  const Sound(this.id, this.name, this.asset, this.icon);
  final String id, name, asset;
  final SoundIcon icon;
}

const sounds = [
  Sound(
    'rain',
    'Rain',
    'assets/audio/rain.ogg',
    SoundIcon.symbol(Symbols.rainy_rounded),
  ),
  Sound(
    'rain_tent',
    'Rain in tent',
    'assets/audio/rain_tent.ogg',
    SoundIcon.symbol(Symbols.camping_rounded),
  ),
  Sound(
    'waves',
    'Waves',
    'assets/audio/waves.ogg',
    SoundIcon.symbol(Symbols.tsunami_rounded),
  ),
  Sound(
    'airplane',
    'Airplane',
    'assets/audio/airplane.ogg',
    SoundIcon.symbol(Symbols.flight_rounded),
  ),
  Sound(
    'river',
    'River',
    'assets/audio/river.ogg',
    SoundIcon.drawn(DrawnIcon.river),
  ),
  Sound(
    'forest_rain',
    'Forest rain',
    'assets/audio/rain_forest.ogg',
    SoundIcon.symbol(Symbols.forest_rounded),
  ),
  Sound(
    'campfire',
    'Campfire',
    'assets/audio/campfire.ogg',
    SoundIcon.symbol(Symbols.local_fire_department_rounded),
  ),
  Sound(
    'stream',
    'Stream',
    'assets/audio/stream.ogg',
    SoundIcon.drawn(DrawnIcon.stream),
  ),
  Sound(
    'storm',
    'Storm',
    'assets/audio/storm.ogg',
    SoundIcon.symbol(Symbols.thunderstorm_rounded),
  ),
  Sound(
    'winter',
    'Winter',
    'assets/audio/winter.ogg',
    SoundIcon.symbol(Symbols.ac_unit_rounded),
  ),
  Sound(
    'train',
    'Train',
    'assets/audio/train.ogg',
    SoundIcon.symbol(Symbols.train_rounded),
  ),
  Sound(
    'cat_purring',
    'Cat purring',
    'assets/audio/cat_purring.ogg',
    SoundIcon.symbol(Symbols.pets_rounded),
  ),
  Sound(
    'birds',
    'Birds',
    'assets/audio/birds.ogg',
    SoundIcon.symbol(Symbols.raven_rounded),
  ),
  Sound(
    'crickets',
    'Crickets',
    'assets/audio/crickets_chirping.ogg',
    SoundIcon.symbol(Symbols.pest_control_rounded),
  ),
  Sound(
    'wind',
    'Wind',
    'assets/audio/wind.ogg',
    SoundIcon.symbol(Symbols.air_rounded),
  ),
  Sound(
    'chimes',
    'Chimes',
    'assets/audio/chimes.ogg',
    SoundIcon.symbol(Symbols.notifications_active_rounded),
  ),
  Sound(
    'clock',
    'Clock',
    'assets/audio/clock.ogg',
    SoundIcon.symbol(Symbols.schedule_rounded),
  ),
];

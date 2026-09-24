import 'package:material_symbols_icons/symbols.dart';

import 'sound_icon.dart';

class Sound {
  const Sound(this.id, this.asset, this.icon);
  final String id, asset;
  final SoundIcon icon;
}

const sounds = [
  Sound(
    'rain',
    'assets/audio/rain.ogg',
    SoundIcon.symbol(Symbols.rainy_rounded),
  ),
  Sound(
    'rain_tent',
    'assets/audio/rain_tent.ogg',
    SoundIcon.symbol(Symbols.camping_rounded),
  ),
  Sound(
    'waves',
    'assets/audio/waves.ogg',
    SoundIcon.symbol(Symbols.tsunami_rounded),
  ),
  Sound(
    'airplane',
    'assets/audio/airplane.ogg',
    SoundIcon.symbol(Symbols.flight_rounded),
  ),
  Sound('river', 'assets/audio/river.ogg', SoundIcon.drawn(DrawnIcon.river)),
  Sound(
    'forest_rain',
    'assets/audio/rain_forest.ogg',
    SoundIcon.symbol(Symbols.forest_rounded),
  ),
  Sound(
    'campfire',
    'assets/audio/campfire.ogg',
    SoundIcon.symbol(Symbols.local_fire_department_rounded),
  ),
  Sound('stream', 'assets/audio/stream.ogg', SoundIcon.drawn(DrawnIcon.stream)),
  Sound(
    'storm',
    'assets/audio/storm.ogg',
    SoundIcon.symbol(Symbols.thunderstorm_rounded),
  ),
  Sound(
    'winter',
    'assets/audio/winter.ogg',
    SoundIcon.symbol(Symbols.ac_unit_rounded),
  ),
  Sound(
    'train',
    'assets/audio/train.ogg',
    SoundIcon.symbol(Symbols.train_rounded),
  ),
  Sound(
    'cat_purring',
    'assets/audio/cat_purring.ogg',
    SoundIcon.symbol(Symbols.pets_rounded),
  ),
  Sound(
    'birds',
    'assets/audio/birds.ogg',
    SoundIcon.symbol(Symbols.raven_rounded),
  ),
  Sound(
    'crickets',
    'assets/audio/crickets_chirping.ogg',
    SoundIcon.symbol(Symbols.pest_control_rounded),
  ),
  Sound('wind', 'assets/audio/wind.ogg', SoundIcon.symbol(Symbols.air_rounded)),
  Sound(
    'chimes',
    'assets/audio/chimes.ogg',
    SoundIcon.symbol(Symbols.notifications_active_rounded),
  ),
  Sound(
    'clock',
    'assets/audio/clock.ogg',
    SoundIcon.symbol(Symbols.schedule_rounded),
  ),
];

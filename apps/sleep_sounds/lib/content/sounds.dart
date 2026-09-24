import 'package:flutter/material.dart';

class Sound {
  const Sound(
    this.id,
    this.name,
    this.detail,
    this.asset,
    this.icon,
    this.color,
  );
  final String id, name, detail, asset;
  final IconData icon;
  final Color color;
}

const sounds = [
  Sound(
    'rain',
    'Rain',
    'Steady drops on a quiet window',
    'assets/audio/rain.ogg',
    Icons.water_drop_outlined,
    Color(0xFF7DA9E8),
  ),
  Sound(
    'rain_tent',
    'Rain in tent',
    'Patter on canvas, snug and dry',
    'assets/audio/rain_tent.ogg',
    Icons.cabin_outlined,
    Color(0xFF9DB8D9),
  ),
  Sound(
    'waves',
    'Waves',
    'Slow, distant sea',
    'assets/audio/waves.ogg',
    Icons.waves_outlined,
    Color(0xFF8ED9C7),
  ),
  Sound(
    'airplane',
    'Airplane',
    'Steady cabin hum at cruising altitude',
    'assets/audio/airplane.ogg',
    Icons.flight_outlined,
    Color(0xFFB4BCD0),
  ),
  Sound(
    'river',
    'River',
    'Water flowing over smooth stones',
    'assets/audio/river.ogg',
    Icons.water_outlined,
    Color(0xFF7FC8D9),
  ),
  Sound(
    'forest_rain',
    'Forest rain',
    'Rain through leaves and branches',
    'assets/audio/rain_forest.ogg',
    Icons.forest_outlined,
    Color(0xFF86C99A),
  ),
  Sound(
    'campfire',
    'Campfire',
    'Warm crackle of burning logs',
    'assets/audio/campfire.ogg',
    Icons.local_fire_department_outlined,
    Color(0xFFF1A66A),
  ),
  Sound(
    'calm_stream',
    'Calm stream',
    'A gentle brook trickling by',
    'assets/audio/calm_stream.ogg',
    Icons.grain,
    Color(0xFF8ED0B8),
  ),
  Sound(
    'thunderstorm',
    'Thunderstorm',
    'Rolling thunder and heavy rain',
    'assets/audio/thunderstorm.ogg',
    Icons.thunderstorm_outlined,
    Color(0xFF9A8FE0),
  ),
  Sound(
    'winter_storm',
    'Winter storm',
    'Howling wind and drifting snow',
    'assets/audio/winter_storm.ogg',
    Icons.ac_unit,
    Color(0xFFBFD8F2),
  ),
  Sound(
    'train',
    'Train',
    'Rhythmic clatter on the rails',
    'assets/audio/train.ogg',
    Icons.train_outlined,
    Color(0xFFF1C589),
  ),
];

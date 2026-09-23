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
    'Soft rain',
    'Steady drops on a quiet window',
    'assets/audio/rain.ogg',
    Icons.water_drop_outlined,
    Color(0xFF7DA9E8),
  ),
  Sound(
    'waves',
    'Night waves',
    'Slow, distant sea',
    'assets/audio/waves.ogg',
    Icons.waves_outlined,
    Color(0xFF8ED9C7),
  ),
  Sound(
    'brown',
    'Brown noise',
    'Deep and steady for cozy focus',
    'assets/audio/brown.ogg',
    Icons.graphic_eq,
    Color(0xFFC7A6F5),
  ),
  Sound(
    'fan',
    'Fan',
    'Even airflow to mask distractions',
    'assets/audio/fan.ogg',
    Icons.air_outlined,
    Color(0xFFF1C589),
  ),
];

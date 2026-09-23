import 'dart:async';
import 'dart:collection';

import 'package:factory_audio/factory_audio.dart';
import 'package:flutter/foundation.dart';

import '../../content/addons.dart';
import '../../content/sounds.dart';
import 'sleep_duration.dart';

typedef AudioLayerFactory = AudioGateway Function();

/// One active add-on layer: its catalog entry, its own audio player, and its
/// current volume (independent from the main sound's volume).
class ActiveAddon {
  ActiveAddon(this.addon, this.gateway, this.volume);
  final Addon addon;
  final AudioGateway gateway;
  double volume;
}

/// Drives the main sound plus zero or more simultaneous add-on layers, one
/// play/pause and one sleep timer for all of them together. Only active
/// add-ons hold a live [AudioGateway] instance.
class PlaybackController extends ChangeNotifier {
  PlaybackController({
    required AudioGateway main,
    required AudioLayerFactory createLayer,
    NowPlayingNotifier? nowPlaying,
  })  : _main = main,
        _createLayer = createLayer,
        _nowPlaying = nowPlaying;

  final AudioGateway _main;
  final AudioLayerFactory _createLayer;
  final NowPlayingNotifier? _nowPlaying;
  final Map<String, ActiveAddon> _addons = {};
  Timer? _timer;

  Sound? sound;
  bool playing = false;
  double volume = .7;
  int timerMinutes = defaultSleepMinutes;
  int remainingSeconds = 0;

  Map<String, ActiveAddon> get activeAddons => UnmodifiableMapView(_addons);
  int get activeAddonCount => _addons.length;
  bool isAddonActive(String id) => _addons.containsKey(id);
  double addonVolume(Addon addon) => _addons[addon.id]?.volume ?? addon.defaultVolume;

  Future<void> play(Sound next) async {
    sound = next;
    playing = true;
    notifyListeners();
    await _main.play(next.asset, title: next.name);
    await _startAllAddonLayers();
    _nowPlaying?.showTrack(id: next.id, title: next.name);
    _nowPlaying?.setPlaying(true);
    setTimer(timerMinutes);
  }

  Future<void> togglePlaying() async {
    final current = sound;
    if (current == null) return;
    if (playing) {
      playing = false;
      _stopTicking();
      notifyListeners();
      await _main.pause();
      await Future.wait(_addons.values.map((a) => a.gateway.pause()));
      _nowPlaying?.setPlaying(false);
    } else {
      playing = true;
      notifyListeners();
      await _main.play(current.asset, title: current.name);
      await _startAllAddonLayers();
      _nowPlaying?.setPlaying(true);
      if (timerMinutes > 0) _startTicking();
    }
  }

  Future<void> setVolume(double value) async {
    volume = value;
    notifyListeners();
    await _main.setVolume(value);
  }

  /// Activates or deactivates one add-on. Only active add-ons ever hold a
  /// live [AudioGateway] — deactivating disposes it immediately.
  Future<void> toggleAddon(Addon addon) async {
    final existing = _addons.remove(addon.id);
    if (existing != null) {
      notifyListeners();
      await existing.gateway.pause();
      await existing.gateway.dispose();
      return;
    }

    final gateway = _createLayer();
    _addons[addon.id] = ActiveAddon(addon, gateway, addon.defaultVolume);
    notifyListeners();
    await gateway.setVolume(addon.defaultVolume);
    if (playing) {
      await gateway.play(addon.asset);
      // A toggle-off may have landed while `play()` was in flight.
      if (_addons[addon.id]?.gateway != gateway) {
        await gateway.dispose();
      }
    }
  }

  Future<void> setAddonVolume(Addon addon, double value) async {
    final entry = _addons[addon.id];
    if (entry == null) return;
    entry.volume = value;
    notifyListeners();
    await entry.gateway.setVolume(value);
  }

  Future<void> _startAllAddonLayers() {
    return Future.wait(_addons.values.map((entry) async {
      await entry.gateway.setVolume(entry.volume);
      await entry.gateway.play(entry.addon.asset);
    }));
  }

  void setTimer(int minutes) {
    _timer?.cancel();
    timerMinutes = minutes;
    remainingSeconds = minutes * 60;
    notifyListeners();
    if (playing && minutes > 0) {
      _startTicking();
    }
  }

  void _startTicking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _stopTicking() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick() {
    if (remainingSeconds > 1) {
      remainingSeconds--;
      notifyListeners();
      return;
    }
    _stopTicking();
    remainingSeconds = 0;
    playing = false;
    notifyListeners();
    _main.pause();
    for (final entry in _addons.values) {
      entry.gateway.pause();
    }
    _nowPlaying?.setPlaying(false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final entry in _addons.values) {
      entry.gateway.dispose();
    }
    super.dispose();
  }
}

import 'dart:async';

import 'package:factory_audio/factory_audio.dart';
import 'package:flutter/foundation.dart';

import '../../content/sounds.dart';
import 'sleep_duration.dart';

typedef AudioGatewayFactory = AudioGateway Function({
  required bool ownsAudioSession,
});

/// Plays any number of sounds at once, with one sleep timer for all of them.
/// Each playing sound holds its own [AudioGateway], disposed when it stops.
class PlaybackController extends ChangeNotifier {
  PlaybackController({required this._createGateway, this._nowPlaying});

  static const _volume = .7;

  final AudioGatewayFactory _createGateway;
  final NowPlayingNotifier? _nowPlaying;
  final Map<String, ({Sound sound, AudioGateway gateway})> _active = {};
  Timer? _timer;

  bool playing = false;
  int timerMinutes = defaultSleepMinutes;
  int remainingSeconds = 0;

  bool get hasSounds => _active.isNotEmpty;

  bool isSelected(Sound sound) => _active.containsKey(sound.id);

  /// Selects [sound] (resuming everything selected if paused), or deselects
  /// just that one if it is already selected.
  Future<void> toggle(Sound sound) async {
    if (isSelected(sound)) return _deselect(sound);

    final wasPlaying = playing;
    final wasEmpty = _active.isEmpty;
    final layer = (
      sound: sound,
      gateway: _createGateway(ownsAudioSession: wasEmpty),
    );
    _active[sound.id] = layer;
    playing = true;
    notifyListeners();

    await Future.wait(
      (wasPlaying ? [layer] : _active.values.toList()).map(_start),
    );
    _showNowPlaying();
    if (wasEmpty) {
      setTimer(timerMinutes);
    } else if (!wasPlaying) {
      _beginCountdown();
    }
  }

  /// Selects every sound in [list] that is not selected yet, or deselects
  /// them all if they already are.
  Future<void> toggleAll(List<Sound> list) async {
    final allSelected = list.every(isSelected);
    for (final sound in list) {
      if (allSelected || !isSelected(sound)) await toggle(sound);
    }
  }

  Future<void> togglePlaying() async {
    if (_active.isEmpty) return;
    if (playing) {
      playing = false;
      _stopTicking();
      notifyListeners();
      await Future.wait(_active.values.map((a) => a.gateway.pause()));
      _nowPlaying?.setPlaying(false);
    } else {
      playing = true;
      notifyListeners();
      await Future.wait(_active.values.map(_start));
      _showNowPlaying();
      _beginCountdown();
    }
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

  Future<void> _start(({Sound sound, AudioGateway gateway}) layer) async {
    await layer.gateway.setVolume(_volume);
    await layer.gateway.play(layer.sound.asset, title: layer.sound.name);
  }

  Future<void> _deselect(Sound sound) async {
    final layer = _active.remove(sound.id)!;
    if (_active.isEmpty) {
      playing = false;
      _stopTicking();
      _nowPlaying?.clear();
    } else {
      _showNowPlaying();
    }
    notifyListeners();
    await layer.gateway.pause();
    await layer.gateway.dispose();
  }

  void _beginCountdown() {
    if (remainingSeconds == 0) {
      setTimer(timerMinutes);
    } else {
      _startTicking();
    }
  }

  void _showNowPlaying() {
    _nowPlaying?.showTrack(
      id: 'mix',
      title: _active.values.map((a) => a.sound.name).join(', '),
    );
    _nowPlaying?.setPlaying(playing);
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
    for (final layer in _active.values) {
      layer.gateway.pause();
    }
    _nowPlaying?.setPlaying(false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final layer in _active.values) {
      layer.gateway.dispose();
    }
    super.dispose();
  }
}

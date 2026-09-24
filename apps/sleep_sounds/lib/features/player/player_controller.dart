import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:factory_audio/factory_audio.dart';
import 'package:factory_storage/factory_storage.dart';
import 'package:flutter/foundation.dart';

import '../../content/sounds.dart';
import 'sleep_duration.dart';

typedef AudioGatewayFactory = AudioGateway Function({
  required bool ownsAudioSession,
});

/// Plays any number of sounds at once, with one sleep timer for all of them.
/// Each playing sound holds its own [AudioGateway], disposed when it stops.
class PlaybackController extends ChangeNotifier {
  PlaybackController({
    required this._createGateway,
    this._nowPlaying,
    this._storage,
  });

  static const _sessionKey = 'last_session_v1';
  static const _masterGain = .7;
  static const _rampDuration = Duration(milliseconds: 250);
  static const _dragRamp = Duration(milliseconds: 50);
  static const minVolume = .1;
  static const _fadeInDuration = Duration(milliseconds: 1500);
  static const _fadeOutDuration = Duration(seconds: 1);
  static const _timerFadeDuration = Duration(seconds: 4);

  final AudioGatewayFactory _createGateway;
  final NowPlayingNotifier? _nowPlaying;
  final KeyValueStore? _storage;
  final Map<String, ({Sound sound, AudioGateway gateway})> _active = {};
  Timer? _timer;
  bool _timerFading = false;

  bool playing = false;
  final Map<String, double> _volumes = {};
  int timerMinutes = defaultSleepMinutes;
  int remainingSeconds = 0;

  /// Gain of a layer with individual [volume] (0..1) in a mix whose volumes
  /// squared add up to [sumOfSquares].
  ///
  /// Ambient sounds are uncorrelated, so their powers add: n sounds at the
  /// same gain are 10*log10(n) dB louder (+7 dB with 5 sounds) and their peaks
  /// approach clipping. Dividing by the root of the summed squares keeps the
  /// mix power equal to the average single sound, and one sound at full volume
  /// stays at [_masterGain]. See apps/sleep_sounds/docs/adr/0001-mix-headroom.md.
  @visibleForTesting
  static double mixGain(double volume, double sumOfSquares) =>
      _masterGain * volume / math.sqrt(math.max(1, sumOfSquares));

  double _gainOf(String id) => mixGain(
    _volumes[id] ?? 1,
    _active.keys.fold(0.0, (sum, id) {
      final v = _volumes[id] ?? 1;
      return sum + v * v;
    }),
  );

  /// Individual volume of [sound], from [minVolume] to 1.
  double volumeOf(Sound sound) => _volumes[sound.id] ?? 1;

  /// Sets the individual volume of a selected [sound]. Every layer's gain is
  /// rebalanced. Call [commitVolumes] when the user lets go.
  void setSoundVolume(Sound sound, double volume) {
    if (!isSelected(sound)) return;
    _volumes[sound.id] = volume.clamp(minVolume, 1.0);
    if (playing) {
      for (final entry in _active.entries) {
        unawaited(entry.value.gateway.fadeTo(_gainOf(entry.key), _dragRamp));
      }
    }
    notifyListeners();
  }

  void commitVolumes() => _saveSession();

  bool get hasSounds => _active.isNotEmpty;

  bool isSelected(Sound sound) => _active.containsKey(sound.id);

  /// Brings back the sounds and timer of the last session, selected but not
  /// playing: the user still has to press play.
  Future<void> restore() async {
    final raw = await _storage?.readString(_sessionKey);
    if (raw == null || _active.isNotEmpty) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final ids = (json['soundIds'] as List).cast<String>();
      final minutes = json['timerMinutes'] as int;
      final volumes = (json['volumes'] as Map<String, dynamic>?) ?? const {};
      for (final sound in sounds.where((s) => ids.contains(s.id))) {
        _active[sound.id] = (
          sound: sound,
          gateway: _createGateway(ownsAudioSession: _active.isEmpty),
        );
      }
      for (final id in _active.keys) {
        final volume = volumes[id];
        if (volume is num) {
          _volumes[id] = volume.toDouble().clamp(minVolume, 1.0);
        }
      }
      if (sleepDurations.any((d) => d.minutes == minutes)) {
        timerMinutes = minutes;
      }
    } catch (_) {
      return;
    }
    notifyListeners();
  }

  void _saveSession() {
    unawaited(
      _storage?.writeString(
        _sessionKey,
        jsonEncode({
          'soundIds': _active.keys.toList(),
          'timerMinutes': timerMinutes,
          'volumes': {for (final id in _active.keys) id: _volumes[id] ?? 1},
        }),
      ),
    );
  }

  /// Selects [sound] (resuming everything selected if paused), or deselects
  /// just that one if it is already selected.
  Future<void> toggle(Sound sound) async {
    if (isSelected(sound)) return _deselect(sound);

    _cancelTimerFade();
    final wasPlaying = playing;
    final wasEmpty = _active.isEmpty;
    final layer = (
      sound: sound,
      gateway: _createGateway(ownsAudioSession: wasEmpty),
    );
    _active[sound.id] = layer;
    _saveSession();
    playing = true;
    if (wasPlaying) _rebalance(except: sound.id);
    notifyListeners();

    await Future.wait(
      (wasPlaying ? [layer] : _active.values.toList()).map(
        (l) => _start(l, fadeIn: wasPlaying ? _rampDuration : _fadeInDuration),
      ),
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
      _timerFading = false;
      notifyListeners();
      _nowPlaying?.setPlaying(false);
      await _fadeOutAndPause(_active.values.toList(), _fadeOutDuration);
    } else {
      playing = true;
      notifyListeners();
      await Future.wait(_active.values.map(_start));
      _showNowPlaying();
      _beginCountdown();
    }
  }

  void setTimer(int minutes) {
    _cancelTimerFade();
    _timer?.cancel();
    timerMinutes = minutes;
    _saveSession();
    remainingSeconds = minutes * 60;
    notifyListeners();
    if (playing && minutes > 0) {
      _startTicking();
    }
  }

  Future<void> _start(
    ({Sound sound, AudioGateway gateway}) layer, {
    Duration fadeIn = _fadeInDuration,
  }) async {
    await layer.gateway.setVolume(0);
    await layer.gateway.play(layer.sound.asset, title: layer.sound.name);
    unawaited(layer.gateway.fadeTo(_gainOf(layer.sound.id), fadeIn));
  }

  /// Fades the layers out and pauses them, unless playback resumed meanwhile.
  Future<void> _fadeOutAndPause(
    List<({Sound sound, AudioGateway gateway})> layers,
    Duration duration,
  ) async {
    await Future.wait(layers.map((l) => l.gateway.fadeTo(0, duration)));
    if (playing) return;
    await Future.wait(layers.map((l) => l.gateway.pause()));
  }

  Future<void> _deselect(Sound sound) async {
    final layer = _active.remove(sound.id)!;
    _volumes.remove(sound.id);
    _saveSession();
    if (_active.isEmpty) {
      playing = false;
      _stopTicking();
      _nowPlaying?.clear();
    } else {
      _showNowPlaying();
    }
    _cancelTimerFade();
    if (playing) _rebalance();
    notifyListeners();
    final wasLast = _active.isEmpty;
    await layer.gateway.fadeTo(0, wasLast ? _fadeOutDuration : _rampDuration);
    await layer.gateway.pause();
    await layer.gateway.dispose();
  }

  void _rebalance({String? except}) {
    for (final entry in _active.entries) {
      if (entry.key == except) continue;
      unawaited(entry.value.gateway.fadeTo(_gainOf(entry.key), _rampDuration));
    }
  }

  /// The user touched the mix or the timer during the final fade-out, so bring
  /// the sounds back instead of letting them fade to silence.
  void _cancelTimerFade() {
    if (!_timerFading) return;
    _timerFading = false;
    _rebalance();
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

  void _beginTimerFade() {
    _timerFading = true;
    for (final layer in _active.values) {
      unawaited(layer.gateway.fadeTo(0, _timerFadeDuration));
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
      if (remainingSeconds == _timerFadeDuration.inSeconds) _beginTimerFade();
      notifyListeners();
      return;
    }
    _stopTicking();
    _timerFading = false;
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

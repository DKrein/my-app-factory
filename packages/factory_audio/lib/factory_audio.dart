import 'dart:async';

import 'package:just_audio/just_audio.dart';

export 'src/now_playing.dart';

/// Playback boundary. Every layer (main sound or add-on) is one
/// [AudioGateway]; the app owns the notification separately via
/// [NowPlayingNotifier] so several layers can mix without fighting over it.
abstract interface class AudioGateway {
  Future<void> play(String assetPath, {String? title, bool loop = true});
  Future<void> pause();
  Future<void> setVolume(double volume);

  /// Ramps the volume linearly to [volume] over [duration]. A new call or
  /// [setVolume] replaces a ramp in progress from the current level.
  Future<void> fadeTo(double volume, Duration duration);
  Future<void> dispose();
}

/// Non-playing implementation for UI development and unit tests.
final class PreviewAudioGateway implements AudioGateway {
  String? playingAsset;
  double volume = 0.7;
  Duration? lastFadeDuration;
  bool disposed = false;
  @override
  Future<void> pause() async => playingAsset = null;
  @override
  Future<void> play(
    String assetPath, {
    String? title,
    bool loop = true,
  }) async => playingAsset = assetPath;
  @override
  Future<void> setVolume(double value) async => volume = value;
  @override
  Future<void> fadeTo(double value, Duration duration) async {
    volume = value;
    lastFadeDuration = duration;
  }

  @override
  Future<void> dispose() async {
    playingAsset = null;
    disposed = true;
  }
}

/// Android/iOS asset player. Lifecycle ownership remains with the app feature.
///
/// Multiple instances can play simultaneously (standard `just_audio`
/// behavior). Exactly one should own the audio session — pass
/// `ownsAudioSession: false` for every layer besides the main sound so only
/// one player drives audio-focus/session activation.
final class JustAudioGateway implements AudioGateway {
  JustAudioGateway({bool ownsAudioSession = true})
    : _player = AudioPlayer(handleAudioSessionActivation: ownsAudioSession);

  static const _fadeStep = Duration(milliseconds: 30);

  final AudioPlayer _player;
  Timer? _fadeTimer;
  Completer<void>? _fadeDone;

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> play(String assetPath, {String? title, bool loop = true}) async {
    await _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
    await _player.setAudioSource(AudioSource.asset(assetPath));
    // just_audio's play() only completes when playback ends or pauses, which a
    // looping sound never does.
    unawaited(_player.play());
  }

  @override
  Future<void> setVolume(double volume) {
    _cancelFade();
    return _player.setVolume(volume.clamp(0, 1).toDouble());
  }

  @override
  Future<void> fadeTo(double volume, Duration duration) {
    _cancelFade();
    final target = volume.clamp(0, 1).toDouble();
    final start = _player.volume;
    final steps = duration.inMilliseconds ~/ _fadeStep.inMilliseconds;
    if (steps <= 1 || start == target) return _player.setVolume(target);

    final done = _fadeDone = Completer<void>();
    var step = 0;
    _fadeTimer = Timer.periodic(_fadeStep, (timer) {
      step++;
      final t = step / steps;
      _player.setVolume(t >= 1 ? target : start + (target - start) * t);
      if (t >= 1) {
        timer.cancel();
        _fadeTimer = null;
        if (!done.isCompleted) done.complete();
      }
    });
    return done.future;
  }

  void _cancelFade() {
    _fadeTimer?.cancel();
    _fadeTimer = null;
    final done = _fadeDone;
    if (done != null && !done.isCompleted) done.complete();
    _fadeDone = null;
  }

  @override
  Future<void> dispose() {
    _cancelFade();
    return _player.dispose();
  }
}

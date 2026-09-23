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
  Future<void> dispose();
}

/// Non-playing implementation for UI development and unit tests.
final class PreviewAudioGateway implements AudioGateway {
  String? playingAsset;
  double volume = 0.7;
  bool disposed = false;
  @override
  Future<void> pause() async => playingAsset = null;
  @override
  Future<void> play(String assetPath, {String? title, bool loop = true}) async =>
      playingAsset = assetPath;
  @override
  Future<void> setVolume(double value) async => volume = value;
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

  final AudioPlayer _player;

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
  Future<void> setVolume(double volume) =>
      _player.setVolume(volume.clamp(0, 1).toDouble());

  @override
  Future<void> dispose() => _player.dispose();
}

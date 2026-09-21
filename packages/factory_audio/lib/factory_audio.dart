import 'package:just_audio/just_audio.dart';

/// Playback boundary. A later Android implementation can own foreground audio.
abstract interface class AudioGateway {
  Future<void> play(String assetPath, {bool loop = true});
  Future<void> pause();
  Future<void> setVolume(double volume);
}

/// Non-playing implementation for UI development and unit tests.
final class PreviewAudioGateway implements AudioGateway {
  String? playingAsset;
  double volume = 0.7;
  @override
  Future<void> pause() async => playingAsset = null;
  @override
  Future<void> play(String assetPath, {bool loop = true}) async =>
      playingAsset = assetPath;
  @override
  Future<void> setVolume(double value) async => volume = value;
}

/// Android/iOS asset player. Lifecycle ownership remains with the app feature.
final class JustAudioGateway implements AudioGateway {
  JustAudioGateway() : _player = AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> play(String assetPath, {bool loop = true}) async {
    await _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
    await _player.setAsset(assetPath);
    await _player.play();
  }

  @override
  Future<void> setVolume(double volume) =>
      _player.setVolume(volume.clamp(0, 1).toDouble());

  Future<void> dispose() => _player.dispose();
}

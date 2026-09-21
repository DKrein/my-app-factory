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

import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

/// Playback boundary. [JustAudioGateway] keeps playing in the background.
abstract interface class AudioGateway {
  Future<void> play(String assetPath, {String? title, bool loop = true});
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
  Future<void> play(String assetPath, {String? title, bool loop = true}) async =>
      playingAsset = assetPath;
  @override
  Future<void> setVolume(double value) async => volume = value;
}

/// Android/iOS asset player. Lifecycle ownership remains with the app feature.
///
/// Call [initBackground] in `main()` before creating the first instance and
/// declare the audio service in the app's AndroidManifest.
final class JustAudioGateway implements AudioGateway {
  JustAudioGateway() : _player = AudioPlayer();

  final AudioPlayer _player;

  static Future<void> initBackground({
    required String channelId,
    required String channelName,
    String notificationIcon = 'mipmap/ic_launcher',
  }) =>
      JustAudioBackground.init(
        androidNotificationChannelId: channelId,
        androidNotificationChannelName: channelName,
        androidNotificationIcon: notificationIcon,
        androidNotificationOngoing: true,
      );

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> play(String assetPath, {String? title, bool loop = true}) async {
    await _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
    await _player.setAudioSource(
      AudioSource.asset(
        assetPath,
        tag: MediaItem(id: assetPath, title: title ?? assetPath),
      ),
    );
    // just_audio's play() only completes when playback ends or pauses, which a
    // looping sound never does.
    unawaited(_player.play());
  }

  @override
  Future<void> setVolume(double volume) =>
      _player.setVolume(volume.clamp(0, 1).toDouble());

  Future<void> dispose() => _player.dispose();
}

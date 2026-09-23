import 'package:audio_service/audio_service.dart';

/// App-owned lock-screen/notification control, decoupled from any single
/// playing [AudioGateway] layer so it can reflect a mix of several layers.
abstract interface class NowPlayingNotifier {
  void showTrack({required String id, required String title});
  void setPlaying(bool playing);
  Future<void> clear();

  /// Routes notification/lock-screen play & pause taps into the app's
  /// layered playback controller.
  void bindTransport({
    required Future<void> Function() onPlay,
    required Future<void> Function() onPause,
  });
}

/// Real implementation backed by `audio_service`. Owns the single Android
/// foreground-service notification/MediaSession for the whole app; it does
/// not itself play audio.
final class AudioServiceNotifier extends BaseAudioHandler
    implements NowPlayingNotifier {
  AudioServiceNotifier._();

  Future<void> Function()? _onPlay;
  Future<void> Function()? _onPause;

  static Future<AudioServiceNotifier> init({
    required String channelId,
    required String channelName,
    String notificationIcon = 'mipmap/ic_launcher',
  }) =>
      AudioService.init(
        builder: AudioServiceNotifier._,
        config: AudioServiceConfig(
          androidNotificationChannelId: channelId,
          androidNotificationChannelName: channelName,
          androidNotificationIcon: notificationIcon,
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );

  @override
  void bindTransport({
    required Future<void> Function() onPlay,
    required Future<void> Function() onPause,
  }) {
    _onPlay = onPlay;
    _onPause = onPause;
  }

  @override
  void showTrack({required String id, required String title}) {
    mediaItem.add(MediaItem(id: id, title: title));
  }

  @override
  void setPlaying(bool playing) {
    playbackState.add(
      PlaybackState(
        controls: [playing ? MediaControl.pause : MediaControl.play],
        playing: playing,
        processingState: AudioProcessingState.ready,
      ),
    );
  }

  @override
  Future<void> clear() async {
    mediaItem.add(null);
    playbackState.add(PlaybackState());
  }

  @override
  Future<void> play() => _onPlay?.call() ?? Future.value();

  @override
  Future<void> pause() => _onPause?.call() ?? Future.value();

  @override
  Future<void> stop() => pause();
}

/// Non-playing implementation for UI development and unit tests.
final class PreviewNowPlayingNotifier implements NowPlayingNotifier {
  String? title;
  bool playing = false;
  bool cleared = false;

  @override
  void showTrack({required String id, required String title}) {
    this.title = title;
  }

  @override
  void setPlaying(bool playing) => this.playing = playing;

  @override
  Future<void> clear() async {
    cleared = true;
    title = null;
  }

  @override
  void bindTransport({
    required Future<void> Function() onPlay,
    required Future<void> Function() onPause,
  }) {}
}

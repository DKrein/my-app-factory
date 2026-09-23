import 'package:factory_audio/factory_audio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PreviewAudioGateway', () {
    test('updates state on play, pause, and volume changes', () async {
      final gateway = PreviewAudioGateway();

      expect(gateway.playingAsset, isNull);
      expect(gateway.volume, equals(0.7));

      await gateway.play('assets/test.ogg');
      expect(gateway.playingAsset, equals('assets/test.ogg'));

      await gateway.setVolume(0.5);
      expect(gateway.volume, equals(0.5));

      await gateway.pause();
      expect(gateway.playingAsset, isNull);
    });

    test('dispose clears state and marks the gateway disposed', () async {
      final gateway = PreviewAudioGateway();
      await gateway.play('assets/test.ogg');

      await gateway.dispose();

      expect(gateway.playingAsset, isNull);
      expect(gateway.disposed, isTrue);
    });
  });

  group('PreviewNowPlayingNotifier', () {
    test('records the shown track and playing state', () async {
      final notifier = PreviewNowPlayingNotifier();

      notifier.showTrack(id: 'rain', title: 'Soft rain');
      notifier.setPlaying(true);

      expect(notifier.title, equals('Soft rain'));
      expect(notifier.playing, isTrue);

      await notifier.clear();
      expect(notifier.title, isNull);
      expect(notifier.cleared, isTrue);
    });
  });
}

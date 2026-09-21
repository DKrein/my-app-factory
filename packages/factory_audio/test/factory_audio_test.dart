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
  });
}

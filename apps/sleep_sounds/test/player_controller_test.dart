import 'package:factory_audio/factory_audio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_sounds/content/addons.dart';
import 'package:sleep_sounds/content/sounds.dart';
import 'package:sleep_sounds/features/player/player_controller.dart';

void main() {
  late PreviewAudioGateway main;
  late List<PreviewAudioGateway> layers;
  late PlaybackController playback;

  PreviewAudioGateway createLayer() {
    final gateway = PreviewAudioGateway();
    layers.add(gateway);
    return gateway;
  }

  setUp(() {
    main = PreviewAudioGateway();
    layers = [];
    playback = PlaybackController(main: main, createLayer: createLayer);
  });

  final rain = sounds.firstWhere((s) => s.id == 'rain');
  final crickets = addons.firstWhere((a) => a.id == 'crickets');
  final fire = addons.firstWhere((a) => a.id == 'fire');

  testWidgets('play/pause fans out to the main sound and every active addon',
      (tester) async {
    await playback.play(rain);
    await playback.toggleAddon(crickets);

    expect(main.playingAsset, equals(rain.asset));
    expect(layers.single.playingAsset, equals(crickets.asset));

    await playback.togglePlaying();
    expect(main.playingAsset, isNull);
    expect(layers.single.playingAsset, isNull);

    await playback.togglePlaying();
    expect(main.playingAsset, equals(rain.asset));
    expect(layers.single.playingAsset, equals(crickets.asset));

    playback.dispose();
  });

  testWidgets('addon volume never touches the main sound volume',
      (tester) async {
    await playback.play(rain);
    await playback.toggleAddon(crickets);

    await playback.setAddonVolume(crickets, .2);

    expect(layers.single.volume, equals(.2));
    expect(main.volume, equals(.7));

    playback.dispose();
  });

  testWidgets('deactivating an addon disposes its gateway (no leaks)',
      (tester) async {
    await playback.play(rain);
    await playback.toggleAddon(crickets);
    expect(playback.activeAddonCount, equals(1));

    await playback.toggleAddon(crickets);

    expect(playback.activeAddonCount, equals(0));
    expect(playback.isAddonActive('crickets'), isFalse);
    expect(layers.single.disposed, isTrue);

    playback.dispose();
  });

  testWidgets('activating multiple addons creates one layer each',
      (tester) async {
    await playback.play(rain);
    await playback.toggleAddon(crickets);
    await playback.toggleAddon(fire);

    expect(layers.length, equals(2));
    expect(layers.every((l) => l.playingAsset != null), isTrue);

    playback.dispose();
  });

  testWidgets('an addon toggled on while paused stays silent until play',
      (tester) async {
    await playback.play(rain);
    await playback.togglePlaying(); // pause

    await playback.toggleAddon(crickets);
    expect(playback.isAddonActive('crickets'), isTrue);
    expect(layers.single.playingAsset, isNull);

    await playback.togglePlaying(); // resume
    expect(layers.single.playingAsset, equals(crickets.asset));

    playback.dispose();
  });

  testWidgets('timer only ticks while playing', (tester) async {
    await playback.play(rain);
    playback.setTimer(1); // 60s
    await tester.pump(const Duration(seconds: 10));
    expect(playback.remainingSeconds, equals(50));

    await playback.togglePlaying(); // pause
    await tester.pump(const Duration(seconds: 60));
    expect(playback.remainingSeconds, equals(50));

    await playback.togglePlaying(); // resume
    await tester.pump(const Duration(seconds: 10));
    expect(playback.remainingSeconds, equals(40));

    playback.dispose();
  });

  testWidgets('timer expiry stops every layer and keeps the selected duration',
      (tester) async {
    await playback.play(rain);
    await playback.toggleAddon(crickets);
    await playback.toggleAddon(fire);
    playback.setTimer(1); // 60s

    await tester.pump(const Duration(seconds: 60));

    expect(playback.playing, isFalse);
    expect(main.playingAsset, isNull);
    expect(layers.every((l) => l.playingAsset == null), isTrue);
    expect(playback.timerMinutes, equals(1));

    playback.dispose();
  });

  testWidgets('switching duration mid-countdown never leaves two timers',
      (tester) async {
    await playback.play(rain);
    playback.setTimer(1); // 60s
    await tester.pump(const Duration(seconds: 5));

    playback.setTimer(2); // 120s
    await tester.pump(const Duration(seconds: 10));

    expect(playback.remainingSeconds, equals(110));

    playback.dispose();
  });

  testWidgets('dispose disposes every addon gateway', (tester) async {
    await playback.play(rain);
    await playback.toggleAddon(crickets);
    await playback.toggleAddon(fire);

    playback.dispose();

    expect(layers.every((l) => l.disposed), isTrue);
  });
}

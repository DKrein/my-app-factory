import 'package:factory_audio/factory_audio.dart';
import 'package:factory_storage/factory_storage.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_sounds/content/sounds.dart';
import 'package:sleep_sounds/features/mixes/saved_mix.dart';
import 'package:sleep_sounds/features/player/player_controller.dart';
import 'package:sleep_sounds/features/player/sleep_duration.dart';

void main() {
  late List<PreviewAudioGateway> gateways;
  late PlaybackController playback;

  PreviewAudioGateway createGateway({required bool ownsAudioSession}) {
    final gateway = PreviewAudioGateway();
    gateways.add(gateway);
    return gateway;
  }

  setUp(() {
    gateways = [];
    playback = PlaybackController(createGateway: createGateway);
  });

  final rain = sounds.firstWhere((s) => s.id == 'rain');
  final crickets = sounds.firstWhere((s) => s.id == 'crickets');

  testWidgets('sounds play together and toggle independently', (tester) async {
    await playback.toggle(rain);
    await playback.toggle(crickets);

    expect(gateways.map((g) => g.playingAsset), [rain.asset, crickets.asset]);
    expect(playback.isSelected(rain), isTrue);
    expect(playback.isSelected(crickets), isTrue);

    await playback.toggle(rain);

    expect(playback.isSelected(rain), isFalse);
    expect(playback.isSelected(crickets), isTrue);
    expect(gateways.first.disposed, isTrue);
    expect(gateways.last.playingAsset, crickets.asset);

    playback.dispose();
  });

  group('last session', () {
    const sessionKey = 'last_session_v1';

    PlaybackController controllerWith(KeyValueStore storage) =>
        PlaybackController(createGateway: createGateway, storage: storage);

    test('sounds and timer are restored selected, not playing', () async {
      final storage = MemoryKeyValueStore();
      final first = controllerWith(storage);
      await first.toggle(rain);
      await first.toggle(crickets);
      first.setTimer(180);
      first.dispose();
      gateways.clear();

      final restored = controllerWith(storage);
      await restored.restore();

      expect(restored.isSelected(rain), isTrue);
      expect(restored.isSelected(crickets), isTrue);
      expect(restored.timerMinutes, 180);
      expect(restored.playing, isFalse);
      expect(gateways.map((g) => g.playingAsset), [null, null]);

      await restored.togglePlaying();

      expect(gateways.map((g) => g.playingAsset), [rain.asset, crickets.asset]);
      restored.dispose();
    });

    test('deselecting everything is remembered too', () async {
      final storage = MemoryKeyValueStore();
      final first = controllerWith(storage);
      await first.toggle(rain);
      await first.toggle(rain);
      first.dispose();

      final restored = controllerWith(storage);
      await restored.restore();

      expect(restored.hasSounds, isFalse);
    });

    test('unknown sounds, bad timer and corrupt data are ignored', () async {
      final storage = MemoryKeyValueStore();
      await storage.writeString(
        sessionKey,
        '{"soundIds":["rain","gone"],"timerMinutes":5000}',
      );
      final restored = controllerWith(storage);
      await restored.restore();

      expect(restored.isSelected(rain), isTrue);
      expect(restored.timerMinutes, defaultSleepMinutes);

      await storage.writeString(sessionKey, 'not json');
      final corrupt = controllerWith(storage);
      await corrupt.restore();

      expect(corrupt.hasSounds, isFalse);
    });
  });

  group('fades', () {
    testWidgets('play fades in over 1.5 s from silence', (tester) async {
      await playback.toggle(rain);

      expect(gateways.single.fades, [
        (
          volume: PlaybackController.mixGain(1, 1),
          duration: const Duration(milliseconds: 1500),
        ),
      ]);
      playback.dispose();
    });

    testWidgets('pause fades out over 1 s, resume fades back in', (
      tester,
    ) async {
      await playback.toggle(rain);
      await playback.togglePlaying();

      expect(gateways.single.fades.last, (
        volume: 0.0,
        duration: const Duration(seconds: 1),
      ));
      expect(gateways.single.playingAsset, isNull);

      await playback.togglePlaying();

      expect(gateways.single.fades.last, (
        volume: PlaybackController.mixGain(1, 1),
        duration: const Duration(milliseconds: 1500),
      ));
      expect(gateways.single.playingAsset, rain.asset);
      playback.dispose();
    });

    testWidgets('a sound added while playing fades in over 250 ms', (
      tester,
    ) async {
      await playback.toggle(rain);
      await playback.toggle(crickets);

      expect(gateways.last.fades.single, (
        volume: PlaybackController.mixGain(1, 2),
        duration: const Duration(milliseconds: 250),
      ));
      playback.dispose();
    });

    testWidgets('removing the last sound fades out over 1 s first', (
      tester,
    ) async {
      await playback.toggle(rain);
      await playback.toggle(rain);

      expect(gateways.single.fades.last, (
        volume: 0.0,
        duration: const Duration(seconds: 1),
      ));
      expect(gateways.single.disposed, isTrue);
    });

    testWidgets('timer fades out over its last 4 s, then pauses', (
      tester,
    ) async {
      await playback.toggle(rain);
      playback.setTimer(15);

      await tester.pump(const Duration(seconds: 895));
      expect(gateways.single.fades.length, 1);

      await tester.pump(const Duration(seconds: 1));
      expect(playback.remainingSeconds, 4);
      expect(gateways.single.fades.last, (
        volume: 0.0,
        duration: const Duration(seconds: 4),
      ));
      expect(gateways.single.playingAsset, rain.asset);

      await tester.pump(const Duration(seconds: 4));
      expect(playback.playing, isFalse);
      expect(gateways.single.playingAsset, isNull);
      playback.dispose();
    });

    testWidgets(
      'changing the timer during the final fade brings the sound back',
      (tester) async {
        await playback.toggle(rain);
        playback.setTimer(15);
        await tester.pump(const Duration(seconds: 897));

        playback.setTimer(30);

        expect(gateways.single.fades.last, (
          volume: PlaybackController.mixGain(1, 1),
          duration: const Duration(milliseconds: 250),
        ));
        expect(playback.remainingSeconds, 30 * 60);
        playback.dispose();
      },
    );
  });

  group('timer options', () {
    late PlaybackController timed;
    late DateTime Function() fakeNow;
    late MemoryKeyValueStore store;

    // 22:00 on 24 Sep 2026, moving with the test's fake clock.
    void setUpTimed(WidgetTester tester) {
      final start = tester.binding.clock.now();
      fakeNow = () => DateTime(
        2026,
        9,
        24,
        22,
      ).add(tester.binding.clock.now().difference(start));
      store = MemoryKeyValueStore();
      timed = PlaybackController(
        createGateway: createGateway,
        storage: store,
        now: fakeNow,
      );
    }

    Duration lastFade() => gateways.single.fades.last.duration;

    group('gradual fade', () {
      testWidgets('starts N minutes before the end and covers them', (
        tester,
      ) async {
        setUpTimed(tester);
        timed.setGradualFade(true);
        timed.setFadeMinutes(5);
        await timed.toggle(rain);
        timed.setTimer(15);

        await tester.pump(const Duration(seconds: 599));
        expect(gateways.single.fades, hasLength(1));

        await tester.pump(const Duration(seconds: 1));
        expect(gateways.single.fades.last, (
          volume: 0.0,
          duration: const Duration(minutes: 5),
        ));
        expect(timed.playing, isTrue);

        await tester.pump(const Duration(minutes: 5));
        expect(timed.playing, isFalse);
        timed.dispose();
      });

      testWidgets(
        'is off until the user turns it on: four seconds at the end',
        (tester) async {
          setUpTimed(tester);
          await timed.toggle(rain);
          timed.setTimer(15);

          await tester.pump(const Duration(minutes: 14, seconds: 55));
          expect(gateways.single.fades, hasLength(1));

          await tester.pump(const Duration(seconds: 1));
          expect(lastFade(), const Duration(seconds: 4));
          timed.dispose();
        },
      );

      testWidgets('cannot outlast a shorter timer', (tester) async {
        setUpTimed(tester);
        timed.setGradualFade(true);
        timed.setFadeMinutes(15);
        await timed.toggle(rain);
        timed.setTimer(1);

        expect(timed.gradualFadeMinutes, 1);

        await tester.pump(const Duration(seconds: 1));

        expect(lastFade(), const Duration(seconds: 59));
        timed.dispose();
      });

      testWidgets('turning it off mid-fade brings the sound back', (
        tester,
      ) async {
        setUpTimed(tester);
        timed.setGradualFade(true);
        await timed.toggle(rain);
        timed.setTimer(15);
        await tester.pump(const Duration(seconds: 600));
        expect(lastFade(), const Duration(minutes: 5));

        timed.setGradualFade(false);

        expect(gateways.single.fades.last, (
          volume: PlaybackController.mixGain(1, 1),
          duration: const Duration(milliseconds: 250),
        ));
        timed.dispose();
      });

      test('the length stays between 1 and 15 minutes', () {
        final c = PlaybackController(createGateway: createGateway);

        c.setFadeMinutes(0);
        expect(c.fadeMinutes, 1);
        c.setFadeMinutes(99);
        expect(c.fadeMinutes, 15);
        expect(c.gradualFadeMinutes, isNull);
      });
    });

    group('custom duration', () {
      testWidgets('counts down like any other and is remembered', (
        tester,
      ) async {
        setUpTimed(tester);
        await timed.toggle(rain);

        timed.setCustomTimer(150);
        await tester.pump(const Duration(seconds: 10));

        expect(timed.timerMinutes, 150);
        expect(timed.customMinutes, 150);
        expect(timed.remainingSeconds, 150 * 60 - 10);
        timed.dispose();
      });

      test('is kept between 1 minute and 23 h 59 min', () {
        final c = PlaybackController(createGateway: createGateway);

        c.setCustomTimer(0);
        expect(c.timerMinutes, 1);
        c.setCustomTimer(99999);
        expect(c.timerMinutes, 23 * 60 + 59);
      });
    });

    group('stop at', () {
      testWidgets('counts to the time on the clock and keeps the duration', (
        tester,
      ) async {
        setUpTimed(tester);
        await timed.toggle(rain);

        timed.setStopAt(const TimeOfDay(hour: 6, minute: 30));

        expect(timed.remainingSeconds, (8 * 60 + 30) * 60);
        expect(timed.stopAtTime, const TimeOfDay(hour: 6, minute: 30));
        expect(timed.timerMinutes, defaultSleepMinutes);
        timed.dispose();
      });

      testWidgets('a time that already passed today means tomorrow', (
        tester,
      ) async {
        setUpTimed(tester);

        expect(
          timed.secondsUntilNext(const TimeOfDay(hour: 21, minute: 0)),
          23 * 3600,
        );
        expect(
          timed.secondsUntilNext(const TimeOfDay(hour: 22, minute: 0)),
          24 * 3600,
        );
        expect(
          timed.secondsUntilNext(const TimeOfDay(hour: 22, minute: 1)),
          60,
        );
        timed.dispose();
      });

      testWidgets('follows the clock, not the count of ticks', (tester) async {
        setUpTimed(tester);
        await timed.toggle(rain);
        timed.setStopAt(const TimeOfDay(hour: 22, minute: 10));

        await tester.pump(const Duration(minutes: 4));

        expect(timed.remainingSeconds, 6 * 60);
        timed.dispose();
      });

      testWidgets('stops at the time, then goes back to the chosen duration', (
        tester,
      ) async {
        setUpTimed(tester);
        await timed.toggle(rain);
        timed.setStopAt(const TimeOfDay(hour: 22, minute: 1));

        await tester.pump(const Duration(seconds: 61));

        expect(timed.playing, isFalse);
        expect(timed.stopAtTime, isNull);

        await timed.togglePlaying();

        expect(timed.remainingSeconds, defaultSleepMinutes * 60);
        timed.dispose();
      });

      testWidgets('picking a duration cancels it', (tester) async {
        setUpTimed(tester);
        await timed.toggle(rain);
        timed.setStopAt(const TimeOfDay(hour: 6, minute: 30));

        timed.setTimer(30);

        expect(timed.stopAtTime, isNull);
        expect(timed.remainingSeconds, 30 * 60);
        timed.dispose();
      });

      testWidgets('resuming after the time has passed starts a fresh timer', (
        tester,
      ) async {
        setUpTimed(tester);
        await timed.toggle(rain);
        timed.setStopAt(const TimeOfDay(hour: 22, minute: 10));
        await timed.togglePlaying();

        await tester.pump(const Duration(minutes: 15));
        await timed.togglePlaying();

        expect(timed.stopAtTime, isNull);
        expect(timed.remainingSeconds, defaultSleepMinutes * 60);
        expect(timed.playing, isTrue);
        timed.dispose();
      });

      testWidgets('the gradual fade also works with a stop-at time', (
        tester,
      ) async {
        setUpTimed(tester);
        timed.setGradualFade(true);
        timed.setFadeMinutes(2);
        await timed.toggle(rain);
        timed.setStopAt(const TimeOfDay(hour: 22, minute: 10));

        await tester.pump(const Duration(minutes: 8));

        expect(lastFade(), const Duration(minutes: 2));
        timed.dispose();
      });
    });

    group('storage', () {
      testWidgets('the fade options and the custom duration come back', (
        tester,
      ) async {
        setUpTimed(tester);
        timed.setGradualFade(true);
        timed.setFadeMinutes(8);
        timed.commitTimerOptions();
        timed.setCustomTimer(150);
        timed.dispose();

        final restored = PlaybackController(
          createGateway: createGateway,
          storage: store,
        );
        await restored.restore();

        expect(restored.gradualFade, isTrue);
        expect(restored.fadeMinutes, 8);
        expect(restored.customMinutes, 150);
        expect(restored.timerMinutes, 150);
      });

      testWidgets('a stop-at time is not remembered', (tester) async {
        setUpTimed(tester);
        await timed.toggle(rain);
        timed.setStopAt(const TimeOfDay(hour: 6, minute: 30));
        timed.dispose();

        final restored = PlaybackController(
          createGateway: createGateway,
          storage: store,
        );
        await restored.restore();

        expect(restored.stopAtTime, isNull);
        expect(restored.timerMinutes, defaultSleepMinutes);
      });

      test('broken options are ignored', () async {
        final broken = MemoryKeyValueStore();
        await broken.writeString('timer_options_v1', 'nope');
        final c = PlaybackController(
          createGateway: createGateway,
          storage: broken,
        );

        await c.restore();

        expect(c.gradualFade, isFalse);
        expect(c.fadeMinutes, 5);
      });
    });
  });

  group('mixes', () {
    final waves = sounds.firstWhere((s) => s.id == 'waves');

    testWidgets(
      'a snapshot holds the sounds, volumes and optionally the timer',
      (tester) async {
        await playback.toggle(rain);
        await playback.toggle(crickets);
        playback.setSoundVolume(rain, .5);
        playback.setTimer(180);

        final withTimer = playback.snapshot(name: 'A', includeTimer: true);
        final without = playback.snapshot(name: 'B', includeTimer: false);

        expect(withTimer.volumes, {'rain': .5, 'crickets': 1.0});
        expect(withTimer.timerMinutes, 180);
        expect(without.timerMinutes, isNull);
        playback.dispose();
      },
    );

    testWidgets('isMix is true only for the same sounds and volumes', (
      tester,
    ) async {
      await playback.toggle(rain);
      playback.setSoundVolume(rain, .5);

      expect(
        playback.isMix(const SavedMix(name: 'x', volumes: {'rain': .5})),
        isTrue,
      );
      expect(
        playback.isMix(const SavedMix(name: 'x', volumes: {'rain': 1.0})),
        isFalse,
      );
      expect(
        playback.isMix(
          const SavedMix(name: 'x', volumes: {'rain': .5, 'waves': 1.0}),
        ),
        isFalse,
      );
      playback.dispose();
    });

    testWidgets('loading a mix replaces the selection and plays it', (
      tester,
    ) async {
      await playback.toggle(rain);

      await playback.applyMix(
        const SavedMix(
          name: 'Night',
          volumes: {'waves': .4, 'crickets': .8},
          timerMinutes: 180,
        ),
      );

      expect(playback.isSelected(rain), isFalse);
      expect(playback.isSelected(waves), isTrue);
      expect(playback.isSelected(crickets), isTrue);
      expect(playback.volumeOf(waves), .4);
      expect(playback.volumeOf(crickets), .8);
      expect(playback.timerMinutes, 180);
      expect(playback.playing, isTrue);
      expect(gateways.first.disposed, isTrue);
      expect(gateways.last.playingAsset, crickets.asset);
      expect(
        playback.isMix(playback.snapshot(name: 'x', includeTimer: false)),
        isTrue,
      );
      playback.dispose();
    });

    testWidgets('a mix without a timer leaves the timer alone', (tester) async {
      playback.setTimer(360);

      await playback.applyMix(
        const SavedMix(name: 'Quiet', volumes: {'rain': 1.0}),
      );

      expect(playback.timerMinutes, 360);
      expect(playback.isSelected(rain), isTrue);
      playback.dispose();
    });

    testWidgets('a new sound in the mix starts at its saved gain, not full', (
      tester,
    ) async {
      await playback.applyMix(
        const SavedMix(name: 'Soft', volumes: {'rain': .3}),
      );

      expect(gateways.single.volume, PlaybackController.mixGain(.3, .09));
      playback.dispose();
    });

    testWidgets('loading resumes a paused selection that already matches', (
      tester,
    ) async {
      await playback.toggle(rain);
      await playback.togglePlaying();
      expect(playback.playing, isFalse);

      await playback.applyMix(
        const SavedMix(name: 'Same', volumes: {'rain': 1.0}),
      );

      expect(playback.playing, isTrue);
      expect(gateways.single.playingAsset, rain.asset);
      playback.dispose();
    });

    testWidgets('a mix whose sounds are all gone does nothing', (tester) async {
      await playback.toggle(rain);

      await playback.applyMix(
        const SavedMix(name: 'Old', volumes: {'removed_sound': 1.0}),
      );

      expect(playback.isSelected(rain), isTrue);
      playback.dispose();
    });

    testWidgets('loading a mix is saved with the last session', (tester) async {
      final storage = MemoryKeyValueStore();
      final controller = PlaybackController(
        createGateway: createGateway,
        storage: storage,
      );

      await controller.applyMix(
        const SavedMix(
          name: 'Night',
          volumes: {'waves': .4},
          timerMinutes: 180,
        ),
      );

      final saved = await storage.readString('last_session_v1');
      expect(saved, contains('"soundIds":["waves"]'));
      expect(saved, contains('"timerMinutes":180'));
      expect(saved, contains('"waves":0.4'));
      controller.dispose();
    });
  });

  group('individual volume', () {
    test('a quieter sound counts less in the headroom', () {
      const sumOfSquares = 1 + .25;

      expect(
        PlaybackController.mixGain(1, sumOfSquares),
        closeTo(.7 / 1.118033988749895, 1e-9),
      );
      expect(
        PlaybackController.mixGain(.5, sumOfSquares),
        closeTo(.35 / 1.118033988749895, 1e-9),
      );
    });

    testWidgets('changing one volume rebalances every layer', (tester) async {
      await playback.toggle(rain);
      await playback.toggle(crickets);

      playback.setSoundVolume(rain, .5);

      expect(playback.volumeOf(rain), .5);
      expect(playback.volumeOf(crickets), 1);
      expect(gateways.first.volume, PlaybackController.mixGain(.5, 1.25));
      expect(gateways.last.volume, PlaybackController.mixGain(1, 1.25));
      expect(gateways.first.lastFadeDuration, const Duration(milliseconds: 50));
      playback.dispose();
    });

    testWidgets('volume never goes below the minimum or above 1', (
      tester,
    ) async {
      await playback.toggle(rain);

      playback.setSoundVolume(rain, 0);
      expect(playback.volumeOf(rain), PlaybackController.minVolume);

      playback.setSoundVolume(rain, 3);
      expect(playback.volumeOf(rain), 1);
      playback.dispose();
    });

    testWidgets('a sound that is not selected has no volume to set', (
      tester,
    ) async {
      playback.setSoundVolume(rain, .4);

      expect(playback.volumeOf(rain), 1);
    });

    testWidgets('stopping a sound forgets its volume', (tester) async {
      await playback.toggle(rain);
      playback.setSoundVolume(rain, .4);

      await playback.toggle(rain);
      await playback.toggle(rain);

      expect(playback.volumeOf(rain), 1);
      playback.dispose();
    });

    test('committed volumes come back with the session', () async {
      final storage = MemoryKeyValueStore();
      final first = PlaybackController(
        createGateway: createGateway,
        storage: storage,
      );
      await first.toggle(rain);
      await first.toggle(crickets);
      first.setSoundVolume(rain, .3);
      first.commitVolumes();
      first.dispose();
      gateways.clear();

      final restored = PlaybackController(
        createGateway: createGateway,
        storage: storage,
      );
      await restored.restore();

      expect(restored.volumeOf(rain), .3);
      expect(restored.volumeOf(crickets), 1);

      await restored.togglePlaying();

      expect(gateways.first.volume, PlaybackController.mixGain(.3, 1.09));
      restored.dispose();
    });

    test('a session saved without volumes still restores', () async {
      final storage = MemoryKeyValueStore();
      await storage.writeString(
        'last_session_v1',
        '{"soundIds":["rain"],"timerMinutes":60}',
      );
      final restored = PlaybackController(
        createGateway: createGateway,
        storage: storage,
      );
      await restored.restore();

      expect(restored.isSelected(rain), isTrue);
      expect(restored.volumeOf(rain), 1);
    });
  });

  group('mix headroom', () {
    final waves = sounds.firstWhere((s) => s.id == 'waves');

    test('gain is 0.7 for one sound and falls with 1/sqrt(n)', () {
      expect(PlaybackController.mixGain(1, 0), .7);
      expect(PlaybackController.mixGain(1, 1), .7);
      expect(PlaybackController.mixGain(1, 3), closeTo(.7 / 1.7320508, 1e-6));
      expect(PlaybackController.mixGain(1, 5), closeTo(.7 / 2.2360680, 1e-6));
    });

    test('mix power stays constant as sounds are added', () {
      double power(int n) =>
          n *
          PlaybackController.mixGain(1, n.toDouble()) *
          PlaybackController.mixGain(1, n.toDouble());
      expect(power(5), closeTo(power(1), 1e-9));
    });

    testWidgets('adding a sound ramps the others down over 250 ms', (
      tester,
    ) async {
      await playback.toggle(rain);
      expect(gateways.first.volume, PlaybackController.mixGain(1, 1));

      await playback.toggle(crickets);

      expect(gateways.first.volume, PlaybackController.mixGain(1, 2));
      expect(
        gateways.first.lastFadeDuration,
        const Duration(milliseconds: 250),
      );
      expect(gateways.last.volume, PlaybackController.mixGain(1, 2));
      playback.dispose();
    });

    testWidgets('removing a sound ramps the rest back up', (tester) async {
      await playback.toggle(rain);
      await playback.toggle(crickets);
      await playback.toggle(waves);
      expect(gateways.first.volume, PlaybackController.mixGain(1, 3));

      await playback.toggle(waves);

      expect(gateways.first.volume, PlaybackController.mixGain(1, 2));
      expect(gateways[1].volume, PlaybackController.mixGain(1, 2));
      expect(
        gateways.first.lastFadeDuration,
        const Duration(milliseconds: 250),
      );
      playback.dispose();
    });
  });

  testWidgets('pausing keeps every sound selected', (tester) async {
    await playback.toggle(rain);
    await playback.toggle(crickets);

    await playback.togglePlaying();

    expect(playback.playing, isFalse);
    expect(playback.isSelected(rain), isTrue);
    expect(playback.isSelected(crickets), isTrue);
    expect(gateways.every((g) => g.playingAsset == null), isTrue);

    playback.dispose();
  });

  testWidgets('selecting a new sound while paused resumes all of them', (
    tester,
  ) async {
    final waves = sounds.firstWhere((s) => s.id == 'waves');
    await playback.toggle(rain);
    await playback.toggle(crickets);
    await playback.togglePlaying();

    await playback.toggle(waves);

    expect(playback.playing, isTrue);
    expect(gateways.map((g) => g.playingAsset), [
      rain.asset,
      crickets.asset,
      waves.asset,
    ]);

    playback.dispose();
  });

  testWidgets('deselecting while paused stays paused until play', (
    tester,
  ) async {
    await playback.toggle(rain);
    await playback.toggle(crickets);
    await playback.togglePlaying();

    await playback.toggle(rain);

    expect(playback.playing, isFalse);
    expect(playback.isSelected(rain), isFalse);
    expect(gateways.first.disposed, isTrue);
    expect(gateways.last.playingAsset, isNull);

    await playback.togglePlaying();

    expect(gateways.last.playingAsset, crickets.asset);

    playback.dispose();
  });

  testWidgets('play after the timer ran out starts a fresh countdown', (
    tester,
  ) async {
    await playback.toggle(rain);
    playback.setTimer(1);
    await tester.pump(const Duration(seconds: 60));
    expect(playback.playing, isFalse);

    await playback.togglePlaying();
    await tester.pump(const Duration(seconds: 10));

    expect(playback.remainingSeconds, equals(50));

    playback.dispose();
  });

  testWidgets('stopping the last sound stops the timer', (tester) async {
    await playback.toggle(rain);
    await playback.toggle(rain);

    expect(playback.playing, isFalse);

    await tester.pump(const Duration(minutes: 5));
    expect(playback.remainingSeconds, equals(defaultSleepMinutes * 60));

    playback.dispose();
  });

  testWidgets('pause and resume affect every sound', (tester) async {
    await playback.toggle(rain);
    await playback.toggle(crickets);

    await playback.togglePlaying();
    expect(gateways.every((g) => g.playingAsset == null), isTrue);

    await playback.togglePlaying();
    expect(gateways.map((g) => g.playingAsset), [rain.asset, crickets.asset]);

    playback.dispose();
  });

  testWidgets('adding a sound does not restart the timer', (tester) async {
    await playback.toggle(rain);
    playback.setTimer(1);
    await tester.pump(const Duration(seconds: 10));

    await playback.toggle(crickets);

    expect(playback.remainingSeconds, equals(50));

    playback.dispose();
  });

  testWidgets('timer only ticks while playing', (tester) async {
    await playback.toggle(rain);
    playback.setTimer(1);
    await tester.pump(const Duration(seconds: 10));
    expect(playback.remainingSeconds, equals(50));

    await playback.togglePlaying();
    await tester.pump(const Duration(seconds: 60));
    expect(playback.remainingSeconds, equals(50));

    await playback.togglePlaying();
    await tester.pump(const Duration(seconds: 10));
    expect(playback.remainingSeconds, equals(40));

    playback.dispose();
  });

  testWidgets('timer expiry pauses every sound and keeps the duration', (
    tester,
  ) async {
    await playback.toggle(rain);
    await playback.toggle(crickets);
    playback.setTimer(1);

    await tester.pump(const Duration(seconds: 60));

    expect(playback.playing, isFalse);
    expect(gateways.every((g) => g.playingAsset == null), isTrue);
    expect(playback.timerMinutes, equals(1));

    playback.dispose();
  });

  testWidgets('switching duration mid-countdown never leaves two timers', (
    tester,
  ) async {
    await playback.toggle(rain);
    playback.setTimer(1);
    await tester.pump(const Duration(seconds: 5));

    playback.setTimer(2);
    await tester.pump(const Duration(seconds: 10));

    expect(playback.remainingSeconds, equals(110));

    playback.dispose();
  });

  testWidgets('dispose disposes every gateway', (tester) async {
    await playback.toggle(rain);
    await playback.toggle(crickets);

    playback.dispose();

    expect(gateways.every((g) => g.disposed), isTrue);
  });
}

import 'dart:convert';

import 'package:factory_storage/factory_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_sounds/features/mixes/mix_library.dart';
import 'package:sleep_sounds/features/mixes/saved_mix.dart';

SavedMix mix(String name, {Map<String, double>? volumes, int? timer}) =>
    SavedMix(
      name: name,
      volumes: volumes ?? {'rain': 1.0},
      timerMinutes: timer,
    );

void main() {
  late MemoryKeyValueStore storage;
  late MixLibrary library;

  setUp(() {
    storage = MemoryKeyValueStore();
    library = MixLibrary(storage);
  });

  test('a mix survives a round trip through JSON', () {
    final original = mix(
      'Bedtime',
      volumes: {'rain': .8, 'wind': .4},
      timer: 180,
    );

    final copy = SavedMix.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );

    expect(copy.name, 'Bedtime');
    expect(copy.volumes, {'rain': .8, 'wind': .4});
    expect(copy.volumes.keys.toList(), ['rain', 'wind']);
    expect(copy.timerMinutes, 180);
  });

  test('a mix without a timer leaves the timer out', () {
    expect(mix('A').toJson().containsKey('timerMinutes'), isFalse);
    expect(SavedMix.fromJson(mix('A').toJson()).timerMinutes, isNull);
  });

  group('names', () {
    test('the default name is the first free "Mix N"', () {
      expect(library.defaultName(), 'Mix 1');

      library.save(mix('Mix 1'));
      expect(library.defaultName(), 'Mix 2');

      library.save(mix('Mix 2'));
      library.delete('Mix 1');
      expect(library.defaultName(), 'Mix 1');
    });

    test('a name already in use is refused, whatever its case or spacing', () {
      expect(library.save(mix('Bedtime')), isTrue);

      expect(library.save(mix('Bedtime')), isFalse);
      expect(library.save(mix('  bedtime ')), isFalse);
      expect(library.isNameTaken('BEDTIME'), isTrue);
      expect(library.mixes, hasLength(1));
    });

    test('an empty name is refused', () {
      expect(library.save(mix('   ')), isFalse);
      expect(library.mixes, isEmpty);
    });

    test('the saved name is trimmed', () {
      library.save(mix('  Storm  '));

      expect(library.mixes.single.name, 'Storm');
    });
  });

  group('renaming and deleting', () {
    setUp(() {
      library.save(mix('One'));
      library.save(mix('Two'));
    });

    test('rename keeps the mix and its position', () {
      expect(library.rename('One', 'First'), isTrue);

      expect(library.mixes.map((m) => m.name), ['First', 'Two']);
    });

    test('rename to a taken name is refused, to its own name is fine', () {
      expect(library.rename('One', 'two'), isFalse);
      expect(library.rename('One', 'ONE'), isTrue);

      expect(library.mixes.map((m) => m.name), ['ONE', 'Two']);
    });

    test('delete removes only that mix', () {
      library.delete('One');

      expect(library.mixes.map((m) => m.name), ['Two']);
    });
  });

  group('storage', () {
    test('mixes are written with a schema version and load back', () async {
      library.save(mix('Bedtime', volumes: {'rain': .6}, timer: 60));
      await Future<void>.delayed(Duration.zero);

      final doc = jsonDecode(
        (await storage.readString(MixLibrary.storageKey))!,
      ) as Map<String, dynamic>;
      expect(doc['schema'], MixLibrary.currentSchema);

      final reloaded = MixLibrary(storage);
      await reloaded.load();

      expect(reloaded.mixes.single.name, 'Bedtime');
      expect(reloaded.mixes.single.volumes, {'rain': .6});
      expect(reloaded.mixes.single.timerMinutes, 60);
    });

    test('changes notify listeners', () {
      var notified = 0;
      library.addListener(() => notified++);

      library.save(mix('A'));
      library.rename('A', 'B');
      library.delete('B');

      expect(notified, 3);
    });

    test('nothing stored means no mixes', () async {
      await library.load();

      expect(library.mixes, isEmpty);
    });

    test('corrupt data loads as no mixes instead of crashing', () async {
      await storage.writeString(MixLibrary.storageKey, 'not json');

      await library.load();

      expect(library.mixes, isEmpty);
    });
  });
}

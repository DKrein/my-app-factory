import 'package:factory_storage/factory_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MemoryKeyValueStore', () {
    test('writes, reads, and removes string values', () async {
      final store = MemoryKeyValueStore();

      expect(await store.readString('key1'), isNull);

      await store.writeString('key1', 'value1');
      expect(await store.readString('key1'), equals('value1'));

      await store.remove('key1');
      expect(await store.readString('key1'), isNull);
    });
  });
}

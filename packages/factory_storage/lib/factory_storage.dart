/// Small key-value contract. Platform storage stays behind this boundary.
abstract interface class KeyValueStore {
  Future<String?> readString(String key);
  Future<void> writeString(String key, String value);
  Future<void> remove(String key);
}

/// Useful for previews and tests. Apps replace it with a platform adapter.
final class MemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _values = {};
  @override
  Future<String?> readString(String key) async => _values[key];
  @override
  Future<void> writeString(String key, String value) async =>
      _values[key] = value;
  @override
  Future<void> remove(String key) async => _values.remove(key);
}

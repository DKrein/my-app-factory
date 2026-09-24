import 'dart:async';
import 'dart:convert';

import 'package:factory_storage/factory_storage.dart';
import 'package:flutter/foundation.dart';

import 'saved_mix.dart';

/// The user's saved mixes, kept in storage as
/// `{"schema": 1, "mixes": [...]}`.
///
/// Whether the user may save one more is decided by `ProFeatures`, not here.
class MixLibrary extends ChangeNotifier {
  MixLibrary(this._storage);

  static const storageKey = 'saved_mixes';
  static const currentSchema = 1;

  /// Upgrades a document from schema N to N+1. Add an entry when the format
  /// changes; the loader applies them in order.
  static final Map<int, Map<String, dynamic> Function(Map<String, dynamic>)>
  _migrations = {};

  final KeyValueStore _storage;
  List<SavedMix> _mixes = const [];

  List<SavedMix> get mixes => List.unmodifiable(_mixes);

  Future<void> load() async {
    final raw = await _storage.readString(storageKey);
    if (raw == null) return;
    try {
      var doc = jsonDecode(raw) as Map<String, dynamic>;
      var schema = doc['schema'] as int;
      while (schema < currentSchema) {
        doc = _migrations[schema]!(doc);
        schema = doc['schema'] as int;
      }
      _mixes = [
        for (final json in (doc['mixes'] as List).cast<Map<String, dynamic>>())
          SavedMix.fromJson(json),
      ];
    } catch (_) {
      _mixes = const [];
    }
    notifyListeners();
  }

  /// The first free "Mix N".
  String defaultName() {
    var n = 1;
    while (isNameTaken('Mix $n')) {
      n++;
    }
    return 'Mix $n';
  }

  bool isNameTaken(String name, {String? except}) {
    final wanted = _normalize(name);
    return _mixes.any((m) => _normalize(m.name) == wanted && m.name != except);
  }

  /// Saves [mix] unless its name is empty or already used. Returns whether it
  /// was saved.
  bool save(SavedMix mix) {
    final name = mix.name.trim();
    if (name.isEmpty || isNameTaken(name)) return false;
    _replace([..._mixes, mix.withName(name)]);
    return true;
  }

  bool rename(String name, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || isNameTaken(trimmed, except: name)) return false;
    _replace([
      for (final m in _mixes) m.name == name ? m.withName(trimmed) : m,
    ]);
    return true;
  }

  void delete(String name) => _replace([
    for (final m in _mixes)
      if (m.name != name) m,
  ]);

  void _replace(List<SavedMix> mixes) {
    _mixes = mixes;
    unawaited(
      _storage.writeString(
        storageKey,
        jsonEncode({
          'schema': currentSchema,
          'mixes': [for (final m in _mixes) m.toJson()],
        }),
      ),
    );
    notifyListeners();
  }

  static String _normalize(String name) => name.trim().toLowerCase();
}

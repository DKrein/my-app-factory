import 'dart:async';

import 'package:factory_storage/factory_storage.dart';
import 'package:factory_ui/factory_ui.dart';
import 'package:flutter/foundation.dart';

/// The palette the user picked, kept in storage as its id.
///
/// This holds only the choice. What is actually drawn also depends on Pro:
/// see `SleepSoundsApp`, which falls back to [FactoryPalette.capyNight] when
/// the picked palette is not allowed.
class ThemeController extends ChangeNotifier {
  ThemeController(this._storage);

  static const storageKey = 'theme_v1';

  final KeyValueStore _storage;
  FactoryPalette _selected = FactoryPalette.capyNight;

  /// The palettes the picker offers, in order.
  List<FactoryPalette> get options => FactoryPalette.all;

  FactoryPalette get selected => _selected;

  Future<void> load() async {
    final id = await _storage.readString(storageKey);
    if (id == null) return;
    _selected = FactoryPalette.byId(id);
    notifyListeners();
  }

  void select(FactoryPalette palette) {
    if (palette.id == _selected.id) return;
    _selected = palette;
    unawaited(_storage.writeString(storageKey, palette.id));
    notifyListeners();
  }
}

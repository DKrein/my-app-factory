import 'dart:convert';

import 'package:factory_ui/factory_ui.dart';

import 'sounds.dart';

/// Reads assets/credits.json, the single record of who made each sound and
/// under which license. A sound's title comes from the catalog, and
/// [changesText] is what to say about a sound that was edited.
List<CreditEntry> parseCredits(
  String json, {
  required String Function(Sound sound) soundLabel,
  required String changesText,
}) {
  final names = {for (final sound in sounds) sound.id: soundLabel(sound)};
  return [
    for (final entry in (jsonDecode(json) as List).cast<Map<String, dynamic>>())
      CreditEntry(
        title: names[entry['soundId']] ?? entry['soundId'] as String,
        originalTitle: entry['originalTitle'] as String,
        author: entry['author'] as String,
        sourceUrl: entry['sourceUrl'] as String,
        license: entry['license'] as String,
        licenseUrl: entry['licenseUrl'] as String,
        changes: entry['edited'] == true ? changesText : null,
      ),
  ];
}

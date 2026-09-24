import 'dart:convert';

import 'package:factory_ui/factory_ui.dart';

import 'sounds.dart';

/// Reads assets/credits.json, the single record of who made each sound and
/// under which license. A sound's title comes from the catalog.
List<CreditEntry> parseCredits(String json) {
  final names = {for (final sound in sounds) sound.id: sound.name};
  return [
    for (final entry in (jsonDecode(json) as List).cast<Map<String, dynamic>>())
      CreditEntry(
        title: names[entry['soundId']] ?? entry['soundId'] as String,
        originalTitle: entry['originalTitle'] as String,
        author: entry['author'] as String,
        sourceUrl: entry['sourceUrl'] as String,
        license: entry['license'] as String,
        licenseUrl: entry['licenseUrl'] as String,
        changes: entry['changes'] as String?,
      ),
  ];
}

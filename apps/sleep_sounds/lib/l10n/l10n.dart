import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/widgets.dart';

import '../content/sounds.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

extension AppL10nContext on BuildContext {
  /// The app's strings in the language of the device.
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// The strings for the device language, for code that has no [BuildContext]:
/// notifications and the notification channels. English when the device
/// language is not supported.
AppLocalizations deviceL10n() {
  final device = PlatformDispatcher.instance.locale;
  final supported = AppLocalizations.supportedLocales.firstWhere(
    (l) => l.languageCode == device.languageCode,
    orElse: () => const Locale('en'),
  );
  return lookupAppLocalizations(supported);
}

/// The name of [sound] in the language of [l10n].
String soundName(AppLocalizations l10n, Sound sound) => switch (sound.id) {
  'rain' => l10n.soundRain,
  'rain_tent' => l10n.soundRainTent,
  'waves' => l10n.soundWaves,
  'airplane' => l10n.soundAirplane,
  'river' => l10n.soundRiver,
  'forest_rain' => l10n.soundForestRain,
  'campfire' => l10n.soundCampfire,
  'stream' => l10n.soundStream,
  'storm' => l10n.soundStorm,
  'winter' => l10n.soundWinter,
  'train' => l10n.soundTrain,
  'cat_purring' => l10n.soundCatPurring,
  'birds' => l10n.soundBirds,
  'crickets' => l10n.soundCrickets,
  'wind' => l10n.soundWind,
  'chimes' => l10n.soundChimes,
  'clock' => l10n.soundClock,
  _ => sound.id,
};

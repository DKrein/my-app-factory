// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get aboutTooltip => 'About the app';

  @override
  String get welcome => 'Welcome!';

  @override
  String get welcomeBody =>
      'This is the starting point for your new App Factory app.';

  @override
  String get persistenceActive => 'Local persistence is on';

  @override
  String actionsSaved(int count) {
    return 'Actions saved in the KeyValueStore: $count';
  }

  @override
  String get loadingState => 'Loading state...';

  @override
  String get incrementAction => 'Add action';

  @override
  String get aboutTitle => 'About this app';

  @override
  String get aboutBody =>
      'Built with Flutter on the reusable App Factory base. Fully offline-first, with no hidden network dependencies.';
}

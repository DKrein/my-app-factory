// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get homeTitle => 'Time to capy-nap';

  @override
  String get timerTitle => 'Capy Timer';

  @override
  String get windDownTitle => 'To wind down';

  @override
  String get tooltipSettings => 'Settings';

  @override
  String get tooltipPause => 'Pause';

  @override
  String get tooltipPlay => 'Play';

  @override
  String get selectSoundToPlay => 'Select a sound to play';

  @override
  String get proIsOn => 'Pro is on. Thank you!';

  @override
  String get timerOptions => 'Timer options';

  @override
  String get timerOptionsPro => 'Timer options (Pro)';

  @override
  String get saveMix => 'Save mix';

  @override
  String get saveMixPro => 'Save mix (Pro)';

  @override
  String get statusPaused => 'Paused';

  @override
  String get statusPlaying => 'Playing';

  @override
  String statusStoppingIn(String time) {
    return 'Stopping in $time';
  }

  @override
  String statusStoppingAt(String clock, String time) {
    return 'Stopping at $clock · in $time';
  }

  @override
  String statusWithFade(String status, int minutes) {
    return '$status · fades over the last $minutes min';
  }

  @override
  String get timerOff => 'Off';

  @override
  String get volumeLocked => 'Volume, a Pro feature';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get tooltipCloseSettings => 'Close settings';

  @override
  String get proTitle => 'Sleepy Capy Pro';

  @override
  String get proCardBody =>
      'Volume for each sound, saved mixes and more. One purchase, no ads.';

  @override
  String get seePro => 'See Pro';

  @override
  String get proThanks => 'Thank you for supporting Sleepy Capy.';

  @override
  String get restorePurchase => 'Restore Purchase';

  @override
  String get bedtimeReminder => 'Bedtime Reminder';

  @override
  String reminderDaily(String time) {
    return 'Daily at $time';
  }

  @override
  String get reminderOff => 'Off';

  @override
  String get reminderPickerHelp => 'What time?';

  @override
  String get rateApp => 'Rate Sleepy Capy';

  @override
  String get sendFeedback => 'Send Feedback';

  @override
  String get playbackStops => 'Playback stops unexpectedly?';

  @override
  String get aboutItem => 'About';

  @override
  String get batteryTitle => 'Battery optimization';

  @override
  String get batteryBody =>
      'Android may stop background apps to save battery, which can interrupt playback during the night.\n\nTap Open settings, choose Battery and allow unrestricted battery usage for Sleepy Capy. The exact wording varies by device.';

  @override
  String get cancel => 'Cancel';

  @override
  String get openSettings => 'Open settings';

  @override
  String get close => 'Close';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutPrivacyPolicy => 'Privacy Policy';

  @override
  String get aboutContact => 'Contact';

  @override
  String get aboutLicenses => 'Open source licenses';

  @override
  String get aboutAudioCredits => 'Audio credits';

  @override
  String creditLine(String title, String author) {
    return '\"$title\" by $author';
  }

  @override
  String changesLine(String changes) {
    return 'Changes: $changes';
  }

  @override
  String get creditChangesEdited => 'Trimmed, looped and level-adjusted.';

  @override
  String get mixSaveTitle => 'Save mix';

  @override
  String get mixRenameTitle => 'Rename mix';

  @override
  String get mixSaveAction => 'Save';

  @override
  String get mixRenameAction => 'Rename';

  @override
  String get mixDeleteAction => 'Delete';

  @override
  String get mixNameLabel => 'Name';

  @override
  String get mixNameTaken => 'That name is already used. Pick another.';

  @override
  String mixIncludeTimer(String label) {
    return 'Include timer ($label)';
  }

  @override
  String mixDeleteTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get timerSheetTitle => 'Timer options';

  @override
  String get fadeSection => 'Fade out';

  @override
  String get fadeGradually => 'Fade out gradually';

  @override
  String fadeOnHint(int minutes) {
    return 'Volume lowers over the last $minutes min.';
  }

  @override
  String get fadeOffHint => 'Off: the sound fades in the last 4 s.';

  @override
  String get customDuration => 'Custom duration';

  @override
  String get stopAtSection => 'Stop at';

  @override
  String get setAction => 'Set';

  @override
  String inTime(String time) {
    return 'in $time';
  }

  @override
  String get paywallSubtitle => 'One purchase, yours to keep. No subscription.';

  @override
  String get paywallOwnedTitle => 'You have Pro';

  @override
  String get paywallFeatureVolume => 'Set the volume of each sound';

  @override
  String get paywallFeatureMixes => 'Save as many mixes as you like';

  @override
  String get paywallFeatureTimer =>
      'Fade out slowly, set any length, or stop at a time';

  @override
  String get paywallFeatureThemes => 'More night themes';

  @override
  String get paywallFeatureNoAds => 'No ads';

  @override
  String get paywallFreeNote =>
      'All 17 sounds, mixing and the timer stay free.';

  @override
  String paywallPrice(String price) {
    return '$price · one-time purchase';
  }

  @override
  String get getPro => 'Get Pro';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get tryAgain => 'Try again';

  @override
  String get paywallStoreUnreachable =>
      'Can\'t reach the store right now. Check your connection and try again.';

  @override
  String get paywallPending =>
      'Waiting for your payment to go through. Pro turns on by itself when it does.';

  @override
  String get paywallPurchaseFailed =>
      'The purchase didn\'t go through. Try again.';

  @override
  String get paywallRestoreFailed =>
      'Couldn\'t check your purchases. Check your connection and try again.';

  @override
  String get paywallNothingToRestore =>
      'No earlier Pro purchase was found on this Google account.';

  @override
  String get themeTitle => 'Theme';

  @override
  String get themeProNote => 'Extra themes are part of Sleepy Capy Pro.';

  @override
  String themeProLabel(String name) {
    return '$name, a Pro theme';
  }

  @override
  String get audioChannelName => 'Sound playback';

  @override
  String get reminderChannelName => 'Bedtime reminder';

  @override
  String get reminderChannelDescription =>
      'Daily reminder to wind down for sleep';

  @override
  String get reminderNotificationTitle => 'It\'s Capytime!';

  @override
  String get reminderNotificationBody =>
      'It\'s Capytime! Time to get cozy and sleepy.';

  @override
  String get soundRain => 'Rain';

  @override
  String get soundRainTent => 'Rain in tent';

  @override
  String get soundWaves => 'Waves';

  @override
  String get soundAirplane => 'Airplane';

  @override
  String get soundRiver => 'River';

  @override
  String get soundForestRain => 'Forest rain';

  @override
  String get soundCampfire => 'Campfire';

  @override
  String get soundStream => 'Stream';

  @override
  String get soundStorm => 'Storm';

  @override
  String get soundWinter => 'Winter';

  @override
  String get soundTrain => 'Train';

  @override
  String get soundCatPurring => 'Cat purring';

  @override
  String get soundBirds => 'Birds';

  @override
  String get soundCrickets => 'Crickets';

  @override
  String get soundWind => 'Wind';

  @override
  String get soundChimes => 'Chimes';

  @override
  String get soundClock => 'Clock';
}

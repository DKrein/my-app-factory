import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Time to capy-nap'**
  String get homeTitle;

  /// No description provided for @timerTitle.
  ///
  /// In en, this message translates to:
  /// **'Capy Timer'**
  String get timerTitle;

  /// No description provided for @windDownTitle.
  ///
  /// In en, this message translates to:
  /// **'To wind down'**
  String get windDownTitle;

  /// No description provided for @tooltipSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tooltipSettings;

  /// No description provided for @tooltipPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get tooltipPause;

  /// No description provided for @tooltipPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get tooltipPlay;

  /// No description provided for @selectSoundToPlay.
  ///
  /// In en, this message translates to:
  /// **'Select a sound to play'**
  String get selectSoundToPlay;

  /// No description provided for @proIsOn.
  ///
  /// In en, this message translates to:
  /// **'Pro is on. Thank you!'**
  String get proIsOn;

  /// No description provided for @timerOptions.
  ///
  /// In en, this message translates to:
  /// **'Timer options'**
  String get timerOptions;

  /// No description provided for @timerOptionsPro.
  ///
  /// In en, this message translates to:
  /// **'Timer options (Pro)'**
  String get timerOptionsPro;

  /// No description provided for @saveMix.
  ///
  /// In en, this message translates to:
  /// **'Save mix'**
  String get saveMix;

  /// No description provided for @saveMixPro.
  ///
  /// In en, this message translates to:
  /// **'Save mix (Pro)'**
  String get saveMixPro;

  /// No description provided for @statusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get statusPaused;

  /// No description provided for @statusPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get statusPlaying;

  /// No description provided for @statusStoppingIn.
  ///
  /// In en, this message translates to:
  /// **'Stopping in {time}'**
  String statusStoppingIn(String time);

  /// No description provided for @statusStoppingAt.
  ///
  /// In en, this message translates to:
  /// **'Stopping at {clock} · in {time}'**
  String statusStoppingAt(String clock, String time);

  /// No description provided for @statusWithFade.
  ///
  /// In en, this message translates to:
  /// **'{status} · fades over the last {minutes} min'**
  String statusWithFade(String status, int minutes);

  /// No description provided for @timerOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get timerOff;

  /// No description provided for @volumeLocked.
  ///
  /// In en, this message translates to:
  /// **'Volume, a Pro feature'**
  String get volumeLocked;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @tooltipCloseSettings.
  ///
  /// In en, this message translates to:
  /// **'Close settings'**
  String get tooltipCloseSettings;

  /// No description provided for @proTitle.
  ///
  /// In en, this message translates to:
  /// **'Sleepy Capy Pro'**
  String get proTitle;

  /// No description provided for @proCardBody.
  ///
  /// In en, this message translates to:
  /// **'Volume for each sound, saved mixes and more. One purchase, no ads.'**
  String get proCardBody;

  /// No description provided for @seePro.
  ///
  /// In en, this message translates to:
  /// **'See Pro'**
  String get seePro;

  /// No description provided for @proThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you for supporting Sleepy Capy.'**
  String get proThanks;

  /// No description provided for @restorePurchase.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchase'**
  String get restorePurchase;

  /// No description provided for @bedtimeReminder.
  ///
  /// In en, this message translates to:
  /// **'Bedtime Reminder'**
  String get bedtimeReminder;

  /// No description provided for @reminderDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily at {time}'**
  String reminderDaily(String time);

  /// No description provided for @reminderOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get reminderOff;

  /// No description provided for @reminderPickerHelp.
  ///
  /// In en, this message translates to:
  /// **'What time?'**
  String get reminderPickerHelp;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate Sleepy Capy'**
  String get rateApp;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @playbackStops.
  ///
  /// In en, this message translates to:
  /// **'Playback stops unexpectedly?'**
  String get playbackStops;

  /// No description provided for @aboutItem.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutItem;

  /// No description provided for @batteryTitle.
  ///
  /// In en, this message translates to:
  /// **'Battery optimization'**
  String get batteryTitle;

  /// No description provided for @batteryBody.
  ///
  /// In en, this message translates to:
  /// **'Android may stop background apps to save battery, which can interrupt playback during the night.\n\nTap Open settings, choose Battery and allow unrestricted battery usage for Sleepy Capy. The exact wording varies by device.'**
  String get batteryBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// No description provided for @aboutPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get aboutPrivacyPolicy;

  /// No description provided for @aboutContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get aboutContact;

  /// No description provided for @aboutLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get aboutLicenses;

  /// No description provided for @aboutAudioCredits.
  ///
  /// In en, this message translates to:
  /// **'Audio credits'**
  String get aboutAudioCredits;

  /// No description provided for @creditLine.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" by {author}'**
  String creditLine(String title, String author);

  /// No description provided for @changesLine.
  ///
  /// In en, this message translates to:
  /// **'Changes: {changes}'**
  String changesLine(String changes);

  /// No description provided for @creditChangesEdited.
  ///
  /// In en, this message translates to:
  /// **'Trimmed, looped and level-adjusted.'**
  String get creditChangesEdited;

  /// No description provided for @mixSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save mix'**
  String get mixSaveTitle;

  /// No description provided for @mixRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename mix'**
  String get mixRenameTitle;

  /// No description provided for @mixSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get mixSaveAction;

  /// No description provided for @mixRenameAction.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get mixRenameAction;

  /// No description provided for @mixDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get mixDeleteAction;

  /// No description provided for @mixNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get mixNameLabel;

  /// No description provided for @mixNameTaken.
  ///
  /// In en, this message translates to:
  /// **'That name is already used. Pick another.'**
  String get mixNameTaken;

  /// No description provided for @mixIncludeTimer.
  ///
  /// In en, this message translates to:
  /// **'Include timer ({label})'**
  String mixIncludeTimer(String label);

  /// No description provided for @mixDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String mixDeleteTitle(String name);

  /// No description provided for @timerSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Timer options'**
  String get timerSheetTitle;

  /// No description provided for @fadeSection.
  ///
  /// In en, this message translates to:
  /// **'Fade out'**
  String get fadeSection;

  /// No description provided for @fadeGradually.
  ///
  /// In en, this message translates to:
  /// **'Fade out gradually'**
  String get fadeGradually;

  /// No description provided for @fadeOnHint.
  ///
  /// In en, this message translates to:
  /// **'Volume lowers over the last {minutes} min.'**
  String fadeOnHint(int minutes);

  /// No description provided for @fadeOffHint.
  ///
  /// In en, this message translates to:
  /// **'Off: the sound fades in the last 4 s.'**
  String get fadeOffHint;

  /// No description provided for @customDuration.
  ///
  /// In en, this message translates to:
  /// **'Custom duration'**
  String get customDuration;

  /// No description provided for @stopAtSection.
  ///
  /// In en, this message translates to:
  /// **'Stop at'**
  String get stopAtSection;

  /// No description provided for @setAction.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get setAction;

  /// No description provided for @inTime.
  ///
  /// In en, this message translates to:
  /// **'in {time}'**
  String inTime(String time);

  /// No description provided for @paywallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One purchase, yours to keep. No subscription.'**
  String get paywallSubtitle;

  /// No description provided for @paywallOwnedTitle.
  ///
  /// In en, this message translates to:
  /// **'You have Pro'**
  String get paywallOwnedTitle;

  /// No description provided for @paywallFeatureVolume.
  ///
  /// In en, this message translates to:
  /// **'Set the volume of each sound'**
  String get paywallFeatureVolume;

  /// No description provided for @paywallFeatureMixes.
  ///
  /// In en, this message translates to:
  /// **'Save as many mixes as you like'**
  String get paywallFeatureMixes;

  /// No description provided for @paywallFeatureTimer.
  ///
  /// In en, this message translates to:
  /// **'Fade out slowly, set any length, or stop at a time'**
  String get paywallFeatureTimer;

  /// No description provided for @paywallFeatureThemes.
  ///
  /// In en, this message translates to:
  /// **'More night themes'**
  String get paywallFeatureThemes;

  /// No description provided for @paywallFeatureNoAds.
  ///
  /// In en, this message translates to:
  /// **'No ads'**
  String get paywallFeatureNoAds;

  /// No description provided for @paywallFreeNote.
  ///
  /// In en, this message translates to:
  /// **'All 17 sounds, mixing and the timer stay free.'**
  String get paywallFreeNote;

  /// No description provided for @paywallPrice.
  ///
  /// In en, this message translates to:
  /// **'{price} · one-time purchase'**
  String paywallPrice(String price);

  /// No description provided for @getPro.
  ///
  /// In en, this message translates to:
  /// **'Get Pro'**
  String get getPro;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @paywallStoreUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the store right now. Check your connection and try again.'**
  String get paywallStoreUnreachable;

  /// No description provided for @paywallPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your payment to go through. Pro turns on by itself when it does.'**
  String get paywallPending;

  /// No description provided for @paywallPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'The purchase didn\'t go through. Try again.'**
  String get paywallPurchaseFailed;

  /// No description provided for @paywallRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check your purchases. Check your connection and try again.'**
  String get paywallRestoreFailed;

  /// No description provided for @paywallNothingToRestore.
  ///
  /// In en, this message translates to:
  /// **'No earlier Pro purchase was found on this Google account.'**
  String get paywallNothingToRestore;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeTitle;

  /// No description provided for @themeProNote.
  ///
  /// In en, this message translates to:
  /// **'Extra themes are part of Sleepy Capy Pro.'**
  String get themeProNote;

  /// No description provided for @themeProLabel.
  ///
  /// In en, this message translates to:
  /// **'{name}, a Pro theme'**
  String themeProLabel(String name);

  /// No description provided for @audioChannelName.
  ///
  /// In en, this message translates to:
  /// **'Sound playback'**
  String get audioChannelName;

  /// No description provided for @reminderChannelName.
  ///
  /// In en, this message translates to:
  /// **'Bedtime reminder'**
  String get reminderChannelName;

  /// No description provided for @reminderChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder to wind down for sleep'**
  String get reminderChannelDescription;

  /// No description provided for @reminderNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'It\'s Capytime!'**
  String get reminderNotificationTitle;

  /// No description provided for @reminderNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'It\'s Capytime! Time to get cozy and sleepy.'**
  String get reminderNotificationBody;

  /// Name of a sound in the catalog
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get soundRain;

  /// Name of a sound in the catalog
  ///
  /// In en, this message translates to:
  /// **'Rain in tent'**
  String get soundRainTent;

  /// Name of a sound in the catalog
  ///
  /// In en, this message translates to:
  /// **'Waves'**
  String get soundWaves;

  /// Name of a sound in the catalog
  ///
  /// In en, this message translates to:
  /// **'Airplane'**
  String get soundAirplane;

  /// Name of a sound in the catalog
  ///
  /// In en, this message translates to:
  /// **'River'**
  String get soundRiver;

  /// Name of a sound in the catalog
  ///
  /// In en, this message translates to:
  /// **'Forest rain'**
  String get soundForestRain;

  /// Name of a sound in the catalog
  ///
  /// In en, this message translates to:
  /// **'Campfire'**
  String get soundCampfire;

  /// Name of a sound in the catalog
  ///
  /// In en, this message translates to:
  /// **'Stream'**
  String get soundStream;

  /// Name of a sound in the catalog
  ///
  /// In en, this message translates to:
  /// **'Storm'**
  String get soundStorm;

  /// Name of a sound in the catalog
  ///
  /// In en, this message translates to:
  /// **'Winter'**
  String get soundWinter;

  /// Name of a sound in the catalog
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get soundTrain;

  /// Name of a sound in the catalog
  ///
  /// In en, this message translates to:
  /// **'Cat purring'**
  String get soundCatPurring;

  /// Name of a sound in the catalog
  ///
  /// In en, this message translates to:
  /// **'Birds'**
  String get soundBirds;

  /// Name of a sound in the catalog
  ///
  /// In en, this message translates to:
  /// **'Crickets'**
  String get soundCrickets;

  /// Name of a sound in the catalog
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get soundWind;

  /// Name of a sound in the catalog
  ///
  /// In en, this message translates to:
  /// **'Chimes'**
  String get soundChimes;

  /// Name of a sound in the catalog
  ///
  /// In en, this message translates to:
  /// **'Clock'**
  String get soundClock;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

import 'dart:async';

import 'package:factory_ads/factory_ads.dart';
import 'package:factory_audio/factory_audio.dart';
import 'package:factory_billing/factory_billing.dart';
import 'package:factory_storage/factory_storage.dart';
import 'package:flutter/material.dart';

import 'app_config.g.dart';
import 'features/library/library_page.dart';
import 'features/mixes/mix_library.dart';
import 'features/player/player_controller.dart';
import 'features/pro/pro_features.dart';
import 'features/theme/theme_controller.dart';
import 'features/reminders/bedtime_reminder.dart';

import 'package:factory_ui/factory_ui.dart';

import 'l10n/l10n.dart';

const sleepSoundsCatalog = BillingCatalog(
  products: [
    BillingProduct(
      id: AppConfig.proProductId,
      entitlements: {ProFeatures.entitlement},
      title: 'Sleepy Capy Pro',
      description: 'One-time purchase. Unlocks every Pro feature.',
    ),
  ],
);

const defaultProProduct = StoreProduct(
  id: AppConfig.proProductId,
  title: 'Sleepy Capy Pro',
  description: 'One-time purchase. Unlocks every Pro feature.',
  price: r'$4.99',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final nowPlaying = await AudioServiceNotifier.init(
    channelId: '${AppConfig.applicationId}.audio',
    channelName: deviceL10n().audioChannelName,
    notificationIcon: 'drawable/ic_launcher_monochrome',
  );
  final storage = await SharedPreferencesStore.create();
  final ads = GoogleMobileAdsGateway();
  final billing = PlayBillingGateway(catalog: sleepSoundsCatalog);

  // Non-blocking initialization
  unawaited(
    bedtimeReminders
        .init()
        .then((_) => bedtimeReminders.restore(storage))
        .catchError((_) {}),
  );

  runApp(
    SleepSoundsApp(
      storage: storage,
      ads: ads,
      billing: billing,
      nowPlaying: nowPlaying,
    ),
  );
}

class SleepSoundsApp extends StatefulWidget {
  const SleepSoundsApp({
    super.key,
    this.createGateway,
    this.storage,
    this.ads,
    this.billing,
    this.nowPlaying,
  });

  final AudioGatewayFactory? createGateway;
  final KeyValueStore? storage;
  final AdsGateway? ads;
  final BillingGateway? billing;
  final NowPlayingNotifier? nowPlaying;

  @override
  State<SleepSoundsApp> createState() => _SleepSoundsAppState();
}

class _SleepSoundsAppState extends State<SleepSoundsApp> {
  late final PlaybackController _playback;
  late final MixLibrary _mixes;
  late final ThemeController _themes;
  final _storeSettled = ValueNotifier(false);
  late final KeyValueStore _storage;
  late final AdsGateway _ads;
  late final BillingGateway _billing;

  @override
  void initState() {
    super.initState();
    _storage = widget.storage ?? MemoryKeyValueStore();
    _playback = PlaybackController(
      createGateway:
          widget.createGateway ??
          ({required ownsAudioSession}) =>
              JustAudioGateway(ownsAudioSession: ownsAudioSession),
      nowPlaying: widget.nowPlaying,
      storage: _storage,
      soundLabel: (sound) => soundName(deviceL10n(), sound),
    );
    unawaited(_playback.restore());
    _mixes = MixLibrary(_storage);
    unawaited(_mixes.load());
    _themes = ThemeController(_storage);
    unawaited(_themes.load());
    widget.nowPlaying?.bindTransport(
      onPlay: _playback.togglePlaying,
      onPause: _playback.togglePlaying,
    );
    _ads = widget.ads ?? PreviewAdsGateway(initialized: true);
    _billing =
        widget.billing ??
        FakeBillingGateway(
          catalog: sleepSoundsCatalog,
          initialProducts: [defaultProProduct],
        );
    unawaited(_initializeMonetization());
  }

  /// Opens the store first: what the user owns decides whether the ad SDK is
  /// started at all. Pro users never start it.
  Future<void> _initializeMonetization() async {
    await _billing.initialize();
    if (!mounted) return;
    _storeSettled.value = true;
    if (ProFeatures(_billing.entitlements).showAds) await _ads.initialize();
  }

  @override
  void dispose() {
    _playback.dispose();
    _mixes.dispose();
    _themes.dispose();
    _storeSettled.dispose();
    super.dispose();
  }

  /// The picked palette, unless it needs Pro and the user has not got it.
  /// Until the store has answered, the picked one is shown so a Pro user does
  /// not see the default flash at every launch.
  FactoryPalette get _palette {
    final picked = _themes.selected;
    final pro = ProFeatures(_billing.entitlements);
    return _storeSettled.value && !pro.canUseTheme(picked)
        ? FactoryPalette.capyNight
        : picked;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      _themes,
      _storeSettled,
      ProFeatures(_billing.entitlements).changes,
    ]),
    builder: (context, _) => MaterialApp(
      title: AppConfig.name,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: factoryDarkTheme(_palette),
      home: LibraryPage(
        playback: _playback,
        mixes: _mixes,
        themes: _themes,
        storage: _storage,
        ads: _ads,
        billing: _billing,
      ),
    ),
  );
}

import 'dart:async';

import 'package:factory_ads/factory_ads.dart';
import 'package:factory_audio/factory_audio.dart';
import 'package:factory_billing/factory_billing.dart';
import 'package:factory_storage/factory_storage.dart';
import 'package:flutter/material.dart';

import 'app_config.g.dart';
import 'features/library/library_page.dart';
import 'features/player/player_controller.dart';
import 'features/reminders/bedtime_reminder.dart';
import 'features/splash/splash_screen.dart';

import 'package:factory_ui/factory_ui.dart';

const sleepSoundsCatalog = BillingCatalog(
  products: [
    BillingProduct(
      id: AppConfig.removeAdsProductId,
      entitlements: {FactoryEntitlements.removeAds},
      title: 'Remove Ads',
      description: 'Turn off every banner and ad in the app.',
    ),
  ],
);

const defaultRemoveAdsProduct = StoreProduct(
  id: AppConfig.removeAdsProductId,
  title: 'Remove Ads',
  description: 'Permanently disables all ads',
  price: r'$2.99',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final nowPlaying = await AudioServiceNotifier.init(
    channelId: '${AppConfig.applicationId}.audio',
    channelName: 'Sound playback',
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
  unawaited(ads.initialize());
  unawaited(billing.initialize());

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
  late final KeyValueStore _storage;
  late final AdsGateway _ads;
  late final BillingGateway _billing;

  @override
  void initState() {
    super.initState();
    _playback = PlaybackController(
      createGateway:
          widget.createGateway ??
          ({required ownsAudioSession}) =>
              JustAudioGateway(ownsAudioSession: ownsAudioSession),
      nowPlaying: widget.nowPlaying,
    );
    widget.nowPlaying?.bindTransport(
      onPlay: _playback.togglePlaying,
      onPause: _playback.togglePlaying,
    );
    _storage = widget.storage ?? MemoryKeyValueStore();
    _ads = widget.ads ?? PreviewAdsGateway(initialized: true);
    _billing =
        widget.billing ??
        FakeBillingGateway(
          catalog: sleepSoundsCatalog,
          initialProducts: [defaultRemoveAdsProduct],
        );
  }

  @override
  void dispose() {
    _playback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: AppConfig.name,
    debugShowCheckedModeBanner: false,
    theme: factoryDarkTheme(),
    home: AppSplashScreen(
      storage: _storage,
      next: LibraryPage(
        playback: _playback,
        storage: _storage,
        ads: _ads,
        billing: _billing,
      ),
    ),
  );
}

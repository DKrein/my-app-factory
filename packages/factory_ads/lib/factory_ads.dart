import 'dart:async';

import 'package:factory_core/factory_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Official Google AdMob test ad unit IDs.
/// Use these during development and testing to prevent policy violations.
abstract final class AdmobTestUnits {
  /// Test App ID (Android).
  static const androidAppId = 'ca-app-pub-3940256099942544~3347511713';

  /// Standard Banner test ad unit (Android).
  static const androidBanner = 'ca-app-pub-3940256099942544/6300978111';

  /// Standard Interstitial test ad unit (Android).
  static const androidInterstitial = 'ca-app-pub-3940256099942544/1033173712';

  /// Standard Rewarded test ad unit (Android).
  static const androidRewarded = 'ca-app-pub-3940256099942544/5224354917';

  /// Standard Banner test ad unit (iOS).
  static const iosBanner = 'ca-app-pub-3940256099942544/2934735716';

  /// Standard Interstitial test ad unit (iOS).
  static const iosInterstitial = 'ca-app-pub-3940256099942544/4411468910';

  /// Standard Rewarded test ad unit (iOS).
  static const iosRewarded = 'ca-app-pub-3940256099942544/1712485313';
}

/// Explicit placement identifier within an application.
final class AdPlacement {
  const AdPlacement(this.id, {this.description});

  final String id;
  final String? description;

  static const bannerHome = AdPlacement(
    'banner_home',
    description: 'Banner display on home screen',
  );

  static const bannerSettings = AdPlacement(
    'banner_settings',
    description: 'Banner display on the settings screen',
  );

  static const interstitialAfterAction = AdPlacement(
    'interstitial_after_action',
    description: 'Interstitial shown after a significant user action',
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AdPlacement && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'AdPlacement($id)';
}

/// Policy that determines whether an ad can be displayed for a given placement.
abstract interface class AdsPolicy {
  bool canShow(AdPlacement placement);
}

/// Policy that always allows ads.
final class AlwaysShowAdsPolicy implements AdsPolicy {
  const AlwaysShowAdsPolicy();

  @override
  bool canShow(AdPlacement placement) => true;
}

/// Policy that disables all ads.
final class DisabledAdsPolicy implements AdsPolicy {
  const DisabledAdsPolicy();

  @override
  bool canShow(AdPlacement placement) => false;
}

/// Policy determined by a custom predicate (e.g. checking billing entitlements).
final class CustomAdsPolicy implements AdsPolicy {
  const CustomAdsPolicy(this._predicate);

  final bool Function(AdPlacement placement) _predicate;

  @override
  bool canShow(AdPlacement placement) => _predicate(placement);
}

/// Simplified consent status for user privacy regulations (GDPR, LGPD, etc.).
enum AdConsentStatus { unknown, required, notRequired, obtained }

/// Boundary for Ad operations. Keeps third-party SDKs isolated.
abstract interface class AdsGateway {
  Future<AppResult<void>> initialize();
  bool get isInitialized;

  /// Turns true once the SDK is initialized. [FactoryBannerAd] builds nothing,
  /// and so loads no ad, before that.
  ValueListenable<bool> get ready;

  Widget buildBanner({
    required String adUnitId,
    required AdPlacement placement,
    required AdsPolicy policy,
    Widget? fallback,
    ValueChanged<bool>? onLoadedChanged,
  });

  Future<bool> showInterstitial({
    required String adUnitId,
    required AdPlacement placement,
    required AdsPolicy policy,
  });
}

/// In-memory/mock implementation for tests and previews.
final class PreviewAdsGateway implements AdsGateway {
  PreviewAdsGateway({bool initialized = false})
    : _ready = ValueNotifier(initialized);

  final ValueNotifier<bool> _ready;
  final List<AdPlacement> shownInterstitials = [];

  @override
  bool get isInitialized => _ready.value;

  @override
  ValueListenable<bool> get ready => _ready;

  @override
  Future<AppResult<void>> initialize() async {
    _ready.value = true;
    return const Success(null);
  }

  @override
  Widget buildBanner({
    required String adUnitId,
    required AdPlacement placement,
    required AdsPolicy policy,
    Widget? fallback,
    ValueChanged<bool>? onLoadedChanged,
  }) {
    if (!policy.canShow(placement)) {
      return fallback ?? const SizedBox.shrink();
    }
    return _PreviewBanner(
      placementId: placement.id,
      onLoadedChanged: onLoadedChanged,
    );
  }

  @override
  Future<bool> showInterstitial({
    required String adUnitId,
    required AdPlacement placement,
    required AdsPolicy policy,
  }) async {
    if (!policy.canShow(placement)) return false;
    shownInterstitials.add(placement);
    return true;
  }
}

/// Production AdMob gateway powered by `google_mobile_ads`.
final class GoogleMobileAdsGateway implements AdsGateway {
  GoogleMobileAdsGateway();

  final ValueNotifier<bool> _ready = ValueNotifier(false);

  @override
  bool get isInitialized => _ready.value;

  @override
  ValueListenable<bool> get ready => _ready;

  /// Asks for the user's consent where the law requires it, then starts the
  /// SDK.
  @override
  Future<AppResult<void>> initialize() => requestConsentAndInitialize();

  Future<AppResult<void>> _initializeSdk() async {
    try {
      await MobileAds.instance.initialize();
      _ready.value = true;
      return const Success(null);
    } catch (e) {
      return Failure(
        AppFailure('Falha ao inicializar Google Mobile Ads', cause: e),
      );
    }
  }

  /// Helper to request UMP consent update and show form if required, then initialize.
  Future<AppResult<void>> requestConsentAndInitialize({
    bool tagForUnderAgeOfConsent = false,
  }) async {
    final completer = Completer<AppResult<void>>();

    final params = ConsentRequestParameters(
      tagForUnderAgeOfConsent: tagForUnderAgeOfConsent,
    );

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        ConsentForm.loadAndShowConsentFormIfRequired((formError) async {
          // Initialize regardless of consent form result (offline or non-EEA still runs).
          final initResult = await _initializeSdk();
          if (!completer.isCompleted) {
            completer.complete(initResult);
          }
        });
      },
      (requestConsentError) async {
        // Fallback: network failure shouldn't block ads initialization.
        final initResult = await _initializeSdk();
        if (!completer.isCompleted) {
          completer.complete(initResult);
        }
      },
    );

    return completer.future;
  }

  @override
  Widget buildBanner({
    required String adUnitId,
    required AdPlacement placement,
    required AdsPolicy policy,
    Widget? fallback,
    ValueChanged<bool>? onLoadedChanged,
  }) {
    if (!policy.canShow(placement)) {
      return fallback ?? const SizedBox.shrink();
    }
    return _AdMobBannerWidget(
      adUnitId: adUnitId,
      fallback: fallback,
      onLoadedChanged: onLoadedChanged,
    );
  }

  @override
  Future<bool> showInterstitial({
    required String adUnitId,
    required AdPlacement placement,
    required AdsPolicy policy,
  }) async {
    if (!policy.canShow(placement)) return false;

    final completer = Completer<bool>();
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(true);
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (!completer.isCompleted) completer.complete(false);
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (error) {
          if (!completer.isCompleted) completer.complete(false);
        },
      ),
    );

    return completer.future;
  }
}

class _PreviewBanner extends StatefulWidget {
  const _PreviewBanner({required this.placementId, this.onLoadedChanged});

  final String placementId;
  final ValueChanged<bool>? onLoadedChanged;

  @override
  State<_PreviewBanner> createState() => _PreviewBannerState();
}

class _PreviewBannerState extends State<_PreviewBanner> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onLoadedChanged?.call(true);
    });
  }

  @override
  Widget build(BuildContext context) => Container(
    height: 50,
    color: const Color(0x3300FF00),
    alignment: Alignment.center,
    child: Text(
      'Preview Ad [${widget.placementId}]',
      style: const TextStyle(fontSize: 12, color: Colors.white70),
    ),
  );
}

class _AdMobBannerWidget extends StatefulWidget {
  const _AdMobBannerWidget({
    required this.adUnitId,
    this.fallback,
    this.onLoadedChanged,
  });

  final String adUnitId;
  final Widget? fallback;
  final ValueChanged<bool>? onLoadedChanged;

  @override
  State<_AdMobBannerWidget> createState() => _AdMobBannerWidgetState();
}

class _AdMobBannerWidgetState extends State<_AdMobBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId: widget.adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() => _isLoaded = true);
          widget.onLoadedChanged?.call(true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() => _isLoaded = false);
          widget.onLoadedChanged?.call(false);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded && _bannerAd != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return widget.fallback ?? const SizedBox.shrink();
  }
}

/// Reusable banner ad widget with automatic policy evaluation.
class FactoryBannerAd extends StatelessWidget {
  const FactoryBannerAd({
    super.key,
    required this.gateway,
    required this.adUnitId,
    required this.placement,
    required this.policy,
    this.fallback,
    this.onLoadedChanged,
  });

  final AdsGateway gateway;
  final String adUnitId;
  final AdPlacement placement;
  final AdsPolicy policy;
  final Widget? fallback;

  /// Called with `true` when an ad is on screen and `false` if loading fails,
  /// so the host can reserve space only while there is something to show.
  final ValueChanged<bool>? onLoadedChanged;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: gateway.ready,
    builder: (context, ready, _) => ready
        ? gateway.buildBanner(
            adUnitId: adUnitId,
            placement: placement,
            policy: policy,
            fallback: fallback,
            onLoadedChanged: onLoadedChanged,
          )
        : fallback ?? const SizedBox.shrink(),
  );
}

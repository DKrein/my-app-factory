import 'dart:async';
import 'package:factory_ads/factory_ads.dart';
import 'package:factory_audio/factory_audio.dart';
import 'package:factory_billing/factory_billing.dart';
import 'package:factory_core/factory_core.dart';
import 'package:factory_storage/factory_storage.dart';
import 'package:factory_ui/factory_ui.dart';
import 'package:flutter/material.dart';

import 'app_config.g.dart';

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

  await JustAudioGateway.initBackground(
    channelId: '${AppConfig.applicationId}.audio',
    channelName: 'Sound playback',
    notificationIcon: 'drawable/ic_launcher_monochrome',
  );
  final storage = await SharedPreferencesStore.create();
  final ads = GoogleMobileAdsGateway();
  final billing = PlayBillingGateway(catalog: sleepSoundsCatalog);

  // Non-blocking initialization
  unawaited(ads.initialize());
  unawaited(billing.initialize());

  runApp(
    SleepSoundsApp(
      storage: storage,
      ads: ads,
      billing: billing,
    ),
  );
}

class Sound {
  const Sound(this.name, this.detail, this.asset, this.icon, this.color);
  final String name, detail, asset;
  final IconData icon;
  final Color color;
}

const sounds = [
  Sound(
    'Soft rain',
    'Steady drops on a quiet window',
    'assets/audio/rain.ogg',
    Icons.water_drop_outlined,
    Color(0xFF7DA9E8),
  ),
  Sound(
    'Night waves',
    'Slow, distant sea',
    'assets/audio/waves.ogg',
    Icons.waves_outlined,
    Color(0xFF8ED9C7),
  ),
  Sound(
    'Brown noise',
    'Deep and steady for cozy focus',
    'assets/audio/brown.ogg',
    Icons.graphic_eq,
    Color(0xFFC7A6F5),
  ),
  Sound(
    'Fan',
    'Even airflow to mask distractions',
    'assets/audio/fan.ogg',
    Icons.air_outlined,
    Color(0xFFF1C589),
  ),
];

class PlaybackController extends ChangeNotifier {
  PlaybackController(this._audio);

  final AudioGateway _audio;
  Timer? _timer;
  Sound? sound;
  bool playing = false;
  double volume = .7;
  int timerMinutes = 0;
  int remainingSeconds = 0;

  Future<void> play(Sound next) async {
    sound = next;
    playing = true;
    notifyListeners();
    await _audio.play(next.asset, title: next.name);
  }

  Future<void> togglePlaying() async {
    final current = sound;
    if (current == null) return;
    if (playing) {
      playing = false;
      notifyListeners();
      await _audio.pause();
    } else {
      await play(current);
    }
  }

  Future<void> setVolume(double value) async {
    volume = value;
    notifyListeners();
    await _audio.setVolume(value);
  }

  void setTimer(int minutes) {
    _timer?.cancel();
    timerMinutes = minutes;
    remainingSeconds = minutes * 60;
    notifyListeners();
    if (minutes > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  void _tick() {
    if (remainingSeconds > 1) {
      remainingSeconds--;
      notifyListeners();
      return;
    }
    _timer?.cancel();
    timerMinutes = 0;
    remainingSeconds = 0;
    playing = false;
    notifyListeners();
    _audio.pause();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class SleepSoundsApp extends StatefulWidget {
  const SleepSoundsApp({
    super.key,
    this.audio,
    this.storage,
    this.ads,
    this.billing,
  });

  final AudioGateway? audio;
  final KeyValueStore? storage;
  final AdsGateway? ads;
  final BillingGateway? billing;

  @override
  State<SleepSoundsApp> createState() => _SleepSoundsAppState();
}

class _SleepSoundsAppState extends State<SleepSoundsApp> {
  late final AudioGateway _audio;
  late final PlaybackController _playback;
  late final KeyValueStore _storage;
  late final AdsGateway _ads;
  late final BillingGateway _billing;
  bool _internalAudio = false;

  @override
  void initState() {
    super.initState();
    if (widget.audio != null) {
      _audio = widget.audio!;
    } else {
      _audio = JustAudioGateway();
      _internalAudio = true;
    }
    _playback = PlaybackController(_audio);
    _storage = widget.storage ?? MemoryKeyValueStore();
    _ads = widget.ads ?? PreviewAdsGateway(initialized: true);
    _billing = widget.billing ??
        FakeBillingGateway(
          catalog: sleepSoundsCatalog,
          initialProducts: [defaultRemoveAdsProduct],
        );
  }

  @override
  void dispose() {
    _playback.dispose();
    if (_internalAudio && _audio is JustAudioGateway) {
      _audio.dispose();
    }
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

const splashTaglines = [
  'Sleeping like a capybara with a full belly.',
  "Have you ever seen a capybara complain about a bad night's sleep?",
  'Keep calm and capy-sleep on.',
  'Time to capybara down and drift away.',
  'Sweet dreams, little capy-dreamer.',
  'No worries, just capy-naps.',
  'Life is better with a little more capy-sleep.',
  'Let your worries float away like a sleepy capybara.',
  'A cozy capybara is a sleepy capybara.',
  "Tonight, we're taking it easy — capy-easy.",
];

class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({super.key, required this.storage, required this.next});

  final KeyValueStore storage;
  final Widget next;

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen> {
  static const _taglineIndexKey = 'splash_tagline_index_v1';
  static const _splashDuration = Duration(milliseconds: 3500);

  String _tagline = splashTaglines.first;

  @override
  void initState() {
    super.initState();
    _pickTagline();
    Future.delayed(_splashDuration, _goToNext);
  }

  Future<void> _pickTagline() async {
    final stored = await widget.storage.readString(_taglineIndexKey);
    final index = int.tryParse(stored ?? '') ?? 0;
    if (mounted) {
      setState(() => _tagline = splashTaglines[index % splashTaglines.length]);
    }
    await widget.storage.writeString(
      _taglineIndexKey,
      '${(index + 1) % splashTaglines.length}',
    );
  }

  void _goToNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => widget.next),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: FactoryColors.night,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sleepy Capy',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: FactoryColors.ink,
                  ),
                ),
                const SizedBox(height: 20),
                Image.asset('assets/branding/icon_foreground.png', width: 200),
                const SizedBox(height: 24),
                Text(
                  _tagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: FactoryColors.mutedInk,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({
    super.key,
    required this.playback,
    required this.storage,
    required this.ads,
    required this.billing,
  });

  final PlaybackController playback;
  final KeyValueStore storage;
  final AdsGateway ads;
  final BillingGateway billing;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  static const _favoritesStorageKey = 'favorites_sounds_v1';
  final favorites = <String>{};
  StreamSubscription<PurchaseEvent>? _purchaseSubscription;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _purchaseSubscription = widget.billing.purchaseEvents.listen(_handlePurchaseEvent);
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final raw = await widget.storage.readString(_favoritesStorageKey);
    if (raw != null && raw.isNotEmpty && mounted) {
      setState(() {
        favorites.addAll(
          raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty),
        );
      });
    }
  }

  Future<void> _toggleFavorite(Sound sound) async {
    setState(() {
      if (favorites.contains(sound.name)) {
        favorites.remove(sound.name);
      } else {
        favorites.add(sound.name);
      }
    });
    await widget.storage.writeString(_favoritesStorageKey, favorites.join(','));
  }

  void _handlePurchaseEvent(PurchaseEvent event) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (event.status) {
      case PurchaseProgressStatus.purchased:
        messenger.showSnackBar(
          const SnackBar(content: Text('Purchase complete! Ads removed.')),
        );
        break;
      case PurchaseProgressStatus.restored:
        messenger.showSnackBar(
          const SnackBar(content: Text('Purchases restored successfully!')),
        );
        break;
      case PurchaseProgressStatus.pending:
        messenger.showSnackBar(
          const SnackBar(content: Text('Processing purchase with Play Store...')),
        );
        break;
      case PurchaseProgressStatus.error:
        messenger.showSnackBar(
          SnackBar(content: Text('Error: ${event.errorMessage ?? "Transaction failed"}')),
        );
        break;
      case PurchaseProgressStatus.canceled:
      case PurchaseProgressStatus.idle:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final adsPolicy = CustomAdsPolicy(
      (placement) => !widget.billing.entitlements.has(FactoryEntitlements.removeAds),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Good night',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ),
                      IconButton(
                        onPressed: _openSettings,
                        icon: const Icon(Icons.tune_outlined),
                        tooltip: 'Settings',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pick a sound and let the day wind down.',
                    style: TextStyle(color: FactoryColors.mutedInk),
                  ),
                  const SizedBox(height: 28),
                  ListenableBuilder(
                    listenable: widget.playback,
                    builder: (context, _) {
                      final selected = widget.playback.sound;
                      return Card(
                        child: ListTile(
                          onTap: selected == null ? null : _openPlayer,
                          leading: CircleAvatar(
                            child: Icon(selected?.icon ?? Icons.nightlight_round),
                          ),
                          title: Text(selected?.name ?? 'Pick a sound'),
                          subtitle: Text(
                            selected == null
                                ? 'Your night starts here'
                                : widget.playback.playing
                                    ? 'Now playing'
                                    : 'Paused',
                          ),
                          trailing: Icon(
                            selected == null
                                ? Icons.arrow_downward
                                : Icons.play_arrow,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'To wind down',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sounds.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: .88,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemBuilder: (_, i) => _card(sounds[i]),
                  ),
                ],
              ),
            ),
            ListenableBuilder(
              listenable: widget.billing.entitlements,
              builder: (context, _) {
                if (widget.billing.entitlements.has(FactoryEntitlements.removeAds)) {
                  return const SizedBox.shrink();
                }
                return FactoryBannerAd(
                  gateway: widget.ads,
                  adUnitId: AppConfig.bannerAdUnitId,
                  placement: AdPlacement.bannerHome,
                  policy: adsPolicy,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(Sound sound) {
    final favorite = favorites.contains(sound.name);
    return Card(
      child: InkWell(
        onTap: () {
          widget.playback.play(sound);
          _openPlayer();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _toggleFavorite(sound),
                  icon: Icon(
                    favorite ? Icons.favorite : Icons.favorite_border,
                    color: favorite ? FactoryColors.mist : FactoryColors.mutedInk,
                  ),
                ),
              ),
              Icon(sound.icon, size: 34, color: sound.color),
              const Spacer(),
              Text(sound.name, style: Theme.of(context).textTheme.titleMedium),
              Text(
                sound.detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: FactoryColors.mutedInk,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSettings() => showModalBottomSheet<void>(
        context: context,
        backgroundColor: FactoryColors.surfaceElevated,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => SettingsSheet(billing: widget.billing),
      );

  void _openPlayer() => showModalBottomSheet<void>(
        context: context,
        backgroundColor: FactoryColors.surfaceElevated,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => PlayerSheet(playback: widget.playback),
      );
}


class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key, required this.billing});

  final BillingGateway billing;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  StoreProduct? _product;
  bool _productLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final result = await widget.billing.queryProducts(
      {AppConfig.removeAdsProductId},
    );
    if (!mounted) return;
    setState(() {
      _productLoaded = true;
      if (result is Success<List<StoreProduct>> && result.value.isNotEmpty) {
        _product = result.value.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final billing = widget.billing;
    return ListenableBuilder(
      listenable: billing.entitlements,
      builder: (context, _) {
        final isPremium = billing.entitlements.has(FactoryEntitlements.removeAds);
        final product = _product;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  color: FactoryColors.surface,
                  child: ListTile(
                    leading: Icon(
                      isPremium ? Icons.verified : Icons.lock_outline,
                      color: isPremium ? FactoryColors.mist : FactoryColors.moon,
                    ),
                    title: Text(
                      isPremium ? 'Premium Active' : 'Remove Ads',
                    ),
                    subtitle: Text(
                      isPremium
                          ? 'All ads are turned off.'
                          : 'Enjoy distraction-free sleep sounds.',
                    ),
                    trailing: isPremium
                        ? const Icon(Icons.check, color: FactoryColors.mist)
                        : TextButton(
                            onPressed: product == null
                                ? null
                                : () => billing.buyNonConsumable(product),
                            child: Text(
                              product?.price ??
                                  (_productLoaded ? 'Unavailable' : '...'),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.restore, color: FactoryColors.mutedInk),
                  title: const Text('Restore purchases'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await billing.restorePurchases();
                  },
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.dark_mode_outlined, color: FactoryColors.mutedInk),
                  title: Text('Dark Theme'),
                  subtitle: Text('On by default for nighttime relaxation'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PlayerSheet extends StatelessWidget {
  const PlayerSheet({super.key, required this.playback});

  final PlaybackController playback;

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: playback,
        builder: (context, _) {
          final sound = playback.sound!;
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: sound.color.withValues(alpha: .25),
                    child: Icon(sound.icon, size: 52, color: sound.color),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    sound.name,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  if (playback.remainingSeconds > 0)
                    Text(
                      'Stopping in: ${_formatTime(playback.remainingSeconds)}',
                      style: const TextStyle(
                        color: FactoryColors.mist,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 16),
                  IconButton.filled(
                    onPressed: playback.togglePlaying,
                    icon: Icon(playback.playing ? Icons.pause : Icons.play_arrow),
                    tooltip: playback.playing ? 'Pause' : 'Play',
                  ),
                  Slider(
                    value: playback.volume,
                    onChanged: playback.setVolume,
                  ),
                  Wrap(
                    spacing: 8,
                    children: [0, 15, 30, 45, 60]
                        .map(
                          (m) => ChoiceChip(
                            label: Text(m == 0 ? 'No timer' : '$m min'),
                            selected: playback.timerMinutes == m,
                            onSelected: (_) => playback.setTimer(m),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

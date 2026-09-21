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
      title: 'Remover Anúncios',
      description: 'Desative todos os banners e anúncios do aplicativo.',
    ),
  ],
);

const defaultRemoveAdsProduct = StoreProduct(
  id: AppConfig.removeAdsProductId,
  title: 'Remover Anúncios',
  description: 'Desativa permanentemente todos os anúncios',
  price: r'R$ 9,90',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
    'Chuva suave',
    'Gotas constantes em uma janela tranquila',
    'assets/audio/rain.ogg',
    Icons.water_drop_outlined,
    Color(0xFF7DA9E8),
  ),
  Sound(
    'Ondas noturnas',
    'Mar lento e distante',
    'assets/audio/waves.ogg',
    Icons.waves_outlined,
    Color(0xFF8ED9C7),
  ),
  Sound(
    'Ruído marrom',
    'Grave contínuo e aconchegante',
    'assets/audio/brown.ogg',
    Icons.graphic_eq,
    Color(0xFFC7A6F5),
  ),
  Sound(
    'Ventilador',
    'Sopro uniforme para abafar distrações',
    'assets/audio/fan.ogg',
    Icons.air_outlined,
    Color(0xFFF1C589),
  ),
];

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
        home: LibraryPage(
          audio: _audio,
          storage: _storage,
          ads: _ads,
          billing: _billing,
        ),
      );
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({
    super.key,
    required this.audio,
    required this.storage,
    required this.ads,
    required this.billing,
  });

  final AudioGateway audio;
  final KeyValueStore storage;
  final AdsGateway ads;
  final BillingGateway billing;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  static const _favoritesStorageKey = 'favorites_sounds_v1';
  Sound? selected;
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
          const SnackBar(content: Text('Compra concluída! Anúncios removidos.')),
        );
        break;
      case PurchaseProgressStatus.restored:
        messenger.showSnackBar(
          const SnackBar(content: Text('Compras restauradas com sucesso!')),
        );
        break;
      case PurchaseProgressStatus.pending:
        messenger.showSnackBar(
          const SnackBar(content: Text('Compra em processamento pela Play Store...')),
        );
        break;
      case PurchaseProgressStatus.error:
        messenger.showSnackBar(
          SnackBar(content: Text('Erro: ${event.errorMessage ?? "Falha na transação"}')),
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
                          'Boa noite',
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                      ),
                      IconButton(
                        onPressed: _openSettings,
                        icon: const Icon(Icons.tune_outlined),
                        tooltip: 'Configurações',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Escolha um som e deixe o dia baixar o volume.',
                    style: TextStyle(color: FactoryColors.mutedInk),
                  ),
                  const SizedBox(height: 28),
                  Card(
                    child: ListTile(
                      onTap: selected == null ? null : () => _player(selected!),
                      leading: CircleAvatar(
                        child: Icon(selected?.icon ?? Icons.nightlight_round),
                      ),
                      title: Text(selected?.name ?? 'Escolha um som'),
                      subtitle: Text(
                        selected == null ? 'Sua noite começa aqui' : 'Tocando agora',
                      ),
                      trailing: Icon(
                        selected == null ? Icons.arrow_downward : Icons.play_arrow,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Para desacelerar',
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
          setState(() => selected = sound);
          _player(sound);
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

  Future<void> _player(Sound sound) async {
    await widget.audio.play(sound.asset);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: FactoryColors.surfaceElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PlayerSheet(sound: sound, audio: widget.audio),
    );
  }
}

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key, required this.billing});

  final BillingGateway billing;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: billing.entitlements,
      builder: (context, _) {
        final isPremium = billing.entitlements.has(FactoryEntitlements.removeAds);

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configurações',
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
                      isPremium ? 'Versão Premium Ativa' : 'Remover Anúncios',
                    ),
                    subtitle: Text(
                      isPremium
                          ? 'Todos os anúncios estão desativados.'
                          : 'Aproveite noites de sono sem distrações.',
                    ),
                    trailing: isPremium
                        ? const Icon(Icons.check, color: FactoryColors.mist)
                        : TextButton(
                            onPressed: () async {
                              final productsResult = await billing.queryProducts(
                                {AppConfig.removeAdsProductId},
                              );
                              final product = (productsResult is Success<List<StoreProduct>> &&
                                      productsResult.value.isNotEmpty)
                                  ? productsResult.value.first
                                  : defaultRemoveAdsProduct;

                              await billing.buyNonConsumable(product);
                            },
                            child: const Text('R\$ 9,90'),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.restore, color: FactoryColors.mutedInk),
                  title: const Text('Restaurar compras'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await billing.restorePurchases();
                  },
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.dark_mode_outlined, color: FactoryColors.mutedInk),
                  title: Text('Tema Escuro'),
                  subtitle: Text('Ativo por padrão para relaxamento noturno'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PlayerSheet extends StatefulWidget {
  const PlayerSheet({super.key, required this.sound, required this.audio});

  final Sound sound;
  final AudioGateway audio;

  @override
  State<PlayerSheet> createState() => _PlayerSheetState();
}

class _PlayerSheetState extends State<PlayerSheet> {
  bool playing = true;
  int timerMinutes = 0;
  int remainingSeconds = 0;
  Timer? _countdownTimer;
  double volume = .7;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _onTimerSelected(int minutes) {
    _countdownTimer?.cancel();
    setState(() {
      timerMinutes = minutes;
      remainingSeconds = minutes * 60;
    });

    if (minutes > 0) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (remainingSeconds <= 1) {
          timer.cancel();
          widget.audio.pause();
          setState(() {
            playing = false;
            timerMinutes = 0;
            remainingSeconds = 0;
          });
        } else {
          setState(() {
            remainingSeconds--;
          });
        }
      });
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: widget.sound.color.withValues(alpha: .25),
                child: Icon(widget.sound.icon, size: 52, color: widget.sound.color),
              ),
              const SizedBox(height: 16),
              Text(
                widget.sound.name,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              if (remainingSeconds > 0)
                Text(
                  'Desligando em: ${_formatTime(remainingSeconds)}',
                  style: const TextStyle(
                    color: FactoryColors.mist,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 16),
              IconButton.filled(
                onPressed: () async {
                  if (playing) {
                    await widget.audio.pause();
                  } else {
                    await widget.audio.play(widget.sound.asset);
                  }
                  if (mounted) setState(() => playing = !playing);
                },
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                tooltip: playing ? 'Pausar' : 'Tocar',
              ),
              Slider(
                value: volume,
                onChanged: (v) {
                  widget.audio.setVolume(v);
                  setState(() => volume = v);
                },
              ),
              Wrap(
                spacing: 8,
                children: [0, 15, 30, 45, 60]
                    .map(
                      (m) => ChoiceChip(
                        label: Text(m == 0 ? 'Sem timer' : '$m min'),
                        selected: timerMinutes == m,
                        onSelected: (_) => _onTimerSelected(m),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      );
}

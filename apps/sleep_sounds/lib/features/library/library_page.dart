import 'dart:async';
import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:factory_ads/factory_ads.dart';
import 'package:factory_billing/factory_billing.dart';
import 'package:factory_storage/factory_storage.dart';
import 'package:factory_ui/factory_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:in_app_review/in_app_review.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_config.g.dart';
import '../../content/credits.dart';
import '../../content/sounds.dart';
import '../common/starfield_background.dart';
import 'card_volume_slider.dart';
import 'equalizer_bars.dart';
import '../player/player_controller.dart';
import '../mixes/mix_chips.dart';
import '../mixes/mix_dialogs.dart';
import '../mixes/mix_library.dart';
import '../pro/paywall_page.dart';
import '../pro/pro_features.dart';
import '../player/duration_carousel.dart';
import '../player/sleep_duration.dart';
import '../reminders/bedtime_reminder.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({
    super.key,
    required this.playback,
    required this.mixes,
    required this.storage,
    required this.ads,
    required this.billing,
  });

  final PlaybackController playback;
  final MixLibrary mixes;
  final KeyValueStore storage;
  final AdsGateway ads;
  final BillingGateway billing;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  static const _favoritesStorageKey = 'favorites_sounds_v2';
  static const _pagePadding = EdgeInsets.symmetric(horizontal: 24);
  static const _bannerHeight = 50.0;
  final favorites = <String>{};
  bool _bannerLoaded = false;
  StreamSubscription<PurchaseEvent>? _purchaseSubscription;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _purchaseSubscription = widget.billing.purchaseEvents.listen(
      _handlePurchaseEvent,
    );
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
      if (!favorites.remove(sound.id)) favorites.add(sound.id);
    });
    await widget.storage.writeString(_favoritesStorageKey, favorites.join(','));
  }

  void _handlePurchaseEvent(PurchaseEvent event) {
    if (!mounted) return;
    if (event.status == PurchaseProgressStatus.purchased ||
        event.status == PurchaseProgressStatus.restored) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pro is on. Thank you!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pro = ProFeatures(widget.billing.entitlements);
    final adsPolicy = CustomAdsPolicy((placement) => pro.showAds);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StarfieldBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: pro.changes,
            builder: (context, _) {
              final showAds = pro.showAds;
              final reservedForBanner = showAds && _bannerLoaded
                  ? _bannerHeight
                  : 0.0;
              return Stack(
                children: [
                  ListView(
                    padding: EdgeInsets.only(
                      top: 24,
                      bottom: 24 + reservedForBanner,
                    ),
                    children: [
                      Padding(
                        padding: _pagePadding,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Time to capy-nap',
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
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: _pagePadding,
                        child: Text(
                          'Capy Timer',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListenableBuilder(
                        listenable: widget.playback,
                        builder: (context, _) => Column(
                          children: [
                            SizedBox(
                              height: 64,
                              child: DurationCarousel(
                                selectedMinutes: widget.playback.timerMinutes,
                                onSelected: widget.playback.setTimer,
                              ),
                            ),
                            if (widget.playback.hasSounds)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  !widget.playback.playing
                                      ? 'Paused'
                                      : widget.playback.timerMinutes == 0
                                      ? 'Playing'
                                      : 'Stopping in ${formatSleepRemaining(widget.playback.remainingSeconds)}',
                                  style: const TextStyle(
                                    color: FactoryColors.mist,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: _pagePadding,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'To wind down',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            _saveMixButton(),
                            _playPauseButton(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: _pagePadding,
                        child: ListenableBuilder(
                          listenable: widget.playback,
                          builder: (context, _) => _favoritesRow(),
                        ),
                      ),
                      MixChips(
                        library: widget.mixes,
                        playback: widget.playback,
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: _pagePadding,
                        child: ListenableBuilder(
                          listenable: widget.playback,
                          builder: (context, _) => GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: sounds.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisExtent: _cardHeight(context),
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                            itemBuilder: (_, i) => _card(sounds[i]),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (showAds)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Center(
                        child: FactoryBannerAd(
                          gateway: widget.ads,
                          adUnitId: AppConfig.bannerAdUnitId,
                          placement: AdPlacement.bannerHome,
                          policy: adsPolicy,
                          onLoadedChanged: (loaded) {
                            if (mounted) setState(() => _bannerLoaded = loaded);
                          },
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _saveMixButton() => ListenableBuilder(
    listenable: Listenable.merge([
      widget.playback,
      widget.mixes,
      ProFeatures(widget.billing.entitlements).changes,
    ]),
    builder: (context, _) {
      final pro = ProFeatures(widget.billing.entitlements);
      final locked = !pro.canSaveMix(widget.mixes.mixes.length);
      final enabled = widget.playback.hasSounds;
      return IconButton(
        tooltip: locked ? 'Save mix (Pro)' : 'Save mix',
        onPressed: !enabled
            ? null
            : locked
            ? () => PaywallPage.open(context, widget.billing)
            : () => showSaveMixDialog(
                context,
                library: widget.mixes,
                playback: widget.playback,
              ),
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Symbols.bookmark_add_rounded,
              size: 26,
              color: enabled
                  ? FactoryColors.mist
                  : FactoryColors.mutedInk.withValues(alpha: .45),
            ),
            if (locked)
              const Positioned(
                right: -4,
                bottom: -4,
                child: Icon(
                  Symbols.lock_rounded,
                  size: 13,
                  fill: 1,
                  color: FactoryColors.mutedInk,
                ),
              ),
          ],
        ),
      );
    },
  );

  Widget _playPauseButton() => ListenableBuilder(
    listenable: widget.playback,
    builder: (context, _) {
      final playback = widget.playback;
      return AnimatedOpacity(
        opacity: playback.hasSounds ? 1 : .35,
        duration: const Duration(milliseconds: 200),
        child: Material(
          color: FactoryColors.moon,
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: playback.hasSounds
                ? playback.togglePlaying
                : () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Select a sound to play')),
                  ),
            color: FactoryColors.night,
            icon: Icon(playback.playing ? Icons.pause : Icons.play_arrow),
            tooltip: playback.playing ? 'Pause' : 'Play',
          ),
        ),
      );
    },
  );

  Widget _cardShell({
    required bool active,
    required VoidCallback onTap,
    required Widget child,
  }) => Card(
    color: active ? FactoryColors.activeSurface : null,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: active ? FactoryColors.activeOutline : Colors.transparent,
        width: 1.5,
      ),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 2, 6, 10),
        child: child,
      ),
    ),
  );

  Widget _cardLabel(String text) => Text(
    text,
    maxLines: 2,
    textAlign: TextAlign.center,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.titleSmall,
  );

  static const _heartSlotHeight = 32.0;
  static const _cardBaseHeight = 152.0;

  /// Grows with the system font size so a two-line name still fits above the
  /// volume slider.
  double _cardHeight(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return _cardBaseHeight * scale.clamp(1.0, 1.6);
  }

  Widget _heart({
    required bool filled,
    required Color color,
    double size = 22,
  }) => Icon(
    Symbols.favorite_rounded,
    color: color,
    size: size,
    fill: filled ? 1 : 0,
    weight: 400,
  );

  /// Only the active card has a tappable heart; a favorite that is not active
  /// shows a small badge instead. The slot keeps the same height either way,
  /// so icons and labels do not shift when a card is toggled.
  Widget _heartSlot(Sound sound, {required bool active}) {
    final favorite = favorites.contains(sound.id);
    if (active) {
      return IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: favorite ? 'Remove from favorites' : 'Add to favorites',
        onPressed: () => _toggleFavorite(sound),
        icon: _heart(
          filled: favorite,
          color: favorite ? FactoryColors.ink : FactoryColors.mutedInk,
        ),
      );
    }
    if (favorite) {
      return Padding(
        padding: const EdgeInsets.only(top: 10, right: 10),
        child: _heart(filled: true, color: FactoryColors.ink, size: 14),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _volumeSlider(Sound sound) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: CardVolumeSlider(
      volume: widget.playback.volumeOf(sound),
      locked: !ProFeatures(widget.billing.entitlements).canSetIndividualVolume,
      onChanged: (v) => widget.playback.setSoundVolume(sound, v),
      onChangeEnd: (_) => widget.playback.commitVolumes(),
      onLockedTap: () => PaywallPage.open(context, widget.billing),
    ),
  );

  Widget _card(Sound sound) {
    final active = widget.playback.isSelected(sound);
    return _cardShell(
      active: active,
      onTap: () => widget.playback.toggle(sound),
      child: Column(
        children: [
          SizedBox(
            height: _heartSlotHeight,
            child: Stack(
              children: [
                if (active)
                  Positioned(
                    left: 10,
                    top: 10,
                    child: EqualizerBars(playing: widget.playback.playing),
                  ),
                Align(
                  alignment: Alignment.topRight,
                  child: _heartSlot(sound, active: active),
                ),
              ],
            ),
          ),
          sound.icon.build(FactoryColors.mist, 34),
          const Spacer(),
          _cardLabel(sound.name),
          SizedBox(
            height: CardVolumeSlider.height + 4,
            child: active ? _volumeSlider(sound) : null,
          ),
        ],
      ),
    );
  }

  List<Sound> get _favoriteSounds =>
      sounds.where((s) => favorites.contains(s.id)).toList();

  /// Plays every favorite, or pauses/resumes playback once all of them are
  /// selected.
  void _onFavoritesPressed(List<Sound> favoriteSounds) {
    if (favoriteSounds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Start a sound and tap its heart to add it to Favorites.',
          ),
        ),
      );
    } else if (favoriteSounds.every(widget.playback.isSelected)) {
      widget.playback.togglePlaying();
    } else {
      widget.playback.toggleAll(favoriteSounds);
    }
  }

  Widget _favoritesRow() {
    final favoriteSounds = _favoriteSounds;
    final empty = favoriteSounds.isEmpty;
    final active = !empty && favoriteSounds.every(widget.playback.isSelected);
    final playing = active && widget.playback.playing;
    return Material(
      color: active
          ? FactoryColors.activeSurface
          : FactoryColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: active ? FactoryColors.activeOutline : FactoryColors.outline,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => _onFavoritesPressed(favoriteSounds),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _heart(
                filled: !empty,
                color: empty
                    ? FactoryColors.mutedInk.withValues(alpha: .6)
                    : FactoryColors.mist,
                size: 30,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Favorites',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: empty
                            ? FactoryColors.mutedInk
                            : FactoryColors.ink,
                      ),
                    ),
                    Text(
                      empty
                          ? 'Start a sound and tap its heart'
                          : favoriteSounds.map((s) => s.name).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: FactoryColors.mutedInk),
                    ),
                  ],
                ),
              ),
              if (!empty)
                Tooltip(
                  message: playing ? 'Pause favorites' : 'Play favorites',
                  child: Icon(
                    playing
                        ? Symbols.pause_rounded
                        : Symbols.play_arrow_rounded,
                    fill: 1,
                    size: 28,
                    color: playing ? FactoryColors.ink : FactoryColors.mutedInk,
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
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: FactoryColors.night,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => FractionallySizedBox(
      heightFactor: 1,
      child: SettingsSheet(billing: widget.billing, storage: widget.storage),
    ),
  );
}

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({
    super.key,
    required this.billing,
    required this.storage,
  });

  final BillingGateway billing;
  final KeyValueStore storage;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  static const _settingsStarOpacity = .2;
  static final _aboutLabels = AboutLabels(
    title: 'About',
    version: 'Version',
    privacyPolicy: 'Privacy Policy',
    contact: 'Contact',
    openSourceLicenses: 'Open source licenses',
    audioCredits: 'Audio credits',
    creditLine: (title, author) => '"$title" by $author',
    changesLine: (changes) => 'Changes: $changes',
  );
  late final Future<List<CreditEntry>> _credits = rootBundle
      .loadString('assets/credits.json')
      .then(parseCredits);
  // A tighter line height keeps the glyphs of a two-line tile centered on
  // the same line as its icon and switch.
  static const _twoLineTileText = TextStyle(height: 1.2);
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = BedtimeReminderService.defaultTime;

  @override
  void initState() {
    super.initState();
    _loadReminderState();
  }

  Future<void> _loadReminderState() async {
    final (enabled, time) = await bedtimeReminders.readState(widget.storage);
    if (!mounted) return;
    setState(() {
      _reminderEnabled = enabled;
      _reminderTime = time;
    });
  }

  Future<TimeOfDay?> _pickTime() => showTimePicker(
    context: context,
    initialTime: _reminderTime,
    helpText: 'What time?',
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
      child: child!,
    ),
  );

  Future<void> _onReminderToggled(bool value) async {
    if (value) {
      final granted = await bedtimeReminders.requestPermission();
      if (!granted || !mounted) return;
      final picked = await _pickTime();
      if (picked == null) return;
      await bedtimeReminders.schedule(picked);
      await bedtimeReminders.save(widget.storage, enabled: true, time: picked);
      if (!mounted) return;
      setState(() {
        _reminderEnabled = true;
        _reminderTime = picked;
      });
    } else {
      await bedtimeReminders.cancel();
      await bedtimeReminders.save(widget.storage, enabled: false);
      if (!mounted) return;
      setState(() => _reminderEnabled = false);
    }
  }

  Future<void> _changeReminderTime() async {
    if (!_reminderEnabled) return;
    final picked = await _pickTime();
    if (picked == null) return;
    await bedtimeReminders.schedule(picked);
    await bedtimeReminders.save(widget.storage, enabled: true, time: picked);
    if (!mounted) return;
    setState(() => _reminderTime = picked);
  }

  String get _formattedVersion {
    final parts = AppConfig.version.split('+');
    final name = parts.first;
    return parts.length > 1 ? '$name (${parts[1]})' : name;
  }

  // Google's native review popup (requestReview) only ever shows once the
  // app is live on the Play Store and quota-eligible — it silently no-ops
  // otherwise, including for every sideloaded/debug install. Deep-linking to
  // the store listing is what actually works today and after launch alike.
  Future<void> _rateUs() => InAppReview.instance.openStoreListing();

  Future<void> _openBatterySettings() async {
    try {
      await AppSettings.openAppSettings();
    } catch (_) {
      await AppSettings.openAppSettings(
        type: AppSettingsType.batteryOptimization,
      );
    }
  }

  Future<void> _showBatteryOptimizationDialog() => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: FactoryColors.surfaceElevated,
      title: const Text('Battery optimization'),
      content: const Text(
        'Android may stop background apps to save battery, which can '
        'interrupt playback during the night.\n\n'
        'Tap Open settings, choose Battery and allow unrestricted battery '
        'usage for Sleepy Capy. The exact wording varies by device.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            _openBatterySettings();
          },
          child: const Text('Open settings'),
        ),
      ],
    ),
  );

  Future<void> _openAbout() async {
    final credits = await _credits;
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AboutScreen(
          appName: 'Sleepy Capy',
          version: _formattedVersion,
          privacyPolicyUrl: AppConfig.privacyPolicyUrl,
          supportEmail: AppConfig.supportEmail,
          credits: credits,
          labels: _aboutLabels,
          openLink: (uri) =>
              launchUrl(uri, mode: LaunchMode.externalApplication),
        ),
      ),
    );
  }

  Future<void> _sendFeedback() {
    final body = StringBuffer()
      ..writeln('App: ${AppConfig.name} ${AppConfig.version}')
      ..writeln(
        'Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      )
      ..writeln('---')
      ..writeln('Feedback: ');
    return launchUrl(
      Uri(
        scheme: 'mailto',
        path: AppConfig.feedbackEmail,
        query:
            'subject=${Uri.encodeComponent('Sleepy Capy')}'
            '&body=${Uri.encodeComponent(body.toString())}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billing = widget.billing;
    final pro = ProFeatures(billing.entitlements);
    return ListenableBuilder(
      listenable: pro.changes,
      builder: (context, _) {
        final isPremium = pro.isPro;

        return StarfieldBackground(
          starOpacity: _settingsStarOpacity,
          child: SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 32,
                      ),
                      tooltip: 'Close settings',
                    ),
                    Expanded(
                      child: Text(
                        'Settings',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isPremium)
                          Card(
                            color: FactoryColors.surface,
                            child: ListTile(
                              leading: const Icon(
                                Icons.verified,
                                color: FactoryColors.mist,
                              ),
                              title: const Text('Sleepy Capy Pro'),
                              subtitle: const Text(
                                'Thank you for supporting Sleepy Capy.',
                              ),
                              trailing: const Icon(
                                Icons.check,
                                color: FactoryColors.mist,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: FactoryColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: FactoryColors.outline),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Sleepy Capy Pro',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: FactoryColors.ink,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Volume for each sound, saved mixes and more. '
                                  'One purchase, no ads.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: FactoryColors.mutedInk,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                FilledButton(
                                  onPressed: () =>
                                      PaywallPage.open(context, billing),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: FactoryColors.mist,
                                    foregroundColor: FactoryColors.night,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 28,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text(
                                    'See Pro',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 8),
                        ListTile(
                          leading: const Icon(
                            Icons.restore,
                            color: FactoryColors.mutedInk,
                          ),
                          title: const Text('Restore Purchase'),
                          onTap: () async {
                            Navigator.of(context).pop();
                            await billing.restorePurchases();
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(
                            Icons.bedtime_outlined,
                            color: FactoryColors.mutedInk,
                          ),
                          title: const Text(
                            'Bedtime Reminder',
                            style: _twoLineTileText,
                          ),
                          subtitle: Text(
                            _reminderEnabled
                                ? 'Daily at ${MaterialLocalizations.of(context).formatTimeOfDay(_reminderTime, alwaysUse24HourFormat: false)}'
                                : 'Off',
                            style: _twoLineTileText,
                          ),
                          onTap: _reminderEnabled ? _changeReminderTime : null,
                          trailing: Switch(
                            value: _reminderEnabled,
                            onChanged: _onReminderToggled,
                          ),
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.star_outline,
                            color: FactoryColors.mutedInk,
                          ),
                          title: const Text('Rate Sleepy Capy'),
                          onTap: _rateUs,
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.mail_outline,
                            color: FactoryColors.mutedInk,
                          ),
                          title: const Text('Send Feedback'),
                          onTap: _sendFeedback,
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(
                            Icons.battery_alert_outlined,
                            color: FactoryColors.mutedInk,
                          ),
                          title: const Text('Playback stops unexpectedly?'),
                          onTap: _showBatteryOptimizationDialog,
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.info_outline,
                            color: FactoryColors.mutedInk,
                          ),
                          title: const Text('About'),
                          onTap: _openAbout,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

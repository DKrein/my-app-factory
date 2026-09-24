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
import '../../l10n/l10n.dart';
import '../../content/sounds.dart';
import '../common/starfield_background.dart';
import 'card_volume_slider.dart';
import 'equalizer_bars.dart';
import '../player/player_controller.dart';
import '../mixes/mix_chips.dart';
import '../mixes/mix_dialogs.dart';
import '../mixes/mix_library.dart';
import '../pro/paywall_page.dart';
import '../theme/theme_controller.dart';
import '../theme/theme_picker.dart';
import '../pro/pro_features.dart';
import '../player/duration_carousel.dart';
import '../player/sleep_duration.dart';
import '../player/timer_options_sheet.dart';
import '../reminders/bedtime_reminder.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({
    super.key,
    required this.playback,
    required this.mixes,
    required this.themes,
    required this.storage,
    required this.ads,
    required this.billing,
  });

  final PlaybackController playback;
  final MixLibrary mixes;
  final ThemeController themes;
  final KeyValueStore storage;
  final AdsGateway ads;
  final BillingGateway billing;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  static const _pagePadding = EdgeInsets.symmetric(horizontal: 24);
  static const _bannerHeight = 50.0;
  bool _bannerLoaded = false;
  StreamSubscription<PurchaseEvent>? _purchaseSubscription;

  @override
  void initState() {
    super.initState();
    _purchaseSubscription = widget.billing.purchaseEvents.listen(
      _handlePurchaseEvent,
    );
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  void _handlePurchaseEvent(PurchaseEvent event) {
    if (!mounted) return;
    if (event.status == PurchaseProgressStatus.purchased ||
        event.status == PurchaseProgressStatus.restored) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.proIsOn)));
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
                                context.l10n.homeTitle,
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                            ),
                            IconButton(
                              onPressed: _openSettings,
                              icon: const Icon(Icons.tune_outlined),
                              tooltip: context.l10n.tooltipSettings,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: _pagePadding,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.l10n.timerTitle,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            _timerOptionsButton(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListenableBuilder(
                        listenable: widget.playback,
                        builder: (context, _) => Column(
                          children: [
                            SizedBox(height: 64, child: _durationCarousel()),
                            if (widget.playback.hasSounds)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  8,
                                  24,
                                  0,
                                ),
                                child: Text(
                                  _timerStatus(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: context.palette.mist,
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
                                context.l10n.windDownTitle,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            _saveMixButton(),
                            _playPauseButton(),
                          ],
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

  String _clock(TimeOfDay time) => MaterialLocalizations.of(context)
      .formatTimeOfDay(
        time,
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );

  Widget _durationCarousel() {
    final playback = widget.playback;
    final stopAt = playback.stopAtTime;
    return DurationCarousel(
      durations: sleepDurationChoices(
        timerMinutes: playback.timerMinutes,
        stopAtLabel: stopAt == null ? null : _clock(stopAt),
      ),
      selectedMinutes: stopAt == null ? playback.timerMinutes : stopAtMinutes,
      onSelected: (minutes) {
        if (minutes != stopAtMinutes) playback.setTimer(minutes);
      },
    );
  }

  String _timerStatus() {
    final playback = widget.playback;
    final stopAt = playback.stopAtTime;
    final l10n = context.l10n;
    if (!playback.playing) return l10n.statusPaused;
    if (playback.timerMinutes == 0 && stopAt == null) return l10n.statusPlaying;
    final remaining = formatSleepRemaining(playback.remainingSeconds);
    final status = stopAt == null
        ? l10n.statusStoppingIn(remaining)
        : l10n.statusStoppingAt(_clock(stopAt), remaining);
    final fade = playback.gradualFadeMinutes;
    return fade == null ? status : l10n.statusWithFade(status, fade);
  }

  Widget _timerOptionsButton() {
    final pro = ProFeatures(widget.billing.entitlements);
    return ListenableBuilder(
      listenable: pro.changes,
      builder: (context, _) {
        final locked = !pro.canUseAdvancedTimer;
        return IconButton(
          tooltip: locked
              ? context.l10n.timerOptionsPro
              : context.l10n.timerOptions,
          onPressed: locked
              ? () => PaywallPage.open(context, widget.billing)
              : () => showTimerOptions(context, widget.playback),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Symbols.timer_rounded,
                size: 26,
                color: context.palette.mist,
              ),
              if (locked)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Icon(
                    Symbols.lock_rounded,
                    size: 13,
                    fill: 1,
                    color: context.palette.mutedInk,
                  ),
                ),
            ],
          ),
        );
      },
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
        tooltip: locked ? context.l10n.saveMixPro : context.l10n.saveMix,
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
                  ? context.palette.mist
                  : context.palette.mutedInk.withValues(alpha: .45),
            ),
            if (locked)
              Positioned(
                right: -4,
                bottom: -4,
                child: Icon(
                  Symbols.lock_rounded,
                  size: 13,
                  fill: 1,
                  color: context.palette.mutedInk,
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
          color: context.palette.moon,
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: playback.hasSounds
                ? playback.togglePlaying
                : () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.selectSoundToPlay)),
                  ),
            color: context.palette.night,
            icon: Icon(playback.playing ? Icons.pause : Icons.play_arrow),
            tooltip: playback.playing
                ? context.l10n.tooltipPause
                : context.l10n.tooltipPlay,
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
    color: active ? context.palette.activeSurface : null,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: active ? context.palette.activeOutline : Colors.transparent,
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

  static const _equalizerSlotHeight = 24.0;
  static const _cardBaseHeight = 144.0;

  /// Grows with the system font size so a two-line name still fits above the
  /// volume slider.
  double _cardHeight(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return _cardBaseHeight * scale.clamp(1.0, 1.6);
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
            height: _equalizerSlotHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: active
                  ? Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: EqualizerBars(playing: widget.playback.playing),
                    )
                  : null,
            ),
          ),
          sound.icon.build(context.palette.mist, 34),
          const Spacer(),
          _cardLabel(soundName(context.l10n, sound)),
          SizedBox(
            height: CardVolumeSlider.height + 4,
            child: active ? _volumeSlider(sound) : null,
          ),
        ],
      ),
    );
  }

  void _openSettings() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.palette.night,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => FractionallySizedBox(
      heightFactor: 1,
      child: SettingsSheet(
        billing: widget.billing,
        storage: widget.storage,
        ads: widget.ads,
        themes: widget.themes,
      ),
    ),
  );
}

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({
    super.key,
    required this.billing,
    required this.storage,
    required this.ads,
    required this.themes,
  });

  final BillingGateway billing;
  final KeyValueStore storage;
  final AdsGateway ads;
  final ThemeController themes;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  static const _settingsStarOpacity = .2;
  AboutLabels get _aboutLabels {
    final l10n = context.l10n;
    return AboutLabels(
      title: l10n.aboutTitle,
      version: l10n.aboutVersion,
      privacyPolicy: l10n.aboutPrivacyPolicy,
      contact: l10n.aboutContact,
      openSourceLicenses: l10n.aboutLicenses,
      audioCredits: l10n.aboutAudioCredits,
      creditLine: l10n.creditLine,
      changesLine: l10n.changesLine,
    );
  }

  Future<List<CreditEntry>> _loadCredits() async {
    final l10n = context.l10n;
    final json = await rootBundle.loadString('assets/credits.json');
    return parseCredits(
      json,
      soundLabel: (sound) => soundName(l10n, sound),
      changesText: l10n.creditChangesEdited,
    );
  }

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
    helpText: context.l10n.reminderPickerHelp,
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
      backgroundColor: context.palette.surfaceElevated,
      title: Text(context.l10n.batteryTitle),
      content: Text(context.l10n.batteryBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            _openBatterySettings();
          },
          child: Text(context.l10n.openSettings),
        ),
      ],
    ),
  );

  Future<void> _openAbout() async {
    final credits = await _loadCredits();
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
                      tooltip: context.l10n.tooltipCloseSettings,
                    ),
                    Expanded(
                      child: Text(
                        context.l10n.settingsTitle,
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
                            color: context.palette.surface,
                            child: ListTile(
                              leading: Icon(
                                Icons.verified,
                                color: context.palette.mist,
                              ),
                              title: Text(context.l10n.proTitle),
                              subtitle: Text(context.l10n.proThanks),
                              trailing: Icon(
                                Icons.check,
                                color: context.palette.mist,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: context.palette.surfaceElevated,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: context.palette.outline,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  context.l10n.proTitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: context.palette.ink,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  context.l10n.proCardBody,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: context.palette.mutedInk,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                FilledButton(
                                  onPressed: () =>
                                      PaywallPage.open(context, billing),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: context.palette.mist,
                                    foregroundColor: context.palette.night,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 28,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: Text(
                                    context.l10n.seePro,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        ThemePicker(
                          themes: widget.themes,
                          pro: pro,
                          onLockedTap: () => PaywallPage.open(context, billing),
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          leading: Icon(
                            Icons.restore,
                            color: context.palette.mutedInk,
                          ),
                          title: Text(context.l10n.restorePurchase),
                          onTap: () async {
                            Navigator.of(context).pop();
                            await billing.restorePurchases();
                          },
                        ),
                        const Divider(),
                        ListTile(
                          leading: Icon(
                            Icons.bedtime_outlined,
                            color: context.palette.mutedInk,
                          ),
                          title: Text(
                            context.l10n.bedtimeReminder,
                            style: _twoLineTileText,
                          ),
                          subtitle: Text(
                            _reminderEnabled
                                ? context.l10n.reminderDaily(
                                    MaterialLocalizations.of(
                                      context,
                                    ).formatTimeOfDay(
                                      _reminderTime,
                                      alwaysUse24HourFormat:
                                          MediaQuery.alwaysUse24HourFormatOf(
                                            context,
                                          ),
                                    ),
                                  )
                                : context.l10n.reminderOff,
                            style: _twoLineTileText,
                          ),
                          onTap: _reminderEnabled ? _changeReminderTime : null,
                          trailing: Switch(
                            value: _reminderEnabled,
                            onChanged: _onReminderToggled,
                          ),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.star_outline,
                            color: context.palette.mutedInk,
                          ),
                          title: Text(context.l10n.rateApp),
                          onTap: _rateUs,
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.mail_outline,
                            color: context.palette.mutedInk,
                          ),
                          title: Text(context.l10n.sendFeedback),
                          onTap: _sendFeedback,
                        ),
                        const Divider(),
                        ListTile(
                          leading: Icon(
                            Icons.battery_alert_outlined,
                            color: context.palette.mutedInk,
                          ),
                          title: Text(context.l10n.playbackStops),
                          onTap: _showBatteryOptimizationDialog,
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.info_outline,
                            color: context.palette.mutedInk,
                          ),
                          title: Text(context.l10n.aboutItem),
                          onTap: _openAbout,
                        ),
                      ],
                    ),
                  ),
                ),
                if (pro.showAds)
                  FactoryBannerAd(
                    gateway: widget.ads,
                    adUnitId: AppConfig.bannerAdUnitId,
                    placement: AdPlacement.bannerSettings,
                    policy: CustomAdsPolicy((placement) => pro.showAds),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

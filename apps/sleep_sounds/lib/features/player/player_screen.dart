import 'package:factory_ui/factory_ui.dart';
import 'package:flutter/material.dart';

import '../common/starfield_background.dart';
import 'addons_sheet.dart';
import 'duration_carousel.dart';
import 'player_controller.dart';
import 'sleep_duration.dart';

Future<void> openPlayerSheet(
  BuildContext context,
  PlaybackController playback,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: FactoryColors.night,
  barrierColor: Colors.black.withValues(alpha: .55),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (_) => FractionallySizedBox(
    heightFactor: 1,
    child: SoundPlayerScreen(playback: playback),
  ),
);

class SoundPlayerScreen extends StatelessWidget {
  const SoundPlayerScreen({super.key, required this.playback});

  final PlaybackController playback;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: playback,
    builder: (context, _) {
      final sound = playback.sound;
      if (sound == null) return const SizedBox.shrink();

      return StarfieldBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 32,
                      ),
                      tooltip: 'Close player',
                    ),
                    const Expanded(
                      child: Text(
                        'Now playing',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: FactoryColors.mutedInk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 176,
                          height: 176,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: sound.color.withValues(alpha: .16),
                            boxShadow: [
                              BoxShadow(
                                color: sound.color.withValues(alpha: .22),
                                blurRadius: 48,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(sound.icon, size: 68, color: sound.color),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          sound.name,
                          style: Theme.of(context).textTheme.displaySmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sound.detail,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: FactoryColors.mutedInk),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.volume_down,
                      color: FactoryColors.mutedInk,
                    ),
                    Expanded(
                      child: Slider(
                        value: playback.volume,
                        onChanged: playback.setVolume,
                      ),
                    ),
                    const Icon(Icons.volume_up, color: FactoryColors.mutedInk),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sleep timer',
                  style: TextStyle(
                    color: FactoryColors.mutedInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(
                  height: 64,
                  child: DurationCarousel(
                    selectedMinutes: playback.timerMinutes,
                    onSelected: playback.setTimer,
                  ),
                ),
                Text(
                  playback.remainingSeconds > 0
                      ? (playback.playing
                            ? 'Stopping in ${formatSleepRemaining(playback.remainingSeconds)}'
                            : 'Paused · ${formatSleepRemaining(playback.remainingSeconds)} left')
                      : 'Timer finished',
                  style: const TextStyle(
                    color: FactoryColors.mist,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => openAddonsSheet(context, playback),
                  icon: const Icon(Icons.graphic_eq_rounded),
                  label: Text(
                    playback.activeAddonCount == 0
                        ? 'Add-ons'
                        : 'Add-ons · ${playback.activeAddonCount}',
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: FactoryColors.outline),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Material(
                  color: FactoryColors.moon,
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: playback.togglePlaying,
                    iconSize: 44,
                    padding: const EdgeInsets.all(20),
                    color: FactoryColors.night,
                    icon: Icon(
                      playback.playing ? Icons.pause : Icons.play_arrow,
                    ),
                    tooltip: playback.playing ? 'Pause' : 'Play',
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      );
    },
  );
}

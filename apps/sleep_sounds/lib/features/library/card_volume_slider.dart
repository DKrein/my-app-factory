import 'package:factory_ui/factory_ui.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../player/player_controller.dart';

/// Volume control at the bottom of an active card. Without Pro it shows the
/// same track with a lock, and tapping it calls [onLockedTap].
class CardVolumeSlider extends StatelessWidget {
  const CardVolumeSlider({
    super.key,
    required this.volume,
    required this.locked,
    required this.onChanged,
    required this.onChangeEnd,
    required this.onLockedTap,
  });

  static const height = 22.0;

  final double volume;
  final bool locked;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  final VoidCallback onLockedTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: locked ? _lockedTrack(context) : _slider(context),
  );

  Widget _lockedTrack(BuildContext context) => Semantics(
    button: true,
    label: 'Volume, a Pro feature',
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onLockedTap,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: context.palette.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Symbols.lock_rounded,
            size: 14,
            fill: 1,
            color: context.palette.mutedInk,
          ),
        ],
      ),
    ),
  );

  Widget _slider(BuildContext context) => SliderTheme(
    data: SliderTheme.of(context).copyWith(
      trackHeight: 4,
      activeTrackColor: context.palette.mist,
      inactiveTrackColor: context.palette.mist.withValues(alpha: .35),
      thumbColor: context.palette.mist,
      overlayColor: context.palette.mist.withValues(alpha: .16),
      thumbShape: const RoundSliderThumbShape(
        enabledThumbRadius: 6,
        elevation: 0,
        pressedElevation: 0,
      ),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
      trackShape: const RoundedRectSliderTrackShape(),
    ),
    child: Slider(
      value: volume.clamp(PlaybackController.minVolume, 1.0),
      min: PlaybackController.minVolume,
      max: 1,
      onChanged: onChanged,
      onChangeEnd: onChangeEnd,
      semanticFormatterCallback: (value) => '${(value * 100).round()}%',
    ),
  );
}

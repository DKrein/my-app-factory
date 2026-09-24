import 'package:factory_ui/factory_ui.dart';
import 'package:flutter/material.dart';

import 'player_controller.dart';
import 'sleep_duration.dart';
import '../../l10n/l10n.dart';

Future<void> showTimerOptions(
  BuildContext context,
  PlaybackController playback,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: context.palette.surfaceElevated,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (_) => TimerOptionsSheet(playback: playback),
);

/// The Pro timer options: a gradual final fade, a custom duration and a time
/// to stop at.
class TimerOptionsSheet extends StatefulWidget {
  const TimerOptionsSheet({super.key, required this.playback});

  final PlaybackController playback;

  @override
  State<TimerOptionsSheet> createState() => _TimerOptionsSheetState();
}

class _TimerOptionsSheetState extends State<TimerOptionsSheet> {
  static const _defaultCustomMinutes = 120;
  static const _defaultStopAt = TimeOfDay(hour: 7, minute: 0);

  late int _hours;
  late int _minutes;
  late TimeOfDay _stopAt;

  PlaybackController get _playback => widget.playback;

  @override
  void initState() {
    super.initState();
    final custom = _playback.customMinutes > 0
        ? _playback.customMinutes
        : _defaultCustomMinutes;
    _hours = custom ~/ 60;
    _minutes = custom % 60;
    _stopAt = _playback.stopAtTime ?? _defaultStopAt;
  }

  String _clock(TimeOfDay time) => MaterialLocalizations.of(context)
      .formatTimeOfDay(
        time,
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );

  Future<void> _pickStopAt() async {
    final picked = await showTimePicker(context: context, initialTime: _stopAt);
    if (picked != null && mounted) setState(() => _stopAt = picked);
  }

  Widget _section(String title, Widget child) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );

  Widget _dropdown({
    required int value,
    required int count,
    required String unit,
    required ValueChanged<int> onChanged,
  }) => DropdownButton<int>(
    value: value,
    isExpanded: true,
    dropdownColor: context.palette.surfaceElevated,
    underline: const SizedBox.shrink(),
    items: [
      for (var i = 0; i < count; i++)
        DropdownMenuItem(value: i, child: Text('$i $unit')),
    ],
    onChanged: (v) => onChanged(v ?? value),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _playback,
    builder: (context, _) {
      final totalMinutes = _hours * 60 + _minutes;
      return SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.timerSheetTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.close,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              _section(
                context.l10n.fadeSection,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.l10n.fadeGradually),
                      subtitle: Text(
                        _playback.gradualFade
                            ? context.l10n.fadeOnHint(_playback.fadeMinutes)
                            : context.l10n.fadeOffHint,
                      ),
                      value: _playback.gradualFade,
                      onChanged: _playback.setGradualFade,
                    ),
                    Row(
                      children: [
                        const Text('1 min'),
                        Expanded(
                          child: Slider(
                            value: _playback.fadeMinutes.toDouble(),
                            min: PlaybackController.minFadeMinutes.toDouble(),
                            max: PlaybackController.maxFadeMinutes.toDouble(),
                            divisions:
                                PlaybackController.maxFadeMinutes -
                                PlaybackController.minFadeMinutes,
                            label: '${_playback.fadeMinutes} min',
                            onChanged: _playback.gradualFade
                                ? (v) => _playback.setFadeMinutes(v.round())
                                : null,
                            onChangeEnd: (_) => _playback.commitTimerOptions(),
                          ),
                        ),
                        const Text('15 min'),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(indent: 0, endIndent: 0),
              _section(
                context.l10n.customDuration,
                Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: _dropdown(
                        value: _hours,
                        count: 24,
                        unit: 'h',
                        onChanged: (v) => setState(() => _hours = v),
                      ),
                    ),
                    Expanded(
                      child: _dropdown(
                        value: _minutes,
                        count: 60,
                        unit: 'min',
                        onChanged: (v) => setState(() => _minutes = v),
                      ),
                    ),
                    FilledButton(
                      key: const Key('set-custom-duration'),
                      onPressed: totalMinutes == 0
                          ? null
                          : () {
                              _playback.setCustomTimer(totalMinutes);
                              Navigator.of(context).pop();
                            },
                      child: Text(context.l10n.setAction),
                    ),
                  ],
                ),
              ),
              const Divider(indent: 0, endIndent: 0),
              _section(
                context.l10n.stopAtSection,
                Row(
                  spacing: 12,
                  children: [
                    OutlinedButton(
                      onPressed: _pickStopAt,
                      child: Text(_clock(_stopAt)),
                    ),
                    Expanded(
                      child: Text(
                        context.l10n.inTime(
                          formatSleepRemaining(
                            _playback.secondsUntilNext(_stopAt),
                          ),
                        ),
                        style: TextStyle(color: context.palette.mutedInk),
                      ),
                    ),
                    FilledButton(
                      key: const Key('set-stop-at'),
                      onPressed: () {
                        _playback.setStopAt(_stopAt);
                        Navigator.of(context).pop();
                      },
                      child: Text(context.l10n.setAction),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

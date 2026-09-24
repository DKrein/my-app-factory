import 'package:factory_ui/factory_ui.dart';
import 'package:flutter/material.dart';

import '../../content/sounds.dart';
import '../player/player_controller.dart';
import '../player/sleep_duration.dart';
import 'mix_library.dart';
import 'saved_mix.dart';
import '../../l10n/l10n.dart';

/// Asks for a name and saves the mix that is playing.
Future<void> showSaveMixDialog(
  BuildContext context, {
  required MixLibrary library,
  required PlaybackController playback,
}) => showDialog<void>(
  context: context,
  builder: (_) => _SaveMixDialog(library: library, playback: playback),
);

Future<void> showRenameMixDialog(
  BuildContext context, {
  required MixLibrary library,
  required SavedMix mix,
}) => showDialog<void>(
  context: context,
  builder: (_) => _NameDialog(
    title: context.l10n.mixRenameTitle,
    action: context.l10n.mixRenameAction,
    initialName: mix.name,
    isTaken: (name) => library.isNameTaken(name, except: mix.name),
    onSubmit: (name) => library.rename(mix.name, name),
  ),
);

/// The menu that opens on a long press of a mix chip.
Future<void> showMixMenu(
  BuildContext context, {
  required MixLibrary library,
  required SavedMix mix,
}) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: context.palette.surfaceElevated,
  builder: (sheetContext) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text(mix.name, style: Theme.of(context).textTheme.titleMedium),
        ),
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: Text(context.l10n.mixRenameAction),
          onTap: () {
            Navigator.of(sheetContext).pop();
            showRenameMixDialog(context, library: library, mix: mix);
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: Text(context.l10n.mixDeleteAction),
          onTap: () {
            Navigator.of(sheetContext).pop();
            _confirmDelete(context, library: library, mix: mix);
          },
        ),
      ],
    ),
  ),
);

Future<void> _confirmDelete(
  BuildContext context, {
  required MixLibrary library,
  required SavedMix mix,
}) => showDialog<void>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    backgroundColor: context.palette.surfaceElevated,
    title: Text(context.l10n.mixDeleteTitle(mix.name)),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(dialogContext).pop(),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(
        onPressed: () {
          library.delete(mix.name);
          Navigator.of(dialogContext).pop();
        },
        child: Text(context.l10n.mixDeleteAction),
      ),
    ],
  ),
);

class _SaveMixDialog extends StatefulWidget {
  const _SaveMixDialog({required this.library, required this.playback});

  final MixLibrary library;
  final PlaybackController playback;

  @override
  State<_SaveMixDialog> createState() => _SaveMixDialogState();
}

class _SaveMixDialogState extends State<_SaveMixDialog> {
  bool _includeTimer = true;

  String get _timerLabel {
    final minutes = widget.playback.timerMinutes;
    return minutes == 0 ? context.l10n.timerOff : customDurationLabel(minutes);
  }

  @override
  Widget build(BuildContext context) {
    final active = [
      for (final sound in sounds)
        if (widget.playback.isSelected(sound)) sound,
    ];
    return _NameDialog(
      title: context.l10n.mixSaveTitle,
      action: context.l10n.mixSaveAction,
      initialName: widget.library.defaultName(),
      isTaken: widget.library.isNameTaken,
      onSubmit: (name) => widget.library.save(
        widget.playback.snapshot(name: name, includeTimer: _includeTimer),
      ),
      extra: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              for (final sound in active)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    sound.icon.build(context.palette.mist, 28),
                    Text(
                      '${(widget.playback.volumeOf(sound) * 100).round()}%',
                      style: TextStyle(
                        color: context.palette.mutedInk,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _includeTimer,
            onChanged: (value) => setState(() => _includeTimer = value ?? true),
            title: Text(context.l10n.mixIncludeTimer(_timerLabel)),
          ),
        ],
      ),
    );
  }
}

/// A dialog with one name field that refuses empty and already-used names.
class _NameDialog extends StatefulWidget {
  const _NameDialog({
    required this.title,
    required this.action,
    required this.initialName,
    required this.isTaken,
    required this.onSubmit,
    this.extra,
  });

  final String title;
  final String action;
  final String initialName;
  final bool Function(String name) isTaken;
  final bool Function(String name) onSubmit;
  final Widget? extra;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialName)
        ..selection = TextSelection(
          baseOffset: 0,
          extentOffset: widget.initialName.length,
        );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _empty => _controller.text.trim().isEmpty;
  bool get _taken => !_empty && widget.isTaken(_controller.text);

  void _submit() {
    if (_empty || _taken) return;
    if (widget.onSubmit(_controller.text)) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: context.palette.surfaceElevated,
    title: Text(widget.title),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 24,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: context.l10n.mixNameLabel,
              counterText: '',
              errorText: _taken ? context.l10n.mixNameTaken : null,
            ),
          ),
          ?widget.extra,
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.l10n.cancel),
      ),
      FilledButton(
        onPressed: _empty || _taken ? null : _submit,
        child: Text(widget.action),
      ),
    ],
  );
}

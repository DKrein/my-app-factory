import 'package:factory_ui/factory_ui.dart';
import 'package:flutter/material.dart';

import 'sleep_duration.dart';

/// Horizontal snapping picker for the sleep timer duration, e.g.
/// `30m  [1h]  3h  6h`. Tapping an item snaps it to the center and commits
/// the selection; dragging snaps to the nearest item on release.
class DurationCarousel extends StatefulWidget {
  const DurationCarousel({
    super.key,
    required this.durations,
    required this.selectedMinutes,
    required this.onSelected,
  });

  final List<SleepDuration> durations;
  final int selectedMinutes;
  final ValueChanged<int> onSelected;

  @override
  State<DurationCarousel> createState() => _DurationCarouselState();
}

class _DurationCarouselState extends State<DurationCarousel> {
  static const _viewportFraction = 0.2;

  late final PageController _controller = PageController(
    viewportFraction: _viewportFraction,
    initialPage: _indexOf(widget.selectedMinutes),
  );
  late double _page = _controller.initialPage.toDouble();
  bool _syncing = false;

  int _indexOf(int minutes) {
    final index = widget.durations.indexWhere((d) => d.minutes == minutes);
    return index == -1
        ? widget.durations.indexWhere((d) => d.minutes == defaultSleepMinutes)
        : index;
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onPageScroll);
  }

  void _onPageScroll() {
    if (!_controller.position.haveDimensions) return;
    setState(() => _page = _controller.page ?? _page);
  }

  @override
  void didUpdateWidget(covariant DurationCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetIndex = _indexOf(widget.selectedMinutes);
    if (targetIndex != _page.round() &&
        (widget.selectedMinutes != oldWidget.selectedMinutes ||
            widget.durations.length != oldWidget.durations.length)) {
      // A change that came from outside must not be reported back as if the
      // user had swiped through the items in between.
      _syncing = true;
      _controller
          .animateToPage(
            targetIndex,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
          )
          .whenComplete(() => _syncing = false);
    }
  }

  void _selectPage(int index) {
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onPageScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageView.builder(
    controller: _controller,
    itemCount: widget.durations.length,
    onPageChanged: (index) {
      if (!_syncing) widget.onSelected(widget.durations[index].minutes);
    },
    itemBuilder: (context, index) {
      final distance = (_page - index).abs();
      final t = (1 - distance).clamp(0.0, 1.0);
      final fontSize = (20 - 3.5 * distance).clamp(12.0, 20.0);
      final color = Color.lerp(
        context.palette.mutedInk,
        context.palette.ink,
        t,
      )!;
      return Center(
        child: GestureDetector(
          onTap: () => _selectPage(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: context.palette.surfaceElevated.withValues(alpha: t * .9),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: context.palette.moon.withValues(alpha: .55 * t),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.durations[index].label,
                style: TextStyle(
                  color: color,
                  fontSize: fontSize,
                  fontWeight: t > .5 ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_sounds/features/library/equalizer_bars.dart';

List<double> barHeights(WidgetTester tester) => tester
    .widgetList<Container>(
      find.descendant(
        of: find.byType(EqualizerBars),
        matching: find.byType(Container),
      ),
    )
    .map((c) => c.constraints!.maxHeight)
    .toList();

Widget bars({required bool playing}) =>
    MaterialApp(home: EqualizerBars(playing: playing));

void main() {
  testWidgets('bars move while playing', (tester) async {
    await tester.pumpWidget(bars(playing: true));
    final start = barHeights(tester);

    await tester.pump(const Duration(milliseconds: 200));

    expect(barHeights(tester), isNot(start));
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('bars rest flat and stop animating when paused', (tester) async {
    await tester.pumpWidget(bars(playing: true));
    await tester.pump(const Duration(milliseconds: 200));

    await tester.pumpWidget(bars(playing: false));
    await tester.pump(const Duration(milliseconds: 200));

    final heights = barHeights(tester);
    expect(heights.toSet(), hasLength(1));
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pump(const Duration(milliseconds: 300));
    expect(barHeights(tester), heights);
  });

  testWidgets('reduced motion keeps the bars still even when playing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: EqualizerBars(playing: true)),
      ),
    );

    expect(tester.hasRunningAnimations, isFalse);
    expect(barHeights(tester).toSet(), hasLength(1));
  });
}

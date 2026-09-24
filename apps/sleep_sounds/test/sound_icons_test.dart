import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_sounds/content/sounds.dart';

void main() {
  test('every sound has its own icon', () {
    final keys = sounds.map((s) => (s.icon.glyph?.codePoint, s.icon.drawn));

    expect(keys.toSet(), hasLength(sounds.length));
  });

  testWidgets('every sound icon renders at the card size', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Wrap(
          children: [for (final s in sounds) s.icon.build(Colors.white, 34)],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Icon), findsNWidgets(sounds.length - 2));
    expect(find.byType(CustomPaint), findsAtLeastNWidgets(2));
  });
}

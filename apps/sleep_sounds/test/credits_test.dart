import 'dart:io';

import 'package:factory_ui/factory_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_sounds/content/credits.dart';
import 'package:sleep_sounds/content/sounds.dart';

import 'settings_style_test.dart' show pumpSettings;

void main() {
  final credits = parseCredits(File('assets/credits.json').readAsStringSync());

  test('every sound has exactly one credit, titled like the sound', () {
    expect(
      credits.map((c) => c.title),
      unorderedEquals(sounds.map((s) => s.name)),
    );
  });

  test('every credit links to its source and its license', () {
    for (final c in credits) {
      expect(c.author, isNotEmpty, reason: c.title);
      expect(
        c.sourceUrl,
        startsWith('https://freesound.org/'),
        reason: c.title,
      );
      expect(
        c.licenseUrl,
        startsWith('https://creativecommons.org/'),
        reason: c.title,
      );
    }
  });

  test('Train is the only CC BY 4.0 sound and says what changed', () {
    final byAttribution = credits.where((c) => c.license == 'CC BY 4.0');

    expect(byAttribution.map((c) => c.title), ['Train']);
    expect(byAttribution.single.changes, isNotEmpty);
    expect(
      credits.where((c) => c.license == 'CC0 1.0'),
      hasLength(sounds.length - 1),
    );
  });

  testWidgets('Settings opens About, which lists the audio credits', (
    tester,
  ) async {
    await pumpSettings(tester);

    expect(find.text('Privacy Policy'), findsNothing);
    expect(find.text('App Version'), findsNothing);

    await tester.ensureVisible(find.text('About'));
    await tester.pump();
    await tester.tap(find.text('About'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AboutScreen), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('contact@douglaskrein.com'), findsOneWidget);

    await tester.tap(find.text('Audio credits'));
    await tester.pumpAndSettle();

    expect(find.text('CC0 1.0'), findsWidgets);

    await tester.scrollUntilVisible(find.text('CC BY 4.0'), 200);

    expect(find.text('CC BY 4.0'), findsOneWidget);
  });
}

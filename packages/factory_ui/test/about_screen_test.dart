import 'package:factory_ui/factory_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _cc0 = CreditEntry(
  title: 'Rain',
  originalTitle: 'Rain 01',
  author: 'mrspivey',
  sourceUrl: 'https://freesound.org/people/mrspivey/sounds/805174/',
  license: 'CC0 1.0',
  licenseUrl: 'https://creativecommons.org/publicdomain/zero/1.0/',
);

const _ccBy = CreditEntry(
  title: 'Train',
  originalTitle: 'Steam train travelling',
  author: 'kevp888',
  sourceUrl: 'https://freesound.org/people/kevp888/sounds/855145/',
  license: 'CC BY 4.0',
  licenseUrl: 'https://creativecommons.org/licenses/by/4.0/',
  changes: 'Trimmed and looped.',
);

final _labels = AboutLabels(
  title: 'About',
  version: 'Version',
  privacyPolicy: 'Privacy Policy',
  contact: 'Contact',
  openSourceLicenses: 'Open source licenses',
  audioCredits: 'Audio credits',
  creditLine: (title, author) => '"$title" by $author',
  changesLine: (changes) => 'Changes: $changes',
);

void main() {
  late List<Uri> opened;

  Future<void> pumpAbout(WidgetTester tester) async {
    opened = [];
    await tester.pumpWidget(
      MaterialApp(
        theme: factoryDarkTheme(),
        home: AboutScreen(
          appName: 'Sleepy Capy',
          version: '1.2.3 (4)',
          privacyPolicyUrl: 'https://example.com/privacy',
          supportEmail: 'help@example.com',
          credits: const [_cc0, _ccBy],
          labels: _labels,
          openLink: (uri) async => opened.add(uri),
        ),
      ),
    );
  }

  testWidgets('shows the version, contact address and every item', (
    tester,
  ) async {
    await pumpAbout(tester);

    expect(find.text('Sleepy Capy 1.2.3 (4)'), findsOneWidget);
    expect(find.text('help@example.com'), findsOneWidget);
    for (final label in [
      'Privacy Policy',
      'Contact',
      'Open source licenses',
      'Audio credits',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('privacy policy and contact go through openLink', (tester) async {
    await pumpAbout(tester);

    await tester.tap(find.text('Privacy Policy'));
    await tester.tap(find.text('Contact'));

    expect(opened, [
      Uri.parse('https://example.com/privacy'),
      Uri(scheme: 'mailto', path: 'help@example.com'),
    ]);
  });

  testWidgets('open source licenses opens the licence page', (tester) async {
    await pumpAbout(tester);

    await tester.tap(find.text('Open source licenses'));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('credits list author, license and what changed', (tester) async {
    await pumpAbout(tester);

    await tester.tap(find.text('Audio credits'));
    await tester.pumpAndSettle();

    expect(find.text('Rain'), findsOneWidget);
    expect(find.text('"Rain 01" by mrspivey'), findsOneWidget);
    expect(find.text('CC0 1.0'), findsOneWidget);
    expect(find.text('"Steam train travelling" by kevp888'), findsOneWidget);
    expect(find.text('CC BY 4.0'), findsOneWidget);
    expect(find.text('Changes: Trimmed and looped.'), findsOneWidget);
    expect(find.textContaining('Changes:'), findsOneWidget);
  });

  testWidgets('a credit opens its source and its license', (tester) async {
    await pumpAbout(tester);
    await tester.tap(find.text('Audio credits'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Train'));
    await tester.tap(find.text('CC BY 4.0'));

    expect(opened, [Uri.parse(_ccBy.sourceUrl), Uri.parse(_ccBy.licenseUrl)]);
  });
}

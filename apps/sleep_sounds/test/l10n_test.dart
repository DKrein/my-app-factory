import 'dart:convert';
import 'dart:io';

import 'package:factory_ads/factory_ads.dart';
import 'package:factory_audio/factory_audio.dart';
import 'package:factory_billing/factory_billing.dart';
import 'package:factory_storage/factory_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_sounds/content/sounds.dart';
import 'package:sleep_sounds/features/pro/pro_features.dart';
import 'package:sleep_sounds/l10n/l10n.dart';
import 'package:sleep_sounds/features/player/player_controller.dart';
import 'package:sleep_sounds/main.dart';

Map<String, String> strings(String lang) {
  final json = jsonDecode(
    File('lib/l10n/app_$lang.arb').readAsStringSync(),
  ) as Map<String, dynamic>;
  return {
    for (final e in json.entries)
      if (!e.key.startsWith('@')) e.key: e.value as String,
  };
}

Set<String> placeholders(String text) => {
  for (final m in RegExp(r'\{(\w+)\}').allMatches(text)) m.group(1)!,
};

void main() {
  final en = strings('en');
  final pt = strings('pt');

  group('the two languages match', () {
    test('every English key has a Portuguese one, and the other way round', () {
      expect(
        pt.keys.toSet().difference(en.keys.toSet()),
        isEmpty,
        reason: 'keys only in app_pt.arb',
      );
      expect(
        en.keys.toSet().difference(pt.keys.toSet()),
        isEmpty,
        reason: 'keys missing from app_pt.arb',
      );
    });

    test('a translation uses the same placeholders as the English text', () {
      for (final key in en.keys) {
        expect(
          placeholders(pt[key]!),
          placeholders(en[key]!),
          reason: 'placeholders of "$key"',
        );
      }
    });

    test('no translation is empty', () {
      for (final entry in [...en.entries, ...pt.entries]) {
        if (entry.key == '@@locale') continue;
        expect(entry.value.trim(), isNotEmpty, reason: entry.key);
      }
    });

    test('each file says which language it is', () {
      String locale(String lang) =>
          (jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
                  as Map<String, dynamic>)['@@locale']
              as String;

      expect(locale('en'), 'en');
      expect(locale('pt'), 'pt');
    });

    test('English is the fallback, then Portuguese', () {
      expect(AppLocalizations.supportedLocales.map((l) => l.languageCode), [
        'en',
        'pt',
      ]);
    });
  });

  group('sound names', () {
    final english = lookupAppLocalizations(const Locale('en'));
    final portuguese = lookupAppLocalizations(const Locale('pt'));

    test('every sound has a real name in both languages', () {
      for (final sound in sounds) {
        expect(soundName(english, sound), isNot(sound.id), reason: sound.id);
        expect(soundName(portuguese, sound), isNot(sound.id), reason: sound.id);
      }
    });

    test('names are unique within a language', () {
      for (final l10n in [english, portuguese]) {
        final names = sounds.map((s) => soundName(l10n, s)).toList();
        expect(names.toSet(), hasLength(names.length));
      }
    });

    test('a few names read right', () {
      final rain = sounds.firstWhere((s) => s.id == 'rain');
      final campfire = sounds.firstWhere((s) => s.id == 'campfire');

      expect(soundName(english, rain), 'Rain');
      expect(soundName(portuguese, rain), 'Chuva');
      expect(soundName(portuguese, campfire), 'Fogueira');
    });
  });

  group('the app follows the language of the device', () {
    Future<void> pumpApp(
      WidgetTester tester, {
      required Locale locale,
      bool pro = false,
      MemoryKeyValueStore? storage,
    }) async {
      tester.platformDispatcher.localesTestValue = [locale];
      tester.platformDispatcher.localeTestValue = locale;
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      final billing = FakeBillingGateway(
        catalog: sleepSoundsCatalog,
        initialProducts: [defaultProProduct],
      );
      if (pro) billing.entitlements.grant([ProFeatures.entitlement]);
      await tester.pumpWidget(
        SleepSoundsApp(
          storage: storage ?? MemoryKeyValueStore(),
          createGateway: ({required ownsAudioSession}) => PreviewAudioGateway(),
          ads: PreviewAdsGateway(initialized: true),
          billing: billing,
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
    }

    testWidgets('Portuguese', (tester) async {
      await pumpApp(tester, locale: const Locale('pt', 'BR'));

      expect(find.text('Hora do capi-cochilo'), findsOneWidget);
      expect(find.text('Timer Capy'), findsOneWidget);
      expect(find.text('Para relaxar'), findsOneWidget);
      expect(find.text('Chuva'), findsOneWidget);
      expect(find.text('Chuva na barraca'), findsOneWidget);
      expect(find.text('Time to capy-nap'), findsNothing);
    });

    testWidgets('the timer chip "Off" is translated', (tester) async {
      final storage = MemoryKeyValueStore();
      await storage.writeString(
        'last_session_v1',
        '{"soundIds":[],"timerMinutes":0}',
      );
      await pumpApp(tester, locale: const Locale('pt'), storage: storage);

      expect(find.text('Desl.'), findsOneWidget);
      expect(find.text('Off'), findsNothing);
    });

    testWidgets('the status line is translated, with its values', (
      tester,
    ) async {
      await pumpApp(tester, locale: const Locale('pt'));

      await tester.tap(
        find.descendant(
          of: find.byType(GridView),
          matching: find.text('Chuva'),
        ),
      );
      await tester.pump();

      expect(find.text('Para em 1h 00m'), findsOneWidget);

      await tester.tap(find.byTooltip('Pausar'));
      await tester.pump();

      expect(find.text('Pausado'), findsOneWidget);
    });

    testWidgets('Settings and the paywall', (tester) async {
      await pumpApp(tester, locale: const Locale('pt'));

      await tester.tap(find.byIcon(Icons.tune_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('Lembrete de dormir'), findsOneWidget);
      expect(find.text('Conhecer o Pro'), findsOneWidget);
      expect(find.text('Tema'), findsOneWidget);

      await tester.tap(find.text('Conhecer o Pro'));
      await tester.pumpAndSettle();

      expect(find.text('Quero o Pro'), findsOneWidget);
      expect(find.text('Ajuste o volume de cada som'), findsOneWidget);
      expect(find.text(r'$4.99 · compra única'), findsOneWidget);
    });

    testWidgets('Pro screens: timer options and the saved-mix dialog', (
      tester,
    ) async {
      await pumpApp(tester, locale: const Locale('pt'), pro: true);
      await tester.tap(
        find.descendant(
          of: find.byType(GridView),
          matching: find.text('Chuva'),
        ),
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Opções do timer'));
      await tester.pumpAndSettle();

      expect(find.text('Duração personalizada'), findsOneWidget);
      expect(find.text('Parar às'), findsOneWidget);
      expect(find.text('Diminuir o volume aos poucos'), findsOneWidget);

      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Salvar mix'));
      await tester.pumpAndSettle();

      expect(find.text('Incluir o timer (1h)'), findsOneWidget);
      expect(find.text('Nome'), findsOneWidget);
    });

    testWidgets('an unsupported language falls back to English', (
      tester,
    ) async {
      await pumpApp(tester, locale: const Locale('fr'));

      expect(find.text('Time to capy-nap'), findsOneWidget);
      expect(find.text('Rain'), findsOneWidget);
    });

    testWidgets('a mix saved with a custom timer names it in the dialog', (
      tester,
    ) async {
      await pumpApp(tester, locale: const Locale('en'), pro: true);
      await tester.tap(
        find.descendant(of: find.byType(GridView), matching: find.text('Rain')),
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Timer options'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<int>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5 min').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('set-custom-duration')));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Save mix'));
      await tester.pumpAndSettle();

      expect(find.text('Include timer (2h 5m)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  test('the notification names the sounds in the given language', () async {
    final notifier = PreviewNowPlayingNotifier();
    final portuguese = lookupAppLocalizations(const Locale('pt'));
    final controller = PlaybackController(
      createGateway: ({required ownsAudioSession}) => PreviewAudioGateway(),
      nowPlaying: notifier,
      soundLabel: (sound) => soundName(portuguese, sound),
    );

    await controller.toggle(sounds.firstWhere((s) => s.id == 'rain'));
    await controller.toggle(sounds.firstWhere((s) => s.id == 'wind'));

    expect(notifier.title, 'Chuva, Vento');
    controller.dispose();
  });
}

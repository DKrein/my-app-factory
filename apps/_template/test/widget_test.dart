import 'dart:convert';
import 'dart:io';

import 'package:app_template/main.dart';
import 'package:factory_storage/factory_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TemplateApp renders starter page and persists counter', (
    tester,
  ) async {
    final storage = MemoryKeyValueStore();

    await tester.pumpWidget(TemplateApp(storage: storage));
    await tester.pumpAndSettle();

    expect(find.text('App Template'), findsOneWidget);
    expect(find.text('Welcome!'), findsOneWidget);
    expect(find.text('Actions saved in the KeyValueStore: 0'), findsOneWidget);

    // Tap increment button
    await tester.tap(find.text('Add action'));
    await tester.pumpAndSettle();

    expect(find.text('Actions saved in the KeyValueStore: 1'), findsOneWidget);

    // Verify persisted in KeyValueStore
    final stored = await storage.readString('starter_counter');
    expect(stored, equals('1'));

    // Open About bottom sheet
    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    expect(find.text('About this app'), findsOneWidget);
  });

  testWidgets('follows the device language: Portuguese', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('pt', 'BR')];
    tester.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await tester.pumpWidget(TemplateApp(storage: MemoryKeyValueStore()));
    await tester.pumpAndSettle();

    expect(find.text('Bem-vindo!'), findsOneWidget);
    expect(find.text('Incrementar ação'), findsOneWidget);
  });

  testWidgets('an unsupported language falls back to English', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    tester.platformDispatcher.localeTestValue = const Locale('fr');
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await tester.pumpWidget(TemplateApp(storage: MemoryKeyValueStore()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome!'), findsOneWidget);
  });

  test(
    'every key in app_en.arb exists in app_pt.arb, with the same placeholders',
    () {
      Map<String, dynamic> read(String lang) =>
          jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync())
              as Map<String, dynamic>;
      Set<String> keys(Map<String, dynamic> arb) =>
          arb.keys.where((k) => !k.startsWith('@')).toSet();
      Set<String> holes(String text) => {
        for (final m in RegExp(r'\{(\w+)\}').allMatches(text)) m.group(1)!,
      };

      final en = read('en');
      final pt = read('pt');

      expect(keys(en), keys(pt));
      for (final key in keys(en).where((k) => k != '@@locale')) {
        expect(holes(pt[key] as String), holes(en[key] as String), reason: key);
      }
    },
  );
}

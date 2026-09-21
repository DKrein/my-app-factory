import 'package:app_template/main.dart';
import 'package:factory_storage/factory_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TemplateApp renders starter page and persists counter', (tester) async {
    final storage = MemoryKeyValueStore();

    await tester.pumpWidget(
      TemplateApp(storage: storage),
    );
    await tester.pumpAndSettle();

    expect(find.text('App Template'), findsOneWidget);
    expect(find.text('Bem-vindo!'), findsOneWidget);
    expect(find.text('Ações realizadas e salvas no KeyValueStore: 0'), findsOneWidget);

    // Tap increment button
    await tester.tap(find.text('Incrementar Ação'));
    await tester.pumpAndSettle();

    expect(find.text('Ações realizadas e salvas no KeyValueStore: 1'), findsOneWidget);

    // Verify persisted in KeyValueStore
    final stored = await storage.readString('starter_counter');
    expect(stored, equals('1'));

    // Open About bottom sheet
    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pumpAndSettle();

    expect(find.text('Sobre este Aplicativo'), findsOneWidget);
  });
}

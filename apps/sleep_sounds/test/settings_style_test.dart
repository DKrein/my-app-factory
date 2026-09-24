import 'package:factory_billing/factory_billing.dart';
import 'package:factory_storage/factory_storage.dart';
import 'package:factory_ui/factory_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_sounds/features/common/starfield_background.dart';
import 'package:sleep_sounds/features/library/library_page.dart';
import 'package:sleep_sounds/main.dart';

Future<void> pumpSettings(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: factoryDarkTheme(),
      home: Scaffold(
        body: SettingsSheet(
          billing: FakeBillingGateway(
            catalog: sleepSoundsCatalog,
            initialProducts: [defaultRemoveAdsProduct],
          ),
          storage: MemoryKeyValueStore(),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('the sky is fainter than on the home screen', (tester) async {
    await pumpSettings(tester);

    final sky = tester.widget<StarfieldBackground>(
      find.byType(StarfieldBackground),
    );
    expect(sky.starOpacity, lessThan(.3));
  });

  testWidgets('upsell card uses the app palette', (tester) async {
    await pumpSettings(tester);

    final card = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Make Sleepy Capy Ad-Free'),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = card.decoration! as BoxDecoration;
    expect(decoration.color, FactoryColors.surfaceElevated);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.style!.backgroundColor!.resolve({}), FactoryColors.mist);
  });

  testWidgets('icon, text and switch of the reminder share one center line', (
    tester,
  ) async {
    await pumpSettings(tester);

    final title = tester.getRect(find.text('Bedtime Reminder'));
    final subtitle = tester.getRect(find.text('Off'));
    final textCenter = (title.top + subtitle.bottom) / 2;

    expect(tester.getCenter(find.byType(Switch)).dy, closeTo(textCenter, 1));
    expect(
      tester.getCenter(find.byIcon(Icons.bedtime_outlined)).dy,
      closeTo(textCenter, 1),
    );
  });
}

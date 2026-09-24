import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:factory_ads/factory_ads.dart';
import 'package:factory_audio/factory_audio.dart';
import 'package:factory_billing/factory_billing.dart';
import 'package:factory_storage/factory_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_sounds/main.dart';

/// Width and height read from the PNG header.
(int, int) pngSize(String path) {
  final bytes = File(path).readAsBytesSync();
  final header = ByteData.sublistView(bytes, 16, 24);
  return (header.getUint32(0), header.getUint32(4));
}

void main() {
  group('the icons have the sizes the stores ask for', () {
    const sizes = {
      'assets/branding/icon_foreground.png': (1024, 1024),
      'assets/branding/icon_background.png': (1024, 1024),
      'assets/branding/icon_monochrome.png': (1024, 1024),
      'assets/branding/icon_legacy.png': (1024, 1024),
      'store/icon_512.png': (512, 512),
      'store/feature_graphic_1024x500.png': (1024, 500),
    };
    sizes.forEach((path, size) {
      test('$path is ${size.$1}x${size.$2}', () {
        expect(pngSize(path), size);
      });
    });

    test('the Play icon is under 1 MB', () {
      expect(File('store/icon_512.png').lengthSync(), lessThan(1024 * 1024));
    });
  });

  group('adaptive icon art stays inside the visible circle', () {
    // The visible part of a round adaptive icon is a 66 dp circle in a 108 dp
    // canvas: a radius of 30.5% of the canvas. A little slack for anti-aliasing.
    const maxRadius = 0.31;

    for (final name in ['icon_foreground', 'icon_monochrome']) {
      testWidgets(name, (tester) async {
        final farthest = await tester.runAsync(() async {
          final codec = await ui.instantiateImageCodec(
            File('assets/branding/$name.png').readAsBytesSync(),
          );
          final image = (await codec.getNextFrame()).image;
          final rgba = (await image.toByteData())!;
          final size = image.width;
          final center = (size - 1) / 2;
          var far = 0.0;
          for (var y = 0; y < size; y++) {
            for (var x = 0; x < size; x++) {
              if (rgba.getUint8((y * size + x) * 4 + 3) > 16) {
                far = math.max(
                  far,
                  math.sqrt(math.pow(x - center, 2) + math.pow(y - center, 2)),
                );
              }
            }
          }
          return far / size;
        });

        expect(farthest, lessThanOrEqualTo(maxRadius));
        expect(farthest, greaterThan(.2), reason: 'the art should not be tiny');
      });
    }
  });

  group('the native splash', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    test('draws the icon on the dark background, on every Android version', () {
      expect(pubspec, contains('image: assets/branding/icon_foreground.png'));
      expect(pubspec, contains('color: "0B1020"'));
      expect(pubspec, contains('icon_background_color: "0B1020"'));
      expect(File('assets/branding/icon_foreground.png').existsSync(), isTrue);
    });

    test('the Android 12 splash resource was generated', () {
      final styles = File('android/app/src/main/res/values-v31/styles.xml')
          .readAsStringSync();

      expect(styles, contains('windowSplashScreenAnimatedIcon'));
      expect(
        File('android/app/src/main/res/drawable-xxxhdpi/android12splash.png')
            .existsSync(),
        isTrue,
      );
    });
  });

  testWidgets(
    'the app opens straight on the library, with no splash of its own',
    (tester) async {
      await tester.pumpWidget(
        SleepSoundsApp(
          storage: MemoryKeyValueStore(),
          createGateway: ({required ownsAudioSession}) => PreviewAudioGateway(),
          ads: PreviewAdsGateway(initialized: true),
          billing: FakeBillingGateway(catalog: sleepSoundsCatalog),
        ),
      );
      await tester.pump();

      expect(find.text('Time to capy-nap'), findsOneWidget);
      expect(find.text('Sleepy Capy'), findsNothing);
    },
  );
}

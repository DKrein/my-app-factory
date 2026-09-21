import 'package:factory_navigation/factory_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FactoryRoutes', () {
    test('defines shared route names', () {
      expect(FactoryRoutes.settings, equals('/settings'));
    });
  });
}

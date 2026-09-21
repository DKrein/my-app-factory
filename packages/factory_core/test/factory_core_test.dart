import 'package:factory_core/factory_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppFailure', () {
    test('formats message and retains cause', () {
      final error = Exception('network down');
      final failure = AppFailure('Erro de conexão', cause: error);

      expect(failure.message, equals('Erro de conexão'));
      expect(failure.cause, equals(error));
      expect(failure.toString(), equals('Erro de conexão'));
    });
  });

  group('AppResult', () {
    test('Success returns encapsulated value', () {
      const result = Success<int>(42);
      expect(result.value, equals(42));
      expect(result, isA<AppResult<int>>());
    });

    test('Failure returns AppFailure', () {
      const failure = Failure<int>(AppFailure('Falha'));
      expect(failure.error.message, equals('Falha'));
      expect(failure, isA<AppResult<int>>());
    });
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Screens must take their text from `context.l10n`, never from a literal.
/// A literal is fine when it is only numbers and units ("15 min", "2 h").
void main() {
  final calls = RegExp(
    r'''(?:Text\(\s*(?:const\s+)?|tooltip:\s*|labelText:\s*|helpText:\s*|hintText:\s*|semanticLabel:\s*|label:\s*)(['"])((?:\\.|(?!\1).)*)\1''',
  );

  test('no screen has English text written into the code', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.startsWith('lib/l10n/')) continue;
      final text = entity.readAsStringSync();
      for (final match in calls.allMatches(text)) {
        var literal = match.group(2)!;
        literal = literal
            .replaceAll(RegExp(r'\$\{[^}]*\}|\$\w+'), '')
            .replaceAll(RegExp(r'\b(min|h|m|s)\b'), '');
        if (RegExp(r'[A-Za-z]{2,}').hasMatch(literal)) {
          offenders.add('${entity.path}: "${match.group(2)}"');
        }
      }
    }

    expect(offenders, isEmpty, reason: 'move these to app_en.arb / app_pt.arb');
  });

  test('the guard itself catches a literal', () {
    expect(calls.hasMatch("Text('Hello there')"), isTrue);
    expect(calls.hasMatch("tooltip: 'Close'"), isTrue);
    expect(calls.hasMatch('Text(context.l10n.close)'), isFalse);
  });
}

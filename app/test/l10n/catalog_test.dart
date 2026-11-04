import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Localization gates (docs/localization.md §2, step 7). Every shipped
/// locale must define every key with the same placeholders, and values
/// must not silently fall back to English.
void main() {
  final dir = Directory('lib/l10n/arb');
  final catalogs = {
    for (final f in dir.listSync().whereType<File>().where((f) => f.path.endsWith('.arb')))
      RegExp(r'app_(\w+)\.arb$').firstMatch(f.path)!.group(1)!:
          jsonDecode(f.readAsStringSync()) as Map<String, Object?>,
  };
  final template = catalogs['en']!;
  Iterable<String> messageKeys(Map<String, Object?> c) => c.keys.where((k) => !k.startsWith('@'));

  // Values allowed to be identical to English (brand names, examples).
  const sameAsEnglish = {'appName', 'digitsLatin', 'inviteCodeHint'};

  Set<String> placeholders(String message) => {
    // A placeholder is `{name}` or `{name, …}`; ICU branch bodies such as
    // `=0{Comment}` or `other{…}` follow a word character and are skipped.
    for (final m in RegExp(r'(?<![=\w])\{(\w+)[,}]').allMatches(message)) m.group(1)!,
  };

  test('at least English and Persian ship', () {
    expect(catalogs.keys, containsAll(['en', 'fa']));
  });

  for (final entry in catalogs.entries.where((e) => e.key != 'en')) {
    final locale = entry.key;
    final catalog = entry.value;

    test('$locale has exactly the template keys', () {
      final missing = messageKeys(template).toSet().difference(messageKeys(catalog).toSet());
      final extra = messageKeys(catalog).toSet().difference(messageKeys(template).toSet());
      expect(missing, isEmpty, reason: 'missing in $locale');
      expect(extra, isEmpty, reason: 'unknown keys in $locale');
    });

    test('$locale keeps every placeholder', () {
      for (final key in messageKeys(template)) {
        final en = template[key]! as String;
        final other = catalog[key] as String? ?? '';
        expect(placeholders(other), placeholders(en), reason: '$locale:$key');
      }
    });

    test('$locale has no untranslated values', () {
      final untranslated = [
        for (final key in messageKeys(template))
          if (!sameAsEnglish.contains(key) && catalog[key] == template[key]) key,
      ];
      expect(untranslated, isEmpty);
    });
  }

  test('no empty values', () {
    for (final c in catalogs.entries) {
      for (final key in messageKeys(c.value)) {
        expect((c.value[key]! as String).trim(), isNotEmpty, reason: '${c.key}:$key');
      }
    }
  });
}

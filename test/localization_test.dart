import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rimapay/core/localization/l10n.dart';

/// Guards the Hausa translation layer.
///
/// `flutter gen-l10n` already makes a mistyped key a compile error, so these
/// tests cover what it does not: that Hausa is actually complete, that the two
/// ARB files agree on placeholders, and that the delegate set can genuinely
/// serve Hausa — which flutter_localizations itself cannot.
void main() {
  Map<String, dynamic> loadArb(String locale) => json.decode(
        File('lib/l10n/app_$locale.arb').readAsStringSync(),
      ) as Map<String, dynamic>;

  final en = loadArb('en');
  final ha = loadArb('ha');

  Iterable<String> messageKeys(Map<String, dynamic> arb) =>
      arb.keys.where((k) => !k.startsWith('@'));

  group('completeness', () {
    test('every English string has a Hausa translation', () {
      final missing =
          messageKeys(en).toSet().difference(messageKeys(ha).toSet());
      expect(missing, isEmpty,
          reason: 'Missing Hausa for: ${missing.join(', ')}');
    });

    test('no Hausa string is orphaned', () {
      final orphaned =
          messageKeys(ha).toSet().difference(messageKeys(en).toSet());
      expect(orphaned, isEmpty,
          reason: 'Hausa keys with no English source: ${orphaned.join(', ')}');
    });

    test('gen-l10n reports nothing untranslated', () {
      // l10n.yaml writes this on every generation; a non-empty file means the
      // build is shipping English text to Hausa users.
      final file = File('lib/l10n/untranslated.json');
      if (!file.existsSync()) return;
      final contents = file.readAsStringSync().trim();
      if (contents.isEmpty) return;
      final report = json.decode(contents) as Map<String, dynamic>;
      for (final entry in report.entries) {
        expect(entry.value, isEmpty,
            reason: 'Untranslated in ${entry.key}: ${entry.value}');
      }
    });
  });

  group('value hygiene', () {
    test('no value contains a literal backslash-n', () {
      final offenders = <String>[];
      for (final arb in [en, ha]) {
        for (final key in messageKeys(arb)) {
          if ((arb[key] as String).contains(r'\n')) offenders.add(key);
        }
      }
      expect(offenders, isEmpty,
          reason: 'Escaped newlines in: ${offenders.join(', ')}');
    });

    test('no value is empty', () {
      for (final arb in [en, ha]) {
        for (final key in messageKeys(arb)) {
          expect((arb[key] as String).trim(), isNotEmpty, reason: key);
        }
      }
    });

    test('placeholders match between languages', () {
      final pattern = RegExp(r'\{(\w+)\}');
      final mismatched = <String>[];
      for (final key in messageKeys(en)) {
        if (!ha.containsKey(key)) continue;
        final enTokens =
            pattern.allMatches(en[key] as String).map((m) => m.group(1)!).toSet();
        final haTokens =
            pattern.allMatches(ha[key] as String).map((m) => m.group(1)!).toSet();
        if (!enTokens.containsAll(haTokens) ||
            !haTokens.containsAll(enTokens)) {
          mismatched.add('$key (en: $enTokens, ha: $haTokens)');
        }
      }
      expect(mismatched, isEmpty,
          reason: 'Placeholder drift: ${mismatched.join('; ')}');
    });

    test('every placeholder is declared in the template metadata', () {
      final pattern = RegExp(r'\{(\w+)\}');
      final undeclared = <String>[];
      for (final key in messageKeys(en)) {
        final tokens = pattern
            .allMatches(en[key] as String)
            .map((m) => m.group(1)!)
            .toSet();
        if (tokens.isEmpty) continue;
        final meta = en['@$key'] as Map<String, dynamic>?;
        final declared =
            (meta?['placeholders'] as Map<String, dynamic>?)?.keys.toSet() ??
                <String>{};
        if (!declared.containsAll(tokens)) {
          undeclared.add('$key: ${tokens.difference(declared)}');
        }
      }
      expect(undeclared, isEmpty,
          reason: 'Undeclared placeholders: ${undeclared.join('; ')}');
    });

    test('Hausa is not merely a copy of English', () {
      final identical = messageKeys(en)
          .where((k) => ha[k] == en[k])
          .where((k) {
            final value = en[k] as String;
            // Proper nouns, brand names and symbol-only values legitimately match.
            return value.length > 3 &&
                !value.contains('RimaPay') &&
                !RegExp(r'^[\W\d]*$').hasMatch(value);
          })
          .toList();
      expect(
        identical.length,
        lessThan(messageKeys(en).length * 0.15),
        reason: 'Likely untranslated: ${identical.take(25).join(', ')}',
      );
    });
  });

  group('delegates', () {
    test('supports English and Hausa', () {
      expect(
        L10n.supportedLocales.map((l) => l.languageCode).toSet(),
        {'en', 'ha'},
      );
    });

    test('a delegate exists for every Localizations type in Hausa', () {
      // flutter_localizations ships no Hausa bundle, so without the fallback
      // delegates MaterialApp asserts the moment the locale becomes Hausa.
      const hausa = Locale('ha');
      for (final type in [
        MaterialLocalizations,
        WidgetsLocalizations,
        CupertinoLocalizations,
      ]) {
        expect(
          L10n.delegates.any((d) => d.type == type && d.isSupported(hausa)),
          isTrue,
          reason: 'No delegate serves $type in Hausa',
        );
      }
    });

    test('every supported locale has a display name', () {
      for (final locale in L10n.supportedLocales) {
        expect(L10n.languageNames[locale.languageCode], isNotNull);
      }
    });
  });

  group('lookup', () {
    test('resolves Hausa and English through the generated class', () async {
      final haStrings = await AppL10n.delegate.load(const Locale('ha'));
      final enStrings = await AppL10n.delegate.load(const Locale('en'));
      expect(haStrings.sendMoney, 'Aika Kudi');
      expect(enStrings.sendMoney, 'Send Money');
    });

    test('substitutes placeholders', () async {
      final haStrings = await AppL10n.delegate.load(const Locale('ha'));
      expect(haStrings.dailyLimit('₦50,000'), contains('₦50,000'));
    });
  });
}

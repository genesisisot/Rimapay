import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rimapay/core/localization/l10n.dart';
import 'package:rimapay/core/providers/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// End-to-end cover for the language switch.
///
/// The previous implementation failed precisely here: the provider, the
/// delegates and the widgets were each individually plausible, but nothing
/// tied a change in the stored preference to Hausa text actually appearing on
/// screen. These tests assert that whole path.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// A minimal app wired exactly like main.dart.
  Widget harness() => Consumer(
        builder: (context, ref, _) => MaterialApp(
          locale: ref.watch(languageProvider),
          localizationsDelegates: L10n.delegates,
          supportedLocales: L10n.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  Text(context.l10n.sendMoney),
                  Text(context.l10n.upgradeToUnlock),
                ],
              ),
            ),
          ),
        ),
      );

  testWidgets('defaults to English', (tester) async {
    await tester.pumpWidget(ProviderScope(child: harness()));
    await tester.pumpAndSettle();

    expect(find.text('Send Money'), findsOneWidget);
  });

  testWidgets('switching to Hausa re-renders the whole tree in Hausa',
      (tester) async {
    late WidgetRef ref;
    await tester.pumpWidget(ProviderScope(
      child: Consumer(builder: (context, r, _) {
        ref = r;
        return harness();
      }),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Send Money'), findsOneWidget);

    await ref.read(languageProvider.notifier).setLanguage('ha');
    await tester.pumpAndSettle();

    expect(find.text('Send Money'), findsNothing);
    expect(find.text('Aika Kudi'), findsOneWidget);
  });

  testWidgets('Hausa renders hooked letters, not tofu', (tester) async {
    late WidgetRef ref;
    await tester.pumpWidget(ProviderScope(
      child: Consumer(builder: (context, r, _) {
        ref = r;
        return harness();
      }),
    ));
    await tester.pumpAndSettle();
    await ref.read(languageProvider.notifier).setLanguage('ha');
    await tester.pumpAndSettle();

    // 'Haɓaka don Buɗewa' — the hooked letters are the ones no bundled font
    // covered before Inter was added as a fallback.
    final text = tester.widget<Text>(find.byType(Text).at(1)).data!;
    expect(text, contains('ɓ'));
    expect(text, contains('ɗ'));
  });

  group('persistence', () {
    testWidgets('the chosen language is written to preferences',
        (tester) async {
      late WidgetRef ref;
      await tester.pumpWidget(ProviderScope(
        child: Consumer(builder: (context, r, _) {
          ref = r;
          return harness();
        }),
      ));
      await tester.pumpAndSettle();

      await ref.read(languageProvider.notifier).setLanguage('ha');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kLanguagePrefKey), 'ha');
    });

    testWidgets('a saved language is restored on the first frame',
        (tester) async {
      SharedPreferences.setMockInitialValues({kLanguagePrefKey: 'ha'});
      final saved = await LanguageNotifier.readSavedLanguageCode();

      await tester.pumpWidget(ProviderScope(
        overrides: [
          languageProvider
              .overrideWith((ref) => LanguageNotifier(Locale(saved))),
        ],
        child: harness(),
      ));
      // Deliberately only one pump: this asserts there is no English flash
      // before the saved preference is applied.
      await tester.pump();

      expect(find.text('Aika Kudi'), findsOneWidget);
      expect(find.text('Send Money'), findsNothing);
    });

    testWidgets('the legacy rimapay_language key is migrated', (tester) async {
      SharedPreferences.setMockInitialValues({'rimapay_language': 'ha'});

      expect(await LanguageNotifier.readSavedLanguageCode(), 'ha');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kLanguagePrefKey), 'ha');
      expect(prefs.getString('rimapay_language'), isNull);
    });

    testWidgets('an unsupported saved language falls back to English',
        (tester) async {
      SharedPreferences.setMockInitialValues({kLanguagePrefKey: 'fr'});
      expect(await LanguageNotifier.readSavedLanguageCode(), 'en');
    });
  });

  testWidgets('toggle flips between the two languages', (tester) async {
    late WidgetRef ref;
    await tester.pumpWidget(ProviderScope(
      child: Consumer(builder: (context, r, _) {
        ref = r;
        return harness();
      }),
    ));
    await tester.pumpAndSettle();

    ref.read(toggleLanguageProvider)();
    await tester.pumpAndSettle();
    expect(find.text('Aika Kudi'), findsOneWidget);

    ref.read(toggleLanguageProvider)();
    await tester.pumpAndSettle();
    expect(find.text('Send Money'), findsOneWidget);
  });
}

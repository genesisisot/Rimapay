import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rimapay/core/localization/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted preference key. This is the single source of truth — the old
/// 'rimapay_language' key in StorageService is migrated on first read.
const String kLanguagePrefKey = 'language_code';
const String _kLegacyLanguagePrefKey = 'rimapay_language';

/// Holds the active [Locale]. Unlike the previous implementation, the state
/// holds the *real* locale — forcing it to English here is what made the
/// Hausa translations unreachable.
class LanguageNotifier extends StateNotifier<Locale> {
  LanguageNotifier([Locale? initial])
      : super(initial ?? const Locale('en')) {
    Intl.defaultLocale = state.languageCode;
    // Only needed when the locale was not preloaded in main(); a preloaded
    // value is already correct, so this avoids a redundant read.
    if (initial == null) _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final code = await readSavedLanguageCode();
    if (code != state.languageCode) {
      state = Locale(code);
      Intl.defaultLocale = code;
    }
  }

  /// Reads the stored language, migrating the legacy key if present.
  /// Call this before `runApp` to seed the provider and avoid an English
  /// flash on the first frame.
  static Future<String> readSavedLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    var code = prefs.getString(kLanguagePrefKey);

    if (code == null) {
      final legacy = prefs.getString(_kLegacyLanguagePrefKey);
      if (legacy != null) {
        await prefs.setString(kLanguagePrefKey, legacy);
        await prefs.remove(_kLegacyLanguagePrefKey);
        code = legacy;
      }
    }

    final isSupported =
        L10n.supportedLocales.any((l) => l.languageCode == code);
    return isSupported ? code! : 'en';
  }

  Future<void> setLanguage(String languageCode) async {
    if (!L10n.supportedLocales.any((l) => l.languageCode == languageCode)) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kLanguagePrefKey, languageCode);

    // Keeps DateFormat/NumberFormat in step with the UI language.
    Intl.defaultLocale = languageCode;
    state = Locale(languageCode);
  }

  Future<void> toggleLanguage() =>
      setLanguage(state.languageCode == 'en' ? 'ha' : 'en');
}

final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  return LanguageNotifier();
});

/// Invoke it: `ref.read(toggleLanguageProvider)()` — reading alone only
/// returns the closure.
final toggleLanguageProvider = Provider<void Function()>((ref) {
  return () {
    HapticFeedback.lightImpact();
    ref.read(languageProvider.notifier).toggleLanguage();
  };
});

/// Current language code, e.g. 'en' or 'ha'.
final currentLanguageProvider = Provider<String>((ref) {
  return ref.watch(languageProvider).languageCode;
});

// Strings are read in widgets with `context.l10n.<key>` (see
// core/localization/l10n.dart), which is compile-checked. There is deliberately
// no key-based translation provider here — a stringly-typed lookup is exactly
// what let mistyped keys leak into the UI before.

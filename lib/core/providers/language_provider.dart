import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rimapay/core/localization/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The LanguageProvider holds the state (the current Locale) and manages it.
class LanguageNotifier extends StateNotifier<Locale> {
  // Initialize the state with a default locale and then load the saved one.
  LanguageNotifier() : super(const Locale('en', '')) {
    _loadSavedLanguage();
  }

  // Asynchronously loads the language from shared preferences.
  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString('language_code');
    if (savedLanguageCode != null) {
      // Use English as fallback for unsupported locales
      if (savedLanguageCode == 'ha') {
        // For Hausa, we'll use English as the material locale but keep 'ha' for our translations
        state = const Locale('en', ''); // Use English for Material components
      } else {
        state = Locale(savedLanguageCode, '');
      }
    }
  }

  final _translations = AppLocalizations.localizedValues;
  // Get the current language code for translations (separate from Material locale)
  String get currentLanguageCode {
    final prefs = SharedPreferences.getInstance();
    return prefs.then((p) => p.getString('language_code') ?? 'en').toString();
  }

  // Method to set the language and save it to shared preferences.
  Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);

    // For Material components, always use English as fallback
    // but keep the actual language preference stored
    state = const Locale('en', '');
  }

  // Method to toggle between English and Hausa.
  void toggleLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final currentLang = prefs.getString('language_code') ?? 'en';
    setLanguage(currentLang == 'en' ? 'ha' : 'en');
  }

  // A translation function that can be accessed via the provider.
  Future<String> t(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'en';
    return _translations[languageCode]?[key] ?? key;
  }

  // Synchronous version for immediate access
  String tSync(String key) {
    // This is a simplified version - you might want to cache the language code
    // For now, we'll default to English if we can't determine the language

    return _translations[state.languageCode]?[key] ?? key;
  }
}

// This is the provider that exposes the LanguageNotifier instance.
final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  return LanguageNotifier();
});

// Fixed toggle provider - should not return a function directly
final toggleLanguageProvider = Provider<void Function()>((ref) {
  return () {
    HapticFeedback.lightImpact();
    ref.read(languageProvider.notifier).toggleLanguage();
  };
});

// Provider for getting current language code
final currentLanguageProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('language_code') ?? 'en';
});

// A separate provider just for the translation function
final languageTranslationsProvider = Provider<String Function(String)>((ref) {
  return ref.watch(languageProvider.notifier).tSync;
});

// The translations map remains

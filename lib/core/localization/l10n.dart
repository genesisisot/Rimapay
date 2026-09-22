/// Localization entry point for the app.
///
/// Strings live in `lib/l10n/app_en.arb` and `lib/l10n/app_ha.arb` and are
/// compiled into `AppL10n` by `flutter gen-l10n` (configured in `l10n.yaml`).
/// Read them in a widget with `context.l10n.sendMoney` — a real getter, so a
/// mistyped or deleted string is a compile error rather than a raw key leaking
/// into the UI.
///
/// To add a string: put it in `app_en.arb`, translate it in `app_ha.arb`, run
/// `flutter gen-l10n`. `lib/l10n/untranslated.json` lists anything missing a
/// Hausa translation and must stay empty.
library;

import 'package:flutter/cupertino.dart' show CupertinoLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../l10n/generated/app_localizations.g.dart';

export '../../l10n/generated/app_localizations.g.dart' show AppL10n;

extension AppL10nContext on BuildContext {
  /// The active translations. Safe in any widget below `MaterialApp`.
  AppL10n get l10n => AppL10n.of(this);
}

class L10n {
  const L10n._();

  static const List<Locale> supportedLocales = AppL10n.supportedLocales;

  /// Display names for the language picker, each in its own language.
  static const Map<String, String> languageNames = {
    'en': 'English',
    'ha': 'Hausa',
  };

  /// Everything `MaterialApp` needs.
  ///
  /// The three fallback delegates at the end exist because
  /// `flutter_localizations` ships no Hausa bundle — there is no
  /// `material_ha.arb` and `kMaterialSupportedLanguages` does not contain
  /// 'ha'. Without them `MaterialApp` asserts at startup as soon as the locale
  /// becomes Hausa. Each claims support for 'ha' only and serves the English
  /// bundle, so Flutter's own widget text (date pickers, text-selection menus,
  /// default dialog buttons) stays English while the app's strings are Hausa.
  ///
  /// They are registered after the Global delegates so English still resolves
  /// through the real ones.
  static const List<LocalizationsDelegate<dynamic>> delegates = [
    AppL10n.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    _HausaFallbackMaterialDelegate(),
    _HausaFallbackWidgetsDelegate(),
    _HausaFallbackCupertinoDelegate(),
  ];
}

class _HausaFallbackMaterialDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _HausaFallbackMaterialDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ha';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.load(const Locale('en'));

  @override
  bool shouldReload(_HausaFallbackMaterialDelegate old) => false;
}

class _HausaFallbackWidgetsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _HausaFallbackWidgetsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ha';

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      GlobalWidgetsLocalizations.delegate.load(const Locale('en'));

  @override
  bool shouldReload(_HausaFallbackWidgetsDelegate old) => false;
}

class _HausaFallbackCupertinoDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _HausaFallbackCupertinoDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'ha';

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.load(const Locale('en'));

  @override
  bool shouldReload(_HausaFallbackCupertinoDelegate old) => false;
}

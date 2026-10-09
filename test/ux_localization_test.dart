import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rimapay/core/localization/tier_labels.dart';
import 'package:rimapay/core/providers/auth_provider.dart';
import 'package:rimapay/core/providers/language_provider.dart';
import 'package:rimapay/core/services/storage_service.dart';
import 'package:rimapay/l10n/generated/app_localizations.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('tier names', () {
    final en = lookupAppL10n(const Locale('en'));
    final ha = lookupAppL10n(const Locale('ha'));

    test('match the Account Tiers screen (Basic → Standard → Premium)', () {
      expect(TierLevel.tier1.label(en), 'Basic Tier');
      expect(TierLevel.tier2.label(en), 'Standard Tier');
      expect(TierLevel.tier3.label(en), 'Premium Tier');
    });

    test('are translated in Hausa', () {
      for (final t in TierLevel.values) {
        expect(t.label(ha), isNot(t.label(en)));
      }
    });
  });

  group('auth errors follow the chosen language', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      StorageService.resetForTests();
    });

    Future<String?> biometricLoginError(String lang) async {
      SharedPreferences.setMockInitialValues({});
      StorageService.resetForTests();
      await LanguageNotifier().setLanguage(lang);
      final auth = AuthProvider();
      await auth.loginWithBiometrics(); // no saved session → error
      return auth.error;
    }

    test('English', () async {
      expect(await biometricLoginError('en'),
          lookupAppL10n(const Locale('en')).errBioNeedsPassword);
    });

    test('Hausa', () async {
      expect(await biometricLoginError('ha'),
          lookupAppL10n(const Locale('ha')).errBioNeedsPassword);
    });
  });
}

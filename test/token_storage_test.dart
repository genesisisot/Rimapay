import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rimapay/core/providers/auth_provider.dart';
import 'package:rimapay/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    StorageService.resetForTests();
  });

  tearDown(() => StorageService.tokensInSecureStore = false);

  group('mobile: tokens live in the secure store', () {
    setUp(() => StorageService.tokensInSecureStore = true);

    test('saved tokens never touch plain preferences', () async {
      await StorageService.saveTokens(accessToken: 'acc', refreshToken: 'ref');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('rimapay_access_token'), isNull);
      expect(prefs.getString('rimapay_refresh_token'), isNull);
      expect(await StorageService.getAccessToken(), 'acc');
      expect(await StorageService.getRefreshToken(), 'ref');
    });

    test('tokens left in preferences by older builds are moved', () async {
      SharedPreferences.setMockInitialValues({'rimapay_refresh_token': 'old'});
      StorageService.resetForTests();

      expect(await StorageService.getRefreshToken(), 'old');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('rimapay_refresh_token'), isNull);
      expect(await StorageService.getRefreshToken(), 'old');
    });

    test('clearTokens wipes the secure copies', () async {
      await StorageService.saveTokens(accessToken: 'acc', refreshToken: 'ref');
      await StorageService.clearTokens();
      expect(await StorageService.getAccessToken(), isNull);
      expect(await StorageService.getRefreshToken(), isNull);
    });
  });

  group('logout', () {
    setUp(() => StorageService.tokensInSecureStore = false);

    test('wipes the session when biometric login is off', () async {
      await StorageService.saveTokens(accessToken: 'acc', refreshToken: 'ref');

      await AuthProvider().logout();

      expect(await StorageService.getAccessToken(), isNull);
      expect(await StorageService.getRefreshToken(), isNull);
    });

    test('keeps the refresh token when biometric login is on', () async {
      FlutterSecureStorage.setMockInitialValues(
          {'rimapay_bio_login_enabled': 'true'});
      await StorageService.saveTokens(accessToken: 'acc', refreshToken: 'ref');

      await AuthProvider().logout();

      expect(await StorageService.getRefreshToken(), 'ref');
    });
  });
}

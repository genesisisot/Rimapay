import 'package:flutter_test/flutter_test.dart';
import 'package:rimapay/core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('a transaction PIN left in plain storage by an old build is wiped', () async {
    SharedPreferences.setMockInitialValues({
      'rimapay_pin': '1234',
      'theme_mode': 'light',
    });
    StorageService.resetForTests();

    await StorageService.initialize();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('rimapay_pin'), isFalse);
    expect(prefs.getString('theme_mode'), 'light', reason: 'other settings kept');
  });
}

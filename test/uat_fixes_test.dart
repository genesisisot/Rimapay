import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rimapay/core/providers/auth_provider.dart';
import 'package:rimapay/core/services/storage_service.dart';
import 'package:rimapay/features/bills/data/bills_dtos.dart';
import 'package:shared_preferences/shared_preferences.dart';

User _user(String id) => User(
      id: id,
      email: '$id@example.com',
      firstName: 'Test',
      lastName: id,
      phoneNumber: '08000000000',
      accountType: AccountType.basic,
      tierLevel: TierLevel.tier1,
      isVerified: true,
      bvnVerified: true,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('provider error messages', () {
    test('a colon-separated provider failure becomes a sentence', () {
      expect(
        humanizeProviderMessage(
            '99:Topup Service Failed:But Reversal Successfull:No Issue'),
        'Topup Service Failed. Your money has been reversed (code 99).',
      );
    });

    test('a failure without a reversal keeps the code but not the colons', () {
      expect(
        humanizeProviderMessage('12:Invalid Phone Number'),
        'Invalid Phone Number (code 12).',
      );
    });

    test('an ordinary sentence is left alone', () {
      const msg = 'Insufficient balance. Please fund your account.';
      expect(humanizeProviderMessage(msg), msg);
    });
  });

  group('beneficiaries are per-user', () {
    test("a second user never sees the first user's recipients", () async {
      SharedPreferences.setMockInitialValues({});
      StorageService.resetForTests();

      await StorageService.saveUser(_user('user-a'));
      await StorageService.saveBeneficiaries([
        {'type': 'bank', 'name': 'Ada', 'account': '0010071388'},
      ]);
      expect((await StorageService.getBeneficiaries()).single['name'], 'Ada');

      await StorageService.clearUser();
      await StorageService.saveUser(_user('user-b'));

      expect(await StorageService.getBeneficiaries(), isEmpty);
    });

    test('data saved under the old shared key moves to the signed-in user',
        () async {
      SharedPreferences.setMockInitialValues({
        'rimapay_beneficiaries': jsonEncode([
          {'type': 'bank', 'name': 'Legacy', 'account': '0010071388'},
        ]),
      });
      StorageService.resetForTests();

      await StorageService.saveUser(_user('user-a'));
      expect((await StorageService.getBeneficiaries()).single['name'], 'Legacy');

      // The shared copy is gone, so the next account starts clean.
      await StorageService.clearUser();
      await StorageService.saveUser(_user('user-b'));
      expect(await StorageService.getBeneficiaries(), isEmpty);
    });
  });
}

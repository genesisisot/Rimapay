import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rimapay/core/providers/auth_provider.dart';
import 'package:rimapay/core/providers/transaction_provider.dart';
import 'package:rimapay/core/Utils/brand_names.dart';
import 'package:rimapay/core/services/storage_service.dart';
import 'package:rimapay/features/bills/presentation/widgets/bill_purchase_flow.dart';
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

  group('airtime phone numbers', () {
    test('a number typed in full, with its leading zero, is sent as-is', () {
      expect(localMobileNumber('08137954069'), '08137954069');
    });

    test('a number typed without the zero still gets one', () {
      expect(localMobileNumber('8137954069'), '08137954069');
    });

    test('international form is brought back to local form', () {
      expect(localMobileNumber('2348137954069'), '08137954069');
      expect(localMobileNumber('+234 813 795 4069'), '08137954069');
    });
  });

  group('brand spelling (UAT: "GOTV" misspelt)', () {
    test('biller names get the official GOtv/DStv casing', () {
      expect(fixBrandSpelling('GOTV'), 'GOtv');
      expect(fixBrandSpelling('Gotv Max'), 'GOtv Max');
      expect(fixBrandSpelling('DSTV Compact'), 'DStv Compact');
      expect(fixBrandSpelling('Startimes'), 'Startimes');
    });

    test('biller DTOs and statement labels are corrected', () {
      final b = BillerDto.fromJson({'billerId': 1, 'name': 'GOTV', 'shortName': 'GOTV'});
      expect(b.displayName, 'GOtv');
      expect(prettifyStatementDescription('QTService:GOTV_II'), 'GOtv');
      expect(prettifyStatementDescription('Rev QTService:DSTV'), 'Refund · DStv');
    });
  });
}

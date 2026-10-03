import 'package:flutter_test/flutter_test.dart';
import 'package:rimapay/shared/widgets/bank_logo_assets.dart';

import 'bank_names_fixture.dart';

void main() {
  group('bank logos', () {
    test('matches on institution code', () {
      expect(bankLogoAsset(code: '044'), 'assets/images/banks/044.png');
      expect(bankLogoAsset(code: '58'), 'assets/images/banks/058.png');
      expect(bankLogoAsset(code: '035a'), 'assets/images/banks/035A.png');
    });

    test('GTBank, however it is written', () {
      const gtb = 'assets/images/banks/058.png';
      for (final name in [
        'GTBank',
        'GTBank Plc',
        'GTB',
        'Guaranty Trust Bank',
        'GUARANTY TRUST BANK PLC',
        'Guaranty Trust Bank Plc (GTB)',
        'GTCO',
      ]) {
        expect(bankLogoAsset(name: name), gtb, reason: name);
      }
    });

    test('the other majors, written the short way', () {
      expect(bankLogoAsset(name: 'FirstBank'), 'assets/images/banks/011.png');
      expect(bankLogoAsset(name: 'UBA'), 'assets/images/banks/033.png');
      expect(bankLogoAsset(name: 'Zenith'), 'assets/images/banks/057.png');
      expect(bankLogoAsset(name: 'Access Bank Plc'),
          'assets/images/banks/044.png');
      expect(bankLogoAsset(name: 'Stanbic IBTC'),
          'assets/images/banks/221.png');
      expect(bankLogoAsset(name: 'OPay'), 'assets/images/banks/999992.png');
    });

    test('a code we do not carry still resolves by name', () {
      // NIP codes rather than CBN sort codes, which some endpoints return.
      expect(bankLogoAsset(code: '000013', name: 'GTBank'),
          'assets/images/banks/058.png');
      expect(bankLogoAsset(code: '100004', name: 'Opay'),
          'assets/images/banks/999992.png');
    });

    test('every bank with a bundled mark resolves by name alone', () {
      final missed = <String>[];
      for (final row in bankFixture) {
        if (bankLogoAsset(name: row[0]) == null) missed.add(row[0]);
      }
      expect(missed, isEmpty,
          reason: '${missed.length} of ${bankFixture.length} unresolved');
    });

    test('and by code alone', () {
      final missed = <String>[];
      for (final row in bankFixture) {
        if (bankLogoAsset(code: row[1]) == null) missed.add(row[1]);
      }
      expect(missed, isEmpty);
    });

    test('an unknown bank gets no asset, so the badge shows letters', () {
      expect(bankLogoAsset(code: '', name: 'Zzzqx Holdings'),
          isNull);
      expect(bankLogoAsset(), isNull);
    });
  });
}

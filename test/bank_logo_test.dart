import 'package:flutter_test/flutter_test.dart';
import 'package:rimapay/shared/widgets/bank_logo_assets.dart';

void main() {
  group('bank logos', () {
    test('matches on institution code', () {
      expect(bankLogoAsset(code: '044'), 'assets/images/banks/044.png');
      expect(bankLogoAsset(code: '58'), 'assets/images/banks/058.png');
      expect(bankLogoAsset(code: '035a'), 'assets/images/banks/035A.png');
    });

    test('falls back to the name when the code is one we do not carry', () {
      // The seeded list uses 100004 for OPay and 039 for Stanbic, which are
      // not the codes the marks are filed under.
      expect(bankLogoAsset(code: '100004', name: 'Opay'),
          'assets/images/banks/999992.png');
      expect(bankLogoAsset(code: '039', name: 'Stanbic IBTC'),
          'assets/images/banks/221.png');
    });

    test('names survive the usual decoration', () {
      expect(bankLogoAsset(name: 'Access Bank Plc'),
          'assets/images/banks/044.png');
      expect(bankLogoAsset(name: 'GUARANTY TRUST BANK'),
          'assets/images/banks/058.png');
      expect(bankLogoAsset(name: 'United Bank For Africa'),
          'assets/images/banks/033.png');
      expect(bankLogoAsset(name: 'Zenith Bank'),
          'assets/images/banks/057.png');
      expect(bankLogoAsset(name: 'OPay Digital Services Limited (OPay)'),
          'assets/images/banks/999992.png');
    });

    test('an unknown bank gets no asset, so the badge shows letters', () {
      expect(bankLogoAsset(code: '123456', name: 'Some Tiny MFB'), isNull);
      expect(bankLogoAsset(), isNull);
    });
  });
}

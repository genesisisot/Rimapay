import 'package:flutter_test/flutter_test.dart';
import 'package:rimapay/core/providers/transaction_provider.dart';

// Strings below are exactly what GET /payment/statement returned live.
void main() {
  group('parseStatementDate', () {
    test('reads the US-style operationDate the API sends', () {
      final d = parseStatementDate('9/28/2026 12:00:00 AM')!;
      expect([d.year, d.month, d.day, d.hour], [2026, 9, 28, 0]);
      expect(parseStatementDate('10/2/2026 12:00:00 AM')!.day, 2);
      expect(parseStatementDate('10/2/2026 3:15:07 PM')!.hour, 15);
    });

    test('ISO still works; null/garbage is null (never "now")', () {
      expect(parseStatementDate('2026-10-04T18:46:56Z'), isNotNull);
      expect(parseStatementDate(null), isNull);
      expect(parseStatementDate(''), isNull);
      expect(parseStatementDate('not a date'), isNull);
    });
  });

  group('inferTransactionType for QuickTeller bills', () {
    test('disco purchases are electricity, their refunds are reversals', () {
      expect(inferTransactionType('QTService:AEDC PREPAID_II', false),
          TransactionType.electricity);
      expect(inferTransactionType('QTService:EEDC PREPAID_II', false),
          TransactionType.electricity);
      expect(inferTransactionType('Rev QTService:AEDC PREPAID_II', true),
          TransactionType.reversal);
    });

    test('cable billers are cable; transfers stay transfers', () {
      expect(inferTransactionType('QTService:DSTV', false), TransactionType.cable);
      expect(inferTransactionType('QTService:SHOWMAX', false), TransactionType.cable);
      expect(
          inferTransactionType('TRF:TRF/INTRA/MUSTAPHA FODIO/TO/AYOMIDE EGBAI', true),
          TransactionType.addMoney);
    });

    test('a word merely containing a disco code is not electricity', () {
      expect(inferTransactionType('Transfer rejected', false),
          TransactionType.transfer);
    });
  });

  group('prettifyStatementDescription', () {
    test('bill payments and refunds', () {
      expect(prettifyStatementDescription('QTService:AEDC PREPAID_II'),
          'AEDC Prepaid');
      expect(prettifyStatementDescription('Rev QTService:EEDC PREPAID_II', isCredit: true),
          'Refund · EEDC Prepaid');
    });

    test('intra transfers show the other party', () {
      const desc = 'TRF:TRF/INTRA/Al-Amin Abdul/TO/AYOMIDE EGBAIY';
      expect(prettifyStatementDescription(desc, isCredit: true), 'From Al-Amin Abdul');
      expect(prettifyStatementDescription(desc), 'To AYOMIDE EGBAIY');
    });
  });
}

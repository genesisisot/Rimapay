import 'package:flutter_test/flutter_test.dart';
import 'package:rimapay/core/providers/transaction_provider.dart';

void main() {
  group('the rows from the tester screenshot', () {
    test('a topup is airtime, not a money transfer', () {
      expect(inferTransactionType('Topup:2347062746869', false),
          TransactionType.airtime);
    });

    test('a reversal is a reversal, not "Add Money"', () {
      // It arrives as a credit, which is exactly why it used to be mislabelled.
      expect(inferTransactionType('Rev Topup:2347062746869', true),
          TransactionType.reversal);
    });

    test('a reversal counts as money coming in', () {
      final tx = Transaction(
        id: '1',
        type: TransactionType.reversal,
        amount: 50,
        recipient: '07062746869',
        status: TransactionStatus.success,
        timestamp: DateTime(2026, 9, 29),
        reference: 'r1',
      );
      expect(tx.isIncoming, isTrue);
      expect(tx.typeDisplayName, 'Reversal');
    });
  });

  group('categories', () {
    test('bills are recognised from their own wording', () {
      expect(inferTransactionType('MTN DATA BUNDLE', false),
          TransactionType.data);
      expect(inferTransactionType('IKEDC power purchase', false),
          TransactionType.electricity);
      expect(inferTransactionType('GOTV subscription', false),
          TransactionType.cable);
      expect(inferTransactionType('WAEC scratch card', false),
          TransactionType.education);
    });

    test('an unrecognised description falls back on the direction', () {
      expect(inferTransactionType('NXG00001426', false),
          TransactionType.transfer);
      expect(inferTransactionType('NXG00001426', true),
          TransactionType.addMoney);
    });

    test('a reversal wins over the topup it mentions', () {
      expect(inferTransactionType('REVERSAL OF TOPUP', true),
          TransactionType.reversal);
    });
  });

  group('the subtitle shown under a row', () {
    test('a topup shows the phone number in local form', () {
      expect(prettifyStatementDescription('Topup:2347062746869'),
          '07062746869');
      expect(prettifyStatementDescription('Rev Topup:2347062746869'),
          '07062746869');
    });

    test('an already-local number is left alone', () {
      expect(prettifyStatementDescription('Topup:07062746869'),
          '07062746869');
    });

    test('anything else is passed through untouched', () {
      expect(prettifyStatementDescription('Transfer to IKECHUKWU'),
          'Transfer to IKECHUKWU');
    });
  });
}

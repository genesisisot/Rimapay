import 'package:flutter_test/flutter_test.dart';
import 'package:rimapay/core/providers/transaction_provider.dart';

Transaction _tx({
  required double amount,
  required DateTime at,
  TransactionType type = TransactionType.transfer,
  String reference = '',
  bool timeKnown = true,
}) =>
    Transaction(
      id: '${type.name}_${amount}_${at.toIso8601String()}_$reference',
      type: type,
      amount: amount,
      recipient: 'x',
      status: TransactionStatus.success,
      timestamp: at,
      reference: reference,
      timeKnown: timeKnown,
    );

void main() {
  final today = DateTime(2026, 10, 9, 10, 55);
  final oct2 = DateTime(2026, 10, 2); // stale statement business date

  test('an older same-amount bill row does not swallow a new transfer', () {
    // The live case: ₦1,000 transfer today vs ₦1,000 AEDC rows dated 2 Oct.
    final local = [_tx(amount: 1000, at: today, reference: 'WEH5KKIA8')];
    final statement = [
      _tx(amount: 1000, at: oct2, type: TransactionType.electricity, timeKnown: false),
      _tx(amount: 1000, at: oct2, type: TransactionType.reversal, timeKnown: false),
    ];
    expect(unsettledLocalTransactions(local, statement), hasLength(1));
  });

  test('a statement transfer row dated before the local one is not it', () {
    final local = [_tx(amount: 500, at: today)];
    final statement = [_tx(amount: 500, at: oct2, timeKnown: false)];
    expect(unsettledLocalTransactions(local, statement), hasLength(1));
  });

  test('settles once the statement shows it (same day, or by reference)', () {
    final local = [_tx(amount: 500, at: today, reference: 'WE1')];
    final sameDay = [_tx(amount: 500, at: DateTime(2026, 10, 9), timeKnown: false)];
    expect(unsettledLocalTransactions(local, sameDay), isEmpty);

    final byRef = [_tx(amount: 999, at: oct2, reference: 'WE1')];
    expect(unsettledLocalTransactions(local, byRef), isEmpty);
  });

  test('one statement row settles only one of two equal transfers', () {
    final local = [
      _tx(amount: 200, at: today),
      _tx(amount: 200, at: today.add(const Duration(minutes: 3))),
    ];
    final statement = [_tx(amount: 200, at: DateTime(2026, 10, 9), timeKnown: false)];
    expect(unsettledLocalTransactions(local, statement), hasLength(1));
  });
}

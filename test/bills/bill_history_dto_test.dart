import 'package:flutter_test/flutter_test.dart';
import 'package:rimapay/features/bills/data/bills_dtos.dart';

void main() {
  BillPaymentHistoryDto row(Map<String, dynamic> extra) =>
      BillPaymentHistoryDto.fromJson({'id': '1', 'billerId': 7, ...extra});

  test('extracts a 20-digit token from responseDesc and groups it', () {
    final r = row({'responseDesc': 'Successful. Token: 1234 5678 9012 3456 7890 Units: 45.3kWh'});
    expect(r.token, '1234-5678-9012-3456-7890');
    expect(r.units, '45.3 kWh');
  });

  test('never mistakes a numeric gateway reference for a token', () {
    final r = row({'responseDesc': 'Approved', 'gatewayTransactionRef': '12345678901234567890'});
    expect(r.token, isNull);
  });

  test('prefers the labelled token over other long numbers', () {
    final r = row({'responseDesc': 'Ref 99998888777766665555. Token: 1111-2222-3333-4444-5555'});
    expect(r.token, '1111-2222-3333-4444-5555');
  });

  test('no token for short numbers like a meter or response code', () {
    final r = row({'responseDesc': '00: Approved for meter 45012345678'});
    expect(r.token, isNull);
  });

  test('status flags', () {
    expect(row({'isReversed': true}).isFailed, isTrue);
    expect(row({'status': 'Failed'}).isFailed, isTrue);
    expect(row({'status': 'Pending'}).isPending, isTrue);
    expect(row({'itemName': 'IKEDC Postpaid'}).isPostpaid, isTrue);
  });
}

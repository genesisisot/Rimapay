import 'package:flutter_test/flutter_test.dart';
import 'package:rimapay/features/bills/data/bills_dtos.dart';
import 'package:rimapay/features/bills/presentation/widgets/bill_purchase_flow.dart';

void main() {
  test('airtime history row maps onto the shared history row', () {
    final r = BillPaymentHistoryDto.fromAirtimeJson({
      'transactionReference': 'AIR-1',
      'serviceProvider': 'MTN',
      'mobileNo': '08031234567',
      'amount': 500,
      'status': 'Successful',
      'isReversed': false,
      'transactionDate': '2026-10-09T10:15:00Z',
    });
    expect(r.id, 'AIR-1');
    expect(r.billerName, 'MTN');
    expect(r.customerId, '08031234567');
    expect(r.amount, 500);
    expect(r.utilityType, 'Airtime');
    expect(r.createdAt, isNotNull);
  });

  test('data history row uses the plan name, else the allowance', () {
    final withPlan = BillPaymentHistoryDto.fromDataJson({
      'id': 'd1',
      'networkProvider': 'AIRTEL',
      'planName': '1GB Monthly',
      'dataAllowance': '1GB',
      'mobileNo': '08021234567',
      'amount': 1000,
      'createdAt': '2026-10-09T10:15:00Z',
    });
    expect(withPlan.itemName, '1GB Monthly');
    expect(withPlan.utilityType, 'Data');

    final noPlan = BillPaymentHistoryDto.fromDataJson(
        {'id': 'd2', 'planName': ' ', 'dataAllowance': '2GB'});
    expect(noPlan.itemName, '2GB');
  });

  test('network rows resolve the bundled network logos', () {
    expect(billerAssetFor(const BillerDto(billerId: 0, name: 'MTN')),
        'assets/images/Mtn.png');
    expect(billerAssetFor(const BillerDto(billerId: 0, name: 'Glo')),
        'assets/images/Glo.png');
    expect(billerAssetFor(const BillerDto(billerId: 0, name: '9mobile')),
        'assets/images/9mobile.png');
  });
}

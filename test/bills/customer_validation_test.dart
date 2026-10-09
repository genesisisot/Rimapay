import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rimapay/features/bills/data/bills_api_service.dart';
import 'package:rimapay/features/bills/data/bills_dtos.dart';
import 'package:rimapay/features/bills/presentation/widgets/customer_validation.dart';

/// Answers every request with [status] and [body].
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.status, this.body);
  final int status;
  final Object? body;
  Map<String, dynamic>? lastJson;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
      Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    lastJson = options.data as Map<String, dynamic>?;
    return ResponseBody.fromString(jsonEncode(body), status, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

BillsApiService _api(_FakeAdapter adapter) =>
    BillsApiService(dio: Dio(BaseOptions(baseUrl: 'https://x'))..httpClientAdapter = adapter);

const _req = ValidateCustomerRequest(
    customerId: '45012345678', billerItemId: '9', paymentCode: '0488051528');

void main() {
  // The validator fires a haptic on success, which needs the binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('validateCustomer', () {
    test('verified with the customer name', () async {
      final adapter = _FakeAdapter(200, {
        'isSuccess': true,
        'data': {'customerId': '45012345678', 'fullName': ' ADA OBI ', 'amount': 4200.5},
      });
      final r = await _api(adapter).validateCustomer(_req);
      expect(r.outcome, CustomerValidationOutcome.verified);
      expect(r.customer!.fullName, 'ADA OBI');
      expect(r.customer!.amount, 4200.5);
      expect(adapter.lastJson, {
        'customerId': '45012345678',
        'billerItemId': '9',
        'paymentCode': '0488051528',
      });
    });

    test('404 / 400 / isSuccess:false are invalid', () async {
      for (final status in [404, 400]) {
        final r = await _api(_FakeAdapter(status, {'isSuccess': false, 'message': 'Invalid customer'}))
            .validateCustomer(_req);
        expect(r.outcome, CustomerValidationOutcome.invalid, reason: '$status');
      }
      final r = await _api(_FakeAdapter(200, {'isSuccess': false, 'message': 'No match'}))
          .validateCustomer(_req);
      expect(r.outcome, CustomerValidationOutcome.invalid);
    });

    test('success without a name is not treated as verified', () async {
      final r = await _api(_FakeAdapter(200, {'isSuccess': true, 'data': {'fullName': ''}}))
          .validateCustomer(_req);
      expect(r.outcome, CustomerValidationOutcome.invalid);
    });

    test('5xx is unavailable (retry), never invalid', () async {
      final r = await _api(_FakeAdapter(500, {'isSuccess': false})).validateCustomer(_req);
      expect(r.outcome, CustomerValidationOutcome.unavailable);
    });
  });

  group('CustomerValidator', () {
    test('debounces and drops a reply for an edited number', () async {
      final calls = <String>[];
      final pending = <String, Completer<CustomerValidationResult>>{};
      final v = CustomerValidator((req) {
        calls.add(req.customerId);
        return (pending[req.customerId] = Completer()).future;
      }, debounce: const Duration(milliseconds: 20));

      v.check(const ValidateCustomerRequest(customerId: '1111111111'));
      v.check(const ValidateCustomerRequest(customerId: '11111111112'));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(calls, ['11111111112'], reason: 'only the last input is sent');

      // User edits again while the first request is in flight.
      v.check(const ValidateCustomerRequest(customerId: '22222222222'));
      pending['11111111112']!.complete(CustomerValidationResult.verified(
          const ValidateCustomerDto(fullName: 'WRONG PERSON')));
      await Future<void>.delayed(Duration.zero);
      expect(v.isVerified, isFalse, reason: 'stale reply must be ignored');
      expect(v.phase, ValidationPhase.checking);

      await Future<void>.delayed(const Duration(milliseconds: 40));
      pending['22222222222']!.complete(CustomerValidationResult.verified(
          const ValidateCustomerDto(fullName: 'RIGHT PERSON')));
      await Future<void>.delayed(Duration.zero);
      expect(v.customerName, 'RIGHT PERSON');
      v.dispose();
    });

    test('reset clears a verified result; retry re-sends', () async {
      var n = 0;
      final v = CustomerValidator((_) async {
        n++;
        return CustomerValidationResult.unavailable('down');
      }, debounce: Duration.zero);
      v.check(const ValidateCustomerRequest(customerId: '45012345678'));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(v.phase, ValidationPhase.unavailable);
      v.retry();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(n, 2);
      v.reset();
      expect(v.phase, ValidationPhase.idle);
      v.dispose();
    });
  });
}

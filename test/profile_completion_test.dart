import 'package:flutter_test/flutter_test.dart';
import 'package:rimapay/features/profile/data/profile_dtos.dart';

void main() {
  // Live response of POST profile/completion/pep (2026-10-09): 200 with the
  // status DTO itself, no isSuccess envelope.
  final statusBody = <String, dynamic>{
    'identityUserId': '01a0ce11-4b3b-75e1-b9e2-8a9b8fc0c541',
    'residentialAddressProvided': true,
    'isPepDeclared': false,
    'sourceOfIncomeProvided': false,
  };

  test('a 200 with the status DTO (no envelope) is a success', () {
    expect(CompletionResponse.fromHttp(200, statusBody).isSuccess, isTrue);
  });

  test('an explicit envelope still decides', () {
    expect(
        CompletionResponse.fromHttp(
                200, {'isSuccess': false, 'errorMessage': 'nope'})
            .isSuccess,
        isFalse);
  });

  test('a non-2xx without an envelope is a failure', () {
    final r = CompletionResponse.fromHttp(400, {'title': 'Validation failed'});
    expect(r.isSuccess, isFalse);
    expect(r.errorMessage, 'Validation failed');
  });

  test('answering "No" to PEP still counts as answered', () {
    final s = ProfileCompletionStatusDto.fromJson(statusBody);
    expect(s.isPepDeclared, isFalse);
    expect(s.isPepDeclared != null, isTrue);
  });
}

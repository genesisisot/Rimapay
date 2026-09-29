import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rimapay/l10n/generated/app_localizations.g.dart';
import 'package:rimapay/shared/receipt/receipt_pdf.dart';

/// Writes a sample receipt to build/receipt-preview.pdf so the design can be
/// eyeballed without running the app.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('render a sample receipt', () async {
    final l10n = await AppL10n.delegate.load(const Locale('en'));
    final bytes = await buildReceiptPdf(
      l10n: l10n,
      const ReceiptPdfData(
        title: 'Money Transfer',
        amount: '40000',
        reference: '090267260922175324427058881255',
        dateText: '22 Sep 2026, 6:53 PM',
        status: 'Successful',
        details: [
          ReceiptRow('Beneficiary Details', 'Benedict Chibueze Aniume',
              sub: 'Opay Digital Services  |  8138097759'),
          ReceiptRow('Sender Details', 'Ayomide Egbaiyelo',
              sub: 'Rima MFB  |  0555023383'),
          ReceiptRow('Transfer Fee', '₦10.00'),
          ReceiptRow('Description', 'Rent'),
          ReceiptRow('Payment Type', 'Outward Transfer'),
        ],
      ),
    );
    final out = File('build/receipt-preview.pdf');
    out.parent.createSync(recursive: true);
    out.writeAsBytesSync(bytes);
    expect(bytes.lengthInBytes, greaterThan(1000));
  });
}

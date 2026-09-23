import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/localization/l10n.dart';
/// Formats any amount string as naira, e.g. `"5000"`, `"5,000"` or
/// `"₦5000.00"` → `"₦5,000.00"`. Unparseable input is returned with a ₦ prefix.
String formatNaira(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
  final value = double.tryParse(cleaned);
  if (value == null) return raw.startsWith('₦') ? raw : '₦$raw';
  return '₦${NumberFormat('#,##0.00').format(value)}';
}

/// Everything shown on a RimaPay transaction receipt.
class ReceiptPdfData {
  final String title;
  final String amount;
  final String status;
  final String reference;
  final String dateText;

  /// True when money came IN (credit); false for money going out (debit).
  final bool isCredit;

  /// Label/value rows shown in the details block, in order.
  final List<MapEntry<String, String>> details;

  const ReceiptPdfData({
    required this.title,
    required this.amount,
    required this.reference,
    required this.dateText,
    this.status = 'Successful',
    this.details = const [],
    this.isCredit = false,
  });
}

const _green = PdfColor.fromInt(0xFF166C46);
const _greenDark = PdfColor.fromInt(0xFF0B4F2F);
const _grey = PdfColor.fromInt(0xFF6B7280);
const _line = PdfColor.fromInt(0xFFE5E7EB);
const _soft = PdfColor.fromInt(0xFFF6F8F7);
const _debit = PdfColor.fromInt(0xFFB45309);

PdfColor _statusColor(String status) {
  final s = status.toLowerCase();
  if (s.contains('fail') || s.contains('revers')) return const PdfColor.fromInt(0xFFD33B31);
  if (s.contains('pend') || s.contains('process')) return const PdfColor.fromInt(0xFFD97706);
  return _green;
}

/// Very light version of [c] (88% white) for badge backgrounds.
PdfColor _tint(PdfColor c) => PdfColor(
      c.red + (1 - c.red) * 0.88,
      c.green + (1 - c.green) * 0.88,
      c.blue + (1 - c.blue) * 0.88,
    );

/// Builds a branded, single-page receipt. The page grows to fit its content.
// The PDF is rendered outside the widget tree, so the active translations
// are passed in rather than read from a BuildContext.
Future<Uint8List> buildReceiptPdf(ReceiptPdfData r,
    {required AppL10n l10n}) async {
  // Inter, not PlusJakartaSans: the PDF package embeds this font directly and
  // does not use Flutter's fontFamilyFallback, so the file itself must cover
  // the Hausa hooked letters (ƙ ɗ ɓ) as well as ₦. PlusJakartaSans has ₦ but
  // none of the hooked letters, which rendered Hausa receipts as tofu.
  final regular =
      pw.Font.ttf(await rootBundle.load('assets/fonts/Inter/Inter-Regular.ttf'));
  final bold =
      pw.Font.ttf(await rootBundle.load('assets/fonts/Inter/Inter-Bold.ttf'));
  pw.MemoryImage? logo;
  try {
    logo = pw.MemoryImage(
        (await rootBundle.load('assets/images/RimaMFBLogo.png')).buffer.asUint8List());
  } catch (_) {
    logo = null;
  }

  final statusColor = _statusColor(r.status);
  final doc = pw.Document(title: 'RimaPay Receipt ${r.reference}', author: 'RimaPay');

  pw.Widget row(String label, String value, {bool emphasize = false}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 80,
              child: pw.Text(label, style: pw.TextStyle(font: regular, fontSize: 8.5, color: _grey)),
            ),
            pw.Expanded(
              child: pw.Text(
                value.isEmpty ? '—' : value,
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  font: bold,
                  fontSize: emphasize ? 9.5 : 8.5,
                  color: PdfColors.black,
                ),
              ),
            ),
          ],
        ),
      );

  doc.addPage(
    pw.Page(
      pageFormat: const PdfPageFormat(105 * PdfPageFormat.mm, double.infinity, marginAll: 0),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // ── Header band ──
          pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: const pw.BoxDecoration(
              gradient: pw.LinearGradient(colors: [_greenDark, _green]),
            ),
            child: pw.Row(
              children: [
                if (logo != null)
                  pw.Container(
                    width: 34,
                    height: 34,
                    padding: const pw.EdgeInsets.all(3),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.white,
                      shape: pw.BoxShape.circle,
                    ),
                    child: pw.Image(logo, fit: pw.BoxFit.contain),
                  ),
                if (logo != null) pw.SizedBox(width: 10),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('RimaPay',
                        style: pw.TextStyle(font: bold, fontSize: 14, color: PdfColors.white)),
                    pw.Text(l10n.transactionReceipt,
                        style: pw.TextStyle(font: regular, fontSize: 8.5, color: PdfColors.white)),
                  ],
                ),
              ],
            ),
          ),

          // ── Amount + status ──
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(18, 20, 18, 6),
            child: pw.Column(
              children: [
                pw.Text(r.title,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(font: regular, fontSize: 9, color: _grey)),
                pw.SizedBox(height: 4),
                pw.Text('${r.isCredit ? '+' : '-'}${formatNaira(r.amount)}',
                    style: pw.TextStyle(
                        font: bold,
                        fontSize: 22,
                        color: r.isCredit ? _green : _debit)),
                pw.SizedBox(height: 6),
                pw.Text(r.isCredit ? 'Money In' : 'Money Out',
                    style: pw.TextStyle(
                        font: bold,
                        fontSize: 9,
                        color: r.isCredit ? _green : _debit)),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: _tint(statusColor),
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: statusColor, width: 0.6),
                  ),
                  child: pw.Text(r.status,
                      style: pw.TextStyle(font: bold, fontSize: 8, color: statusColor)),
                ),
              ],
            ),
          ),

          // ── Details ──
          pw.Container(
            margin: const pw.EdgeInsets.fromLTRB(14, 12, 14, 0),
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: _soft,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: _line, width: 0.6),
            ),
            child: pw.Column(
              children: [
                for (final d in r.details) row(d.key, d.value),
                pw.Divider(color: _line, thickness: 0.6, height: 10),
                row('Transaction ID', r.reference, emphasize: true),
                row('Date', r.dateText),
              ],
            ),
          ),

          // ── Footer ──
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(18, 16, 18, 20),
            child: pw.Column(
              children: [
                pw.Text(l10n.thankYouForBankingWithRima,
                    style: pw.TextStyle(font: bold, fontSize: 8.5, color: _green)),
                pw.SizedBox(height: 3),
                pw.Text(
                  l10n.receiptGeneratedNote,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: regular, fontSize: 7, color: _grey),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  return doc.save();
}

/// Builds the receipt and hands it to the OS: share sheet on Android/iOS
/// (Save to Files/Downloads, WhatsApp, email…), a file download on web.
Future<void> shareReceiptPdf(ReceiptPdfData r,
    {required AppL10n l10n}) async {
  final bytes = await buildReceiptPdf(r, l10n: l10n);
  final safeRef = r.reference.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
  final name = safeRef.isEmpty ? '${DateTime.now().millisecondsSinceEpoch}' : safeRef;
  await Printing.sharePdf(bytes: bytes, filename: 'RimaPay-Receipt-$name.pdf');
}

import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/localization/l10n.dart';
import 'save_file.dart';

/// Formats any amount string as naira, e.g. `"5000"`, `"5,000"` or
/// `"₦5000.00"` → `"₦5,000.00"`. Unparseable input is returned with a ₦ prefix.
String formatNaira(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'[^0-9.]'), '');
  final value = double.tryParse(cleaned);
  if (value == null) return raw.startsWith('₦') ? raw : '₦$raw';
  return '₦${NumberFormat('#,##0.00').format(value)}';
}

/// One line of the details card: a label on the left, a value on the right and
/// an optional second line under the value — the bank and account number under
/// a beneficiary's name, for instance.
class ReceiptRow {
  final String label;
  final String value;
  final String? sub;

  const ReceiptRow(this.label, this.value, {this.sub});
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

  /// Label/value rows shown in the details card, in order.
  final List<ReceiptRow> details;

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
const _greenDeep = PdfColor.fromInt(0xFF0B4F2F);
const _goldLight = PdfColor.fromInt(0xFFE8C84A);
const _cream = PdfColor.fromInt(0xFFFAF8F3);
const _ink = PdfColor.fromInt(0xFF1A1A1A);
const _grey = PdfColor.fromInt(0xFF8A8A8A);
const _line = PdfColor.fromInt(0xFFE7E3DA);

/// Status colours sit on the dark header, so they are the light variants.
PdfColor _statusColor(String status) {
  final s = status.toLowerCase();
  if (s.contains('fail')) return const PdfColor.fromInt(0xFFFF8A80);
  if (s.contains('revers')) return const PdfColor.fromInt(0xFFFFCC80);
  if (s.contains('pend') || s.contains('process')) {
    return const PdfColor.fromInt(0xFFFFD54F);
  }
  return _goldLight;
}

/// Builds a branded, single-page receipt. The page grows to fit its content.
// The PDF is rendered outside the widget tree, so the active translations
// are passed in rather than read from a BuildContext.
Future<Uint8List> buildReceiptPdf(ReceiptPdfData r,
    {required AppL10n l10n}) async {
  // PlusJakartaSans is the brand face and has a properly fitted naira sign —
  // Inter draws its crossbars wider than the N, which reads as a strikethrough
  // on a large amount. Inter is kept as a fallback because it covers the Hausa
  // hooked letters (ƙ ɗ ɓ) that PlusJakartaSans lacks; without it a Hausa
  // receipt renders those as tofu.
  final jakartaRegular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/PlusJakartaSans-Regular.ttf'));
  final jakartaBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/PlusJakartaSans-Bold.ttf'));
  final jakartaExtraBold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/PlusJakartaSans-ExtraBold.ttf'));
  final interRegular =
      pw.Font.ttf(await rootBundle.load('assets/fonts/Inter/Inter-Regular.ttf'));
  final interBold =
      pw.Font.ttf(await rootBundle.load('assets/fonts/Inter/Inter-Bold.ttf'));

  final regular = jakartaRegular;
  final bold = jakartaBold;
  final fallbackRegular = [interRegular];
  final fallbackBold = [interBold];

  pw.MemoryImage? logo;
  try {
    // mild.png is the app's own logo and is transparent, so it sits directly
    // on the green without a plate behind it.
    logo = pw.MemoryImage(
        (await rootBundle.load('assets/images/mild.png')).buffer.asUint8List());
  } catch (_) {
    logo = null;
  }

  final statusColor = _statusColor(r.status);
  final doc =
      pw.Document(title: 'RimaPay Receipt ${r.reference}', author: 'RimaPay');

  /// A details row: label left, value right, optional quieter line beneath.
  pw.Widget detailRow(ReceiptRow d, {required bool last}) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 9),
        decoration: last
            ? null
            : const pw.BoxDecoration(
                border: pw.Border(
                    bottom: pw.BorderSide(color: _line, width: 0.6)),
              ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 4,
              child: pw.Text(d.label,
                  style: pw.TextStyle(
                      font: regular,
                      fontFallback: fallbackRegular,
                      fontSize: 8.5,
                      color: _grey)),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              flex: 6,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    d.value.isEmpty ? '—' : d.value,
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      font: bold,
                      fontFallback: fallbackBold,
                      fontSize: d.value.length > 26
                          ? 7.5
                          : (d.value.length > 20 ? 8.5 : 9.5),
                      color: _ink,
                    ),
                  ),
                  if ((d.sub ?? '').isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      d.sub!,
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                          font: regular,
                          fontFallback: fallbackRegular,
                          fontSize: 8,
                          color: _grey),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  doc.addPage(
    pw.Page(
      pageFormat: const PdfPageFormat(
          105 * PdfPageFormat.mm, double.infinity,
          marginAll: 0),
      build: (context) => pw.Container(
        color: _greenDeep,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // ── Logo, on the same centred axis as the amount ──
            if (logo != null)
              pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(16, 26, 16, 0),
                // The parent column stretches its children, so the image needs
                // centring explicitly.
                child: pw.Center(
                  child: pw.SizedBox(
                    height: 78,
                    child: pw.Image(logo, fit: pw.BoxFit.contain),
                  ),
                ),
              ),

            // ── Amount ──
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(16, 18, 16, 4),
              child: pw.Column(
                children: [
                  pw.Text(
                    l10n.transactionAmount.toUpperCase(),
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 8,
                      color: PdfColors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    // Hair space: the naira bar overshoots the N in this face,
                    // and without it the mark runs into the first digit.
                    formatNaira(r.amount).replaceFirst('₦', '₦ '),
                    style: pw.TextStyle(
                        font: jakartaExtraBold,
                        fontSize: 29,
                        color: PdfColors.white),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 5,
                        height: 5,
                        decoration: pw.BoxDecoration(
                            color: statusColor, shape: pw.BoxShape.circle),
                      ),
                      pw.SizedBox(width: 5),
                      pw.Text(
                        '${r.status} · ${r.isCredit ? l10n.moneyIn : l10n.moneyOut}',
                        style: pw.TextStyle(
                            font: bold, fontSize: 8.5, color: statusColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Details card ──
            pw.Container(
              margin: const pw.EdgeInsets.fromLTRB(12, 16, 12, 0),
              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: pw.BoxDecoration(
                color: _cream,
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Column(
                children: [
                  for (final d in r.details) detailRow(d, last: false),
                  detailRow(ReceiptRow(l10n.transactionReference, r.reference),
                      last: false),
                  detailRow(ReceiptRow(l10n.date, r.dateText), last: true),
                ],
              ),
            ),

            // ── App prompt ──
            pw.Container(
              margin: const pw.EdgeInsets.fromLTRB(12, 14, 12, 0),
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: pw.BoxDecoration(
                color: _green,
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                children: [
                  if (logo != null) ...[
                    pw.SizedBox(
                      width: 22,
                      height: 22,
                      child: pw.Image(logo, fit: pw.BoxFit.contain),
                    ),
                    pw.SizedBox(width: 9),
                  ],
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(l10n.thankYouForBankingWithRima,
                            style: pw.TextStyle(
                                font: bold,
                                fontFallback: fallbackBold,
                                fontSize: 8.5,
                                color: PdfColors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Legal footer ──
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: pw.Text(
                l10n.receiptGeneratedNote,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  font: regular,
                  fontFallback: fallbackRegular,
                  fontSize: 6.5,
                  color: PdfColor(1, 1, 1, 0.55),
                  lineSpacing: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  return doc.save();
}

/// Builds the receipt and hands it to the OS: share sheet on Android/iOS
/// (Save to Files/Downloads, WhatsApp, email…), a file download on web.
Future<void> shareReceiptPdf(ReceiptPdfData r, {required AppL10n l10n}) async {
  final bytes = await buildReceiptPdf(r, l10n: l10n);
  await Printing.sharePdf(
      bytes: bytes, filename: 'RimaPay-Receipt-${_fileStem(r)}.pdf');
}

/// The same receipt as a PNG (for WhatsApp, the gallery…): the PDF page is
/// rasterised, so the image always matches the PDF exactly.
Future<void> shareReceiptImage(ReceiptPdfData r, {required AppL10n l10n}) async {
  final pdf = await buildReceiptPdf(r, l10n: l10n);
  final page = await Printing.raster(pdf, pages: const [0], dpi: 200).first;
  final png = await page.toPng();
  await saveOrShareFile(
    png,
    fileName: 'RimaPay-Receipt-${_fileStem(r)}.png',
    mimeType: 'image/png',
  );
}

String _fileStem(ReceiptPdfData r) {
  final safeRef = r.reference.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '');
  return safeRef.isEmpty ? '${DateTime.now().millisecondsSinceEpoch}' : safeRef;
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/Utils/haptics.dart';
import '../../../../shared/widgets/bill_screen_widgets.dart';
import '../../../success/presentation/screens/success_screen.dart';
import '../../data/bills_dtos.dart';

/// Formats a naira amount without the symbol, e.g. `2500.0` → `2,500`.
String formatBillAmount(double amount) => NumberFormat(
        amount == amount.roundToDouble() ? '#,##0' : '#,##0.00')
    .format(amount);

/// Local 11-digit form (`0XXXXXXXXXX`) of a 10-digit number typed after `+234`.
String localMobileNumber(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('234') && digits.length == 13) return '0${digits.substring(3)}';
  if (digits.length == 10) return '0$digits';
  return digits;
}

const _knownBillerAssets = <String, String>{
  'AEDC': 'assets/images/AEDC.png',
  'ABUJA': 'assets/images/AEDC.png',
  'EKEDC': 'assets/images/EKEDC.jpg',
  'EKO': 'assets/images/EKEDC.jpg',
  'IKEDC': 'assets/images/IKEDC.jpg',
  'IKEJA': 'assets/images/IKEDC.jpg',
  'PHED': 'assets/images/PHED.png',
  'PORT HARCOURT': 'assets/images/PHED.png',
  'KEDCO': 'assets/images/KEDCO.png',
  'KANO': 'assets/images/KEDCO.png',
  'JEDC': 'assets/images/JEDC.png',
  'JOS ': 'assets/images/JEDC.png',
  'DSTV': 'assets/images/Dstv.jpeg',
  'GOTV': 'assets/images/Gotv.jpeg',
  'STARTIMES': 'assets/images/Startimes.jpeg',
  'SHOWMAX': 'assets/images/Showmax.png',
};

/// Bundled brand asset for a biller, matched on its short/full name.
String? billerAssetFor(BillerDto biller) {
  final haystack = ' ${biller.shortName ?? ''} ${biller.name ?? ''} '.toUpperCase();
  for (final e in _knownBillerAssets.entries) {
    if (haystack.contains(e.key)) return e.value;
  }
  return null;
}

/// Bundled asset first, then the biller's remote logo, else null (show initials).
ImageProvider? billerImage({String? asset, String? url}) {
  if (asset != null && asset.isNotEmpty) return AssetImage(asset);
  if (url != null && url.startsWith('http')) return NetworkImage(url);
  return null;
}

/// Up to two initials for a biller avatar without a logo.
String billerInitials(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  return words.take(2).map((w) => w[0].toUpperCase()).join();
}

/// Shared confirm → PIN → API → success/error flow for every bill screen.
///
/// Mirrors the wired transfer flow: PIN sheet, blocking loader, source account
/// from [AuthProvider], balance refresh on success, red snackbar on failure.
void runBillPurchase({
  required BuildContext context,
  required List<Map<String, String>> summary,
  required Future<BillPurchaseResult> Function(String pin, String sourceAccount) submit,
  required SuccessScreenProps Function(BillPurchaseResult result) successProps,
}) {
  showPinConfirmSheet(
    context: context,
    summary: summary,
    onConfirmed: (pin) async {
      Navigator.pop(context); // close the PIN sheet

      final auth = context.read<AuthProvider>();
      final sourceAccount = auth.user?.accountNumber ?? '';
      if (sourceAccount.isEmpty) {
        showBillError(context, 'No account found. Please log in again.');
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF166C46)),
        ),
      );

      final result = await submit(pin, sourceAccount);

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // dismiss loader

      if (!result.isSuccess) {
        Haptics.error();
        showBillError(context, result.message);
        return;
      }
      Haptics.success();

      try {
        await auth.fetchAccounts(silent: true);
      } catch (_) {
        // Balance refresh is best-effort; the payment already succeeded.
      }
      if (!context.mounted) return;
      context.pushReplacement('/success', extra: successProps(result));
    },
  );
}

void showBillError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFFD33B31),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
  );
}

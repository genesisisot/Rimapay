import 'package:flutter/material.dart';

import '../../core/providers/transaction_provider.dart';

/// Glyph and accent per kind of transaction, shared by Home's recent list,
/// History, the receipt and the PIN screen so a type looks the same
/// everywhere (Material icons, not emoji — emoji render differently per
/// platform and make Flutter web download an emoji font).
(IconData, Color) transactionVisual(TransactionType type) {
  switch (type) {
    case TransactionType.addMoney:
      return (Icons.south_west_rounded, const Color(0xFF16A34A));
    case TransactionType.reversal:
      return (Icons.replay_rounded, const Color(0xFF0D9488));
    case TransactionType.transfer:
      return (Icons.north_east_rounded, const Color(0xFF2563EB));
    case TransactionType.electricity:
      return (Icons.bolt_rounded, const Color(0xFFD97706));
    case TransactionType.cable:
      return (Icons.live_tv_rounded, const Color(0xFF7C3AED));
    case TransactionType.airtime:
      return (Icons.phone_android_rounded, const Color(0xFF16A34A));
    case TransactionType.data:
      return (Icons.wifi_rounded, const Color(0xFF0284C7));
    case TransactionType.education:
      return (Icons.school_rounded, const Color(0xFF4F46E5));
    case TransactionType.government:
      return (Icons.account_balance_rounded, const Color(0xFF475569));
    case TransactionType.transport:
      return (Icons.directions_bus_rounded, const Color(0xFFEA580C));
    case TransactionType.betting:
      return (Icons.casino_rounded, const Color(0xFFDB2777));
    case TransactionType.loan:
      return (Icons.request_quote_rounded, const Color(0xFFCA8A04));
  }
}

/// Same, for screens that only have a free-text type ("Airtime", "Transfer").
(IconData, Color) transactionVisualForLabel(String label) {
  final t = label.toLowerCase();
  if (t.contains('airtime')) return transactionVisual(TransactionType.airtime);
  if (t.contains('data')) return transactionVisual(TransactionType.data);
  if (t.contains('cable')) return transactionVisual(TransactionType.cable);
  if (t.contains('electric')) {
    return transactionVisual(TransactionType.electricity);
  }
  if (t.contains('education')) {
    return transactionVisual(TransactionType.education);
  }
  if (t.contains('betting')) return transactionVisual(TransactionType.betting);
  if (t.contains('transport')) {
    return transactionVisual(TransactionType.transport);
  }
  if (t.contains('flight')) {
    return (Icons.flight_rounded, const Color(0xFF0284C7));
  }
  if (t.contains('government')) {
    return transactionVisual(TransactionType.government);
  }
  if (t.contains('transfer')) return transactionVisual(TransactionType.transfer);
  return (Icons.payments_rounded, const Color(0xFF166C46));
}

/// Accent lifted toward white on dark surfaces so glyphs keep contrast.
Color transactionGlyphColor(BuildContext context, Color accent) =>
    Theme.of(context).brightness == Brightness.dark
        ? Color.lerp(accent, Colors.white, 0.35)!
        : accent;

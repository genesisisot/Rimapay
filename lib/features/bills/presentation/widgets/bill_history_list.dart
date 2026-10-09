import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/Utils/haptics.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/bills_dtos.dart';
import '../providers/bills_providers.dart';
import 'bill_purchase_flow.dart';
import '../../../../core/theme/app_theme_colors.dart';

final _money = NumberFormat('#,##0.00');

String _naira(double v) => '₦${_money.format(v)}';

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// "Today", "Yesterday" or "Mon, 6 Oct 2026".
String _dayLabel(BuildContext context, DateTime d) {
  final now = DateTime.now();
  if (_sameDay(d, now)) return context.l10n.today;
  if (_sameDay(d, now.subtract(const Duration(days: 1)))) {
    return context.l10n.yesterday;
  }
  return DateFormat('EEE, d MMM yyyy').format(d);
}

String _when(BuildContext context, DateTime? d) {
  if (d == null) return '';
  return '${_dayLabel(context, d)}, ${DateFormat('h:mm a').format(d)}';
}

/// Per-kind wording and behaviour for the shared history UI.
extension _KindUi on BillHistoryKind {
  bool get hasTokens => this == BillHistoryKind.electricity;

  BillCategoryKind get category => this == BillHistoryKind.electricity
      ? BillCategoryKind.electricity
      : BillCategoryKind.cable;

  String customerLabel(BuildContext context) =>
      this == BillHistoryKind.electricity
          ? context.l10n.meterNumber
          : context.l10n.smartCardNumber;

  String itemLabel(BuildContext context) => this == BillHistoryKind.electricity
      ? context.l10n.meterType
      : context.l10n.package;

  String searchHint(BuildContext context) => this == BillHistoryKind.electricity
      ? context.l10n.searchMeterOrReference
      : context.l10n.searchSmartcardOrReference;

  String repeatLabel(BuildContext context) =>
      this == BillHistoryKind.electricity
          ? context.l10n.buyAgain
          : context.l10n.renew;

  IconData get icon => this == BillHistoryKind.electricity
      ? Icons.bolt_rounded
      : Icons.live_tv_rounded;
}

/// Biller for a history row: the live biller when we have it, else a stand-in
/// built from the name on the row (still resolves the bundled logo).
BillerDto _billerFor(
    WidgetRef ref, BillHistoryKind kind, BillPaymentHistoryDto row) {
  final billers =
      ref.watch(billersByKindProvider(kind.category)).valueOrNull?.billers ??
          const <BillerDto>[];
  for (final b in billers) {
    if (b.billerId == row.billerId) return b;
  }
  return BillerDto(
    billerId: row.billerId,
    name: row.billerName ?? row.categoryName ?? '',
  );
}

void _copy(BuildContext context, String text, String message) {
  Clipboard.setData(ClipboardData(text: text));
  Haptics.success();
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.primary500,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
}

// ── History tab ───────────────────────────────────────────────────────────────

/// History tab for a bill screen: past payments grouped by day, searchable,
/// with details, copy/share (and meter tokens for electricity) and a one-tap
/// repeat ("Buy again" / "Renew").
class BillHistoryList extends ConsumerStatefulWidget {
  final BillHistoryKind kind;

  /// Prefill the Buy tab from a past payment.
  final void Function(BillPaymentHistoryDto row) onRepeat;

  /// Jump to the Buy tab (empty state CTA).
  final VoidCallback onBuyNew;

  /// Hide the built-in search when the host screen has its own; pass its text
  /// as [query] instead.
  final bool showSearch;
  final String query;

  const BillHistoryList({
    super.key,
    required this.kind,
    required this.onRepeat,
    required this.onBuyNew,
    this.showSearch = true,
    this.query = '',
  });

  @override
  ConsumerState<BillHistoryList> createState() => _BillHistoryListState();
}

class _BillHistoryListState extends ConsumerState<BillHistoryList> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) {
        ref.read(billHistoryProvider(widget.kind).notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  bool _matches(BillPaymentHistoryDto r) {
    final query = widget.showSearch ? _query : widget.query.trim();
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    final digits = q.replaceAll(RegExp(r'\D'), '');
    return [r.customerId, r.transactionReference, r.billerName, r.itemName]
            .any((f) => (f ?? '').toLowerCase().contains(q)) ||
        (digits.length >= 4 &&
            (r.token ?? '').replaceAll('-', '').contains(digits));
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final state = ref.watch(billHistoryProvider(kind));
    final notifier = ref.read(billHistoryProvider(kind).notifier);

    if (state.isInitialLoad) return const _HistorySkeleton();

    if (state.items.isEmpty && state.error != null) {
      return _CenteredMessage(
        icon: Icons.cloud_off_rounded,
        iconColor: AppColors.error,
        title: context.l10n.couldNotLoadHistory,
        message: state.error!,
        actionLabel: context.l10n.retry,
        onAction: notifier.refresh,
      );
    }

    if (state.items.isEmpty) {
      final electricity = kind == BillHistoryKind.electricity;
      return RefreshIndicator(
        color: AppColors.primary500,
        onRefresh: notifier.refresh,
        child: LayoutBuilder(
          builder: (context, c) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: c.maxHeight,
              child: _CenteredMessage(
                icon: kind.icon,
                iconColor: AppColors.goldPrimary,
                title: electricity
                    ? context.l10n.noElectricityPurchasesYet
                    : context.l10n.noCablePurchasesYet,
                message: electricity
                    ? context.l10n.electricityHistoryEmptyHint
                    : context.l10n.cableHistoryEmptyHint,
                actionLabel: electricity
                    ? context.l10n.buyElectricity
                    : context.l10n.payCableTv,
                onAction: widget.onBuyNew,
              ),
            ),
          ),
        ),
      );
    }

    final visible = state.items.where(_matches).toList();

    // Flatten into day headers + rows.
    final entries = <Object>[];
    String? lastDay;
    for (final r in visible) {
      final day = r.createdAt == null ? '' : _dayLabel(context, r.createdAt!);
      if (day != lastDay) {
        entries.add(day);
        lastDay = day;
      }
      entries.add(r);
    }

    return RefreshIndicator(
      color: AppColors.primary500,
      onRefresh: notifier.refresh,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, MediaQuery.of(context).padding.bottom + 24),
        itemCount: entries.length + 2,
        itemBuilder: (context, i) {
          if (i == 0) {
            if (!widget.showSearch) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _SearchField(
                controller: _search,
                hint: kind.searchHint(context),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            );
          }
          if (i == entries.length + 1) {
            return _ListFooter(
              state: state,
              noMatches: visible.isEmpty,
              onRetry: notifier.loadMore,
            );
          }
          final e = entries[i - 1];
          if (e is String) return _DayHeader(label: e);
          final row = e as BillPaymentHistoryDto;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _HistoryCard(
              kind: kind,
              row: row,
              onTap: () => showBillPaymentSheet(
                context,
                kind: kind,
                row: row,
                onRepeat: widget.onRepeat,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withOpacity(0.45);
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(Icons.search_rounded, size: 20, color: muted),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(fontSize: 14, color: muted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: true,
                fillColor: Colors.transparent,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, v, __) => v.text.isEmpty
                ? const SizedBox(width: 14)
                : IconButton(
                    icon: Icon(Icons.close_rounded, size: 18, color: muted),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String label;
  const _DayHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox(height: 12);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  final BillHistoryState state;
  final bool noMatches;
  final VoidCallback onRetry;

  const _ListFooter({
    required this.state,
    required this.noMatches,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2.4, color: AppColors.primary500),
          ),
        ),
      );
    }
    if (state.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(context.l10n.retry),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary500),
          ),
        ),
      );
    }
    final text = noMatches
        ? context.l10n.noMatchingPurchases
        : (!state.hasMore ? context.l10n.endOfHistory : null);
    if (text == null) return const SizedBox(height: 24);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: noMatches ? 40 : 16),
      child: Center(
        child: Text(text, style: TextStyle(fontSize: 12, color: muted)),
      ),
    );
  }
}

// ── Row card ──────────────────────────────────────────────────────────────────

class _HistoryCard extends ConsumerWidget {
  final BillHistoryKind kind;
  final BillPaymentHistoryDto row;
  final VoidCallback onTap;

  const _HistoryCard(
      {required this.kind, required this.row, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biller = _billerFor(ref, kind, row);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final token = kind.hasTokens ? row.token : null;
    final item = row.itemName ??
        (kind.hasTokens
            ? (row.isPostpaid ? context.l10n.postpaid : context.l10n.prepaid)
            : '');

    Widget? footer;
    if (row.isFailed) {
      footer = _InfoStrip(
        icon: Icons.undo_rounded,
        color: AppColors.error,
        text: row.reversalDescription?.trim().isNotEmpty == true
            ? humanizeProviderMessage(row.reversalDescription!.trim())
            : context.l10n.reversed,
      );
    } else if (kind.hasTokens) {
      if (token != null) {
        footer = TokenBox(token: token, compact: true);
      } else if (row.isPostpaid) {
        footer = _InfoStrip(
          icon: Icons.receipt_long_rounded,
          color: AppColors.primary500,
          text: context.l10n.postpaidNoToken,
        );
      } else if (!row.isPending) {
        footer = _InfoStrip(
          icon: Icons.info_outline_rounded,
          color: onSurface.withOpacity(0.55),
          text: context.l10n.tokenUnavailable,
        );
      }
    }

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Haptics.tap();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _BillerAvatar(biller: biller, kind: kind, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          biller.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: onSurface),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [row.customerId ?? '—', if (item.isNotEmpty) item]
                              .join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12, color: onSurface.withOpacity(0.55)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _naira(row.amount),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: row.isFailed
                              ? onSurface.withOpacity(0.45)
                              : onSurface,
                          decoration:
                              row.isFailed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (row.isFailed || row.isPending)
                        _StatusChip(row: row)
                      else
                        Text(
                          row.createdAt == null
                              ? ''
                              : DateFormat('h:mm a').format(row.createdAt!),
                          style: TextStyle(
                              fontSize: 11, color: onSurface.withOpacity(0.5)),
                        ),
                    ],
                  ),
                ],
              ),
              if (footer != null) ...[
                const SizedBox(height: 12),
                footer,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BillerAvatar extends StatelessWidget {
  final BillerDto biller;
  final BillHistoryKind kind;
  final double size;

  const _BillerAvatar({
    required this.biller,
    required this.kind,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final image =
        billerImage(asset: billerAssetFor(biller), url: biller.logoUrl);
    final initials = billerInitials(biller.displayName);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.goldPrimary.withOpacity(0.12),
        image: image == null
            ? null
            : DecorationImage(
                image: image, fit: BoxFit.cover, onError: (_, __) {}),
      ),
      child: image != null
          ? null
          : Center(
              child: initials.isEmpty
                  ? Icon(kind.icon,
                      size: size * 0.5, color: AppColors.goldPrimary)
                  : Text(
                      initials,
                      style: TextStyle(
                        fontSize: size * 0.32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.goldPrimary,
                      ),
                    ),
            ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final BillPaymentHistoryDto row;
  const _StatusChip({required this.row});

  @override
  Widget build(BuildContext context) {
    final (label, color) = row.isFailed
        ? (context.l10n.reversed, AppColors.error)
        : row.isPending
            ? (context.l10n.pending, AppColors.warning)
            : (context.l10n.successful, AppColors.primary500);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _InfoStrip(
      {required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Token box ─────────────────────────────────────────────────────────────────

/// The meter token in large, spaced digits with a one-tap Copy that confirms
/// itself (icon flips to a tick). Tapping anywhere on the box also copies.
class TokenBox extends StatefulWidget {
  final String token;

  /// Smaller type for list rows; the details sheet uses the full size.
  final bool compact;

  const TokenBox({super.key, required this.token, this.compact = false});

  @override
  State<TokenBox> createState() => _TokenBoxState();
}

class _TokenBoxState extends State<TokenBox> {
  bool _copied = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  void _copyToken() {
    _copy(context, widget.token.replaceAll('-', ''), context.l10n.tokenCopied);
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _copyToken,
      child: Container(
        width: double.infinity,
        padding:
            EdgeInsets.fromLTRB(14, compact ? 10 : 14, 10, compact ? 10 : 14),
        decoration: BoxDecoration(
          color: AppColors.goldPrimary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.goldPrimary.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.electricityToken.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: AppColors.goldPrimary,
                    ),
                  ),
                  SizedBox(height: compact ? 3 : 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.token.replaceAll('-', ' '),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: compact ? 16 : 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _copied ? AppColors.primary500 : AppColors.goldPrimary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _copied ? Icons.check_rounded : Icons.copy_rounded,
                      key: ValueKey(_copied),
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _copied ? context.l10n.copied : context.l10n.copy,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Details sheet ─────────────────────────────────────────────────────────────

void showBillPaymentSheet(
  BuildContext context, {
  required BillHistoryKind kind,
  required BillPaymentHistoryDto row,
  required void Function(BillPaymentHistoryDto row) onRepeat,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _PaymentSheet(
      kind: kind,
      row: row,
      onRepeat: () {
        Navigator.pop(sheetContext);
        onRepeat(row);
      },
    ),
  );
}

class _PaymentSheet extends ConsumerWidget {
  final BillHistoryKind kind;
  final BillPaymentHistoryDto row;
  final VoidCallback onRepeat;

  const _PaymentSheet({
    required this.kind,
    required this.row,
    required this.onRepeat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biller = _billerFor(ref, kind, row);
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final token = kind.hasTokens ? row.token : null;
    final reference = row.transactionReference;

    final details = <(String, String, bool)>[
      (context.l10n.provider, biller.name ?? biller.displayName, false),
      if (row.customerId?.isNotEmpty == true)
        (kind.customerLabel(context), row.customerId!, true),
      if (row.itemName?.isNotEmpty == true)
        (kind.itemLabel(context), row.itemName!, false),
      if (kind.hasTokens && row.units != null)
        (context.l10n.units, row.units!, false),
      if (row.createdAt != null)
        (context.l10n.dateAndTime, _when(context, row.createdAt), false),
      if (reference?.isNotEmpty == true)
        (context.l10n.reference, reference!, true),
    ];

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _BillerAvatar(biller: biller, kind: kind, size: 52),
            const SizedBox(height: 10),
            Text(
              biller.displayName,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 4),
            Text(
              _naira(row.amount),
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w800, color: onSurface),
            ),
            const SizedBox(height: 8),
            _StatusChip(row: row),
            const SizedBox(height: 20),
            if (row.isFailed)
              _InfoStrip(
                icon: Icons.undo_rounded,
                color: AppColors.error,
                text: row.reversalDescription?.trim().isNotEmpty == true
                    ? humanizeProviderMessage(row.reversalDescription!.trim())
                    : context.l10n.reversed,
              )
            else if (token != null) ...[
              TokenBox(token: token),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Haptics.press();
                    Share.share(
                      '${biller.displayName} token for meter '
                      '${row.customerId ?? ''}: ${token.replaceAll('-', ' ')}'
                      '${row.units != null ? ' (${row.units})' : ''}',
                    );
                  },
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: Text(context.l10n.share),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary500,
                    side: BorderSide(color: Theme.of(context).dividerColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ] else if (kind.hasTokens && row.isPostpaid)
              _InfoStrip(
                icon: Icons.receipt_long_rounded,
                color: AppColors.primary500,
                text: context.l10n.postpaidNoToken,
              )
            else if (kind.hasTokens && !row.isPending)
              _InfoStrip(
                icon: Icons.info_outline_rounded,
                color: onSurface.withOpacity(0.55),
                text: context.l10n.tokenUnavailable,
              ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < details.length; i++) ...[
                    if (i > 0)
                      Divider(height: 1, color: Theme.of(context).dividerColor),
                    _DetailRow(
                      label: details[i].$1,
                      value: details[i].$2,
                      copyable: details[i].$3,
                    ),
                  ],
                ],
              ),
            ),
            if (row.billerId != 0 && row.customerId?.isNotEmpty == true) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Haptics.press();
                  onRepeat();
                },
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        kind.hasTokens
                            ? Icons.bolt_rounded
                            : Icons.autorenew_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        kind.repeatLabel(context),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;

  const _DetailRow({
    required this.label,
    required this.value,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: copyable
          ? () => _copy(context, value, context.l10n.labelCopied(label))
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13, color: onSurface.withOpacity(0.55))),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: onSurface),
              ),
            ),
            if (copyable) ...[
              const SizedBox(width: 8),
              const Icon(Icons.copy_rounded,
                  size: 15, color: AppColors.goldPrimary),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Loading / empty / error ───────────────────────────────────────────────────

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return Shimmer.fromColors(
      baseColor: dark ? Colors.white10 : const Color(0xFFEDEFF1),
      highlightColor: dark ? Colors.white24 : context.adapt(const Color(0xFFF8F9FA), const Color(0xFF1A1F2E)),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => i == 0
            ? bar(double.infinity, 48)
            : Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              bar(110, 12),
                              const SizedBox(height: 6),
                              bar(160, 10),
                            ],
                          ),
                        ),
                        bar(64, 14),
                      ],
                    ),
                    const SizedBox(height: 12),
                    bar(double.infinity, 52),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _CenteredMessage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: iconColor),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: onSurface.withOpacity(0.6)),
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () {
                Haptics.press();
                onAction();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                decoration: BoxDecoration(
                  gradient: AppColors.goldGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── "Your last token" card (Electricity Buy tab) ──────────────────────────────

/// Shortcut on the Electricity Buy tab to the most recent token, so the common
/// "what was my token again?" trip doesn't need the History tab at all.
/// Hidden until there is one.
class LastTokenCard extends ConsumerWidget {
  final VoidCallback onSeeAll;
  final void Function(BillPaymentHistoryDto row) onBuyAgain;

  const LastTokenCard({
    super.key,
    required this.onSeeAll,
    required this.onBuyAgain,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items =
        ref.watch(billHistoryProvider(BillHistoryKind.electricity)).items;
    BillPaymentHistoryDto? last;
    for (final r in items) {
      if (!r.isFailed && r.token != null) {
        last = r;
        break;
      }
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: last == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _body(context, ref, last),
            ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, BillPaymentHistoryDto row) {
    const kind = BillHistoryKind.electricity;
    final biller = _billerFor(ref, kind, row);
    final muted = Theme.of(context).colorScheme.onSurface.withOpacity(0.55);
    return GestureDetector(
      onTap: () => showBillPaymentSheet(context,
          kind: kind, row: row, onRepeat: onBuyAgain),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _BillerAvatar(biller: biller, kind: kind, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.lastToken,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${row.customerId ?? biller.displayName} · ${_when(context, row.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: muted),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Haptics.tap();
                    onSeeAll();
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 0, 4),
                    child: Row(
                      children: [
                        Text(
                          context.l10n.seeAll,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.goldPrimary,
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            size: 18, color: AppColors.goldPrimary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TokenBox(token: row.token!, compact: true),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../services/storage_service.dart';
import '../Utils/brand_names.dart';
import '../../features/profile/data/accounts_api_service.dart';
import '../../features/profile/data/profile_api_service.dart';
import '../../features/profile/data/profile_dtos.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';

enum TransactionType {
  airtime,
  data,
  /// Money returned after a purchase failed upstream — a credit, but not the
  /// user adding funds, so it is counted and labelled separately.
  reversal,
  electricity,
  cable,
  transfer,
  addMoney,
  loan,
  education,
  betting,
  transport,
  government,
}

enum TransactionStatus { pending, success, failed }

class Transaction {
  final String id;
  final TransactionType type;
  final double amount;
  final String recipient;
  final String? description;
  final TransactionStatus status;
  final DateTime timestamp;
  final String? network;
  final String? plan;
  final String? provider;
  final String? accountNumber;
  final String? bank;
  final double? fee;
  final String reference;

  /// False when the source only gave a date (the bank statement has no time
  /// of day), so screens must not print a clock time for it.
  final bool timeKnown;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.recipient,
    this.description,
    required this.status,
    required this.timestamp,
    this.network,
    this.plan,
    this.provider,
    this.accountNumber,
    this.bank,
    this.fee,
    required this.reference,
    this.timeKnown = true,
  });

  /// The statement row had no parseable date at all.
  bool get dateUnknown => timestamp.year <= 1970;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'amount': amount,
        'recipient': recipient,
        'description': description,
        'status': status.index,
        'timestamp': timestamp.toIso8601String(),
        'network': network,
        'plan': plan,
        'provider': provider,
        'accountNumber': accountNumber,
        'bank': bank,
        'fee': fee,
        'reference': reference,
        'timeKnown': timeKnown,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        type: TransactionType.values[json['type'] as int],
        amount: (json['amount'] as num).toDouble(),
        recipient: json['recipient'] as String,
        description: json['description'] as String?,
        status: TransactionStatus.values[json['status'] as int],
        timestamp: DateTime.parse(json['timestamp'] as String),
        network: json['network'] as String?,
        plan: json['plan'] as String?,
        provider: json['provider'] as String?,
        accountNumber: json['accountNumber'] as String?,
        bank: json['bank'] as String?,
        fee: (json['fee'] as num?)?.toDouble(),
        reference: json['reference'] as String,
        timeKnown: json['timeKnown'] as bool? ?? true,
      );

  /// Money coming in: funds added, or a purchase refunded after it failed.
  /// Anything else leaves the account.
  bool get isIncoming =>
      type == TransactionType.addMoney || type == TransactionType.reversal;

  String get formattedAmount => '₦${amount.toStringAsFixed(2)}';
  String get formattedFee => fee != null ? '₦${fee!.toStringAsFixed(2)}' : '₦0.00';

  String get typeDisplayName {
    switch (type) {
      case TransactionType.airtime:
        return 'Airtime Purchase';
      case TransactionType.reversal:
        return 'Reversal';
      case TransactionType.data:
        return 'Data Purchase';
      case TransactionType.electricity:
        return 'Electricity Bill';
      case TransactionType.cable:
        return 'Cable TV';
      case TransactionType.transfer:
        return 'Money Transfer';
      case TransactionType.addMoney:
        return 'Add Money';
      case TransactionType.loan:
        return 'Loan Service';
      case TransactionType.education:
        return 'Education Bill';
      case TransactionType.betting:
        return 'Betting/Lottery';
      case TransactionType.transport:
        return 'Transport';
      case TransactionType.government:
        return 'Government Service';
    }
  }

  String get statusIcon {
    switch (status) {
      case TransactionStatus.success:
        return '✅';
      case TransactionStatus.pending:
        return '⏳';
      case TransactionStatus.failed:
        return '❌';
    }
  }

  Color get statusColor {
    switch (status) {
      case TransactionStatus.success:
        return const Color(0xFF166C46);
      case TransactionStatus.pending:
        return const Color(0xFFEAB308);
      case TransactionStatus.failed:
        return const Color(0xFFD33B31);
    }
  }
}

@immutable
class TransactionState {
  final List<Transaction> transactions;
  final bool isLoading;
  final String? error;

  /// Today's totals as computed by the statement API, when it sent them.
  final double? todaysSpending;
  final double? todaysIncome;

  const TransactionState({
    required this.transactions,
    required this.isLoading,
    this.error,
    this.todaysSpending,
    this.todaysIncome,
  });

  TransactionState copyWith({
    List<Transaction>? transactions,
    bool? isLoading,
    String? error,
    double? todaysSpending,
    double? todaysIncome,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      todaysSpending: todaysSpending ?? this.todaysSpending,
      todaysIncome: todaysIncome ?? this.todaysIncome,
    );
  }
}

/// The statement API gives only a free-text description and a credit/debit
/// flag, so the category has to be inferred. Real descriptions look like
/// `Topup:2347062746869` and `Rev Topup:2347062746869`, which match none of
/// the obvious words — hence the explicit shapes below. Order matters: a
/// reversal is checked before a top-up, since it contains both.
TransactionType inferTransactionType(String description, bool isCredit) {
  final d = description.toLowerCase();

  if (d.contains('revers') || d.startsWith('rev ') || d.startsWith('rev:')) {
    return TransactionType.reversal;
  }
  if (d.contains('airtime') || d.contains('topup') || d.contains('top up') ||
      d.contains('vtu')) {
    return TransactionType.airtime;
  }
  if (d.contains('data') || d.contains('bundle')) return TransactionType.data;
  // QuickTeller bill payments arrive as `QTService:AEDC PREPAID_II`.
  if (d.contains('electric') || d.contains('power') || d.contains('disco') ||
      _discoPattern.hasMatch(d)) {
    return TransactionType.electricity;
  }
  if (d.contains('cable') || d.contains('tv') || d.contains('gotv') ||
      d.contains('dstv') || d.contains('startimes') || d.contains('showmax')) {
    return TransactionType.cable;
  }
  if (d.contains('prepaid') || d.contains('postpaid')) {
    return TransactionType.electricity;
  }
  if (d.contains('school') || d.contains('educat') || d.contains('waec') ||
      d.contains('jamb')) {
    return TransactionType.education;
  }
  if (d.contains('transport')) return TransactionType.transport;
  if (d.contains('govern') || d.contains('tax') || d.contains('remita')) {
    return TransactionType.government;
  }

  // Nothing matched: fall back on the direction of the money.
  return isCredit ? TransactionType.addMoney : TransactionType.transfer;
}

final _discoPattern = RegExp(
    r'\b(aedc|ekedc|ikedc|eedc|ibedc|phed|jed|kaedco|kedco|bedc|yedc)\b');

/// Statement descriptions are the bank's wording, not something to show a
/// customer:
/// - `Topup:2347062746869` → `07062746869`
/// - `QTService:AEDC PREPAID_II` → `AEDC Prepaid` (refunds: `Refund · AEDC Prepaid`)
/// - `TRF:TRF/INTRA/Al-Amin Abdul/TO/AYOMIDE` → `From Al-Amin Abdul` / `To AYOMIDE`
String prettifyStatementDescription(String description, {bool isCredit = false}) {
  final text = description.trim();

  final topup = RegExp(r'^(?:rev\s+)?(?:topup|top up|vtu)\s*[:\-]?\s*(\d{10,14})$',
          caseSensitive: false)
      .firstMatch(text);
  if (topup != null) {
    var number = topup.group(1)!;
    if (number.startsWith('234')) number = '0${number.substring(3)}';
    return number;
  }

  final bill = RegExp(r'^(rev\s+)?qtservice\s*:\s*(.+)$', caseSensitive: false)
      .firstMatch(text);
  if (bill != null) {
    final name = bill
        .group(2)!
        .replaceAll(RegExp(r'_[IVX]+$', caseSensitive: false), '')
        .replaceAll('_', ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .map((w) => _isAcronym(w)
            ? w.toUpperCase()
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
    final label = fixBrandSpelling(name);
    return bill.group(1) != null ? 'Refund · $label' : label;
  }

  final trf = RegExp(r'^trf:\s*trf/\w+/(.+?)/to/(.+)$', caseSensitive: false)
      .firstMatch(text);
  if (trf != null) {
    return isCredit ? 'From ${trf.group(1)!.trim()}' : 'To ${trf.group(2)!.trim()}';
  }
  return description;
}

/// Short all-caps words (AEDC, IKEDC) stay upper case; words like PREPAID
/// become Prepaid. Brands such as GOtv/DStv are fixed by [fixBrandSpelling].
bool _isAcronym(String w) =>
    w.length <= 5 && !RegExp(r'^(prepaid|postpaid|power)$', caseSensitive: false).hasMatch(w);

final _statementDateFormats = [
  DateFormat('M/d/yyyy h:mm:ss a', 'en_US'),
  DateFormat('M/d/yyyy H:mm:ss', 'en_US'),
  DateFormat('M/d/yyyy', 'en_US'),
  DateFormat('d-MMM-yyyy', 'en_US'),
];

/// Parses a statement date. The live API sends `tranDate: null` and
/// `operationDate: "9/28/2026 12:00:00 AM"` (US order, date only), which
/// `DateTime.tryParse` can't read. Returns null when nothing parses.
DateTime? parseStatementDate(String? raw) {
  final s = raw?.trim() ?? '';
  if (s.isEmpty) return null;
  final iso = DateTime.tryParse(s);
  if (iso != null) return iso.isUtc ? iso.toLocal() : iso;
  for (final f in _statementDateFormats) {
    try {
      return f.parseStrict(s);
    } catch (_) {}
  }
  return null;
}

/// Local (just-made) entries the statement doesn't show yet.
///
/// A local entry is settled when a statement row has its reference, or when
/// a row moving money the same way, of the same amount and kind, is dated on
/// or after the local entry's day. Each row settles at most one entry.
///
/// This used to match "same amount within 10 minutes", which, while
/// statement rows were wrongly stamped "now", let an old ₦1,000 bill row
/// swallow a brand-new ₦1,000 transfer, deleting it from History. Rows
/// dated before the local entry can't be it, because the statement only lags.
List<Transaction> unsettledLocalTransactions(
  List<Transaction> local,
  List<Transaction> statement,
) {
  final refs =
      statement.map((t) => t.reference).where((r) => r.isNotEmpty).toSet();
  final unmatched = List<Transaction>.of(statement);
  return local.where((p) {
    if (p.reference.isNotEmpty && refs.contains(p.reference)) return false;
    final day = DateTime(p.timestamp.year, p.timestamp.month, p.timestamp.day);
    final idx = unmatched.indexWhere((s) =>
        (s.amount - p.amount).abs() < 0.001 &&
        s.isIncoming == p.isIncoming &&
        s.type == p.type &&
        !s.dateUnknown &&
        !s.timestamp.isBefore(day));
    if (idx == -1) return true;
    unmatched.removeAt(idx);
    return false;
  }).toList();
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  TransactionNotifier(this._api)
      : super(const TransactionState(
          transactions: [],
          isLoading: false,
        ));

  final ProfileApiService _api;

  /// Loads the account statement (transaction history) from the backend.
  ///
  /// The account number is sourced from the stored user — the same value the
  /// transfer flow uses (`auth.user?.accountNumber`). Defaults to the last
  /// 90 days.
  Future<void> fetchTransactions({
    DateTime? startDate,
    DateTime? endDate,
    int pageSize = 50,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Locally-saved optimistic entries (e.g. a transfer just completed) that
      // the backend statement may not have settled yet. Loaded first so they
      // stay visible even if the statement call is empty or fails.
      final pending = await _loadPendingTransactions();

      // Prefer the account number cached on the stored user; if it hasn't been
      // hydrated yet (AuthProvider.fetchAccounts runs asynchronously), fall
      // back to the accounts API — the same source it uses.
      var accountNumber = (await StorageService.getUser())?.accountNumber;
      if (accountNumber == null || accountNumber.isEmpty) {
        final accounts = await AccountsApiService().getAllAccounts();
        if (accounts.isNotEmpty) {
          accountNumber = accounts.first.accountNumber;
        }
      }
      if (accountNumber == null || accountNumber.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          transactions: pending,
          error: pending.isEmpty
              ? 'No account found. Please try again after your account is ready.'
              : null,
        );
        return;
      }

      final end = endDate ?? DateTime.now();
      // Backend advice: statement data is indexed from December 2025, so use
      // that as the default window start rather than a rolling 90 days.
      final start = startDate ?? DateTime(2025, 12, 1);

      final res = await _api.getStatement(
        accountNumber: accountNumber,
        startDate: _fmtDate(start),
        endDate: _fmtDate(end),
        pageSize: pageSize,
      );

      if (res == null) {
        // Keep the optimistic entries visible; only surface an error if there's
        // truly nothing to show.
        state = state.copyWith(
          isLoading: false,
          transactions: pending,
          error: pending.isEmpty
              ? 'Could not load your transactions. Please try again.'
              : null,
        );
        return;
      }

      // Debug: log raw statement rows to diagnose missing credits/rows.
      debugPrint(
          'statement: acct=$accountNumber ${_fmtDate(start)}..${_fmtDate(end)} '
          '→ ${res.statementList.length} rows (totalCount=${res.totalCount}, '
          'responseCode=${res.responseCode}, responseDesc=${res.responseDesc})');
      for (final item in res.statementList.take(20)) {
        debugPrint(
            '  tranType=${item.tranType} amount=${item.tranAmount} date=${item.tranDate} desc=${item.description}');
      }

      final serverTxs = res.statementList.map(_mapStatementItem).toList();
      final stillPending = unsettledLocalTransactions(pending, serverTxs);

      final merged = [...stillPending, ...serverTxs]
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = state.copyWith(
        transactions: merged,
        isLoading: false,
        todaysSpending: res.todaysSpending,
        todaysIncome: res.todaysIncome,
      );

      // Prune storage to only the entries still not reflected server-side, so
      // it self-cleans and can't grow unbounded.
      await StorageService.saveTransactions(
        stillPending.map((t) => t.toJson()).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load transactions.',
      );
    }
  }

  /// Reads optimistic transactions saved locally by [processTransfer] /
  /// [processTransaction], keeping only recent, de-duplicated entries.
  ///
  /// Kept for two weeks: the bank statement has been seen lagging by a week,
  /// and an entry dropped before the statement shows it is simply lost.
  Future<List<Transaction>> _loadPendingTransactions() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 14));
    final seen = <String>{};
    final pending = <Transaction>[];
    try {
      final stored = await StorageService.getTransactions();
      for (final json in stored) {
        try {
          final tx = Transaction.fromJson(json);
          if (tx.timestamp.isBefore(cutoff)) continue;
          if (tx.reference.isNotEmpty && !seen.add(tx.reference)) continue;
          pending.add(tx);
        } catch (_) {}
      }
    } catch (_) {}
    return pending;
  }

  Transaction _mapStatementItem(StatementItem item) {
    final ref = item.entryReference ?? item.batchReference ?? '';
    // Never fall back to "now": that stamped every row "Today, <current time>".
    final parsed = parseStatementDate(item.tranDate) ??
        parseStatementDate(item.operationDate);
    final ts = parsed ?? DateTime(1970);
    final timeKnown = parsed != null &&
        (parsed.hour != 0 || parsed.minute != 0 || parsed.second != 0);
    final desc = (item.description ?? '').trim();
    return Transaction(
      id: ref.isNotEmpty ? ref : 'stmt_${desc.hashCode}_${item.tranAmount}',
      type: inferTransactionType(desc, item.isCredit),
      amount: item.amount,
      timeKnown: timeKnown,
      recipient: desc.isNotEmpty
          ? prettifyStatementDescription(desc, isCredit: item.isCredit)
          : (item.isCredit ? 'Credit' : 'Debit'),
      description: desc.isNotEmpty ? desc : null,
      status: TransactionStatus.success,
      timestamp: ts,
      reference: ref,
      fee: 0,
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// General transaction for airtime, data, bills (mock until dedicated endpoints exist).
  Future<String> processTransaction({
    required TransactionType type,
    required double amount,
    required String recipient,
    String? description,
    String? network,
    String? plan,
    String? provider,
    String? accountNumber,
    String? bank,
    double? fee,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await Future.delayed(const Duration(seconds: 2));

      final tx = Transaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        amount: amount,
        recipient: recipient,
        description: description,
        status: TransactionStatus.success,
        timestamp: DateTime.now(),
        network: network,
        plan: plan,
        provider: provider,
        accountNumber: accountNumber,
        bank: bank,
        fee: fee ?? _calculateFee(amount),
        reference: 'RMP${DateTime.now().millisecondsSinceEpoch}',
      );

      state = state.copyWith(
        transactions: [tx, ...state.transactions],
        isLoading: false,
      );
      unawaited(_rememberLocal(tx));

      return tx.id;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return '';
    }
  }

  Future<String> processTransfer({
    required String senderAccountNumber,
    required String recipientAccountNumber,
    required String recipientBankCode,
    required String recipientBankName,
    required double amount,
    String? narration,
    required String pin,
    String? otpCode,
    String? otpReference,
    bool isRimaPay = true,
    bool isPhoneNumber = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final refNo = 'WE${List.generate(26, (_) => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'[Random().nextInt(36)]).join()}';
      final req = TransferRequest(
        senderAccountNumber: senderAccountNumber,
        recipientAccountNumber: recipientAccountNumber,
        recipientBankCode: recipientBankCode,
        recipientBankName: recipientBankName,
        amount: amount,
        narration: narration,
        transactionReference: refNo,
        pin: pin,
        otpCode: otpCode,
        otpReference: otpReference,
        isPhoneNumber: isPhoneNumber,
      );
      // Never log the payload: it carries the transaction PIN.
      debugPrint('processTransfer ref=$refNo amount=$amount '
          'to=$recipientAccountNumber isPhone=$isPhoneNumber rima=$isRimaPay');
      final res = isRimaPay ? await _api.transfer(req) : await _api.transferInter(req);
      debugPrint('processTransfer response — isSuccess: ${res.isSuccess}, errorMessage: ${res.errorMessage}, errorCode: ${res.errorCode}');

      if (res.isSuccess) {
        final tx = Transaction(
          id: res.transactionReference ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          type: TransactionType.transfer,
          amount: amount,
          recipient: recipientBankName,
          description: narration ?? recipientAccountNumber,
          status: TransactionStatus.success,
          timestamp: DateTime.now(),
          accountNumber: recipientAccountNumber,
          bank: recipientBankName,
          reference: res.transactionReference ?? '',
          fee: 0,
        );

        state = state.copyWith(
          transactions: [tx, ...state.transactions],
          isLoading: false,
        );
        unawaited(_rememberLocal(tx));

        return res.transactionReference ?? '';
      }

      state = state.copyWith(
        isLoading: false,
        error: res.errorMessage ?? 'Transfer failed.',
      );
      return '';
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      return '';
    }
  }

  /// Adds [tx] to the locally saved, not-yet-on-the-statement entries.
  ///
  /// Only local entries are stored: this used to save the whole list, bank
  /// rows included, which then came back as "pending" duplicates.
  Future<void> _rememberLocal(Transaction tx) async {
    final existing = await _loadPendingTransactions();
    await StorageService.saveTransactions(
      [tx, ...existing.where((t) => t.id != tx.id)]
          .map((t) => t.toJson())
          .toList(),
    );
  }

  double _calculateFee(double amount) {
    if (amount <= 1000) return 5.0;
    if (amount <= 5000) return 10.0;
    if (amount <= 10000) return 15.0;
    if (amount <= 50000) return 25.0;
    return 50.0;
  }
}

final transactionProviders =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  final api = ref.watch(profileApiServiceProvider);
  return TransactionNotifier(api);
});

final recentTransactionsProvider = Provider<List<Transaction>>((ref) {
  return ref
      .watch(transactionProviders.select((state) => state.transactions))
      .take(5)
      .toList();
});

final totalSpentTodayProvider = Provider<double>((ref) {
  return ref
      .watch(transactionProviders.select((state) => state.transactions))
      .where((tx) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return tx.timestamp.isAfter(startOfDay) &&
        tx.status == TransactionStatus.success;
  }).fold(0.0, (sum, tx) => sum + tx.amount);
});

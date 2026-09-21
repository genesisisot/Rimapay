import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage_service.dart';
import '../../features/profile/data/accounts_api_service.dart';
import '../../features/profile/data/profile_api_service.dart';
import '../../features/profile/data/profile_dtos.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';

enum TransactionType {
  airtime,
  data,
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
  });

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
      );

  String get formattedAmount => '₦${amount.toStringAsFixed(2)}';
  String get formattedFee => fee != null ? '₦${fee!.toStringAsFixed(2)}' : '₦0.00';

  String get typeDisplayName {
    switch (type) {
      case TransactionType.airtime:
        return 'Airtime Purchase';
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

  const TransactionState({
    required this.transactions,
    required this.isLoading,
    this.error,
  });

  TransactionState copyWith({
    List<Transaction>? transactions,
    bool? isLoading,
    String? error,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
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
      final serverRefs = serverTxs
          .map((t) => t.reference)
          .where((r) => r.isNotEmpty)
          .toSet();

      // Drop any optimistic entry the statement now reflects — matched by
      // reference, or by same amount within a 10-minute window (the statement
      // often assigns its own entry reference). Each server row can absorb at
      // most ONE optimistic entry, otherwise two transfers of the same amount
      // made minutes apart would both be swallowed by a single settled row.
      final unmatchedServer = List<Transaction>.of(serverTxs);
      final stillPending = pending.where((p) {
        if (p.reference.isNotEmpty && serverRefs.contains(p.reference)) {
          return false;
        }
        final idx = unmatchedServer.indexWhere((s) =>
            (s.amount - p.amount).abs() < 0.001 &&
            s.timestamp.difference(p.timestamp).abs() <
                const Duration(minutes: 10));
        if (idx != -1) {
          unmatchedServer.removeAt(idx);
          return false;
        }
        return true;
      }).toList();

      final merged = [...stillPending, ...serverTxs]
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      state = state.copyWith(transactions: merged, isLoading: false);

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
  Future<List<Transaction>> _loadPendingTransactions() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 2));
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
    final ts = DateTime.tryParse(item.tranDate ?? '') ??
        DateTime.tryParse(item.operationDate ?? '') ??
        DateTime.now();
    final desc = (item.description ?? '').trim();
    return Transaction(
      id: ref.isNotEmpty ? ref : 'stmt_${ts.microsecondsSinceEpoch}',
      type: _inferType(desc, item.isCredit),
      amount: item.amount,
      recipient: desc.isNotEmpty ? desc : (item.isCredit ? 'Credit' : 'Debit'),
      description: desc.isNotEmpty ? desc : null,
      status: TransactionStatus.success,
      timestamp: ts,
      reference: ref,
      fee: 0,
    );
  }

  /// The statement API gives only a free-text description + credit/debit flag,
  /// so infer a category for the UI's icon/colour. Credit → incoming money;
  /// otherwise keyword-match the description, falling back to a transfer.
  TransactionType _inferType(String description, bool isCredit) {
    if (isCredit) return TransactionType.addMoney;
    final d = description.toLowerCase();
    if (d.contains('airtime')) return TransactionType.airtime;
    if (d.contains('data')) return TransactionType.data;
    if (d.contains('electric') || d.contains('power')) {
      return TransactionType.electricity;
    }
    if (d.contains('cable') || d.contains('tv')) return TransactionType.cable;
    if (d.contains('school') || d.contains('educat')) {
      return TransactionType.education;
    }
    if (d.contains('transport')) return TransactionType.transport;
    if (d.contains('govern') || d.contains('tax')) {
      return TransactionType.government;
    }
    return TransactionType.transfer;
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
      unawaited(_persist());

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
        unawaited(_persist());

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

  Future<void> _persist() async {
    final jsonList = state.transactions.map((tx) => tx.toJson()).toList();
    await StorageService.saveTransactions(jsonList);
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

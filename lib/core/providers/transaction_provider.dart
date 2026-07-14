import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage_service.dart';
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

  Future<void> fetchTransactions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final stored = await StorageService.getTransactions();
      final txs = stored
          .map((json) => Transaction.fromJson(json))
          .toList();
      state = state.copyWith(
        transactions: txs,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load transactions.',
      );
    }
  }

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
      );
      // Debug: log request payload
      debugPrint('processTransfer request: ${req.toJson()}');
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

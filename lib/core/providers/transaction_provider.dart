import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        return const Color(0xFF00B252);
      case TransactionStatus.pending:
        return const Color(0xFFEAB308);
      case TransactionStatus.failed:
        return const Color(0xFFEF4444);
    }
  }
}

// Immutable state class for the TransactionNotifier
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

  // Helper method to create a new state object with updated values
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

// StateNotifier to manage the transaction state
class TransactionNotifier extends StateNotifier<TransactionState> {
  TransactionNotifier()
      : super(const TransactionState(
          transactions: [],
          isLoading: false,
        )) {
    // Add some mock transactions on initialization
    _addMockTransactions();
  }

  void _addMockTransactions() {
    state = state.copyWith(
      transactions: [
        Transaction(
          id: 'tx_001',
          type: TransactionType.airtime,
          amount: 1000.0,
          recipient: 'MTN Airtime',
          description: '08123456789',
          status: TransactionStatus.success,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          network: 'MTN',
          reference: 'RMP${DateTime.now().millisecondsSinceEpoch}',
          fee: 10.0,
        ),
        Transaction(
          id: 'tx_002',
          type: TransactionType.transfer,
          amount: 25000.0,
          recipient: 'John Smith',
          description: 'Payment for services',
          status: TransactionStatus.success,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          bank: 'Access Bank',
          accountNumber: '1234567890',
          reference: 'RMP${DateTime.now().millisecondsSinceEpoch - 1000}',
          fee: 25.0,
        ),
        Transaction(
          id: 'tx_003',
          type: TransactionType.electricity,
          amount: 5000.0,
          recipient: 'AEDC Prepaid',
          description: 'Meter: 12345678901',
          status: TransactionStatus.success,
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          provider: 'Abuja Electric',
          reference: 'RMP${DateTime.now().millisecondsSinceEpoch - 2000}',
          fee: 15.0,
        ),
        Transaction(
          id: 'tx_004',
          type: TransactionType.data,
          amount: 2000.0,
          recipient: 'Glo Data',
          description: '08098765432',
          status: TransactionStatus.pending,
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          network: 'Globacom',
          plan: '2GB Monthly',
          reference: 'RMP${DateTime.now().millisecondsSinceEpoch - 3000}',
          fee: 5.0,
        ),
        Transaction(
          id: 'tx_005',
          type: TransactionType.cable,
          amount: 3500.0,
          recipient: 'DStv Premium',
          description: 'Smart Card: 1234567890',
          status: TransactionStatus.success,
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          provider: 'MultiChoice',
          reference: 'RMP${DateTime.now().millisecondsSinceEpoch - 4000}',
          fee: 20.0,
        ),
      ],
    );
  }

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
      // Simulate processing delay
      await Future.delayed(const Duration(seconds: 2));
      
      final transaction = Transaction(
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
      
      // Update the state with the new transaction.
      state = state.copyWith(
        transactions: [transaction, ...state.transactions],
        isLoading: false,
      );
      
      return transaction.id;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
      rethrow;
    }
  }
  
  double _calculateFee(double amount) {
    if (amount <= 1000) return 5.0;
    if (amount <= 5000) return 10.0;
    if (amount <= 10000) return 15.0;
    if (amount <= 50000) return 25.0;
    return 50.0;
  }
}

// Provider for the TransactionNotifier
final transactionProviders = StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  return TransactionNotifier();
});

// A derived provider for recent transactions, which only rebuilds when the list changes.
final recentTransactionsProvider = Provider<List<Transaction>>((ref) {
  return ref.watch(transactionProviders.select((state) => state.transactions)).take(5).toList();
});

// A derived provider for today's total spent.
final totalSpentTodayProvider = Provider<double>((ref) {
  return ref.watch(transactionProviders.select((state) => state.transactions)).where((tx) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return tx.timestamp.isAfter(startOfDay) && tx.status == TransactionStatus.success;
  }).fold(0.0, (sum, tx) => sum + tx.amount);
});

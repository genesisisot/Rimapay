import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:rimapay/features/receipt/presentation/screens/receipt_screen.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/transaction_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showFilter = false;
  String _selectedFilter = 'all';

  final List<FilterOption> _filterOptions = [
    FilterOption(id: 'all', label: 'All Transactions', count: 8),
    FilterOption(id: 'income', label: 'Income', count: 1),
    FilterOption(id: 'expense', label: 'Expenses', count: 7),
    FilterOption(id: 'today', label: 'Today', count: 3),
    FilterOption(id: 'yesterday', label: 'Yesterday', count: 5),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    List<Transaction> filtered = transactions;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((tx) => tx.typeDisplayName.toLowerCase().contains(_searchQuery) || tx.recipient.toLowerCase().contains(_searchQuery) || tx.description!.toLowerCase().contains(_searchQuery))
          .toList();
    }

    // Apply category filter
    switch (_selectedFilter) {
      case 'income':
        filtered = filtered.where((tx) => tx.type == TransactionType.addMoney).toList();
        break;
      case 'expense':
        filtered = filtered.where((tx) => tx.type != TransactionType.addMoney).toList();
        break;
      case 'today':
        final today = DateTime.now();
        filtered = filtered.where((tx) => tx.timestamp.year == today.year && tx.timestamp.month == today.month && tx.timestamp.day == today.day).toList();
        break;
      case 'yesterday':
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        filtered = filtered.where((tx) => tx.timestamp.year == yesterday.year && tx.timestamp.month == yesterday.month && tx.timestamp.day == yesterday.day).toList();
        break;
    }

    return filtered;
  }

  void _handleTransactionTap(Transaction transaction) {
    final receiptData = {
      'id': transaction.id,
      'type': transaction.typeDisplayName,
      'amount': transaction.formattedAmount,
      'recipient': transaction.recipient,
      'date': _formatDate(transaction.timestamp),
      'time': _formatTime(transaction.timestamp),
      'status': 'success',
      'reference': transaction.reference ?? 'RMP${DateTime.now().millisecondsSinceEpoch}',
      'description': '${transaction.typeDisplayName} payment',
    };

    final re = ReceiptData.fromJson(receiptData);
    context.push('/receipt', extra: re);
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute';
  }

  double _calculateDayTotal(List<Transaction> transactions) {
    return transactions.fold(0.0, (total, tx) {
      return tx.type == TransactionType.addMoney ? total - tx.amount : total + tx.amount;
    });
  }

  String _formatCurrency(double amount) {
    return '₦${amount.toStringAsFixed(2)}';
  }

  final trans = [
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
  ];
  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(recentTransactionsProvider);
    final filteredTransactions = _getFilteredTransactions(transactions);
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: Stack(
        children: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header
                _buildHeader(),

                // Content
                Expanded(
                  child: filteredTransactions.isEmpty && _searchQuery.isNotEmpty
                      ? _buildNoResultsState()
                      : filteredTransactions.isEmpty
                          ? _buildEmptyState()
                          : _buildTransactionsList(filteredTransactions),
                ),
              ],
            ),
          ),

          // Filter Modal
          if (_showFilter) _buildFilterModal(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF001a0c), Color(0xFF003d1a), Color(0xFF005e27)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.canPop() ? context.pop() : context.go('/home'),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.18)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Transaction History',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search and Filter
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.18)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Effra'),
                        decoration: InputDecoration(
                          hintText: 'Search transactions...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, fontFamily: 'Effra'),
                          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.6), size: 20),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _showFilter = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm + 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_list,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Filter',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Column Headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'TRANSACTIONS',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white.withOpacity(0.55),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(
                      'TIME',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white.withOpacity(0.55),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      'AMOUNT',
                      textAlign: TextAlign.right,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white.withOpacity(0.55),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(List<Transaction> transactions) {
    // Group transactions by date
    final groupedTransactions = <String, List<Transaction>>{};

    for (final transaction in transactions) {
      final date = DateTime(
        transaction.timestamp.year,
        transaction.timestamp.month,
        transaction.timestamp.day,
      );

      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      final yesterday = todayDate.subtract(const Duration(days: 1));

      String dateKey;
      if (date == todayDate) {
        dateKey = 'TODAY';
      } else if (date == yesterday) {
        dateKey = 'YESTERDAY';
      } else {
        dateKey = _formatDate(transaction.timestamp).toUpperCase();
      }

      groupedTransactions.putIfAbsent(dateKey, () => []).add(transaction);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) {
        final dateKey = groupedTransactions.keys.elementAt(index);
        final dayTransactions = groupedTransactions[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            if (index > 0) const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                dateKey,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.neutral400,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // Transactions for this date
            ...dayTransactions.asMap().entries.map((entry) {
              final txIndex = entry.key;
              final transaction = entry.value;

              return AnimatedContainer(
                duration: Duration(milliseconds: 200 + (txIndex * 50)),
                curve: Curves.easeOut,
                child: _buildTransactionItem(transaction),
              );
            }),

            // Day total
            if (dateKey == 'TODAY' || dateKey == 'YESTERDAY')
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Total ',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.neutral500,
                      ),
                    ),
                    Text(
                      _formatCurrency(_calculateDayTotal(dayTransactions)),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.neutral900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  String _formatNumber(double amount) {
    if (amount >= 1000) {
      final parts = amount.toStringAsFixed(2).split('.');
      final whole = parts[0];
      final dec = parts[1];
      final withCommas = whole.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
      return '$withCommas.$dec';
    }
    return amount.toStringAsFixed(2);
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isIncoming = transaction.type == TransactionType.addMoney;
    final isPending = transaction.status == TransactionStatus.pending;

    return GestureDetector(
      onTap: () => _handleTransactionTap(transaction),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _getTransactionBgColor(transaction.type),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: Text(
                  _getTransactionIcon(transaction.type),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          transaction.typeDisplayName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF101828),
                            fontFamily: 'Effra',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${isIncoming ? '+' : '-'}₦${_formatNumber(transaction.amount)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Effra',
                          color: isIncoming
                              ? const Color(0xFF00B252)
                              : const Color(0xFF101828),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          transaction.recipient,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF667085),
                            fontFamily: 'Effra',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(transaction.timestamp),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF98A2B3),
                          fontFamily: 'Effra',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPending
                              ? const Color(0xFFFFF8EC)
                              : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          isPending ? 'Pending' : 'Done',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Effra',
                            color: isPending
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF00B252),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (transaction.plan != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        transaction.plan!,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF7C3AED),
                          fontFamily: 'Effra',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                Icons.search,
                size: 24,
                color: AppColors.neutral400,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No transactions found',
            style: AppTextStyles.heading4.copyWith(
              color: AppColors.neutral900,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Try searching with different keywords',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Center(
              child: Icon(
                Icons.receipt_long_outlined,
                size: 40,
                color: AppColors.neutral400,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No transactions found',
            style: AppTextStyles.heading4.copyWith(
              color: AppColors.neutral600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your transaction history will appear here',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterModal() {
    return Stack(
      children: [
        // Backdrop
        GestureDetector(
          onTap: () => setState(() => _showFilter = false),
          child: Container(
            color: Colors.black.withOpacity(0.5),
          ),
        ),

        // Modal
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Transactions',
                          style: AppTextStyles.heading4.copyWith(
                            color: AppColors.neutral900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _showFilter = false),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.neutral100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.neutral600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Filter options
                    Column(
                      children: _filterOptions.map((option) {
                        final isSelected = _selectedFilter == option.id;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedFilter = option.id;
                              _showFilter = false;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.neutral50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.success500 : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? AppColors.success500 : AppColors.neutral300,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 12,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Text(
                                    option.label,
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.neutral900,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: AppSpacing.xs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.neutral200,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${option.count}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.neutral500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getTransactionBgColor(TransactionType type) {
    switch (type) {
      case TransactionType.airtime:
      case TransactionType.data:
        return const Color(0xFFFFEBEE);
      case TransactionType.electricity:
        return const Color(0xFFFFF3E0);
      case TransactionType.transfer:
        return const Color(0xFFE3F2FD);
      case TransactionType.addMoney:
        return const Color(0xFFE8F5E8);
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  String _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.airtime:
        return '📱';
      case TransactionType.data:
        return '📶';
      case TransactionType.electricity:
        return '⚡';
      case TransactionType.cable:
        return '📺';
      case TransactionType.transfer:
        return '💸';
      case TransactionType.addMoney:
        return '💰';
      case TransactionType.loan:
        return '🏦';
      case TransactionType.education:
        return '🎓';
      case TransactionType.betting:
        return '🎰';
      case TransactionType.transport:
        return '🚌';
      case TransactionType.government:
        return '🏛️';
    }
  }
}

class FilterOption {
  final String id;
  final String label;
  final int count;

  FilterOption({
    required this.id,
    required this.label,
    required this.count,
  });
}

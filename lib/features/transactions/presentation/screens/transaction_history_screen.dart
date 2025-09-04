import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/transaction_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Success', 'Pending', 'Failed'];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    if (_selectedFilter == 'All') return transactions;
    
    final filterStatus = TransactionStatus.values.firstWhere(
      (status) => status.name.toLowerCase() == _selectedFilter.toLowerCase(),
      orElse: () => TransactionStatus.success,
    );
    
    return transactions.where((tx) => tx.status == filterStatus).toList();
  }

  void _handleTransactionTap(Transaction transaction) {
    final receiptData = {
      'id': transaction.id,
      'type': transaction.typeDisplayName,
      'amount': transaction.formattedAmount,
      'recipient': transaction.recipient,
      'date': _formatDate(transaction.timestamp),
      'time': _formatTime(transaction.timestamp),
      'status': transaction.status.name,
      'reference': transaction.reference,
      'network': transaction.network,
      'plan': transaction.plan,
      'provider': transaction.provider,
      'accountNumber': transaction.accountNumber,
      'bank': transaction.bank,
      'description': transaction.description,
      'fee': transaction.formattedFee,
    };
    
    context.push('/receipt', extra: receiptData);
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return _formatDate(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        backgroundColor: AppColors.neutral0,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios),
          color: AppColors.neutral600,
        ),
        title: Text(
          languageProvider.t('transactions'),
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.neutral900,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Show filter options
            },
            icon: const Icon(Icons.filter_list),
            color: AppColors.neutral600,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Spending Summary
            _buildSpendingSummary(transactionProvider),
            
            // Filter tabs
            _buildFilterTabs(),
            
            // Transaction list
            Expanded(
              child: Consumer<TransactionProvider>(
                builder: (context, provider, child) {
                  final filteredTransactions = _getFilteredTransactions(provider.transactions);
                  
                  if (filteredTransactions.isEmpty) {
                    return _buildEmptyState();
                  }
                  
                  return ListView.builder(
                    padding: EdgeInsets.all(AppSpacing.responsivePadding(context)),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      final showDateHeader = index == 0 || 
                        _shouldShowDateHeader(transaction, filteredTransactions[index - 1]);
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDateHeader) _buildDateHeader(transaction.timestamp),
                          _buildTransactionItem(transaction),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendingSummary(TransactionProvider provider) {
    return Container(
      margin: EdgeInsets.all(AppSpacing.responsivePadding(context)),
      padding: EdgeInsets.all(AppSpacing.responsiveCardPadding(context)),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem(
                'Today',
                '₦${provider.totalSpentToday.toStringAsFixed(2)}',
                Icons.today,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildSummaryItem(
                'This Month',
                '₦${provider.totalSpentThisMonth.toStringAsFixed(2)}',
                Icons.calendar_month,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String amount, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white.withOpacity(0.9),
            size: 20,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            amount,
            style: AppTextStyles.labelLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 50,
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.responsivePadding(context),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final option = _filterOptions[index];
          final isSelected = _selectedFilter == option;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = option;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary500 : AppColors.neutral0,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(
                  color: isSelected ? AppColors.primary500 : AppColors.neutral200,
                ),
                boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary500.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
              ),
              child: Center(
                child: Text(
                  option,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.neutral600,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
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

  bool _shouldShowDateHeader(Transaction current, Transaction previous) {
    final currentDate = DateTime(
      current.timestamp.year,
      current.timestamp.month,
      current.timestamp.day,
    );
    final previousDate = DateTime(
      previous.timestamp.year,
      previous.timestamp.month,
      previous.timestamp.day,
    );
    
    return currentDate != previousDate;
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    String dateText;
    if (dateOnly == today) {
      dateText = 'Today';
    } else if (dateOnly == yesterday) {
      dateText = 'Yesterday';
    } else {
      dateText = _formatDate(date);
    }
    
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.lg,
        bottom: AppSpacing.md,
      ),
      child: Text(
        dateText,
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.neutral600,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return GestureDetector(
      onTap: () => _handleTransactionTap(transaction),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: EdgeInsets.all(AppSpacing.responsiveCardPadding(context)),
        decoration: BoxDecoration(
          color: AppColors.neutral0,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Transaction icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: transaction.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Center(
                child: Text(
                  _getTransactionIcon(transaction.type),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            
            const SizedBox(width: AppSpacing.md),
            
            // Transaction details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          transaction.typeDisplayName,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.neutral900,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        transaction.formattedAmount,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.neutral900,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          transaction.recipient,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.neutral600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: transaction.statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            _getRelativeTime(transaction.timestamp),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.neutral500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/transaction_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/promotional_carousel.dart';
import '../../../../shared/widgets/underbanking_banner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _balanceVisible = true;
  String _selectedPeriod = 'This month';

  final List<String> _timePeriods = [
    'This day',
    'This week', 
    'This month',
    '6 Month',
    '1yr'
  ];

  final List<QuickAction> _quickActions = [
    QuickAction(
      id: 'send',
      title: 'Send',
      icon: Icons.send_outlined,
      color: AppColors.accentBlue,
      route: '/transfer',
    ),
    QuickAction(
      id: 'request',
      title: 'Request',
      icon: Icons.call_received_outlined,
      color: AppColors.primary400,
      route: '/request',
    ),
    QuickAction(
      id: 'topup',
      title: 'Top Up',
      icon: Icons.add_circle_outline,
      color: AppColors.accentOrange,
      route: '/add-money',
    ),
    QuickAction(
      id: 'more',
      title: 'More',
      icon: Icons.apps_outlined,
      color: AppColors.neutral600,
      route: '/bills',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleBalanceVisibility() {
    HapticFeedback.lightImpact();
    setState(() {
      _balanceVisible = !_balanceVisible;
    });
  }

  void _handleQuickAction(QuickAction action) {
    HapticFeedback.lightImpact();
    context.push(action.route);
  }

  void _handleRecentActivityTap(Transaction transaction) {
    final receiptData = {
      'id': transaction.id,
      'type': transaction.typeDisplayName,
      'amount': transaction.formattedAmount,
      'recipient': transaction.recipient,
      'date': _formatDate(transaction.timestamp),
      'time': _formatTime(transaction.timestamp),
      'status': transaction.status.name,
      'reference': transaction.reference,
      'description': transaction.description,
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary50,
              AppColors.neutral0,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                // Header
                SliverAppBar(
                  expandedHeight: 100,
                  floating: false,
                  pinned: false,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.responsivePadding(context),
                        MediaQuery.of(context).padding.top + AppSpacing.md,
                        AppSpacing.responsivePadding(context),
                        AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          // User Avatar and Greeting
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: user?.profileImageUrl != null
                                ? NetworkImage(user!.profileImageUrl!)
                                : null,
                            child: user?.profileImageUrl == null
                                ? Icon(
                                    Icons.person,
                                    color: AppColors.neutral500,
                                  )
                                : null,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Hello, ${user?.firstName ?? 'Ava'}',
                                  style: AppTextStyles.heading4.copyWith(
                                    color: AppColors.neutral900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'welcome back',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.neutral500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Action Buttons
                          IconButton(
                            onPressed: () => context.push('/notifications'),
                            icon: Icon(
                              Icons.notifications_outlined,
                              color: AppColors.neutral700,
                            ),
                          ),
                          IconButton(
                            onPressed: () => context.push('/settings'),
                            icon: Icon(
                              Icons.menu,
                              color: AppColors.neutral700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Content
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.responsivePadding(context)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // My Wallet Section
                        Text(
                          'My wallet',
                          style: AppTextStyles.heading4.copyWith(
                            color: AppColors.neutral900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildDarkWalletCard(user),
                        
                        const SizedBox(height: AppSpacing.xl),

                        // Recent Transactions Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Transaction',
                              style: AppTextStyles.heading4.copyWith(
                                color: AppColors.neutral900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/transactions'),
                              child: Text(
                                'See All',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.neutral400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),

                        // Time Period Filters
                        _buildTimePeriodFilters(),
                        
                        const SizedBox(height: AppSpacing.lg),

                        // Transaction List
                        _buildTransactionList(transactionProvider),
                        
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDarkWalletCard(User? user) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.responsiveCardPadding(context)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1E2E),
            Color(0xFF2A2A3E),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _toggleBalanceVisibility,
                    child: Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _balanceVisible 
                              ? '\$${user?.balance.toStringAsFixed(2) ?? '12,854.00'}'
                              : '\$ ••••••',
                            key: ValueKey(_balanceVisible),
                            style: AppTextStyles.heading1.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(
                          _balanceVisible 
                            ? Icons.visibility_outlined 
                            : Icons.visibility_off_outlined,
                          color: Colors.white.withOpacity(0.8),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Available balance',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  Icons.credit_card,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),

          // Savings Section
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(
                    Icons.savings_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Savings',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      '\$955.00',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Action Buttons
          Row(
            children: _quickActions.map((action) {
              final isFirst = _quickActions.first == action;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    left: isFirst ? 0 : AppSpacing.xs,
                    right: isFirst ? AppSpacing.xs : 0,
                  ),
                  child: ElevatedButton(
                    onPressed: () => _handleQuickAction(action),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                        horizontal: AppSpacing.sm,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(action.icon, size: 20),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          action.title,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimePeriodFilters() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _timePeriods.length,
        itemBuilder: (context, index) {
          final period = _timePeriods[index];
          final isSelected = _selectedPeriod == period;
          
          return Container(
            margin: EdgeInsets.only(
              right: index < _timePeriods.length - 1 ? AppSpacing.sm : 0,
            ),
            child: FilterChip(
              label: Text(
                period,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected ? Colors.white : AppColors.neutral600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedPeriod = period;
                  });
                }
              },
              backgroundColor: AppColors.neutral100,
              selectedColor: AppColors.primary500,
              side: BorderSide(
                color: isSelected ? AppColors.primary500 : AppColors.neutral200,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionList(TransactionProvider provider) {
    final recentTransactions = provider.recentTransactions.take(4).toList();
    
    if (recentTransactions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppSpacing.responsiveCardPadding(context)),
        decoration: BoxDecoration(
          color: AppColors.neutral0,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No recent transactions',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral600,
              ),
            ),
            Text(
              'Your transaction history will appear here',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.neutral500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: recentTransactions.map((transaction) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          child: GestureDetector(
            onTap: () => _handleRecentActivityTap(transaction),
            child: Row(
              children: [
                // Avatar or Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getTransactionColor(transaction.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Center(
                    child: transaction.recipient == 'Omid Farokhi'
                        ? CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(
                              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=40&h=40&fit=crop&crop=face'
                            ),
                          )
                        : Text(
                            _getTransactionEmoji(transaction.type),
                            style: const TextStyle(fontSize: 20),
                          ),
                  ),
                ),
                
                const SizedBox(width: AppSpacing.md),
                
                // Transaction Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.recipient,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.neutral900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _formatDate(transaction.timestamp),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.neutral400,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Amount
                Text(
                  '${transaction.type == TransactionType.transfer ? '- ' : '+ '}\$${transaction.amount.toStringAsFixed(2)}',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: transaction.type == TransactionType.transfer 
                        ? AppColors.error500 
                        : AppColors.success500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getTransactionColor(TransactionType type) {
    switch (type) {
      case TransactionType.transfer:
        return AppColors.error500;
      case TransactionType.addMoney:
        return AppColors.success500;
      case TransactionType.airtime:
        return AppColors.accentPurple;
      case TransactionType.data:
        return AppColors.accentBlue;
      default:
        return AppColors.neutral400;
    }
  }

  String _getTransactionEmoji(TransactionType type) {
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
      default:
        return '💳';
    }
  }
}

class QuickAction {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  QuickAction({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
  });
}
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

  final List<QuickAction> _quickActions = [
    QuickAction(
      id: 'airtime',
      title: 'Airtime',
      icon: '📱',
      color: AppColors.accentPurple,
      route: '/airtime',
    ),
    QuickAction(
      id: 'data',
      title: 'Data',
      icon: '📶',
      color: AppColors.accentBlue,
      route: '/data',
    ),
    QuickAction(
      id: 'electricity',
      title: 'Electricity',
      icon: '⚡',
      color: AppColors.accentYellow,
      route: '/electricity',
    ),
    QuickAction(
      id: 'loans',
      title: 'Loans',
      icon: '🏦',
      color: AppColors.accentOrange,
      route: '/loans',
    ),
    QuickAction(
      id: 'cable',
      title: 'Cable TV',
      icon: '📺',
      color: AppColors.accentPink,
      route: '/cable',
    ),
    QuickAction(
      id: 'more',
      title: 'More Services',
      icon: '⚙️',
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

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final transactionProvider = Provider.of<TransactionProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.neutral0,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.responsivePadding(context),
                      MediaQuery.of(context).padding.top + AppSpacing.md,
                      AppSpacing.responsivePadding(context),
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getGreeting(),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  user?.lastName ?? 'Welcome to RimaPay',
                                  style: AppTextStyles.heading4.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => context.push('/notifications'),
                                  icon: Stack(
                                    children: [
                                      Icon(
                                        Icons.notifications_outlined,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: AppColors.accentOrange,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => context.push('/settings'),
                                  icon: Icon(
                                    Icons.settings_outlined,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Main Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.responsivePadding(context)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Underbanking Banner (if applicable)
                      if (user?.accountType == AccountType.underbanking) ...[
                         UnderbankingBanner(
                          onUpgrade: (){},
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // Balance Card
                      _buildBalanceCard(user),
                      
                      const SizedBox(height: AppSpacing.xl),

                      // Quick Actions
                      _buildQuickActions(),
                      
                      const SizedBox(height: AppSpacing.xl),

                      // Promotional Carousel
                      const PromotionalCarousel(),
                      
                      const SizedBox(height: AppSpacing.xl),

                      // Recent Activity
                      _buildRecentActivity(transactionProvider, languageProvider),
                      
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildBalanceCard(User? user) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.responsiveCardPadding(context)),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Balance',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    onTap: _toggleBalanceVisibility,
                    child: Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _balanceVisible 
                              ? '₦${user?.balance.toStringAsFixed(2) ?? '0.00'}'
                              : '₦ ••••••',
                            key: ValueKey(_balanceVisible),
                            style: AppTextStyles.heading2.copyWith(
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
                ],
              ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.push('/add-money'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary600,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 18),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Add Money',
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.push('/transfer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send, size: 18),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Send',
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: AppTextStyles.heading4.copyWith(
            color: AppColors.neutral900,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.0,
          ),
          itemCount: _quickActions.length,
          itemBuilder: (context, index) {
            final action = _quickActions[index];
            return _buildQuickActionCard(action);
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(QuickAction action) {
    return GestureDetector(
      onTap: () => _handleQuickAction(action),
      child: Container(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Center(
                child: Text(
                  action.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              action.title,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.neutral700,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(TransactionProvider provider, LanguageProvider languageProvider) {
    final recentTransactions = provider.recentTransactions.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: AppTextStyles.heading4.copyWith(
                color: AppColors.neutral900,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/transactions'),
              child: Text(
                'See All',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        
        if (recentTransactions.isEmpty)
          Container(
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
          )
        else
          ...recentTransactions.map((transaction) {
            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: GestureDetector(
                onTap: () => _handleRecentActivityTap(transaction),
                child: Container(
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
                      Container(
                        width: 40,
                        height: 40,
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transaction.typeDisplayName,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.neutral900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              transaction.recipient,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.neutral600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            transaction.formattedAmount,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.neutral900,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _formatTime(transaction.timestamp),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.neutral500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
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
      default:
        return '💳';
    }
  }
}

class QuickAction {
  final String id;
  final String title;
  final String icon;
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
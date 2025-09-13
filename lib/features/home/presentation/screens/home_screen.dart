import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:rimapay/features/receipt/presentation/screens/receipt_screen.dart';

import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/transaction_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/promotional_carousel.dart';
import '../../../../shared/widgets/underbanking_banner.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _balanceVisible = true;
  bool _upgradeModalOpen = false;
  final bool _notificationOpen = false;
  String _selectedService = '';
  final String _activeAccount = 'personal'; // Only personal, no cooperative

  final List<QuickAction> _quickActions = [
    QuickAction(
      id: 'airtime',
      title: 'Airtime',
      subtitle: 'Buy airtime',
      icon: Icons.phone,
      color: const Color(0xFF8B5CF6),
      route: '/bills/airtime',
    ),
    QuickAction(
      id: 'data',
      title: 'Data',
      subtitle: 'Buy data',
      icon: Icons.wifi,
      color: const Color(0xFFF97316),
      route: '/bills/data',
    ),
    QuickAction(
      id: 'buy-electricity',
      title: 'Electricity',
      subtitle: 'Pay bills',
      icon: Icons.lightbulb_outline,
      color: const Color(0xFFEAB308),
      route: '/bills/electricity',
    ),
    // QuickAction(
    //   id: 'loan-service',
    //   title: 'Loans',
    //   subtitle: 'Upgrade to unlock',
    //   icon: Icons.credit_card,
    //   color: const Color(0xFF6B7280),
    //   route: '/bills/loans',
    //   isLocked: true,
    // ),
    QuickAction(
      id: 'cable',
      title: 'Cable TV',
      subtitle: 'Pay for TV',
      icon: Icons.tv,
      color: const Color(0xFFEC4899),
      route: '/bills/cable',
    ),
    // QuickAction(
    //   id: 'bills',
    //   title: 'More Services',
    //   subtitle: 'Other services',
    //   icon: Icons.grid_3x3,
    //   color: const Color(0xFF6B7280),
    //   route: '/bills',
    // ),
  ];

  final List<TransactionItem> _recentTransactions = [
    TransactionItem(
      id: '1',
      type: 'sent',
      name: 'Funmi Adebayo',
      description: 'Dinner split',
      amount: '12,500.00',
      time: '2 min ago',
      avatar: 'https://images.unsplash.com/photo-1494790108755-2616b67fcce8?w=40&h=40&fit=crop&crop=face',
      category: 'transfer',
    ),
    TransactionItem(
      id: '2',
      type: 'received',
      name: 'Freelance Payment',
      description: 'Design project',
      amount: '450,000.00',
      time: '1 hour ago',
      category: 'income',
    ),
    TransactionItem(
      id: '3',
      type: 'sent',
      name: 'Netflix',
      description: 'Monthly subscription',
      amount: '2,900.00',
      time: 'Yesterday',
      category: 'subscription',
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

    // Check if action is locked and user needs upgrade
    if (action.isLocked == true) {
      setState(() {
        _selectedService = action.title;
        _upgradeModalOpen = true;
      });
      return;
    }

    context.push(action.route);
  }

  void _handleRecentActivityTap(TransactionItem transaction) {
    final receiptData = {
      'id': transaction.id,
      'type': transaction.name,
      'amount': '₦${transaction.amount}',
      'recipient': transaction.description,
      'date': DateTime.now().toString().split(' ')[0],
      'time': transaction.time,
      'status': 'success',
      'reference': 'RMP${DateTime.now().millisecondsSinceEpoch}${transaction.id}',
      'description': '${transaction.category} - ${transaction.description}',
      'category': transaction.category,
    };

    final recipet = ReceiptData.fromJson(receiptData);
    context.pushNamed('receipt', extra: recipet);
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

  Color _getTierBadgeColor(String tierLevel) {
    switch (tierLevel) {
      case 'tier0':
        return const Color(0xFFEAB308);
      case 'tier1':
        return const Color(0xFF3B82F6);
      case 'tier2':
        return const Color(0xFF8B5CF6);
      case 'tier3':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getTierIcon(String tierLevel) {
    switch (tierLevel) {
      case 'tier0':
        return Icons.show_chart;
      case 'tier1':
        return Icons.trending_up;
      case 'tier2':
        return Icons.emoji_events;
      case 'tier3':
        return Icons.star;
      default:
        return Icons.show_chart;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTier = {
      'level': 'tier1',
      'name': 'Tier 1',
      'dailyLimit': 'N500000',
      'benefits': [
        'Mobile payments',
        'Bill payments',
        'Basic transfers',
        '24/7 customer support',
      ],
    };

    final isTransferAvailable = false;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                // Header
                SliverAppBar(
                  expandedHeight: 80,
                  floating: true,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      color: Colors.white,
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.responsivePadding(context),
                        MediaQuery.of(context).padding.top + AppSpacing.sm,
                        AppSpacing.responsivePadding(context),
                        AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          // Logo and Greeting
                          Image.asset(
                            "assets/images/AppIcon.png",
                            height: 40,
                            width: 40,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _getGreeting(),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.neutral500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Adebayo Okafor',
                                  style: AppTextStyles.heading4.copyWith(
                                    color: AppColors.neutral900,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Action Buttons
                          _buildActionButton(
                            icon: Icons.language,
                            onPressed: () {
                              ref.read(toggleLanguageProvider);
                            },
                            backgroundColor: const Color(0xFF00B252),
                            iconColor: Colors.white,
                            badge: ref.watch(currentLanguageProvider).when(
                                  data: (lang) => lang.toUpperCase(),
                                  loading: () => 'EN',
                                  error: (_, __) => 'EN',
                                ),
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            icon: Icons.notifications_outlined,
                            onPressed: () => context.push('/notifications'),
                            badge: '3',
                          ),
                          const SizedBox(width: 8),
                          _buildActionButton(
                            icon: Icons.settings,
                            onPressed: () => context.push('/settings'),
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
                        // Underbanking Banner
                        // if (user?.accountType == AccountType.underbanking)
                        //   UnderbankingBanner(
                        //     onUpgrade: () {},
                        //   ),

                        // Business Account Under Review Banner
                        // if (user?.accountType.name == 'Business' &&
                        //     user?.businessInfo?['accountStatus'] == 'under_review')
                        // _buildBusinessReviewBanner(),

                        // Enhanced Wallet Card
                        _buildEnhancedWalletCard(currentTier, isTransferAvailable),

                        const SizedBox(height: AppSpacing.xl),

                        // Quick Actions Section
                        _buildQuickActionsSection(),

                        const SizedBox(height: AppSpacing.xl),

                        // Promotional Carousel
                        const PromotionalCarousel(),

                        const SizedBox(height: AppSpacing.xl),

                        // Recent Activity Section
                        _buildRecentActivitySection(),

                        const SizedBox(height: 100), // Bottom padding for navigation
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

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? iconColor,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.neutral100,
          border: Border.all(color: AppColors.neutral200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Center(
              child: Icon(
                icon,
                size: 18,
                color: iconColor ?? AppColors.neutral600,
              ),
            ),
            if (badge != null)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: badge.length <= 2 ? Colors.red : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: badge.length <= 2 ? Colors.white : const Color(0xFF00B252),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessReviewBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7ED), Color(0xFFFEF3C7)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFBBF24)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFF97316),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Under Review',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: const Color(0xFF92400E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your business account application is being reviewed by our team. This typically takes 1-2 business days.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFFA16207),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedWalletCard(Map<String, dynamic> currentTier, bool isTransferAvailable) {
    final displayBalance = '15,750.00';
    final accountNumber = '2138547690';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF003d1a),
            Color(0xFF005e27),
            Color(0xFF007432),
            Color(0xFF005e27),
            Color(0xFF003d1a),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Balance',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12,
                ),
              ),
              Row(
                children: [
                  // Transfer Button (only if available)
                  if (isTransferAvailable)
                    GestureDetector(
                      onTap: () => context.push('/cooperative-transfer'),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.swap_horiz,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  if (isTransferAvailable) const SizedBox(width: 8),
                  // Balance visibility toggle
                  GestureDetector(
                    onTap: _toggleBalanceVisibility,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _balanceVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Balance Amount
          Text(
            _balanceVisible ? '₦$displayBalance' : '••••••••',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Account: $accountNumber',
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.7),
            ),
          ),

          const SizedBox(height: 12),

          // Tier Information
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _getTierBadgeColor(currentTier['level']),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getTierIcon(currentTier['level']),
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentTier['name'],
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Daily Limit: ${currentTier['dailyLimit']}',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (currentTier['level'] != 'tier3')
                      GestureDetector(
                        onTap: () => context.push('/tiers'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Upgrade',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Benefits
                Row(
                  children: (currentTier['benefits'] as List<String>)
                      .take(2)
                      .map((benefit) => Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              benefit,
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                // Send Money Button
                Expanded(
                  child: _buildWalletActionButton(
                    title: 'Send Money',
                    subtitle: 'Send to others',
                    icon: Icons.send,
                    onPressed: () => context.push('/send'),
                  ),
                ),
                const SizedBox(width: 8),
                // Add Money Button
                Expanded(
                  child: _buildWalletActionButton(
                    title: 'Add Money',
                    subtitle: 'Top up wallet',
                    icon: Icons.add,
                    onPressed: () => context.push('/add-money'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF00B252).withOpacity(0.08),
          border: Border.all(color: const Color(0xFF00B252).withOpacity(0.15)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00B252), Color(0xFF00A047)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D2939),
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                color: Color(0xFF667085),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
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
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _quickActions.length,
          itemBuilder: (context, index) {
            final action = _quickActions[index];
            return GestureDetector(
              onTap: () => _handleQuickAction(action),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: action.color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            action.icon,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        if (action.isLocked == true)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: Color(0xFF6B7280),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              action.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1D2939),
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              action.subtitle,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF667085),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection() {
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
            GestureDetector(
              onTap: () => context.push('/transactions'),
              child: Text(
                'View All',
                style: AppTextStyles.labelMedium.copyWith(
                  color: const Color(0xFF00B252),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Column(
          children: _recentTransactions.take(3).map((transaction) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _handleRecentActivityTap(transaction),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.neutral200),
                  ),
                  child: Row(
                    children: [
                      // Avatar or Icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: transaction.type == 'sent' ? const Color(0xFFEF4444) : const Color(0xFF00B252),
                          shape: BoxShape.circle,
                        ),
                        child: transaction.avatar != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  transaction.avatar!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildTransactionIcon(transaction);
                                  },
                                ),
                              )
                            : _buildTransactionIcon(transaction),
                      ),

                      const SizedBox(width: 12),

                      // Transaction Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    transaction.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1D2939),
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    '${transaction.type == 'sent' ? '-' : '+'}₦${transaction.amount}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: transaction.type == 'sent' ? const Color(0xFFEF4444) : const Color(0xFF00B252),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  transaction.description,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF667085),
                                  ),
                                ),
                                Text(
                                  transaction.time,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF98A2B3),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
    );
  }

  Widget _buildTransactionIcon(TransactionItem transaction) {
    return Center(
      child: Text(
        transaction.name.split(' ').map((n) => n[0]).join(''),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  String _getTierName(String tierLevel) {
    switch (tierLevel) {
      case 'tier0':
        return 'Starter Tier';
      case 'tier1':
        return 'Bronze Tier';
      case 'tier2':
        return 'Silver Tier';
      case 'tier3':
        return 'Gold Tier';
      default:
        return 'Starter Tier';
    }
  }

  String _getDailyLimit(String tierLevel) {
    switch (tierLevel) {
      case 'tier0':
        return '₦50,000';
      case 'tier1':
        return '₦200,000';
      case 'tier2':
        return '₦1,000,000';
      case 'tier3':
        return '₦5,000,000';
      default:
        return '₦50,000';
    }
  }

  List<String> _getTierBenefits(String tierLevel) {
    switch (tierLevel) {
      case 'tier0':
        return ['Basic transfers', 'Bill payments'];
      case 'tier1':
        return ['Higher limits', 'Priority support'];
      case 'tier2':
        return ['Business features', 'Advanced analytics'];
      case 'tier3':
        return ['Premium features', 'Dedicated manager'];
      default:
        return ['Basic transfers', 'Bill payments'];
    }
  }
}

class QuickAction {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
  final bool? isLocked;

  QuickAction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
    this.isLocked,
  });
}

class TransactionItem {
  final String id;
  final String type;
  final String name;
  final String description;
  final String amount;
  final String time;
  final String? avatar;
  final String category;

  TransactionItem({
    required this.id,
    required this.type,
    required this.name,
    required this.description,
    required this.amount,
    required this.time,
    this.avatar,
    required this.category,
  });
}

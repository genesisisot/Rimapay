import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class BillService {
  final String id;
  final String title;
  final String description;
  final String icon;
  final Color color;
  final String route;
  final bool isLocked;
  final TierLevel requiredTier;

  BillService({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.route,
    this.isLocked = false,
    this.requiredTier = TierLevel.tier0,
  });
}

class BillPaymentsScreen extends StatefulWidget {
  const BillPaymentsScreen({super.key});

  @override
  State<BillPaymentsScreen> createState() => _BillPaymentsScreenState();
}

class _BillPaymentsScreenState extends State<BillPaymentsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.dispose();
    super.dispose();
  }

  List<BillService> _getAllServices() {
    return [
      // Essential Services (Always Available)
      BillService(
        id: 'airtime',
        title: 'Airtime',
        description: 'Buy airtime for all networks',
        icon: '📱',
        color: AppColors.accentPurple,
        route: '/airtime',
      ),
      BillService(
        id: 'data',
        title: 'Data',
        description: 'Buy data bundles',
        icon: '📶',
        color: AppColors.accentOrange,
        route: '/data',
      ),
      BillService(
        id: 'electricity',
        title: 'Electricity',
        description: 'Pay electricity bills',
        icon: '⚡',
        color: AppColors.accentYellow,
        route: '/electricity',
      ),
      BillService(
        id: 'cable',
        title: 'Cable TV',
        description: 'Pay for cable subscriptions',
        icon: '📺',
        color: AppColors.accentPink,
        route: '/cable',
      ),
      
      // Tier 1+ Services
      BillService(
        id: 'education',
        title: 'Education Bills',
        description: 'Pay school fees and educational bills',
        icon: '🎓',
        color: AppColors.accentBlue,
        route: '/education-bills',
        isLocked: true,
        requiredTier: TierLevel.tier1,
      ),
      BillService(
        id: 'airtime-to-cash',
        title: 'Airtime to Cash',
        description: 'Convert airtime to cash',
        icon: '💰',
        color: AppColors.primary500,
        route: '/airtime-to-cash',
        isLocked: true,
        requiredTier: TierLevel.tier1,
      ),
      BillService(
        id: 'event-tickets',
        title: 'Event Tickets',
        description: 'Buy event and concert tickets',
        icon: '🎫',
        color: AppColors.accentPink,
        route: '/event-tickets',
        isLocked: true,
        requiredTier: TierLevel.tier1,
      ),
      
      // Tier 2+ Services
      BillService(
        id: 'betting',
        title: 'Betting & Lottery',
        description: 'Fund betting and lottery accounts',
        icon: '🎰',
        color: AppColors.accentOrange,
        route: '/betting-lottery',
        isLocked: true,
        requiredTier: TierLevel.tier2,
      ),
      BillService(
        id: 'pension',
        title: 'Voluntary Pension',
        description: 'Make voluntary pension contributions',
        icon: '🏦',
        color: AppColors.accentBlue,
        route: '/voluntary-pension',
        isLocked: true,
        requiredTier: TierLevel.tier2,
      ),
      BillService(
        id: 'road-transport',
        title: 'Road Transport',
        description: 'Pay for bus tickets and transport',
        icon: '🚌',
        color: AppColors.accentPurple,
        route: '/road-transport',
        isLocked: true,
        requiredTier: TierLevel.tier2,
      ),
      
      // Tier 3+ Services
      BillService(
        id: 'air-transport',
        title: 'Air Transport',
        description: 'Book domestic and international flights',
        icon: '✈️',
        color: AppColors.accentBlue,
        route: '/air-transport',
        isLocked: true,
        requiredTier: TierLevel.tier3,
      ),
      BillService(
        id: 'government',
        title: 'State Government',
        description: 'Pay government fees and taxes',
        icon: '🏛️',
        color: AppColors.primary700,
        route: '/state-government',
        isLocked: true,
        requiredTier: TierLevel.tier3,
      ),
    ];
  }

  List<BillService> _getFilteredServices() {
    final services = _getAllServices();
    if (_searchQuery.isEmpty) return services;
    
    return services.where((service) =>
      service.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      service.description.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  void _handleServiceTap(BillService service) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    if (service.isLocked) {
      final userTierLevel = user?.tierLevel ?? TierLevel.tier0;
      final requiredTierIndex = TierLevel.values.indexOf(service.requiredTier);
      final userTierIndex = TierLevel.values.indexOf(userTierLevel);
      
      if (userTierIndex < requiredTierIndex) {
        _showUpgradeDialog(service);
        return;
      }
    }
    
    context.push(service.route);
  }

  void _showUpgradeDialog(BillService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Row(
          children: [
            Text(service.icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Upgrade Required',
                style: AppTextStyles.heading4.copyWith(
                  color: AppColors.neutral900,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To access ${service.title}, you need to upgrade your account to ${service.requiredTier.name.toUpperCase()} tier or higher.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.primary200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    color: AppColors.primary500,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Upgrade now to unlock premium services',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Later',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.neutral500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/account-tiers');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            child: Text(
              'Upgrade',
              style: AppTextStyles.labelMedium.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

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
          'Bill Payments',
          style: AppTextStyles.heading3.copyWith(
            color: AppColors.neutral900,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Search bar
            Container(
              margin: EdgeInsets.all(AppSpacing.responsivePadding(context)),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search services...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                  filled: true,
                  fillColor: AppColors.neutral0,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: const BorderSide(color: AppColors.neutral200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: const BorderSide(color: AppColors.neutral200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: const BorderSide(color: AppColors.primary500),
                  ),
                ),
              ),
            ),
            
            // Account tier info
            if (user != null)
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: AppSpacing.responsivePadding(context),
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_circle,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.tierName,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Unlock more services by upgrading',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/account-tiers'),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                      ),
                      child: Text(
                        'Upgrade',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Services grid
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.responsivePadding(context),
                ),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _getFilteredServices().length,
                  itemBuilder: (context, index) {
                    final service = _getFilteredServices()[index];
                    return _buildServiceCard(service, user);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(BillService service, User? user) {
    final userTierLevel = user?.tierLevel ?? TierLevel.tier0;
    final requiredTierIndex = TierLevel.values.indexOf(service.requiredTier);
    final userTierIndex = TierLevel.values.indexOf(userTierLevel);
    final isLocked = service.isLocked && userTierIndex < requiredTierIndex;
    
    return GestureDetector(
      onTap: () => _handleServiceTap(service),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isLocked ? AppColors.neutral100 : AppColors.neutral0,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isLocked ? AppColors.neutral200 : service.color.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: isLocked ? AppColors.neutral200 : service.color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isLocked 
                            ? AppColors.neutral200 
                            : service.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Center(
                          child: Text(
                            service.icon,
                            style: TextStyle(
                              fontSize: 20,
                              color: isLocked ? AppColors.neutral400 : null,
                            ),
                          ),
                        ),
                      ),
                      if (isLocked) ...[
                        const Spacer(),
                        Icon(
                          Icons.lock,
                          color: AppColors.neutral400,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    service.title,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: isLocked ? AppColors.neutral400 : AppColors.neutral900,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      service.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isLocked ? AppColors.neutral400 : AppColors.neutral600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isLocked)
                    Container(
                      margin: const EdgeInsets.only(top: AppSpacing.xs),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary100,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        '${service.requiredTier.name.toUpperCase()}+',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary700,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
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
  }
}
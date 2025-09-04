import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class MainNavigationScreen extends StatefulWidget {
  final Widget child;
  
  const MainNavigationScreen({
    super.key,
    required this.child,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  int _currentIndex = 0;
  
  final List<NavigationItem> _items = [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
      route: '/home',
    ),
    NavigationItem(
      icon: Icons.history_outlined,
      activeIcon: Icons.history,
      label: 'Transactions',
      route: '/transactions',
    ),
    NavigationItem(
      icon: Icons.credit_card_outlined,
      activeIcon: Icons.credit_card,
      label: 'Cards',
      route: '/cards',
    ),
    NavigationItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      route: '/profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // DON'T call _updateCurrentIndex() here - it will cause the error
    // because GoRouterState.of(context) is not available yet
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  void _updateCurrentIndex() {
    // Now it's safe to access GoRouterState since we're in didChangeDependencies or build
    final location = GoRouterState.of(context).matchedLocation;
    final index = _items.indexWhere((item) => item.route == location);
    if (index != -1 && index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This is the correct place to call _updateCurrentIndex
    // because the widget tree is fully initialized here
    _updateCurrentIndex();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _currentIndex) return;
    
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    setState(() {
      _currentIndex = index;
    });
    
    context.go(_items[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    // Update current index based on current route
    final location = GoRouterState.of(context).matchedLocation;
    final index = _items.indexWhere((item) => item.route == location);
    if (index != -1 && index != _currentIndex) {
      // Use addPostFrameCallback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _currentIndex = index;
          });
        }
      });
    }
    
    return Scaffold(
      body: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.neutral0,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
           
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.responsivePadding(context),
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isActive = index == _currentIndex;
                
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onItemTapped(index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: isActive 
                                ? AppColors.primary500.withOpacity(0.1)
                                : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: Icon(
                              isActive ? item.activeIcon : item.icon,
                              color: isActive 
                                ? AppColors.primary500 
                                : AppColors.neutral500,
                              size: 24,
                            ),
                          ),
                        
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isActive 
                                ? AppColors.primary500 
                                : AppColors.neutral500,
                              fontWeight: isActive 
                                ? FontWeight.w600 
                                : FontWeight.w500,
                            ),
                            child: Text(
                              languageProvider.t(item.label.toLowerCase()),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}
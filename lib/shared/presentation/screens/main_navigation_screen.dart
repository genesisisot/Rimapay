import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/language_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class MainNavigationScreen extends StatefulWidget {
  final Widget child;
  final bool enableAnimations;
  final Function(String)? onRouteChange;
  
  const MainNavigationScreen({
    super.key,
    required this.child,
    this.enableAnimations = true,
    this.onRouteChange,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _rippleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;
  
  int _currentIndex = 0;
  bool _isAnimating = false;
  
  final List<NavigationItem> _items = [
    NavigationItem(
      id: 'home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
      route: '/home',
    ),
    NavigationItem(
      id: 'transactions',
      icon: Icons.history_outlined,
      activeIcon: Icons.history,
      label: 'Transactions',
      route: '/transactions',
      badge: null, 
    ),
    NavigationItem(
      id: 'cards',
      icon: Icons.credit_card_outlined,
      activeIcon: Icons.credit_card,
      label: 'Cards',
      route: '/cards',
    ),
    NavigationItem(
      id: 'profile',
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
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _rippleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
  }

  void _updateCurrentIndex() {
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
    _updateCurrentIndex();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  Future<void> _onItemTapped(int index) async {
    if (index == _currentIndex || _isAnimating) return;
    
    setState(() {
      _isAnimating = true;
    });

    if (widget.enableAnimations) {
      // Trigger scale animation
      await _animationController.forward();
      await _animationController.reverse();
      
      // Trigger ripple effect
      _rippleController.forward().then((_) {
        _rippleController.reset();
      });
    }
    
    setState(() {
      _currentIndex = index;
      _isAnimating = false;
    });
    
    final route = _items[index].route;
    context.go(route);
    widget.onRouteChange?.call(route);
  }

  Widget _buildBadge(int? badge) {
    if (badge == null || badge == 0) return const SizedBox.shrink();
    
    return Positioned(
      top: -2,
      right: -2,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        constraints: const BoxConstraints(
          minWidth: 16,
          minHeight: 16,
        ),
        child: Text(
          badge > 9 ? '9+' : badge.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildNavigationItem(NavigationItem item, int index, bool isActive) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          splashColor: AppColors.primary500.withOpacity(0.1),
          highlightColor: AppColors.primary500.withOpacity(0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with badge and ripple effect
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Ripple effect background
                    if (isActive)
                      AnimatedBuilder(
                        animation: _rippleAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 40 + (_rippleAnimation.value * 10),
                            height: 40 + (_rippleAnimation.value * 10),
                            decoration: BoxDecoration(
                              color: AppColors.primary500.withOpacity(
                                0.1 * (1 - _rippleAnimation.value),
                              ),
                              shape: BoxShape.circle,
                            ),
                          );
                        },
                      ),
                    // Main icon container
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
                    // Badge
                    _buildBadge(item.badge),
                  ],
                ),
                const SizedBox(height: 4),
                // Label with improved animation
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
                  child: Consumer<LanguageProvider>(
                    builder: (context, languageProvider, child) {
                      return Text(
                        languageProvider.t(item.label.toLowerCase()),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Update current index based on current route
    final location = GoRouterState.of(context).matchedLocation;
    final index = _items.indexWhere((item) => item.route == location);
    if (index != -1 && index != _currentIndex) {
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
                
                return _buildNavigationItem(item, index, isActive);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final String id;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final int? badge;

  NavigationItem({
    required this.id,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    this.badge,
  });
}
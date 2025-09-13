import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rimapay/core/router/app_router.dart';
import '../../core/providers/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class CarouselSlide {
  final String id;
  final String type;
  final IconData icon;
  final Color iconColor;
  final Gradient bgGradient;
  final String title;
  final String description;
  final String actionText;
  final VoidCallback? action;

  CarouselSlide({
    required this.id,
    required this.type,
    required this.icon,
    required this.iconColor,
    required this.bgGradient,
    required this.title,
    required this.description,
    required this.actionText,
    this.action,
  });
}

class PromotionalCarousel extends ConsumerStatefulWidget {
  const PromotionalCarousel({super.key});

  @override
  ConsumerState<PromotionalCarousel> createState() => _PromotionalCarouselState();
}

class _PromotionalCarouselState extends ConsumerState<PromotionalCarousel> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentSlide = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _startAutoSlide();
  }

  void _startAutoSlide() {
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        final nextSlide = (_currentSlide + 1) % 4;
        _pageController.animateToPage(
          nextSlide,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _startAutoSlide();

        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  List<CarouselSlide> _getSlides() {
    final language = ref.read(languageTranslationsProvider);
    final languageProvide = ref.read(languageProvider);
    return [
      CarouselSlide(
        id: 'language',
        type: 'language',
        icon: Icons.language,
        iconColor: Colors.white,
        bgGradient: AppColors.primaryGradient,
        title: language('switchToHausa'),
        description: language('changeLanguageOneTap'),
        actionText: languageProvide.languageCode == 'en' ? 'Switch to HA' : 'Canza zuwa EN',
        action: () {
          ref.read(toggleLanguageProvider);
        },
      ),
      CarouselSlide(
        id: 'upgrade',
        type: 'upgrade',
        icon: Icons.trending_up,
        iconColor: Colors.white,
        bgGradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED), Color(0xFF6D28D9)],
        ),
        title: language('upgradeYourAccount'),
        description: language('unlockMoreFeatures'),
        actionText: language('upgradeAccountNow'),
        action: () {},
      ),
      CarouselSlide(
        id: 'loans',
        type: 'loan',
        icon: Icons.credit_card,
        iconColor: Colors.white,
        bgGradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626), Color(0xFFB91C1C)],
        ),
        title: language('getLoansToday'),
        description: language('quickApprovalProcess'),
        actionText: language('applyForLoan'),
        action: () {},
      ),
      CarouselSlide(
        id: 'transfer',
        type: 'transfer',
        icon: Icons.send,
        iconColor: Colors.white,
        bgGradient: const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF0891B2), Color(0xFF0E7490)],
        ),
        title: language('sendMoneyFaster'),
        description: language('instantTransfersToAnyBank'),
        actionText: language('startSending'),
        action: () {},
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Now you can pass the provider to your helper method
    final slides = _getSlides();
    final screenWidth = MediaQuery.of(context).size.width;
    final carouselWidth = (screenWidth * 0.95).clamp(300.0, 460.0);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.responsivePadding(context),
      ),
      child: SizedBox(
        height: 80,
        width: carouselWidth,
        child: Stack(
          children: [
            // Main Carousel
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentSlide = index;
                });
                _animationController.reset();
                _animationController.forward();
              },
              itemCount: slides.length,
              itemBuilder: (context, index) {
                final slide = slides[index];
                return _buildSlide(slide);
              },
            ),

            // Progress Indicators
            Positioned(
              bottom: 8,
              left: 16,
              child: Row(
                children: slides.asMap().entries.map((entry) {
                  final index = entry.key;
                  final isActive = index == _currentSlide;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 4),
                    height: 4,
                    width: isActive ? 20 : 4,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Auto-progress bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppSpacing.radiusLg),
                    bottomRight: Radius.circular(AppSpacing.radiusLg),
                  ),
                ),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _animationController.value,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(AppSpacing.radiusLg),
                            bottomRight: Radius.circular(AppSpacing.radiusLg),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(CarouselSlide slide) {
    return GestureDetector(
      onTap: slide.action,
      child: Container(
        margin: EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          gradient: slide.bgGradient,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Stack(
          children: [
            // Background effects
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  gradient: RadialGradient(
                    center: const Alignment(0.2, -0.8),
                    radius: 1.2,
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          slide.icon,
                          color: slide.iconColor,
                          size: 24,
                        ),
                        if (slide.type == 'language')
                          Positioned(
                            bottom: -2,
                            right: -2,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  ref.read(languageProvider).countryCode?.toUpperCase() ?? "en",
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.primary500,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  // Content
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          slide.title,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          slide.description,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Action button
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          slide.actionText,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white.withOpacity(0.8),
                          size: 12,
                        ),
                      ],
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

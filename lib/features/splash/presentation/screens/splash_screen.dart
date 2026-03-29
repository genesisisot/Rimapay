import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _backgroundController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _textSlide;
  late Animation<double> _backgroundOpacity;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
  }

  void _initializeAnimations() {
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Background animation controller
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Logo animations
    _logoScale = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // Text animations
    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));

    _textSlide = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));

    // Background animation
    _backgroundOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _startAnimationSequence() async {
    // Start background animation immediately
    _backgroundController.forward();

    // Start logo animation after short delay
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();

    // Start text animation
    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();

    // Navigate to welcome screen
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      context.go('/welcome');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary500.withOpacity(_backgroundOpacity.value),
                      AppColors.primary700.withOpacity(_backgroundOpacity.value * 0.8),
                      AppColors.primary900.withOpacity(_backgroundOpacity.value * 0.6),
                    ],
                  ),
                ),
              );
            },
          ),

          // Background effects
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                return Opacity(
                  opacity: _backgroundOpacity.value * 0.1,
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                            'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><defs><pattern id="grain" width="100" height="100" patternUnits="userSpaceOnUse"><circle cx="25" cy="25" r="1" fill="white" opacity="0.1"/><circle cx="75" cy="75" r="1" fill="white" opacity="0.1"/><circle cx="50" cy="10" r="0.5" fill="white" opacity="0.05"/><circle cx="10" cy="60" r="0.8" fill="white" opacity="0.08"/><circle cx="90" cy="30" r="0.6" fill="white" opacity="0.06"/></pattern></defs><rect width="100" height="100" fill="url(%23grain)"/></svg>'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: Center(
                              child: Image.asset(
                            "assets/images/AppIcon.png",
                            height: 120,
                            width: 120,
                          )),
                      ),
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.xxl),

                // App name and tagline
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: Column(
                          children: [
                            Text(
                              'RimaPay',
                              style: AppTextStyles.display1.copyWith(
                                color: Colors.white,
                                fontSize: 36,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Your Modern Mobile Wallet',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.xxxl * 2),

                // Compliance logos
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textOpacity.value,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.15)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/images/NDIC.png',
                              height: 48,
                              errorBuilder: (_, __, ___) => const SizedBox(),
                            ),
                            Container(
                              width: 1,
                              height: 36,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              color: Colors.white.withOpacity(0.2),
                            ),
                            Text(
                              'AUTHORIZED AND\nREGULATED BY',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Image.asset(
                              'assets/images/CBN.png',
                              height: 50,
                              errorBuilder: (_, __, ___) => const SizedBox(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Loading indicator
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textOpacity.value,
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Floating particles effect
          ...List.generate(5, (index) {
            return AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                final screenSize = MediaQuery.of(context).size;
                final positions = [
                  Offset(screenSize.width * 0.1, screenSize.height * 0.2),
                  Offset(screenSize.width * 0.9, screenSize.height * 0.3),
                  Offset(screenSize.width * 0.2, screenSize.height * 0.8),
                  Offset(screenSize.width * 0.8, screenSize.height * 0.7),
                  Offset(screenSize.width * 0.5, screenSize.height * 0.1),
                ];

                return Positioned(
                  left: positions[index].dx,
                  top: positions[index].dy,
                  child: Opacity(
                    opacity: _backgroundOpacity.value * 0.3,
                    child: Container(
                      width: 4 + (index * 2).toDouble(),
                      height: 4 + (index * 2).toDouble(),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

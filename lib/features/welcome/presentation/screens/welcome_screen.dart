import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSkip() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.setUnderbankingUser();

    context.go('/home');
  }

  void _handleCreateAccount() {
    context.go('/auth?mode=register');
  }

  void _handleLogin() {
    context.go('/auth?mode=login');
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.neutral0,
              AppColors.neutral50,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.responsivePadding(context),
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    // Language toggle
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: _buildLanguageToggle(languageProvider),
                      ),
                    ),

                    const Spacer(flex: 1),

                    // Logo and branding
                    _buildLogo(),

                    const SizedBox(height: AppSpacing.xxl),

                    // Welcome text
                    _buildWelcomeText(languageProvider),

                    const Spacer(flex: 2),

                    // Action buttons
                    _buildActionButtons(languageProvider),

                    const SizedBox(height: AppSpacing.xxl),

                    // Skip option
                    _buildSkipOption(languageProvider),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageToggle(LanguageProvider languageProvider) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary500,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: languageProvider.toggleLanguage,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.language,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  languageProvider.currentLanguage.toUpperCase(),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary500.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'R',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFamily: AppTextStyles.fontFamily,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'RimaPay',
          style: AppTextStyles.display1.copyWith(
            color: AppColors.neutral900,
            fontSize: 32,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeText(LanguageProvider languageProvider) {
    return Column(
      children: [
        Text(
          languageProvider.t('welcome'),
          style: AppTextStyles.heading1.copyWith(
            color: AppColors.neutral900,
            // textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Your modern mobile wallet for seamless payments, transfers, and bill management.',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.neutral600,
            // textAlign: TextAlign.center,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(LanguageProvider languageProvider) {
    return Column(
      children: [
        // Create Account Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleCreateAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary500,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppColors.primary500.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.lg,
              ),
            ),
            child: Text(
              languageProvider.t('createAccount'),
              style: AppTextStyles.buttonMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Sign In Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _handleLogin,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary500,
              side: const BorderSide(color: AppColors.primary500),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.lg,
              ),
            ),
            child: Text(
              languageProvider.t('signIn'),
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.primary500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkipOption(LanguageProvider languageProvider) {
    return TextButton(
      onPressed: _handleSkip,
      child: Text(
        languageProvider.t('skipForNow'),
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.neutral500,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

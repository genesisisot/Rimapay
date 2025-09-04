import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rimapay/core/services/biometric_service.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/settings_tile.dart';
import '../../../../shared/widgets/settings_section.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update system brightness whenever dependencies change
    final themeProvider = context.read<ThemeProvider>();
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    themeProvider.updateSystemBrightness(systemBrightness);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Settings',
        onBack: () => context.go('/home'),
      ),
      body: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProvider, authProvider, child) {
          return SingleChildScrollView(
            padding:  EdgeInsets.symmetric(
              horizontal: AppSpacing.cardPadding,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Profile Section
                _buildProfileSection(authProvider)
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Appearance Section
                SettingsSection(
                  title: 'Appearance',
                  children: [
                    SettingsTile(
                      icon: _getThemeIcon(themeProvider.themeMode),
                      iconColor: AppColors.primary500,
                      title: 'Theme',
                      subtitle: themeProvider.getCurrentThemeDescription(context),
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          HapticFeedback.lightImpact();
                          themeProvider.toggleTheme();
                        },
                        activeColor: AppColors.primary500,
                        activeTrackColor: AppColors.primary200,
                        inactiveThumbColor: AppColors.neutral300,
                        inactiveTrackColor: AppColors.neutral200,
                      ),
                      onTap: () {
                        _showThemeSelector(context, themeProvider);
                      },
                    ),
                  ],
                ).animate()
                    .fadeIn(duration: 300.ms, delay: 100.ms)
                    .slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Security Section
                SettingsSection(
                  title: 'Security',
                  children: [
                    SettingsTile(
                      icon: Icons.lock_outline,
                      iconColor: AppColors.info500,
                      title: 'Change Password',
                      subtitle: 'Update your account password',
                      onTap: () {
                        _showChangePasswordDialog(context);
                      },
                    ),
                    SettingsTile(
                      icon: Icons.pin_outlined,
                      iconColor: AppColors.warning500,
                      title: 'Change PIN',
                      subtitle: 'Update your transaction PIN',
                      onTap: () {
                        _showChangePinDialog(context);
                      },
                    ),
                    SettingsTile(
                      icon: Icons.fingerprint,
                      iconColor: AppColors.success500,
                      title: 'Biometric Login',
                      subtitle: authProvider.user?.hasBiometricEnabled == true
                          ? 'Enabled'
                          : 'Disabled',
                      trailing: Switch(
                        value: authProvider.currentUser?.hasBiometricEnabled ?? false,
                        onChanged: (value) {
                          HapticFeedback.lightImpact();
                          _toggleBiometric(context, authProvider, value);
                        },
                        activeColor: AppColors.primary500,
                        activeTrackColor: AppColors.primary200,
                        inactiveThumbColor: AppColors.neutral300,
                        inactiveTrackColor: AppColors.neutral200,
                      ),
                      onTap: () {
                        _toggleBiometric(
                          context, 
                          authProvider, 
                          !(authProvider.currentUser?.hasBiometricEnabled ?? false),
                        );
                      },
                    ),
                  ],
                ).animate()
                    .fadeIn(duration: 300.ms, delay: 200.ms)
                    .slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Support Section
                SettingsSection(
                  title: 'Support',
                  children: [
                    SettingsTile(
                      icon: Icons.help_outline,
                      iconColor: AppColors.accentBlue,
                      title: 'Help & Support',
                      subtitle: 'Get help with your account',
                      onTap: () {
                        _showHelpDialog(context);
                      },
                    ),
                    SettingsTile(
                      icon: Icons.info_outline,
                      iconColor: AppColors.accentPurple,
                      title: 'About RimaPay',
                      subtitle: 'Version 1.0.0',
                      onTap: () {
                        _showAboutDialog(context);
                      },
                    ),
                    SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      iconColor: AppColors.neutral600,
                      title: 'Privacy Policy',
                      subtitle: 'Read our privacy policy',
                      onTap: () {
                        _showPrivacyPolicy(context);
                      },
                    ),
                  ],
                ).animate()
                    .fadeIn(duration: 300.ms, delay: 300.ms)
                    .slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: AppSpacing.xxxl),
                
                // Logout Button
                _buildLogoutButton(authProvider)
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 400.ms)
                    .slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: AppSpacing.space8),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileSection(AuthProvider authProvider) {
    final user = authProvider.user;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.neutral0,
              size: 30,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.firstName ?? 'User',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? 'user@example.com',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showLogoutConfirmation(context, authProvider),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error500,
          foregroundColor: AppColors.neutral0,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Sign Out',
              style: AppTextStyles.buttonMedium.copyWith(
                color: AppColors.neutral0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getThemeIcon(AppThemeMode themeMode) {
    switch (themeMode) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.auto_mode;
    }
  }

  void _showThemeSelector(BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Text(
              'Choose Theme',
              style: AppTextStyles.titleLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // Theme options
            ...AppThemeMode.values.map((mode) {
              final isSelected = themeProvider.themeMode == mode;
              return ListTile(
                leading: Icon(
                  _getThemeIcon(mode),
                  color: isSelected 
                      ? AppColors.primary500 
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                title: Text(
                  _getThemeName(mode),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                subtitle: Text(
                  _getThemeDescription(mode),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppColors.primary500)
                    : null,
                onTap: () {
                  HapticFeedback.lightImpact();
                  themeProvider.setThemeMode(mode);
                  Navigator.pop(context);
                },
              );
            }),
            
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  String _getThemeName(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }

  String _getThemeDescription(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Always use light theme';
      case AppThemeMode.dark:
        return 'Always use dark theme';
      case AppThemeMode.system:
        return 'Follow device settings';
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text('This feature will be available in the next update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showChangePinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change PIN'),
        content: const Text('This feature will be available in the next update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _toggleBiometric(BuildContext context, AuthProvider authProvider, bool enable) {
    if (enable) {
      authProvider.enableBiometric().then((success) {
        if (!success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Failed to enable biometric'),
              backgroundColor: AppColors.error500,
            ),
          );
        }
      });
    } else {
      // Disable biometric - would need to implement this in AuthProvider
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Disable Biometric'),
          content: const Text('This feature will be available in the next update.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text('For support, please contact us at support@rimapay.com'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'RimaPay',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: AppColors.primaryGradient,
        ),
        child: const Icon(
          Icons.account_balance_wallet_rounded,
          color: AppColors.neutral0,
          size: 30,
        ),
      ),
      children: [
        const Text('Your modern digital wallet for seamless payments and financial management.'),
      ],
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Your privacy is important to us. This privacy policy explains how we collect, use, and protect your information when you use RimaPay.\n\n'
            '1. Information We Collect\n'
            '2. How We Use Your Information\n'
            '3. Information Sharing\n'
            '4. Data Security\n'
            '5. Your Rights\n\n'
            'For the complete privacy policy, please visit our website.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.logout();
              if (context.mounted) {
                context.go('/welcome');
              }
            },
            child: Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error500),
            ),
          ),
        ],
      ),
    );
  }
}
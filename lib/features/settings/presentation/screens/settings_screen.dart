import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../../shared/widgets/rimapay_logo.dart';


enum SettingsModal {
  changePassword,
  changePin,
  logoutConfirm,
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> 
    with TickerProviderStateMixin {
  SettingsModal? _activeModal;
  bool _notifications = true;
  bool _biometrics = true;
  bool _darkMode = false;
  
  // Change Password States
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  
  // Change PIN States
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  
  // Success states
  bool _passwordChangeSuccess = false;
  bool _pinChangeSuccess = false;

  late AnimationController _successAnimationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _successAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    _successAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                child: Column(
                  children: [
                    ..._buildSettingsSections(),
                    const SizedBox(height: 24),
                    _buildAppVersion(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.go('/home'),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ).animate().scale(delay: 50.ms),
            
            const SizedBox(width: 12),
          const RimapayLogo(height: 30, width: 30),
            const SizedBox(width: 12),
            
            Text(
             "Settings",
              style: AppTextStyles.titleLarge.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const Spacer(),
            
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.settings,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: -0.2).fadeIn();
  }

  List<Widget> _buildSettingsSections() {
  final language = ref.watch(languageTranslationsProvider);
  _darkMode = ref.watch(themeProvider).isDarkMode;
   
    
    final settingsSections = [
      // Security Settings
      _SettingsSection(
        title: language('securitySettings'),
        items: [
          _SettingsItem(
            id: 'change-password',
            icon: Icons.lock_outline,
            title: language('changePassword'),
            subtitle: 'Update your account password',
            onTap: () => _setActiveModal(SettingsModal.changePassword),
          ),
          _SettingsItem(
            id: 'change-pin',
            icon: Icons.vpn_key_outlined,
            title: 'Change Login PIN',
            subtitle: 'Update your login PIN',
            onTap: () => _setActiveModal(SettingsModal.changePin),
          ),
          _SettingsItem(
            id: 'change-txn-pin',
            icon: Icons.lock_reset,
            title: 'Change Transaction PIN',
            subtitle: 'Update your transaction PIN',
            onTap: () => _setActiveModal(SettingsModal.changePin),
          ),
          _SettingsItem(
            id: 'reset-txn-pin',
            icon: Icons.refresh,
            title: 'Reset Transaction PIN',
            subtitle: 'Forgot your PIN? Reset it here',
            onTap: () => _showResetPinModal(),
          ),
          _SettingsItem(
            id: 'biometrics',
            icon: Icons.fingerprint,
            title: language('biometrics'),
            subtitle: 'Use fingerprint or Face ID',
            isToggle: true,
            toggleValue: _biometrics,
            onToggleChanged: (value) => setState(() => _biometrics = value),
          ),
        ],
      ),
      
      // Preferences
      _SettingsSection(
        title: language('preferences'),
        items: [
          _SettingsItem(
            id: 'dark-mode',
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            subtitle: 'Switch to dark theme',
            isToggle: true,
            toggleValue: _darkMode,
            onToggleChanged: (value) {
              HapticFeedback.lightImpact();
              ref.read(themeProvider).setThemeMode(
                value ? AppThemeMode.dark : AppThemeMode.light,
              );
            },
          ),
          _SettingsItem(
            id: 'notifications',
            icon: Icons.notifications_outlined,
            title: language('notifications'),
            subtitle: 'Get alerts for transactions',
            isToggle: true,
            toggleValue: _notifications,
            onToggleChanged: (value) => setState(() => _notifications = value),
          ),
          _SettingsItem(
            id: 'language',
            icon: Icons.language,
            title: language('language'),
            subtitle: 'English (US)',
            onTap: () => debugPrint('Language settings'),
          ),
        ],
      ),
      
      // Support
      _SettingsSection(
        title: 'Support',
        items: [
          _SettingsItem(
            id: 'account-limits',
            icon: Icons.bar_chart,
            title: 'Account Limits',
            subtitle: 'View your transaction limits',
            onTap: () => context.push('/account-limits'),
          ),
          _SettingsItem(
            id: 'help',
            icon: Icons.help_outline,
            title: language('helpSupport'),
            subtitle: 'FAQs and customer support',
            onTap: () => _showCustomerCareSheet(),
          ),
          _SettingsItem(
            id: 'contact',
            icon: Icons.headset_mic_outlined,
            title: 'Customer Care',
            subtitle: 'Call or chat with us',
            onTap: () => _showCustomerCareSheet(),
          ),
        ],
      ),

      // Account
      _SettingsSection(
        title: language('account'),
        items: [
          _SettingsItem(
            id: 'logout',
            icon: Icons.logout,
            title: language('logout'),
            subtitle: 'Sign out of your account',
            isDanger: true,
            onTap: () => _setActiveModal(SettingsModal.logoutConfirm),
          ),
        ],
      ),
    ];

    return settingsSections.asMap().entries.map((entry) {
      final index = entry.key;
      final section = entry.value;
      
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                section.title.toUpperCase(),
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: section.items.asMap().entries.map((itemEntry) {
                  final itemIndex = itemEntry.key;
                  final item = itemEntry.value;
                  final isLast = itemIndex == section.items.length - 1;
                  
                  return _buildSettingsItem(item, isLast);
                }).toList(),
              ),
            ),
          ],
        ),
      ).animate(delay: Duration(milliseconds: index * 100))
          .fadeIn(duration: 300.ms)
          .slideY(begin: 0.1);
    }).toList();
  }

  Widget _buildSettingsItem(_SettingsItem item, bool isLast) {
    return GestureDetector(
      onTap: item.isToggle ? null : item.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: isLast ? null : Border(
            bottom: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: item.isDanger 
                    ? AppColors.error500.withOpacity(0.1)
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              ),
              child: Icon(
                item.icon,
                size: 20,
                color: item.isDanger 
                    ? AppColors.error500
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: item.isDanger 
                          ? AppColors.error500
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            if (item.isToggle) ...[
              GestureDetector(
                onTap: () => item.onToggleChanged?.call(!item.toggleValue),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 48,
                  height: 24,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: item.toggleValue 
                        ? AppColors.success500 
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    alignment: item.toggleValue 
                        ? Alignment.centerRight 
                        : Alignment.centerLeft,
                    child: Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).cardColor,
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppVersion() {
    return Column(
      children: [
        Text(
          'RimaPay v2.1.0',
          style: AppTextStyles.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Built with ❤️ in Nigeria',
          style: AppTextStyles.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            fontSize: 11,
          ),
        ),
      ],
    ).animate(delay: 500.ms).fadeIn();
  }

  void _setActiveModal(SettingsModal? modal) {
    setState(() => _activeModal = modal);
    if (modal != null) {
      _showModal(modal);
    }
  }

  void _showModal(SettingsModal modal) {
    switch (modal) {
      case SettingsModal.changePassword:
        _showChangePasswordModal();
        break;
      case SettingsModal.changePin:
        _showChangePinModal();
        break;
      case SettingsModal.logoutConfirm:
        _showLogoutConfirmModal();
        break;
    }
  }

  void _showChangePasswordModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildChangePasswordModal(),
    );
  }

  void _showChangePinModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildChangePinModal(),
    );
  }

  void _showLogoutConfirmModal() {
    showDialog(
      context: context,
      builder: (context) => _buildLogoutConfirmDialog(),
    );
  }

  Widget _buildChangePasswordModal() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Text(
                  'Change Password',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _activeModal = null);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _passwordChangeSuccess
                ? _buildPasswordSuccessView()
                : _buildPasswordForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success500.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.check_circle,
                size: 32,
                color: AppColors.success500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Password Changed Successfully',
            style: AppTextStyles.titleMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your account password has been updated',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordForm() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildPasswordField(
            'Current Password',
            _currentPasswordController,
            _showCurrentPassword,
            (show) => setState(() => _showCurrentPassword = show),
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            'New Password',
            _newPasswordController,
            _showNewPassword,
            (show) => setState(() => _showNewPassword = show),
            hint: 'Must be at least 8 characters long',
          ),
          const SizedBox(height: 16),
          _buildPasswordField(
            'Confirm Password',
            _confirmPasswordController,
            _showConfirmPassword,
            (show) => setState(() => _showConfirmPassword = show),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPasswordValid ? _handleChangePassword : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPasswordValid 
                    ? AppColors.success500 
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Change Password',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool showPassword,
    ValueChanged<bool> onToggleVisibility, {
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !showPassword,
          decoration: InputDecoration(
            hintText: showPassword ? 'Enter ${label.toLowerCase()}' : '••••••••',
            suffixIcon: IconButton(
              icon: Icon(
                showPassword ? Icons.visibility_off : Icons.visibility,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              onPressed: () => onToggleVisibility(!showPassword),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.success500),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(
            hint,
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChangePinModal() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Text(
                  'Change PIN',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _activeModal = null);
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _pinChangeSuccess
                ? _buildPinSuccessView()
                : _buildPinForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildPinSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success500.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.check_circle,
                size: 32,
                color: AppColors.success500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'PIN Changed Successfully',
            style: AppTextStyles.titleMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transaction PIN has been updated',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinForm() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildPinField('Current PIN', _currentPinController),
          const SizedBox(height: 16),
          _buildPinField('New PIN', _newPinController, hint: 'Must be exactly 4 digits'),
          const SizedBox(height: 16),
          _buildPinField('Confirm PIN', _confirmPinController),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPinValid ? _handleChangePin : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPinValid 
                    ? AppColors.success500 
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Change PIN',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinField(String label, TextEditingController controller, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'monospace',
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            hintText: '••••',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              letterSpacing: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.success500),
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(
            hint,
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLogoutConfirmDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.all(32),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.error500.withOpacity(0.1),
            ),
            child: const Icon(
              Icons.logout,
              size: 32,
              color: AppColors.error500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Logout Confirmation',
            style: AppTextStyles.titleMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Are you sure you want to logout from your RimaPay account?',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _activeModal = null);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(
                      color: Theme.of(context).dividerColor.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _handleLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool get _isPasswordValid {
    return _currentPasswordController.text.length >= 8 &&
           _newPasswordController.text.length >= 8 &&
           _newPasswordController.text == _confirmPasswordController.text;
  }

  bool get _isPinValid {
    return _currentPinController.text.length == 4 &&
           _newPinController.text.length == 4 &&
           _newPinController.text == _confirmPinController.text;
  }

  void _handleChangePassword() {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Passwords do not match');
      return;
    }
    if (_newPasswordController.text.length < 8) {
      _showErrorSnackBar('Password must be at least 8 characters long');
      return;
    }

    // Simulate API call
    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() => _passwordChangeSuccess = true);
      _successAnimationController.forward();
      
      Future.delayed(const Duration(milliseconds: 2000), () {
        Navigator.pop(context);
        setState(() {
          _activeModal = null;
          _passwordChangeSuccess = false;
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        });
        _successAnimationController.reset();
      });
    });
  }

  void _handleChangePin() {
    if (_newPinController.text != _confirmPinController.text) {
      _showErrorSnackBar('PINs do not match');
      return;
    }
    if (_newPinController.text.length != 4) {
      _showErrorSnackBar('PIN must be 4 digits');
      return;
    }

    // Simulate API call
    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() => _pinChangeSuccess = true);
      _successAnimationController.forward();
      
      Future.delayed(const Duration(milliseconds: 2000), () {
        Navigator.pop(context);
        setState(() {
          _activeModal = null;
          _pinChangeSuccess = false;
          _currentPinController.clear();
          _newPinController.clear();
          _confirmPinController.clear();
        });
        _successAnimationController.reset();
      });
    });
  }

  void _handleLogout() {
    Navigator.pop(context); // Close dialog
    setState(() => _activeModal = null);
    
    // Perform logout
    final authProvider = context.read<AuthProvider>();
    authProvider.logout().then((_) {
      if (mounted) {
        context.go('/welcome');
      }
    });
  }

  void _showCustomerCareSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(999)),
            ),
            Text('Customer Care',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 6),
            Text('We\'re here to help you',
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
            const SizedBox(height: 24),
            _careOption(Icons.phone_outlined, 'Call Us',
                '0800-RIMAPAY (0800-7462729)', const Color(0xFF1A6B35)),
            const SizedBox(height: 12),
            _careOption(Icons.chat_bubble_outline, 'WhatsApp',
                '+234 800 746 2729', const Color(0xFF25D366)),
            const SizedBox(height: 12),
            _careOption(Icons.mail_outline, 'Email',
                'support@rimamfb.ng', const Color(0xFF3B82F6)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Mon – Fri: 8am – 8pm\nSat: 9am – 5pm',
                      style: TextStyle(
                          fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _careOption(IconData icon, String title, String detail, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: color)),
              Text(detail,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
            ],
          ),
        ],
      ),
    );
  }

  void _showResetPinModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reset Transaction PIN',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              Text(
                'An OTP will be sent to your registered phone number to reset your transaction PIN.',
                style: TextStyle(
                    fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), height: 1.5),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('OTP sent to your registered number'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF1A6B35),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A6B35),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Send OTP',
                      style: TextStyle(
                          color: Theme.of(context).cardColor, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

// Helper classes for settings structure
class _SettingsSection {
  final String title;
  final List<_SettingsItem> items;

  _SettingsSection({
    required this.title,
    required this.items,
  });
}

class _SettingsItem {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isToggle;
  final bool toggleValue;
  final bool isDanger;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggleChanged;

  _SettingsItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isToggle = false,
    this.toggleValue = false,
    this.isDanger = false,
    this.onTap,
    this.onToggleChanged,
  });
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/localization/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final appState = context.watch<AppStateProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(localizations, user, appState),
                  const SizedBox(height: 24),
                  _buildAccountSection(localizations, user, appState),
                  const SizedBox(height: 24),
                  _buildServicesSection(localizations, appState),
                  const SizedBox(height: 24),
                  _buildSupportSection(localizations, appState),
                  const SizedBox(height: 24),
                  _buildLogoutButton(localizations, appState, authProvider),
                  const SizedBox(height: 100), // Bottom padding for navigation
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AppLocalizations localizations, User? user, AppStateProvider appState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  appState.navigateToHome();
                 // appState.setActiveTab('home');
                },
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  // Handle edit profile
                },
                icon: const Icon(
                  Icons.edit,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Profile Avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: user?.profileImageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          user!.profileImageUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Text(
                        user?.firstName?.split(' ').map((word) => word.isNotEmpty ? word[0] : '').join('').toUpperCase() ?? 'U',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary500, width: 2),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: AppColors.primary500,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // User Info
          Text(
            user?.firstName ?? 'User',
            style: AppTextStyles.heading4.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? 'user@email.com',
            style: AppTextStyles.body2.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          
          // Account Tier Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getTierIcon(user?.accountType),
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _getTierDisplayName(user?.accountType),
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(AppLocalizations localizations, User? user, AppStateProvider appState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('accountInformation'),
            style: AppTextStyles.h6.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow(
            localizations.translate("phoneNumber"),
            user?.phoneNumber ?? '+234 XXX XXX XXXX',
            Icons.phone,
          ),
          const Divider(height: 24),
          
          _buildInfoRow(
            localizations.translate("accountNumber"),
             'XXXXXXXXXX',
            Icons.account_balance,
          ),
          const Divider(height: 24),
          
          _buildInfoRow(
            localizations.translate('accountType'),
            _getTierDisplayName(user?.accountType),
            Icons.account_circle,
          ),
          const Divider(height: 24),
          
          InkWell(
            onTap: () {
              //appState.navigateto;
            },
            child: _buildInfoRow(
              localizations.translate('upgradeTier'),
              localizations.translate('viewAccountTiers'),
              Icons.trending_up,
              showArrow: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection(AppLocalizations localizations, AppStateProvider appState) {
    final services = [
      {
        'title': localizations.translate('transactionHistory'),
        'subtitle': localizations.translate('viewAllTransactions'),
        'icon': Icons.receipt_long,
        'onTap': () {
          appState.navigateToTransactions();
          //appState. setActiveTab('transactions');
        },
      },
      {
        'title': localizations.translate('cardManagement'),
        'subtitle': localizations.translate('manageYourCards'),
        'icon': Icons.credit_card,
        'onTap': () {
          appState.navigateToCards();
          //appState.setActiveTab('cards');
        },
      },
      {
        'title': localizations.translate('savedBeneficiaries'),
        'subtitle': localizations.translate('manageBeneficiaries'),
        'icon': Icons.people,
        'onTap': () {
          // Handle saved beneficiaries
        },
      },
      {
        'title': localizations.translate('securitySettings'),
        'subtitle': localizations.translate('pinAndBiometric'),
        'icon': Icons.security,
        'onTap': () {
          // Handle security settings
        },
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('services'),
            style: AppTextStyles.h6.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          
          ...services.asMap().entries.map((entry) {
            final index = entry.key;
            final service = entry.value;
            return Column(
              children: [
                if (index > 0) const Divider(height: 24),
                InkWell(
                  onTap: service['onTap'] as VoidCallback,
                  child: _buildServiceRow(
                    service['title'] as String,
                    service['subtitle'] as String,
                    service['icon'] as IconData,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSupportSection(AppLocalizations localizations, AppStateProvider appState) {
    final supportOptions = [
      {
        'title': "Help & Support",
        'subtitle': localizations.translate('getHelpOrSupport'),
        'icon': Icons.help_outline,
        'onTap': () {
          // Handle help & support
        },
      },
      {
        'title': localizations.settings,
        'subtitle': localizations.translate('appPreferences'),
        'icon': Icons.settings,
        'onTap': () {
          appState.navigateToSettings();
        },
      },
      {
        'title': localizations.translate('rateApp'),
        'subtitle': localizations.translate('rateUsOnStore'),
        'icon': Icons.star_outline,
        'onTap': () {
          // Handle rate app
        },
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('supportAndMore'),
            style: AppTextStyles.h6.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          
          ...supportOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            return Column(
              children: [
                if (index > 0) const Divider(height: 24),
                InkWell(
                  onTap: option['onTap'] as VoidCallback,
                  child: _buildServiceRow(
                    option['title'] as String,
                    option['subtitle'] as String,
                    option['icon'] as IconData,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {bool showArrow = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary500.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary500,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (showArrow)
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.neutral400,
          ),
      ],
    );
  }

  Widget _buildServiceRow(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.neutral600,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.neutral600,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.neutral400,
        ),
      ],
    );
  }

  Widget _buildLogoutButton(AppLocalizations localizations, AppStateProvider appState, AuthProvider authProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(localizations, appState, authProvider),
        icon: const Icon(
          Icons.logout,
          color: Colors.red,
        ),
        label: Text(
          "Logout",
          style: AppTextStyles.buttonMedium.copyWith(
            color: Colors.red,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  IconData _getTierIcon(AccountType? accountType) {
    switch (accountType) {
      case AccountType.basic:
        return Icons.person;
      case AccountType.business:
        return Icons.business;
      case AccountType.underbanking:
        return Icons.account_balance_wallet;
      default:
        return Icons.account_circle;
    }
  }

  String _getTierDisplayName(AccountType? accountType) {
    switch (accountType) {
      case AccountType.basic:
        return 'Personal Account';
      case AccountType.business:
        return 'Business Account';
      case AccountType.underbanking:
        return 'Underbanking Account';
      default:
        return 'Basic Account';
    }
  }

  void _showLogoutDialog(AppLocalizations localizations, AppStateProvider appState, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Logout"),
          content: Text(localizations.translate('logoutConfirmation')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                authProvider.logout();
                appState.navigateToHome();
               // appState.setActiveTab('home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text(
              "Logout",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
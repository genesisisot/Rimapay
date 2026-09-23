import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rimapay/core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart' hide Consumer;
import '../../../../core/providers/theme_provider.dart';
import '../../../../shared/widgets/noise_painter.dart';
import '../providers/profile_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../auth/data/auth_api_service.dart';
import '../../../auth/data/auth_dtos.dart';
import '../../../security/data/pin_api_service.dart';
import '../../../security/data/pin_dtos.dart' as pindto;
import '../../../../core/services/biometric_service.dart';
import '../../../../core/services/secure_store.dart';
import '../../../../core/Utils/haptics.dart';
import '../../../../shared/widgets/bill_screen_widgets.dart' show showPinConfirmSheet;

import '../../../../core/localization/l10n.dart';
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with TickerProviderStateMixin {
  String? _profileImage;
  bool _isEditing = false;
  bool _showImageOptions = false;

  final _imagePicker = ImagePicker();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  // Password change
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _passwordChangeSuccess = false;
  bool _passwordChangeLoading = false;
  String? _passwordChangeError;
  late AnimationController _successAnimController;
  late Animation<double> _scaleAnim;

  final Map<String, String> _data = {
    'fullName': '',
    'phone': '',
    'email': '',
    'gender': '',
    'dateOfBirth': '',
  };

  // Biometric settings (Profile › Security)
  bool _bioLogin = false;
  bool _bioTxn = false;
  bool _bioBusy = false;

  // Tier info
  static const _tierName = 'Basic Tier';
  static const _tierLevel = 'basic';

  @override
  void initState() {
    super.initState();
    _successAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successAnimController, curve: Curves.elasticOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).fetchCompletionStatus();
      _loadUserData();
      _fetchProfile();
      _loadBiometricPrefs();
    });
  }

  Future<void> _loadBiometricPrefs() async {
    final login = await SecureStore.isBiometricLoginEnabled();
    final txn = await SecureStore.isBiometricTxnEnabled();
    if (mounted) {
      setState(() {
        _bioLogin = login;
        _bioTxn = txn;
      });
    }
  }

  void _loadUserData() {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user != null) {
      final name = user.displayName;
      _nameController.text = name;
      _data['fullName'] = name;
      _data['phone'] = user.phoneNumber ?? '';
      _data['email'] = user.email;
      _emailController.text = user.email;
    }
  }

  Future<void> _fetchProfile() async {
    final ok = await ref.read(profileProvider.notifier).fetchMyProfile();
    if (ok && mounted) {
      final profile = ref.read(profileProvider).profile;
      if (profile != null) {
        setState(() {
          final name = [profile.firstName, profile.lastName]
              .where((s) => s != null && s.isNotEmpty)
              .join(' ');
          if (name.isNotEmpty) {
            _data['fullName'] = name;
            _nameController.text = name;
          }
          if (profile.email != null && profile.email!.isNotEmpty) {
            _data['email'] = profile.email!;
            _emailController.text = profile.email!;
          }
          if (profile.phoneNumber != null && profile.phoneNumber!.isNotEmpty) {
            _data['phone'] = profile.phoneNumber!;
          }
          _data['gender'] = profile.gender ?? _data['gender']!;
          _data['dateOfBirth'] = profile.dateOfBirth ?? _data['dateOfBirth']!;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _successAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(context),
              SliverToBoxAdapter(child: _buildBody(context)),
            ],
          ),
          if (_showImageOptions) _buildImageModal(),
        ],
      ),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      expandedHeight: 200,
      pinned: true,
      automaticallyImplyLeading: false,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final collapsed = constraints.maxHeight <=
              kToolbarHeight + MediaQuery.of(context).padding.top + 2;
          return Stack(
            fit: StackFit.expand,
            children: [
              // Green gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF073D25),
                      Color(0xFF0B4F2F),
                      Color(0xFF073D25),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // Noise texture
              Positioned.fill(
                child: CustomPaint(
                  painter: NoisePainter(opacity: 0.045, seed: 5),
                ),
              ),
              // Back button
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/home'),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 17),
                  ),
                ),
              ),
              // Title
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(context.l10n.profile,
                    style: TextStyle(
                      color: Colors.white.withOpacity(collapsed ? 1.0 : 0.0),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Effra',
                    ),
                  ),
                ),
              ),
              // Avatar — only show when expanded
              if (!collapsed)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Transform.translate(
                    offset: const Offset(0, 40),
                    child: _buildAvatar(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _isEditing ? () => setState(() => _showImageOptions = true) : null,
      child: Stack(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.goldGradient,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: _profileImage != null
                  ? Image.file(File(_profileImage!),
                      width: 88, height: 88, fit: BoxFit.cover)
                  : Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                      ),
                      child: Icon(Icons.person,
                          color: Colors.white, size: 40),
                    ),
            ),
          ),
          if (_isEditing)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Color(0xFF166C46),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.camera_alt, color: Colors.white, size: 13),
              ),
            ),
        ],
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
      child: Column(
        children: [
          // Name + tier badge
          _buildNameSection(),
          const SizedBox(height: 20),

          // Complete Profile Section (if profile not fully completed)
          if (!ref.watch(profileProvider).addressCompleted ||
              !ref.watch(profileProvider).pepCompleted ||
              !ref.watch(profileProvider).sourceOfIncomeCompleted)
            _buildCompleteProfileSection(context),

          // Account tier card
          _buildTierCard(context),
          const SizedBox(height: 16),

          // Info cards
          _buildInfoCard(
            icon: Icons.phone_outlined,
            iconColor: const Color(0xFF166C46),
            bgColor: const Color(0xFFF2F7F3),
            label: context.l10n.phoneNumber2,
            value: _data['phone']!,
            subtitle: context.l10n.registeredNumberCanTBeChanged,
          ),
          const SizedBox(height: 10),
          _buildInfoCard(
            icon: Icons.email_outlined,
            iconColor: const Color(0xFF8B5CF6),
            bgColor: const Color(0xFFF5F3FF),
            label: context.l10n.emailAddress,
            value: _isEditing ? _emailController.text : _data['email']!,
            editable: true,
            controller: _emailController,
          ),
          const SizedBox(height: 10),
          _buildInfoCard(
            icon: Icons.person_outline,
            iconColor: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFEFF6FF),
            label: context.l10n.gender2,
            value: _data['gender']!.isNotEmpty ? _data['gender']! : 'Not set',
          ),
          const SizedBox(height: 10),
          _buildInfoCard(
            icon: Icons.calendar_today_outlined,
            iconColor: const Color(0xFFEC4899),
            bgColor: const Color(0xFFFDF2F8),
            label: context.l10n.dateOfBirth2,
            value: _data['dateOfBirth']!.isNotEmpty ? _data['dateOfBirth']! : 'Not set',
          ),
          const SizedBox(height: 20),

          // Edit / Save-Cancel buttons
          _buildEditButtons(),
          const SizedBox(height: 12),

          // Dark mode
          const SizedBox(height: 4),
          Consumer(
            builder: (_, ref, __) {
              final darkMode = ref.watch(themeProvider).isDarkMode;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.dark_mode,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), size: 20),
                    const SizedBox(width: 12),
                    Text(context.l10n.darkMode,
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
                    const Spacer(),
                    Switch(
                      value: darkMode,
                      onChanged: (value) {
                        HapticFeedback.lightImpact();
                        ref.read(themeProvider).setThemeMode(
                          value ? AppThemeMode.dark : AppThemeMode.light,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Security section
          _buildSecuritySection(context),
          const SizedBox(height: 12),

          // Logout
          _buildLogoutButton(context),
          const SizedBox(height: 12),

          // Delete Account
          _buildDeleteAccountButton(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildNameSection() {
    return Column(
      children: [
        _isEditing
            ? SizedBox(
                width: 220,
                child: TextField(
                  controller: _nameController,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: 'Effra',
                  ),
                  decoration: InputDecoration(
                    border: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF166C46), width: 2),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Color(0xFF166C46), width: 2),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).dividerColor, width: 1),
                    ),
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              )
            : Text(
                _nameController.text,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: 'Effra',
                ),
              ),
        const SizedBox(height: 6),
        Text(
          _data['phone']!,
          style: TextStyle(
              fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontFamily: 'Effra'),
        ),
        const SizedBox(height: 8),
        // Tier badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF166C46).withOpacity(0.1),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF166C46).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.star_rounded, color: Color(0xFF166C46), size: 12),
              SizedBox(width: 4),
              Text(
                _tierName,
                style: TextStyle(
                  color: Color(0xFF166C46),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Effra',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteProfileSection(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final addressDone = profileState.addressCompleted;
    final pepDone = profileState.pepCompleted;
    final incomeDone = profileState.sourceOfIncomeCompleted;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_note,
                    color: Color(0xFF16A34A), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(context.l10n.completeYourProfile,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Residential Address
          _buildProfileItem(
            icon: Icons.home_outlined,
            title: context.l10n.residentialAddress,
            isCompleted: addressDone,
            onTap: () => _navigateToProfileStep(context, 'residentialAddress'),
          ),
          const SizedBox(height: 12),
          // PEP Declaration
          _buildProfileItem(
            icon: Icons.verified_outlined,
            title: context.l10n.pepDeclaration,
            isCompleted: pepDone,
            onTap: () => _navigateToProfileStep(context, 'pepDeclaration'),
          ),
          const SizedBox(height: 12),
          // Source of Income
          _buildProfileItem(
            icon: Icons.work_outline,
            title: context.l10n.sourceOfIncome,
            isCompleted: incomeDone,
            onTap: () => _navigateToProfileStep(context, 'sourceOfIncome'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isCompleted ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isCompleted ? Color(0xFFF0FDF4) : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isCompleted ? Color(0xFFBBF7D0) : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFF16A34A).withOpacity(0.1)
                    : Theme.of(context).dividerColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check : icon,
                color: isCompleted
                    ? const Color(0xFF16A34A)
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.55),
                size: isCompleted ? 18 : 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isCompleted
                      ? const Color(0xFF166534)
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color:
                    isCompleted ? const Color(0xFF16A34A) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFF16A34A)
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProfileStep(BuildContext context, String step) async {
    final pathMap = {
      'residentialAddress': '/residential-address',
      'pepDeclaration': '/pep-declaration',
      'sourceOfIncome': '/source-of-income',
    };
    final path = pathMap[step];
    if (path == null) return;

    await context.push<bool>(path);
    if (!mounted) return;

    final profileState = ref.read(profileProvider);
    final allCompleted = profileState.addressCompleted &&
        profileState.pepCompleted &&
        profileState.sourceOfIncomeCompleted;
    if (allCompleted) {
      _showProfileCompleteSuccess(context);
    }
  }

  void _showProfileCompleteSuccess(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: Color(0xFF16A34A), size: 32),
            ),
            const SizedBox(height: 16),
            Text(context.l10n.profileCompleted,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'Effra',
              ),
            ),
            const SizedBox(height: 8),
            Text(context.l10n.yourProfileIsNowFullyComplete,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                height: 1.4,
                fontFamily: 'Effra',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF166C46),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(context.l10n.great,
                    style: TextStyle(
                        fontFamily: 'Effra', fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushNamed('tiers'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF073D25), Color(0xFF0B4F2F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF166C46).withOpacity(0.2),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.star_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.currentTier2,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      fontFamily: 'Effra',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _tierName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: 'Effra',
                    ),
                  ),
                  Text(context.l10n.balance20000Per50000,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.6),
                      fontFamily: 'Effra',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF166C46),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(context.l10n.upgrade,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Effra',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String value,
    String? subtitle,
    bool editable = false,
    TextEditingController? controller,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? iconColor.withOpacity(0.15)
                  : bgColor,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    fontFamily: 'Effra',
                  ),
                ),
                const SizedBox(height: 3),
                if (_isEditing && editable && controller != null)
                  TextField(
                    controller: controller,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontFamily: 'Effra',
                    ),
                    decoration: InputDecoration(
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF166C46)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFF166C46), width: 2),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  )
                else
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontFamily: 'Effra',
                    ),
                  ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      height: 1.3,
                      fontFamily: 'Effra',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButtons() {
    if (!_isEditing) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: () => setState(() => _isEditing = true),
          icon: const Icon(Icons.edit_outlined, size: 17),
          label: Text(context.l10n.editProfile,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Effra'),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            side: BorderSide(color: Theme.of(context).dividerColor),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _nameController.text = _data['fullName']!;
                  _emailController.text = _data['email']!;
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                side: BorderSide(color: Theme.of(context).dividerColor),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(context.l10n.cancel,
                  style: TextStyle(
                      fontFamily: 'Effra', fontWeight: FontWeight.w600)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _isEditing = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.profileUpdated),
                    backgroundColor: Color(0xFF166C46),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF166C46),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(context.l10n.saveChanges,
                  style: TextStyle(
                      fontFamily: 'Effra', fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Security Section ──────────────────────────────────────────────────────

  Widget _buildSecuritySection(BuildContext context) {
    final items = [
      _SecurityItem(
        Icons.lock_outline,
        'Change Password',
        'Update your account password',
        _showChangePasswordModal,
      ),
      _SecurityItem(
        Icons.pin_outlined,
        'Reset Transaction PIN',
        'Forgot your PIN? Reset it with an OTP',
        () => context.push('/security/reset-pin'),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(context.l10n.security2,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                fontFamily: 'Effra',
              ),
            ),
          ),
          ...items.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            final isLast = i == items.length - 1;
            return GestureDetector(
              onTap: item.onTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor.withOpacity(0.5),
                          ),
                        ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF166C46).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: const Color(0xFF166C46), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontFamily: 'Effra',
                              )),
                          Text(item.subtitle,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                fontFamily: 'Effra',
                              )),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                  ],
                ),
              ),
            );
          }),
          Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.5)),
          _biometricRow(
            context,
            icon: Icons.fingerprint,
            title: context.l10n.biometricLogin,
            subtitle: context.l10n.signInWithFingerprintOrFace,
            value: _bioLogin,
            onChanged: (v) => _toggleBiometric(forLogin: true, enable: v),
          ),
          Divider(
              height: 1,
              indent: 64,
              color: Theme.of(context).dividerColor.withOpacity(0.5)),
          _biometricRow(
            context,
            icon: Icons.verified_user_outlined,
            title: context.l10n.biometricForTransactions,
            subtitle: context.l10n.approvePaymentsWithoutTypingYourPin,
            value: _bioTxn,
            onChanged: (v) => _toggleBiometric(forLogin: false, enable: v),
          ),
        ],
      ),
    );
  }

  Widget _biometricRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF166C46).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF166C46), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontFamily: 'Effra',
                    )),
                Text(subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      fontFamily: 'Effra',
                    )),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: const Color(0xFF166C46),
            onChanged: _bioBusy ? null : onChanged,
          ),
        ],
      ),
    );
  }

  void _bioSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? const Color(0xFFD33B31) : const Color(0xFF166C46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  /// Turning off is immediate. Turning on needs: biometrics set up on the
  /// phone → transaction PIN verified by the API → a fingerprint check.
  Future<void> _toggleBiometric({required bool forLogin, required bool enable}) async {
    Haptics.tap();
    if (_bioBusy) return;

    if (!enable) {
      if (forLogin) {
        await SecureStore.setBiometricLogin(false);
      } else {
        await SecureStore.setBiometricTxn(false);
      }
      if (!mounted) return;
      setState(() {
        if (forLogin) {
          _bioLogin = false;
        } else {
          _bioTxn = false;
        }
      });
      return;
    }

    if (!await BiometricService.isAvailable() || !await BiometricService.isEnabled()) {
      _bioSnack('Set up fingerprint or face unlock on this phone first.', error: true);
      return;
    }
    if (!mounted) return;

    showPinConfirmSheet(
      context: context,
      title: forLogin ? 'Enable Biometric Login' : 'Enable Biometric Payments',
      allowBiometric: false,
      summary: [
        {
          'label': 'Action',
          'value': forLogin ? 'Log in with biometrics' : 'Approve payments with biometrics',
        },
      ],
      onConfirmed: (enteredPin) async {
        Navigator.pop(context); // close PIN sheet
        setState(() => _bioBusy = true);

        final res = await PinApiService()
            .verifyPin(pindto.VerifyPinRequest(pin: enteredPin));
        if (!mounted) return;
        if (!res.isSuccess) {
          setState(() => _bioBusy = false);
          Haptics.error();
          _bioSnack(res.message ?? 'Incorrect PIN. Please try again.', error: true);
          return;
        }

        final bio = await BiometricService.authenticateWithResult(forLogin
            ? 'Confirm to enable biometric login'
            : 'Confirm to enable biometric payments');
        if (!mounted) return;
        if (bio != AuthResult.success) {
          setState(() => _bioBusy = false);
          _bioSnack(BiometricService.getAuthResultMessage(bio), error: true);
          return;
        }

        if (forLogin) {
          final user = context.read<AuthProvider>().user;
          await SecureStore.setBiometricLogin(true, user: user?.toJson());
        } else {
          await SecureStore.setBiometricTxn(true, pin: enteredPin);
        }
        if (!mounted) return;
        Haptics.success();
        setState(() {
          _bioBusy = false;
          if (forLogin) {
            _bioLogin = true;
          } else {
            _bioTxn = true;
          }
        });
        _bioSnack(forLogin ? 'Biometric login enabled' : 'Biometric payments enabled');
      },
    );
  }

  void _showChangePasswordModal() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _passwordChangeSuccess = false;
      _passwordChangeLoading = false;
      _passwordChangeError = null;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          bool isPasswordValid() =>
              _currentPasswordController.text.length >= 8 &&
              _newPasswordController.text.length >= 8 &&
              _newPasswordController.text == _confirmPasswordController.text;

          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: _passwordChangeSuccess
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleTransition(
                          scale: _scaleAnim,
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF16A34A).withOpacity(0.1),
                            ),
                            child: const Icon(Icons.check_circle,
                                size: 32, color: Color(0xFF16A34A)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(context.l10n.passwordChanged,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontFamily: 'Effra',
                            )),
                        const SizedBox(height: 6),
                        Text(context.l10n.yourPasswordHasBeenUpdated,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            )),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Text(context.l10n.changePassword,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontFamily: 'Effra',
                                )),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => Navigator.pop(ctx),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                                ),
                                child: Icon(Icons.close,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              _passwordField('Current Password', _currentPasswordController, setModalState),
                              const SizedBox(height: 14),
                              _passwordField('New Password', _newPasswordController, setModalState, hint: 'Minimum 8 characters'),
                              const SizedBox(height: 14),
                              _passwordField('Confirm New Password', _confirmPasswordController, setModalState),
                              if (_passwordChangeError != null) ...[
                                const SizedBox(height: 10),
                                Text(_passwordChangeError!,
                                    style: const TextStyle(color: Color(0xFFD33B31), fontSize: 12)),
                              ],
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: (isPasswordValid() && !_passwordChangeLoading)
                                      ? () async {
                                          setModalState(() {
                                            _passwordChangeLoading = true;
                                            _passwordChangeError = null;
                                          });
                                          try {
                                            final api = AuthApiService();
                                            final req = ChangePasswordRequest(
                                              currentPassword: _currentPasswordController.text,
                                              newPassword: _newPasswordController.text,
                                              confirmPassword: _confirmPasswordController.text,
                                            );
                                            final res = await api.changePassword(req);
                                            if (!ctx.mounted) return;
                                            if (res.isSuccess) {
                                              setModalState(() {
                                                _passwordChangeSuccess = true;
                                                _passwordChangeLoading = false;
                                              });
                                              _successAnimController.forward(from: 0);
                                              Future.delayed(const Duration(seconds: 2), () {
                                                if (mounted) Navigator.pop(ctx);
                                              });
                                            } else {
                                              setModalState(() {
                                                _passwordChangeError = res.errorMessage;
                                                _passwordChangeLoading = false;
                                              });
                                            }
                                          } catch (e) {
                                            setModalState(() {
                                              _passwordChangeError = 'Something went wrong. Please try again.';
                                              _passwordChangeLoading = false;
                                            });
                                          }
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF166C46),
                                    disabledBackgroundColor: Theme.of(context).dividerColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: _passwordChangeLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2, color: Colors.white))
                                      : Text(context.l10n.changePassword,
                                          style: TextStyle(
                                              fontFamily: 'Effra', fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _passwordField(String label, TextEditingController controller, StateSetter setModalState, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontFamily: 'Effra',
            )),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: true,
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(fontSize: 15, fontFamily: 'Effra'),
          decoration: InputDecoration(
            hintText: hint ?? '',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF166C46), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          ),
          onChanged: (_) => setModalState(() {}),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: Text(context.l10n.logOut,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Effra'),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFEF2F2),
          foregroundColor: const Color(0xFFDC2626),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: Color(0xFFFECACA)),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded,
                  color: Color(0xFFDC2626), size: 28),
            ),
            const SizedBox(height: 16),
            Text(context.l10n.logOut2,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'Effra',
              ),
            ),
            const SizedBox(height: 8),
            Text(context.l10n.areYouSureYouWantTo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                height: 1.4,
                fontFamily: 'Effra',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(context.l10n.cancel,
                          style: TextStyle(
                              fontFamily: 'Effra',
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.go('/welcome');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(context.l10n.logOut,
                          style: TextStyle(
                              fontFamily: 'Effra',
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete Account ───────────────────────────────────────────────────────

  Widget _buildDeleteAccountButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () => _confirmDeleteAccount(context),
        icon: const Icon(Icons.delete_forever_rounded, size: 18),
        label: Text(context.l10n.deleteAccount,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Effra'),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFEF2F2),
          foregroundColor: const Color(0xFFDC2626),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: Color(0xFFFECACA)),
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded,
                  color: Color(0xFFDC2626), size: 28),
            ),
            const SizedBox(height: 16),
            Text(context.l10n.deleteAccount2,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'Effra',
              ),
            ),
            const SizedBox(height: 8),
            Text(context.l10n.thisWillPermanentlyDeleteYourAccount,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                height: 1.4,
                fontFamily: 'Effra',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(context.l10n.cancel,
                          style: TextStyle(
                              fontFamily: 'Effra',
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final res = await AuthProvider().deleteAccount();
                        if (res.isSuccess && context.mounted) {
                          context.go('/welcome');
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res.message ?? 'Failed to delete account'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(context.l10n.delete,
                          style: TextStyle(
                              fontFamily: 'Effra',
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Image picker modal ────────────────────────────────────────────────────

  Widget _buildImageModal() {
    return Material(
      color: Colors.black54,
      child: GestureDetector(
        onTap: () => setState(() => _showImageOptions = false),
        child: Container(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.changePhoto,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: 'Effra',
                  ),
                ),
                const SizedBox(height: 16),
                _imageOption(Icons.camera_alt_outlined, 'Take Photo',
                    () => _pickImage(ImageSource.camera)),
                const SizedBox(height: 10),
                _imageOption(
                    Icons.photo_library_outlined,
                    'Choose from Gallery',
                    () => _pickImage(ImageSource.gallery)),
                if (_profileImage != null) ...[
                  const SizedBox(height: 10),
                  _imageOption(
                      Icons.delete_outline, 'Remove Photo', _removeImage,
                      destructive: true),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => setState(() => _showImageOptions = false),
                    style: TextButton.styleFrom(
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(context.l10n.cancel,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontFamily: 'Effra',
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageOption(IconData icon, String label, VoidCallback onTap,
      {bool destructive = false}) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon,
            color:
                destructive ? Color(0xFFDC2626) : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            size: 18),
        label: Text(
          label,
          style: TextStyle(
            color:
                destructive ? Color(0xFFDC2626) : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            fontWeight: FontWeight.w600,
            fontFamily: 'Effra',
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor:
              destructive ? Color(0xFFFEF2F2) : Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() {
          _profileImage = image.path;
          _showImageOptions = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.errorPickingImageE(e))),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _profileImage = null;
      _showImageOptions = false;
    });
  }
}

class _SecurityItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _SecurityItem(this.icon, this.title, this.subtitle, this.onTap);
}

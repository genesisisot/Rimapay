import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rimapay/core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../shared/widgets/noise_painter.dart';
import '../providers/profile_provider.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/providers/auth_provider.dart';

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
  final _nameController = TextEditingController(text: 'Adebayo Johnson');
  final _emailController =
      TextEditingController(text: 'adebayo.johnson@mail.com');

  // PIN management
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _pinChangeSuccess = false;
  late AnimationController _successAnimController;
  late Animation<double> _scaleAnim;

  final Map<String, String> _data = {
    'fullName': 'Adebayo Johnson',
    'phone': '08137954069',
    'email': 'adebayo.johnson@mail.com',
    'gender': 'Male',
    'dateOfBirth': '15th Feb, 1995',
  };

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
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
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
                        color: Theme.of(context).cardColor, size: 17),
                  ),
                ),
              ),
              // Title
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Profile',
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
              border: Border.all(color: Theme.of(context).cardColor, width: 3),
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
                          color: Theme.of(context).cardColor, size: 40),
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
                    Icon(Icons.camera_alt, color: Theme.of(context).cardColor, size: 13),
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
            label: 'PHONE NUMBER',
            value: _data['phone']!,
            subtitle:
                "Registered number — can't be changed. Others find you by this.",
          ),
          const SizedBox(height: 10),
          _buildInfoCard(
            icon: Icons.email_outlined,
            iconColor: const Color(0xFF8B5CF6),
            bgColor: const Color(0xFFF5F3FF),
            label: 'EMAIL ADDRESS',
            value: _isEditing ? _emailController.text : _data['email']!,
            editable: true,
            controller: _emailController,
          ),
          const SizedBox(height: 10),
          _buildInfoCard(
            icon: Icons.person_outline,
            iconColor: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFEFF6FF),
            label: 'GENDER',
            value: _data['gender']!,
          ),
          const SizedBox(height: 10),
          _buildInfoCard(
            icon: Icons.calendar_today_outlined,
            iconColor: const Color(0xFFEC4899),
            bgColor: const Color(0xFFFDF2F8),
            label: 'DATE OF BIRTH',
            value: _data['dateOfBirth']!,
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
                    Text('Dark Mode',
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
                child: Text(
                  'Complete Your Profile',
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
            title: 'Residential Address',
            isCompleted: addressDone,
            onTap: () => _navigateToProfileStep(context, 'residentialAddress'),
          ),
          const SizedBox(height: 12),
          // PEP Declaration
          _buildProfileItem(
            icon: Icons.verified_outlined,
            title: 'PEP Declaration',
            isCompleted: pepDone,
            onTap: () => _navigateToProfileStep(context, 'pepDeclaration'),
          ),
          const SizedBox(height: 12),
          // Source of Income
          _buildProfileItem(
            icon: Icons.work_outline,
            title: 'Source of Income',
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
                  ? Icon(Icons.check, color: Theme.of(context).cardColor, size: 16)
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
            Text(
              'Profile Completed!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'Effra',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your profile is now fully complete.',
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
                child: const Text('Great!',
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
                  Icon(Icons.star_rounded, color: Theme.of(context).cardColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT TIER',
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
                      color: Theme.of(context).cardColor,
                      fontFamily: 'Effra',
                    ),
                  ),
                  Text(
                    '₦50,000 balance • ₦20,000 per txn',
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
              child: Text(
                'Upgrade',
                style: TextStyle(
                  color: Theme.of(context).cardColor,
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
          label: const Text(
            'Edit Profile',
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
              child: const Text('Cancel',
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
                  const SnackBar(
                    content: Text('Profile updated'),
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
              child: const Text('Save Changes',
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
      _SecurityItem(Icons.lock_outline, 'Change Login PIN', 'Update your login PIN'),
      _SecurityItem(Icons.vpn_key_outlined, 'Change Transaction PIN', 'Update your transaction PIN'),
      _SecurityItem(Icons.refresh, 'Reset Transaction PIN', 'Forgot your PIN? Reset it here'),
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
            child: Text(
              'SECURITY',
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
              onTap: () {
                if (i == 2) {
                  _showResetPinModal();
                } else {
                  _showChangePinModal(i == 0 ? 'Login PIN' : 'Transaction PIN');
                }
              },
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
        ],
      ),
    );
  }

  void _showChangePinModal(String pinType) {
    _currentPinController.clear();
    _newPinController.clear();
    _confirmPinController.clear();
    _pinChangeSuccess = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          bool isPinValid() =>
              _currentPinController.text.length == 4 &&
              _newPinController.text.length == 4 &&
              _newPinController.text == _confirmPinController.text;

          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: _pinChangeSuccess
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
                        Text('$pinType Changed!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontFamily: 'Effra',
                            )),
                        const SizedBox(height: 6),
                        Text('Your $pinType has been updated',
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
                            Text('Change $pinType',
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
                              _pinField('Current PIN', _currentPinController, setModalState),
                              const SizedBox(height: 14),
                              _pinField('New PIN', _newPinController, setModalState),
                              const SizedBox(height: 14),
                              _pinField('Confirm New PIN', _confirmPinController, setModalState),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: isPinValid()
                                      ? () {
                                          setModalState(() => _pinChangeSuccess = true);
                                          _successAnimController.forward(from: 0);
                                          Future.delayed(const Duration(seconds: 2), () {
                                            if (mounted) Navigator.pop(ctx);
                                          });
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF166C46),
                                    disabledBackgroundColor: Theme.of(context).dividerColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text('Change $pinType',
                                      style: const TextStyle(
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

  Widget _pinField(String label, TextEditingController controller, StateSetter setModalState) {
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
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, letterSpacing: 10, fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: '----',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              letterSpacing: 10,
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
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onChanged: (_) => setModalState(() {}),
        ),
      ],
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Text('Reset Transaction PIN',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: 'Effra',
                  )),
              const SizedBox(height: 8),
              Text(
                'An OTP will be sent to your registered phone number to reset your transaction PIN.',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  height: 1.5,
                  fontFamily: 'Effra',
                ),
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
                        backgroundColor: const Color(0xFF166C46),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF166C46),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Send OTP',
                      style: TextStyle(
                          fontFamily: 'Effra', fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text(
          'Log Out',
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
            Text(
              'Log Out?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'Effra',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to log out of your RimaPay account?',
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
                      child: const Text('Cancel',
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
                      child: const Text('Log Out',
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
        label: const Text(
          'Delete Account',
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
            Text(
              'Delete Account?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'Effra',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This will permanently delete your account and all data. This action cannot be undone.',
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
                      child: const Text('Cancel',
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
                      child: const Text('Delete',
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
                Text(
                  'Change Photo',
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
                    child: Text('Cancel',
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
        SnackBar(content: Text('Error picking image: $e')),
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
  const _SecurityItem(this.icon, this.title, this.subtitle);
}

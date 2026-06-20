import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:rimapay/Utils/Logics.dart';
import 'package:rimapay/core/router/app_router.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../shared/widgets/noise_painter.dart';
import '../../../../shared/widgets/rimapay_logo.dart';

enum AuthMode { signup, login }

enum Flow { start, personal, underbanking, business, login, success }

enum AccountType { tier1, underbanking, business }

class AuthScreen extends StatefulWidget {
  final AuthMode mode;

  const AuthScreen({
    super.key,
    required this.mode,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _shimmerController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<Offset> _shimmerAnimation;

  // State variables
  Flow _currentFlow = Flow.login;
  Map<String, dynamic>? _accountData;
  Map<String, dynamic>? _personalInfo;

  final Map<String, String> _loginForm = {
    'phoneNumber': '',
    'password': '',
  };

  bool _showPassword = false;
  bool _isLoading = false;
  bool _isBiometricLoading = false;
  bool _biometricSupported = false;

  // Mock credentials for testing
  final Map<String, Map<String, dynamic>> _mockCredentials = {
    '+2348012345678': {
      'password': 'tier1pass',
      'accountType': AccountType.tier1,
      'tierLevel': 'tier1',
      'bvnVerified': true,
      'ninVerified': false,
    },
    '+2348023456789': {
      'password': 'tier2pass',
      'accountType': AccountType.tier1,
      'tierLevel': 'tier2',
      'bvnVerified': true,
      'ninVerified': true,
    },
    '+2348045678901': {
      'password': 'underpass',
      'accountType': AccountType.underbanking,
      'tierLevel': 'tier0',
      'bvnVerified': false,
      'ninVerified': false,
    },
    '+2348056789012': {
      'password': 'bizpass',
      'accountType': AccountType.business,
      'tierLevel': 'tier1',
      'bvnVerified': true,
      'ninVerified': false,
    },
  };

  @override
  void initState() {
    super.initState();
    _currentFlow = widget.mode == AuthMode.login ? Flow.login : Flow.start;
    _initializeAnimations();
    _checkBiometricSupport();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _rotationController, curve: Curves.linear));

    _shimmerAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: const Offset(1.0, 0.0),
    ).animate(
        CurvedAnimation(parent: _shimmerController, curve: Curves.linear));

    _fadeController.forward();
    _scaleController.forward();
    _pulseController.repeat();
    _rotationController.repeat();
    _shimmerController.repeat();
  }

  Future<void> _checkBiometricSupport() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      setState(() {
        _biometricSupported =
            isAvailable && isDeviceSupported && availableBiometrics.isNotEmpty;
      });
    } catch (e) {
      setState(() {
        _biometricSupported = false;
      });
    }
  }

  Future<void> _handleLoginSubmit() async {
    if (_loginForm['phoneNumber']!.isEmpty || _loginForm['password']!.isEmpty) {
      _showErrorMessage('Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final auth = context.read<AuthProvider>();
    final ok = await auth.loginWithCredentials(
      phoneNumber: _loginForm['phoneNumber'],
      password: _loginForm['password']!,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (ok) {
      AppNavigation.goToHome(context);
    } else {
      _showErrorMessage(auth.error ?? 'Login failed. Please try again.');
    }
  }

  Future<void> _handleBiometricLogin() async {
    if (!_biometricSupported) {
      _showErrorMessage(
          'Biometric authentication is not supported on this device');
      return;
    }

    setState(() {
      _isBiometricLoading = true;
    });

    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access your RimaPay account',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (isAuthenticated) {
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      log(e.toString());
      _showErrorMessage('Biometric authentication failed. Please try again.');
    } finally {
      setState(() {
        _isBiometricLoading = false;
      });
    }
  }

  void _showLinkDeviceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LinkDeviceSheet(),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _shimmerController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentFlow) {
      case Flow.login:
        return _buildLoginForm();
      case Flow.success:
        return _buildSuccessScreen();
      default:
        return _buildAccountOpeningStart();
    }
  }

  Widget _buildLoginForm() {
    final bool canSubmit = _loginForm['phoneNumber']!.isNotEmpty &&
        _loginForm['password']!.isNotEmpty &&
        !_isLoading;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.arrow_back_ios_new,
                          color: Theme.of(context).colorScheme.onSurface, size: 17),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo + wordmark
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Row(
                          children: [
                            const RimapayLogo(width: 48, height: 48),
                            const SizedBox(width: 12),
                        Text(
                          'RimaPay',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Headline
                      Text(
                        'Welcome\nBack 👋',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 34,
                            height: 1.15,
                            fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to your RimaPay account',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 15,
                            height: 1.4),
                      ),
                      const SizedBox(height: 36),

                      // Phone field
                      _AuthFloatingField(
                        label: 'Phone Number',
                        hint: '8012 345 678',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefixWidget: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '+234',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(width: 8),
                            SizedBox(
                              width: 1,
                              height: 18,
                              child: ColoredBox(color: Theme.of(context).dividerColor),
                            ),
                          ],
                        ),
                        prefixWidth: 72,
                        onChanged: (v) => setState(() {
                          final digits = v.replaceAll(RegExp(r'[^\d]'), '').replaceFirst(RegExp('^0+'), '');
                          _loginForm['phoneNumber'] = '+234$digits';
                        }),
                      ),
                      const SizedBox(height: 18),

                      // Password field
                      _AuthFloatingField(
                        label: 'Password',
                        hint: '••••••••',
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        prefixIcon: Icons.lock_outline_rounded,
                        onChanged: (v) =>
                            setState(() => _loginForm['password'] = v),
                        suffixIcon: GestureDetector(
                          onTap: () =>
                              setState(() => _showPassword = !_showPassword),
                          child: Icon(
                            _showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => context.push('/forgot-password'),
                            child: const Text('Forgot Password?',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF166C46))),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Sign In button
                      GestureDetector(
                        onTap: canSubmit ? _handleLoginSubmit : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: canSubmit
                                ? const LinearGradient(
                                    colors: [
                                        Color(0xFF166C46),
                                        Color(0xFF166C46)
                                      ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight)
                                : null,
                            color: canSubmit ? null : Theme.of(context).dividerColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white)))
                                : Text('Sign In',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: canSubmit
                                            ? Colors.white
                                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Divider
                      Row(children: [
                        Expanded(
                            child: Divider(color: Theme.of(context).dividerColor)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or',
                              style: TextStyle(
                                  fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                        ),
                        Expanded(
                            child: Divider(color: Theme.of(context).dividerColor)),
                      ]),
                      const SizedBox(height: 12),

                      // Biometric button
                      GestureDetector(
                        onTap: _handleBiometricLogin,
                        child: Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isBiometricLoading) ...[
                                const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Color(0xFF166C46)))),
                                const SizedBox(width: 12),
                                Text('Authenticating...',
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                              ] else ...[
                                const Icon(Icons.fingerprint,
                                    color: Color(0xFF166C46), size: 24),
                                const SizedBox(width: 10),
                                Text(
                                  _biometricSupported
                                      ? 'Login with Biometrics'
                                      : 'Set Up Biometrics',
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Footer
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? ",
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 14)),
                            GestureDetector(
                              onTap: () => context.pushNamed('auth',
                                  queryParameters: {'mode': 'signup'}),
                              child: const Text('Create Account',
                                  style: TextStyle(
                                      color: Color(0xFF166C46),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: GestureDetector(
                          onTap: () => _showLinkDeviceSheet(context),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'New device? ',
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 13),
                                ),
                                TextSpan(
                                  text: 'Link existing account',
                                  style: TextStyle(
                                    color: Color(0xFF166C46),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: context.isDark
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1A1F2E),
                    const Color(0xFF0B2417),
                    const Color(0xFF073D25),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    const Color(0xFFF0FDF4),
                    const Color(0xFFDCFCE7),
                  ],
                ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: AppColors.goldGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'Welcome to RimaPay! 🎉',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'Your account has been successfully created and verified',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (_accountData != null) ...[
                        const SizedBox(height: 32),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: context.bgCard.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: context.border.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildInfoRow('Account Number:',
                                    _accountData!['accountNumber'] ?? ''),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                    'Account Type:',
                                    _accountData!['accountType'] ??
                                        _accountData!['tier'] ??
                                        ''),
                                const SizedBox(height: 12),
                                _buildInfoRow('Daily Limit:',
                                    _accountData!['dailyLimit'] ?? '₦50,000'),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(
                          height:
                              24), // Added bottom padding for better scroll experience
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountOpeningStart() {
    return Scaffold(
      body: Stack(
        children: [
          // Green gradient background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF073D25),
                    Color(0xFF0B4F2F),
                    Color(0xFF073D25),
                    Color(0xFF0B4F2F),
                  ],
                  stops: [0.0, 0.3, 0.65, 1.0],
                ),
              ),
            ),
          ),
          // Noise texture
          Positioned.fill(
            child: CustomPaint(
              painter: NoisePainter(opacity: 0.055, seed: 7),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Header row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.18)),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _currentFlow = Flow.login),
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Rima MFB Logo
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: RimapayLogo(
                        width: MediaQuery.of(context).size.width * 0.40,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Hero text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Open an\nAccount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Choose the account type that fits your needs',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Account type cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _buildAccountTypeCard(
                          title: 'Personal Account',
                          subtitle:
                              'For individuals — send, receive & pay bills',
                          icon: Icons.person_outline,
                          onTap: () {
                            setState(() => _currentFlow = Flow.personal);
                            context.pushNamed("personal-account");
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildAccountTypeCard(
                          title: 'Corporate Account',
                          subtitle: 'For businesses and organizations',
                          icon: Icons.business_outlined,
                          onTap: () {
                            setState(() => _currentFlow = Flow.business);
                            context.pushNamed("business-account");
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildAccountTypeCard(
                          title: 'Underbanked',
                          subtitle: 'Financial inclusion — micro-loans & savings groups',
                          icon: Icons.people_outline,
                          onTap: () {
                            setState(() => _currentFlow = Flow.underbanking);
                            context.pushNamed("personal-account", extra: "underbanked");
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Footer
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'By continuing, you agree to our Terms of Service and Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Link existing account
                  GestureDetector(
                    onTap: () => _showLinkDeviceSheet(context),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 13),
                          ),
                          const TextSpan(
                            text: 'Link existing account',
                            style: TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTypeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F7F3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF166C46),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF667085),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: const Color(0xFF98A2B3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface)),
      ],
    );
  }
}

// ── Link Existing Account Sheet ───────────────────────────────────────────────

class _LinkDeviceSheet extends StatefulWidget {
  const _LinkDeviceSheet();

  @override
  State<_LinkDeviceSheet> createState() => _LinkDeviceSheetState();
}

class _LinkDeviceSheetState extends State<_LinkDeviceSheet> {
  int _step = 0; // 0=phone, 1=otp+pin, 2=success
  final _phoneCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final List<String> _otp = List.filled(6, '');
  bool _loading = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_step == 2) ...[
              _buildSuccess(),
            ] else ...[
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FAF4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.link_rounded,
                        color: Color(0xFF166C46), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Link Existing Account',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 2),
                      Text('Verify identity to link to this device',
                          style: TextStyle(
                              fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_step == 0) _buildPhoneStep(),
              if (_step == 1) _buildOtpPinStep(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFB923C).withOpacity(0.4)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFF97316), size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Use your account number to link your existing RimaPay account.',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFF78350F), height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Account Number',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.text,
          style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'e.g. 1234567890',
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 14),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
              borderSide:
                  const BorderSide(color: Color(0xFF166C46), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () async {
            if (_phoneCtrl.text.trim().isEmpty) return;
            setState(() => _loading = true);
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) setState(() { _loading = false; _step = 1; });
          },
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF166C46),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white)))
                  : const Text('Send Verification Code',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpPinStep() {
    final filled = _otp.where((d) => d.isNotEmpty).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            children: [
              const TextSpan(text: 'Code sent to your registered phone number'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) {
            final hasDigit = _otp[i].isNotEmpty;
            final isActive = i == filled;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 44,
              height: 50,
              margin: EdgeInsets.only(right: i < 5 ? 8 : 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF166C46)
                      : hasDigit
                          ? const Color(0xFF166C46).withOpacity(0.4)
                          : Theme.of(context).dividerColor,
                  width: isActive ? 2 : 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  hasDigit ? '•' : '',
                  style: TextStyle(
                      fontSize: 22, color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        // Mini numpad
        ...([['1','2','3'],['4','5','6'],['7','8','9'],['','0','⌫']].map((row) =>
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: row.map((k) => Expanded(
                child: k.isEmpty ? const SizedBox() : GestureDetector(
                  onTap: () {
                    if (k == '⌫') {
                      final idx = _otp.lastIndexWhere((d) => d.isNotEmpty);
                      if (idx != -1) setState(() => _otp[idx] = '');
                    } else {
                      final idx = _otp.indexWhere((d) => d.isEmpty);
                      if (idx != -1) setState(() => _otp[idx] = k);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 46,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: k == '⌫'
                          ? Icon(Icons.backspace_outlined,
                              size: 18, color: Theme.of(context).colorScheme.onSurface)
                          : Text(k,
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface)),
                    ),
                  ),
                ),
              )).toList(),
            ),
          )
        ).toList()),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            if (filled < 6) return;
            setState(() => _loading = true);
            await Future.delayed(const Duration(seconds: 2));
            if (mounted) setState(() { _loading = false; _step = 2; });
          },
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: filled == 6 ? const Color(0xFF166C46) : Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white)))
                  : Text('Link Account',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: filled == 6
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        const SizedBox(height: 8),
        const Center(
          child: Icon(Icons.check_circle, color: Color(0xFF166C46), size: 60),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text('Account Linked!',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface)),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Your RimaPay account is now linked\nto this device.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), height: 1.5),
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
            // Navigate to home
          },
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF166C46),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('Continue to Account',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Floating Label Input ──────────────────────────────────────────────────────

class _AuthFloatingField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final Widget? prefixWidget;
  final double prefixWidth;
  final bool obscureText;
  final ValueChanged<String> onChanged;
  final Widget? suffixIcon;

  const _AuthFloatingField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.prefixWidget,
    this.prefixWidth = 48,
    this.obscureText = false,
    required this.onChanged,
    this.suffixIcon,
  });

  @override
  State<_AuthFloatingField> createState() => _AuthFloatingFieldState();
}

class _AuthFloatingFieldState extends State<_AuthFloatingField> {
  final FocusNode _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasValue = widget.controller.text.isNotEmpty;
    final bool active = _focused || hasValue;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      decoration: BoxDecoration(
        color: _focused ? Colors.white : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _focused
              ? AppColors.goldPrimary
              : hasValue
                  ? AppColors.goldPrimary.withOpacity(0.35)
                  : Theme.of(context).dividerColor,
          width: _focused ? 1.5 : 1,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                    color: const Color(0xFF166C46).withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
              ]
            : [],
      ),
      child: Stack(
        children: [
          // Prefix icon or widget
          Positioned(
            left: 14,
            top: 0,
            bottom: 0,
            child: Center(
              child: widget.prefixWidget ??
                  Icon(widget.prefixIcon,
                      size: 18,
                      color: _focused
                          ? AppColors.goldPrimary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
            ),
          ),
          // Text field — always in tree so taps always register
          Positioned(
            left: widget.prefixWidth,
            right: widget.suffixIcon != null ? 44 : 16,
            top: active ? 24 : 0,
            bottom: active ? 6 : 0,
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              keyboardType: widget.keyboardType,
              obscureText: widget.obscureText,
              onChanged: widget.onChanged,
              style: TextStyle(
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Effra'),
              decoration: InputDecoration(
                hintText: active ? widget.hint : null,
                hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    fontSize: 14,
                    fontFamily: 'Effra'),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          // Floating label — IgnorePointer so taps pass through to TextField
          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            top: active ? 8 : 20,
            left: widget.prefixWidth,
            child: IgnorePointer(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(
                  fontSize: active ? 11 : 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Effra',
                  color: _focused
                      ? AppColors.goldPrimary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
                child: Text(widget.label),
              ),
            ),
          ),
          // Suffix icon
          if (widget.suffixIcon != null)
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(child: widget.suffixIcon!),
            ),
        ],
      ),
    );
  }
}

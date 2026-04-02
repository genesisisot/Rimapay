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
import '../../../../shared/widgets/noise_painter.dart';

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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _rotationController, curve: Curves.linear));

    _shimmerAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: const Offset(1.0, 0.0),
    ).animate(CurvedAnimation(parent: _shimmerController, curve: Curves.linear));

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
        _biometricSupported = isAvailable && isDeviceSupported && availableBiometrics.isNotEmpty;
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

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    //final credential = _mockCredentials[_loginForm['phoneNumber']];

    setState(() {
      _isLoading = false;
    });

    AppNavigation.goToHome(context);
  }

  Future<void> _handleBiometricLogin() async {
    if (!_biometricSupported) {
      _showErrorMessage('Biometric authentication is not supported on this device');
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
      backgroundColor: Colors.white,
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
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF374151), size: 17),
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
                            Image.asset('assets/images/AppIcon.png', width: 48, height: 48),
                            const SizedBox(width: 12),
                            const Text(
                              'RimaPay',
                              style: TextStyle(color: Color(0xFF101828), fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Headline
                      const Text(
                        'Welcome\nBack 👋',
                        style: TextStyle(color: Color(0xFF101828), fontSize: 34, height: 1.15, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in to your RimaPay account',
                        style: TextStyle(color: Color(0xFF667085), fontSize: 15, height: 1.4),
                      ),
                      const SizedBox(height: 36),

                      // Phone field
                      _AuthFloatingField(
                        label: 'Phone Number',
                        hint: '0801 234 5678',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                        onChanged: (v) => setState(() => _loginForm['phoneNumber'] = addLeadingZero(v)),
                      ),
                      const SizedBox(height: 18),

                      // Password field
                      _AuthFloatingField(
                        label: 'Password',
                        hint: '••••••••',
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        prefixIcon: Icons.lock_outline_rounded,
                        onChanged: (v) => setState(() => _loginForm['password'] = v),
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _showPassword = !_showPassword),
                          child: Icon(
                            _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 18, color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {},
                          child: const Text('Forgot Password?',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF00B252))),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Sign In button
                      GestureDetector(
                        onTap: canSubmit ? _handleLoginSubmit : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: double.infinity, height: 54,
                          decoration: BoxDecoration(
                            gradient: canSubmit
                                ? const LinearGradient(colors: [Color(0xFF00B252), Color(0xFF00A651)], begin: Alignment.centerLeft, end: Alignment.centerRight)
                                : null,
                            color: canSubmit ? null : const Color(0xFFE4E7EC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(width: 22, height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                : Text('Sign In',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                                        color: canSubmit ? Colors.white : const Color(0xFF9CA3AF))),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Divider
                      Row(children: [
                        const Expanded(child: Divider(color: Color(0xFFE4E7EC))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
                        ),
                        const Expanded(child: Divider(color: Color(0xFFE4E7EC))),
                      ]),
                      const SizedBox(height: 12),

                      // Biometric button
                      GestureDetector(
                        onTap: _handleBiometricLogin,
                        child: Container(
                          width: double.infinity, height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE4E7EC)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isBiometricLoading) ...[
                                const SizedBox(width: 22, height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00B252)))),
                                const SizedBox(width: 12),
                                const Text('Authenticating...', style: TextStyle(color: Color(0xFF374151), fontSize: 15, fontWeight: FontWeight.w600)),
                              ] else ...[
                                const Icon(Icons.fingerprint, color: Color(0xFF00B252), size: 24),
                                const SizedBox(width: 10),
                                Text(
                                  _biometricSupported ? 'Login with Biometrics' : 'Set Up Biometrics',
                                  style: const TextStyle(color: Color(0xFF374151), fontSize: 15, fontWeight: FontWeight.w600),
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
                            const Text("Don't have an account? ",
                                style: TextStyle(color: Color(0xFF667085), fontSize: 14)),
                            GestureDetector(
                              onTap: () => context.pushNamed('personal-account'),
                              child: const Text('Create Account',
                                  style: TextStyle(color: Color(0xFF00B252), fontSize: 14, fontWeight: FontWeight.w700)),
                            ),
                          ],
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFF0FDF4),
              Color(0xFFDCFCE7),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
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
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF00B252), Color(0xFF00A047)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
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
                        child: const Text(
                          'Welcome to RimaPay! 🎉',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
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
                            color: Colors.grey[600],
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
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildInfoRow('Account Number:', _accountData!['accountNumber'] ?? ''),
                                const SizedBox(height: 12),
                                _buildInfoRow('Account Type:', _accountData!['accountType'] ?? _accountData!['tier'] ?? ''),
                                const SizedBox(height: 12),
                                _buildInfoRow('Daily Limit:', _accountData!['dailyLimit'] ?? '₦50,000'),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24), // Added bottom padding for better scroll experience
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF001a0c),
                    Color(0xFF003d1a),
                    Color(0xFF005e27),
                    Color(0xFF003d1a),
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
                          title: 'Business Account',
                          subtitle:
                              'For businesses and organizations',
                          icon: Icons.business_outlined,
                          onTap: () {
                            setState(() => _currentFlow = Flow.business);
                            context.pushNamed("business-account");
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
                color: const Color(0xFFecfdf5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF00B252),
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF667085),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: Color(0xFF98A2B3),
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
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
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
  final IconData prefixIcon;
  final bool obscureText;
  final ValueChanged<String> onChanged;
  final Widget? suffixIcon;

  const _AuthFloatingField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    required this.prefixIcon,
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
        color: _focused ? Colors.white : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _focused
              ? const Color(0xFF00B252)
              : hasValue
                  ? const Color(0xFF00B252).withOpacity(0.35)
                  : const Color(0xFFE4E7EC),
          width: _focused ? 1.5 : 1,
        ),
        boxShadow: _focused
            ? [BoxShadow(color: const Color(0xFF00B252).withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 3))]
            : [],
      ),
      child: Stack(
        children: [
          // Prefix icon
          Positioned(
            left: 14, top: 0, bottom: 0,
            child: Center(
              child: Icon(widget.prefixIcon, size: 18,
                  color: _focused ? const Color(0xFF00B252) : const Color(0xFF9CA3AF)),
            ),
          ),
          // Text field — always in tree so taps always register
          Positioned(
            left: 48,
            right: widget.suffixIcon != null ? 44 : 16,
            top: active ? 24 : 0,
            bottom: active ? 6 : 0,
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              keyboardType: widget.keyboardType,
              obscureText: widget.obscureText,
              onChanged: widget.onChanged,
              style: const TextStyle(fontSize: 15, color: Color(0xFF101828), fontWeight: FontWeight.w500, fontFamily: 'Effra'),
              decoration: InputDecoration(
                hintText: active ? widget.hint : null,
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14, fontFamily: 'Effra'),
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
            left: 48,
            child: IgnorePointer(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(
                  fontSize: active ? 11 : 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Effra',
                  color: _focused ? const Color(0xFF00B252) : const Color(0xFF9CA3AF),
                ),
                child: Text(widget.label),
              ),
            ),
          ),
          // Suffix icon
          if (widget.suffixIcon != null)
            Positioned(
              right: 12, top: 0, bottom: 0,
              child: Center(child: widget.suffixIcon!),
            ),
        ],
      ),
    );
  }
}

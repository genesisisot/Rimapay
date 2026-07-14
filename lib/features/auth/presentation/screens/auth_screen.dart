import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:rimapay/Utils/Logics.dart';
import 'package:rimapay/core/router/app_router.dart';
import 'package:rimapay/core/services/storage_service.dart';
import 'package:rimapay/features/onboarding/data/onboarding_dtos.dart';
import 'package:rimapay/features/onboarding/data/onboarding_api_service.dart';
import 'package:rimapay/features/onboarding/presentation/providers/onboarding_provider.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../security/data/pin_api_service.dart';
import '../../../security/data/pin_dtos.dart' as security;
import '../../data/auth_api_service.dart';
import '../../data/auth_dtos.dart';
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
      if (!auth.pinCreated) {
        _showCreatePinDialog();
      } else {
        AppNavigation.goToHome(context);
      }
    } else {
      _showErrorMessage(auth.error ?? 'Login failed. Please try again.');
    }
  }

  Future<void> _showCreatePinDialog() async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 12,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).dividerColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                'Create Transaction PIN',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(ctx).colorScheme.onSurface,
                  fontFamily: 'Effra',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You need to create a transaction PIN before you can send money.',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.6),
                  fontFamily: 'Effra',
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: pinController,
                obscureText: true,
                maxLength: 8,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'PIN (4-8 digits)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.length < 4) return 'PIN must be 4-8 digits';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                maxLength: 8,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Confirm PIN',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v != pinController.text) return 'PINs do not match';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF166C46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final auth = ctx.read<AuthProvider>();
                    final api = PinApiService(
                      dio: DioClient.instance.forBaseUrl(
                        '${ApiConfig.directGateway}/identity',
                      ),
                    );
                    final res = await api.createPin(security.CreatePinRequest(
                      pin: pinController.text,
                      confirmPin: confirmController.text,
                      userId: auth.user?.id ?? '',
                    ));
                    log('[pin create] isSuccess=${res.isSuccess} message=${res.message} statusCode=${res.statusCode} errorCode=${res.errorCode}');
                    if (!ctx.mounted) return;
                    if (res.isSuccess) {
                      auth.setPinCreated();
                      Navigator.pop(ctx, true);
                    } else {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(res.message ?? 'Failed to create PIN')),
                      );
                    }
                  },
                  child: const Text(
                    'Create PIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Effra',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result == true) {
      AppNavigation.goToHome(context);
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

  Future<void> _showDeviceLinkSheet(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DeviceLinkingSheet(),
    );
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device linked successfully. Please log in.'),
          backgroundColor: Color(0xFF166C46),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showLinkDeviceSheet(BuildContext context) async {
    final sessionId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LinkDeviceSheet(),
    );
    if (sessionId != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _ContinueLinkingPage(sessionId: sessionId),
        ),
      );
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
                          _loginForm['phoneNumber'] = '234$digits';
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
                      const SizedBox(height: 8),
                      Center(
                        child: GestureDetector(
                          onTap: () => _showDeviceLinkSheet(context),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'New phone? ',
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 13),
                                ),
                                TextSpan(
                                  text: 'Link your device',
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

// ── Device Linking Sheet ─────────────────────────────────────────────────────

class _DeviceLinkingSheet extends ConsumerStatefulWidget {
  const _DeviceLinkingSheet();

  @override
  ConsumerState<_DeviceLinkingSheet> createState() =>
      _DeviceLinkingSheetState();
}

class _DeviceLinkingSheetState extends ConsumerState<_DeviceLinkingSheet> {
  int _step = 0; // 0=phone, 1=otp, 2=success
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _sessionToken;
  String? _faceImageBase64;
  String _normalizedPhone = '';

  // OTP
  final List<String> _otp = List.filled(6, '');
  bool _verifyingOtp = false;
  bool _isResending = false;
  int _resendCountdown = 0;
  Timer? _resendTimer;

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
            if (_step == 0) _buildPhoneStep(),
            if (_step == 1) _buildOtpStep(),
            if (_step == 2) _buildSuccessStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FAF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.phone_android_rounded,
                  color: Color(0xFF166C46), size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Link Your Device',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text('Register this device to your account',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6))),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: const Color(0xFFFB923C).withOpacity(0.4)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFF97316), size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Enter the phone number linked to your RimaPay account.',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFF78350F), height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Phone Number',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'e.g. 8012345678',
            hintStyle: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.4),
                fontSize: 14),
            prefixText: '+234 ',
            prefixStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF166C46), width: 1.5),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!,
              style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _onInitiateDeviceRegistration,
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
                  : const Text('Continue →',
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

  Widget _buildOtpStep() {
    final filled = _otp.where((d) => d.isNotEmpty).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FAF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.sms_rounded,
                  color: Color(0xFF166C46), size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Enter OTP',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 2),
                Text('We sent a code to your phone',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6))),
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) {
            final hasDigit = i < filled;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 42,
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: hasDigit
                    ? const Color(0xFF166C46)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasDigit
                      ? const Color(0xFF166C46)
                      : Theme.of(context).dividerColor,
                ),
              ),
              child: Center(
                child: Text(
                  _otp[i],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: hasDigit
                        ? Colors.white
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.3),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),
        ...([
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', '⌫']
        ].map((row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: row.map((k) => Expanded(
                  child: k.isEmpty
                      ? const SizedBox()
                      : GestureDetector(
                          onTap: () {
                            if (k == '⌫') {
                              final idx = _otp
                                  .lastIndexWhere((d) => d.isNotEmpty);
                              if (idx != -1) {
                                setState(() => _otp[idx] = '');
                              }
                            } else {
                              final idx =
                                  _otp.indexWhere((d) => d.isEmpty);
                              if (idx != -1) {
                                setState(() => _otp[idx] = k);
                              }
                            }
                          },
                          child: Container(
                            margin:
                                const EdgeInsets.symmetric(horizontal: 4),
                            height: 46,
                            decoration: BoxDecoration(
                              color: context.bgInput,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: k == '⌫'
                                  ? Icon(Icons.backspace_outlined,
                                      size: 18,
                                       color: Theme.of(context).colorScheme.onSurface)
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
            ))
        ).toList(),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: filled == 6 ? _onConfirmOtp : null,
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: filled == 6
                  ? const Color(0xFF166C46)
                  : const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: _verifyingOtp
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white)))
                  : const Text('Verify →',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (_resendCountdown > 0)
          Center(
            child: Text(
              'Resend code in $_resendCountdown s',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.4),
              ),
            ),
          )
        else
          Center(
            child: GestureDetector(
              onTap: _isResending ? null : _resendOtp,
              child: _isResending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Resend OTP',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!,
              style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
      ],
    );
  }

  Widget _buildSuccessStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline,
              color: Color(0xFF166C46), size: 64),
          const SizedBox(height: 16),
          Text('Device Linked Successfully',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text('You can now use this device to access your account.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.of(context).pop('success'),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF166C46),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('Done',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onInitiateDeviceRegistration() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Enter your phone number.');
      return;
    }
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '').replaceFirst(RegExp('^0+'), '');
    final normalized = digits.startsWith('234') ? digits : '234$digits';
    _normalizedPhone = normalized;
    setState(() {_loading = true;_error = null;});
    try {
      final api = AuthApiService();
      final deviceId = await StorageService.getDeviceId();
      log('[device] initiate phone=$normalized deviceId=$deviceId');
      final res = await api.initiateDeviceRegistration(
        InitiateDeviceRegistrationRequest(
          deviceId: deviceId,
          phoneNumber: normalized,
        ),
      );
      if (!mounted) return;
      log('[device] initiate → isSuccess=${res.isSuccess}');
      if (res.isSuccess) {
        setState(() {
          _sessionToken = res.data;
          _loading = false;
        });
        if (!mounted) return;
        final faceImage = await Navigator.push<String?>(
          context,
          MaterialPageRoute(
            builder: (_) => _DeviceFaceCapturePage(
              sessionToken: _sessionToken!,
            ),
          ),
        );
        if (faceImage != null && mounted) {
          setState(() {
            _step = 1;
            _faceImageBase64 = faceImage;
            _otp
              ..clear()
              ..addAll(List.filled(6, ''));
          });
        }
      } else {
        setState(() {
          _loading = false;
          _error = res.message ?? 'Failed to initiate device registration.';
        });
      }
    } catch (e) {
      log('[device] initiate error: $e');
      if (mounted) {
        setState(() {_loading = false;_error = 'Network error. Please try again.';});
      }
    }
  }

  Future<void> _onConfirmOtp() async {
    final otp = _otp.join();
    setState(() {_verifyingOtp = true;_error = null;});
    try {
      final api = AuthApiService();
      log('[device] confirmOtp token=${_sessionToken?.substring(0, 20)}...');
      final res = await api.confirmDeviceOtp(ConfirmDeviceOtpRequest(
        sessionToken: _sessionToken!,
        otpCode: otp,
      ));
      if (!mounted) return;
      log('[device] confirmOtp → isSuccess=${res.isSuccess}');
      if (res.isSuccess) {
        setState(() {_step = 2;_verifyingOtp = false;});
      } else {
        setState(() {
          _verifyingOtp = false;
          _error = res.message ?? 'Invalid OTP. Please try again.';
        });
      }
    } catch (e) {
      log('[device] confirmOtp error: $e');
      if (mounted) {
        setState(() {_verifyingOtp = false;_error = 'Network error. Please try again.';});
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_isResending || _faceImageBase64 == null) return;
    setState(() {_isResending = true;_error = null;});
    try {
      final api = AuthApiService();
      final res = await api.verifyDeviceFace(VerifyDeviceFaceRequest(
        sessionToken: _sessionToken!,
        faceImage: _faceImageBase64!,
      ));
      if (!mounted) return;
      if (res.isSuccess) {
        _startResendCountdown();
      } else {
        setState(() => _error = res.message ?? 'Failed to resend OTP.');
      }
    } catch (e) {
      log('[device] resend error: $e');
      if (mounted) setState(() => _error = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _startResendCountdown() {
    _resendCountdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) t.cancel();
      });
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneCtrl.dispose();
    super.dispose();
  }
}

// ── Device Face Capture (Full-Screen) ────────────────────────────────────────

class _DeviceFaceCapturePage extends ConsumerStatefulWidget {
  final String sessionToken;
  const _DeviceFaceCapturePage({required this.sessionToken});

  @override
  ConsumerState<_DeviceFaceCapturePage> createState() =>
      _DeviceFaceCapturePageState();
}

class _DeviceFaceCapturePageState
    extends ConsumerState<_DeviceFaceCapturePage> {
  CameraController? _cameraController;
  bool _cameraActive = false;
  bool _verifyingFace = false;
  String? _cameraError;
  String? _error;

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF073D25),
              const Color(0xFF0B4F2F),
              const Color(0xFF0D6B3E),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Noise overlay
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: NoisePainter(opacity: 0.055, seed: 7),
                ),
              ),
            ),
            Column(
              children: [
                // Top bar with back button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _cameraController?.dispose();
                          Navigator.pop(context, false);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.18)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_cameraActive &&
                          _cameraController != null &&
                          _cameraController!.value.isInitialized)
                        Positioned.fill(
                            child: CameraPreview(_cameraController!))
                      else
                        Container(color: Colors.black87),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _OvalOverlayPainter(
                              color: const Color(0xFFD4AF37)),
                        ),
                      ),
                      // Info card
                      Positioned(
                        top: 60,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8)
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16A34A)
                                      .withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.remove_red_eye_outlined,
                                    color: Color(0xFF16A34A),
                                    size: 18),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text('Face Verification',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111827))),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Bottom button
                      Positioned(
                        bottom: 40,
                        left: 24,
                        right: 24,
                        child: GestureDetector(
                          onTap: _cameraActive
                              ? _capturePhoto
                              : _requestCameraPermission,
                          child: Container(
                            width: double.infinity,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: AppColors.goldGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                _cameraActive
                                    ? 'Take Selfie'
                                    : 'Start Camera',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_cameraError != null)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black54,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(_cameraError!,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14),
                                    textAlign: TextAlign.center),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 12)),
                  ),
              ],
            ),
            if (_verifyingFace) _buildVerifyingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyingOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xE60B1F14),
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF166C46))),
              ),
              SizedBox(height: 16),
              Text('Verifying your face…',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937))),
              SizedBox(height: 4),
              Text('Please hold still',
                  style: TextStyle(
                      fontSize: 13, color: Color(0xFF6B7280))),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        _initCamera();
      } else {
        setState(() => _cameraError = 'Camera permission denied.');
      }
    } catch (e) {
      setState(() => _cameraError = 'Could not access camera.');
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'No camera available.');
        return;
      }
      final controller = CameraController(
        cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        ),
        ResolutionPreset.medium,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _cameraController = controller;
        _cameraActive = true;
      });
    } catch (e) {
      log('[face] camera init error: $e');
      if (mounted) {
        setState(() => _cameraError = 'Could not open camera.');
      }
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) return;
    try {
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      setState(() {
        _cameraActive = false;
        _verifyingFace = true;
      });
      _cameraController?.dispose();
      _cameraController = null;

      final api = AuthApiService();
      final res = await api.verifyDeviceFace(VerifyDeviceFaceRequest(
        sessionToken: widget.sessionToken,
        faceImage: base64Image,
      ));
      if (!mounted) return;
      setState(() => _verifyingFace = false);
      if (res.isSuccess) {
        Navigator.pop(context, base64Image);
      } else {
        setState(() {
          _error = res.message ?? 'Face verification failed. Please try again.';
        });
        _initCamera();
      }
    } catch (e) {
      log('[face] capture error: $e');
      _cameraController?.dispose();
      _cameraController = null;
      if (mounted) {
        setState(() {
          _cameraError = 'Failed to capture photo.';
          _verifyingFace = false;
        });
      }
    }
  }
}

// ── Link Existing Account Sheet ───────────────────────────────────────────────

class _LinkDeviceSheet extends ConsumerStatefulWidget {
  const _LinkDeviceSheet();

  @override
  ConsumerState<_LinkDeviceSheet> createState() => _LinkDeviceSheetState();
}

class _LinkDeviceSheetState extends ConsumerState<_LinkDeviceSheet> {
  int _step = 0; // 0=account, 1=otp
  final _acctCtrl = TextEditingController();
  final List<String> _otp = List.filled(6, '');
  bool _loading = false;
  String? _error;
  String? _sessionId;
  String? _otpRef;
  bool _isResending = false;
  int _resendCountdown = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _acctCtrl.dispose();
    _resendTimer?.cancel();
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
            if (_step == 1) ...[
              _buildOtpStep(),
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
                      Text('Verify your existing account to continue',
                          style: TextStyle(
                              fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_step == 0) _buildAccountStep(),
              if (_step == 1) _buildOtpStep(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountStep() {
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
          controller: _acctCtrl,
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
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
        const SizedBox(height: 20),
        GestureDetector(
          onTap: _onSendVerification,
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

  static final _accountRegex = RegExp(r'^\d{10}$');

  Future<void> _onSendVerification() async {
    final acct = _acctCtrl.text.trim();
    if (!_accountRegex.hasMatch(acct)) {
      setState(() => _error = 'Enter a valid 10-digit account number.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final api = ref.read(onboardingApiServiceProvider);
      final check = await api.checkOnboarded(acct);
      if (!mounted) return;
      if (check.isSuccess && check.data != null && check.data!.isOnboarded) {
        setState(() {_loading = false;_error = 'This account has already been onboarded.';});
        return;
      }
      final deviceId = await StorageService.getDeviceId();
      log('[auth] initiateExisting account=$acct deviceId=$deviceId');
      final res = await api.initiateExisting(
        InitiateExistingOnboardingRequest(
          accountNumber: acct,
          deviceId: deviceId,
        ),
      );
      if (!mounted) return;
      log('[auth] initiateExisting → isSuccess=${res.isSuccess} errorCode=${res.errorCode}');
      if (res.isSuccess && res.data != null) {
        final d = res.data!;
        setState(() {
          _sessionId = d.sessionId;
          _otpRef = d.otpReference;
          _step = 1;
          _loading = false;
          _error = null;
        });
        return;
      }
      if (res.errorCode == 'ACTIVE_SESSION_EXISTS') {
        final resumeSessionId = res.data?.sessionId;
        if (resumeSessionId == null) {
          setState(() {
            _loading = false;
            _error = 'An active session exists but could not be resumed. Please try again later.';
          });
          return;
        }
        log('[auth] ACTIVE_SESSION_EXISTS → resume sessionId=$resumeSessionId');
        final resumeRes = await api.resume(ResumeOnboardingRequest(
          sessionId: resumeSessionId,
          deviceId: deviceId,
        ));
        if (!mounted) return;
        if (resumeRes.isSuccess && resumeRes.data != null) {
          final rd = resumeRes.data!;
          _sessionId = rd.sessionId;
          _otpRef = null;
          log('[auth] resume → stage=${rd.currentStage} requiresOtpResend=${rd.requiresOtpResend}');
          if (rd.currentStage.index >= OnboardingStage.otpVerified.index) {
            Navigator.pop(context, _sessionId);
            return;
          }
          if (rd.requiresOtpResend) {
            final otpRes = await api.resendOtp(
              ResendOnboardingOtpRequest(sessionId: _sessionId!),
            );
            if (!mounted) return;
            if (otpRes.isSuccess && otpRes.data != null) {
              _otpRef = otpRes.data!.otpReference;
            }
          }
          setState(() { _step = 1; _loading = false; _error = null; });
          return;
        }
        setState(() {
          _loading = false;
          _error = 'Could not resume session: ${resumeRes.errorMessage}';
        });
        return;
      }
      setState(() {
        _loading = false;
        _error = res.errorMessage ?? 'Could not verify account.';
      });
    } catch (e) {
      log('[auth] initiateExisting error: $e');
      if (mounted) setState(() { _loading = false; _error = 'Network error. Please try again.'; });
    }
  }

  Widget _buildOtpStep() {
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
                color: Theme.of(context).cardColor,
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
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Didn't receive code? ",
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            GestureDetector(
              onTap: (_resendCountdown > 0 || _isResending)
                  ? null
                  : _handleResendOtp,
              child: _isResending
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF166C46))))
                  : Text(
                      _resendCountdown > 0
                          ? 'Resend in ${_resendCountdown}s'
                          : 'Resend',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _resendCountdown > 0
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF166C46),
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
          onTap: _onLinkAccount,
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

  Future<void> _onLinkAccount() async {
    final filled = _otp.where((d) => d.isNotEmpty).length;
    if (filled < 6) return;
    if (_sessionId == null || _otpRef == null) {
      setState(() => _error = 'Session expired. Please start again.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final api = ref.read(onboardingApiServiceProvider);
      log('[auth] verifyOtp sessionId=$_sessionId otpRef=$_otpRef code=${_otp.join()}');
      final res = await api.verifyOtp(
        VerifyOnboardingOtpRequest(
          sessionId: _sessionId!,
          otpCode: _otp.join(),
          otpReference: _otpRef!,
        ),
      );
      if (!mounted) return;
      log('[auth] verifyOtp → isSuccess=${res.isSuccess} errorCode=${res.errorCode}');
      setState(() => _loading = false);
      if (res.isSuccess && res.data != null && res.data!.isVerified) {
        Navigator.pop(context, _sessionId);
      } else {
        setState(() => _error = res.errorMessage ?? 'Invalid code. Please try again.');
      }
    } catch (e) {
      log('[auth] verifyOtp error: $e');
      if (mounted) setState(() { _loading = false; _error = 'Network error. Please try again.'; });
    }
  }

  Future<void> _handleResendOtp() async {
    if (_sessionId == null) return;
    setState(() { _isResending = true; _error = null; });
    try {
      final api = ref.read(onboardingApiServiceProvider);
      final res = await api.resendOtp(
        ResendOnboardingOtpRequest(sessionId: _sessionId!),
      );
      if (!mounted) return;
      setState(() => _isResending = false);
      if (res.isSuccess) {
        _startResendCountdown();
      } else {
        setState(() => _error = res.errorMessage ?? 'Failed to resend OTP.');
      }
    } catch (e) {
      if (mounted) setState(() { _isResending = false; _error = 'Network error.'; });
    }
  }

  void _startResendCountdown() {
    _resendCountdown = 45;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

}

// ── Continue Linking (Full-Screen) ─────────────────────────────────────────────

class _ContinueLinkingPage extends ConsumerStatefulWidget {
  final String sessionId;
  const _ContinueLinkingPage({required this.sessionId});

  @override
  ConsumerState<_ContinueLinkingPage> createState() =>
      _ContinueLinkingPageState();
}

class _ContinueLinkingPageState
    extends ConsumerState<_ContinueLinkingPage> {
  int _step = 0; // 0=facial, 1=password, 2=pin, 3=success
  bool _loading = false;
  String? _error;
  String? _message;

  // Camera / facial
  CameraController? _cameraController;
  bool _cameraActive = false;
  bool _verifyingFace = false;
  String? _cameraError;

  // Password
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // PIN
  final List<String> _pin = List.filled(4, '');
  bool _creatingPin = false;

  @override
  void initState() {
    super.initState();
    _resumeAndJump();
  }

  Future<void> _resumeAndJump() async {
    try {
      final deviceId = await StorageService.getDeviceId();
      final api = ref.read(onboardingApiServiceProvider);
      final res = await api.resume(ResumeOnboardingRequest(
        sessionId: widget.sessionId,
        deviceId: deviceId,
      ));
      if (!mounted) return;
      if (res.isSuccess && res.data != null) {
        final stage = res.data!.currentStage;
        log('[continue] resume → stage=$stage');
        if (stage.index >= OnboardingStage.coreBankingAccountCreated.index) {
          setState(() => _step = 3);
        } else if (stage.index >= OnboardingStage.identityAccountCreated.index) {
          setState(() => _step = 2);
        } else if (stage.index >= OnboardingStage.facialValidationCompleted.index) {
          setState(() => _step = 1);
        }
        // else stays at step 0 (facial)
      }
    } catch (e) {
      log('[continue] resume error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _step == 1
            ? _buildPasswordStep()
            : _step == 2
                ? _buildPinStep()
                : Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
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
                  Positioned.fill(
                    child: CustomPaint(
                      painter: NoisePainter(opacity: 0.055, seed: 7),
                    ),
                  ),
                  if (_step == 0) _buildFacialStep(),
                  if (_step == 3) _buildSuccess(),
                ],
              ),
      ),
    );
  }

  // ── Facial Verification ─────────────────────────────────────────

  Widget _buildFacialStep() {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.18)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_cameraActive &&
                      _cameraController != null &&
                      _cameraController!.value.isInitialized)
                    Positioned.fill(
                        child: CameraPreview(_cameraController!))
                  else
                    Container(color: Colors.black87),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _OvalOverlayPainter(
                          color: const Color(0xFFD4AF37)),
                    ),
                  ),
                  Positioned(
                    top: 60,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8)
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A)
                                  .withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.remove_red_eye_outlined,
                                color: Color(0xFF16A34A),
                                size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text('Face Verification',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827))),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 24,
                    right: 24,
                    child: GestureDetector(
                      onTap: _cameraActive
                          ? _capturePhoto
                          : _requestCameraPermission,
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: AppColors.goldGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            _cameraActive
                                ? 'Take Selfie'
                                : 'Start Camera',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_cameraError != null)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(_cameraError!,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14),
                                textAlign: TextAlign.center),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!,
                    style: const TextStyle(
                        color: Colors.red, fontSize: 12)),
              ),
          ],
        ),
        if (_verifyingFace) _buildVerifyingOverlay(),
      ],
    );
  }

  Widget _buildVerifyingOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xE60B1F14),
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(
              horizontal: 28, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Color(0xFF166C46)),
                ),
              ),
              SizedBox(height: 22),
              Text('Verifying your face',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827))),
              SizedBox(height: 8),
              Text('Hold on a moment ...',
                  style: TextStyle(
                      fontSize: 14, color: Color(0xFF6B7280))),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestCameraPermission() async {
    if (kIsWeb) {
      await _initializeCamera();
      return;
    }
    final status = await Permission.camera.request();
    if (status.isGranted) {
      await _initializeCamera();
    } else {
      setState(() {
        _cameraError = 'Camera permission denied.';
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'No camera found');
        return;
      }
      final front = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first);
      _cameraController = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _cameraActive = true;
          _cameraError = null;
        });
      }
    } catch (e) {
      setState(() {
        _cameraError = 'Failed to initialize camera: $e';
        _cameraActive = false;
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }
    try {
      final image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      setState(() {
        _cameraActive = false;
        _verifyingFace = true;
      });
      _cameraController?.dispose();
      _cameraController = null;

      final api = ref.read(onboardingApiServiceProvider);
      final res = await api.validateFace(FacialValidationRequest(
        sessionId: widget.sessionId,
        capturedImageBase64: base64Image,
        livenessCheckPassed: true,
      ));
      if (!mounted) return;
      setState(() => _verifyingFace = false);
      if (res.isSuccess && res.data != null && res.data!.isMatch) {
        setState(() {
          _step = 1;
          _error = null;
        });
      } else {
        setState(() {
          _error = res.errorMessage ??
              'Face verification failed. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _cameraError = 'Failed to capture photo: $e';
        _verifyingFace = false;
      });
    }
  }

  // ── Create Password ─────────────────────────────────────────────

  Widget _buildPasswordStep() {
    return Container(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text('Create Password',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text(
              'Create a password to secure your account',
              style: TextStyle(
                  fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), height: 1.5),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _passwordCtrl,
              obscureText: !_showPassword,
              style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                hintText: 'Min 8 characters',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                suffixIcon: GestureDetector(
                  onTap: () =>
                      setState(() => _showPassword = !_showPassword),
                  child: Icon(
                    _showPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 18,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1F2E) : const Color(0xFFF3F4F6),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Min 8 chars with uppercase, lowercase & number',
                style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordCtrl,
              obscureText: !_showConfirmPassword,
              style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                hintText: 'Re-enter your password',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                suffixIcon: GestureDetector(
                  onTap: () => setState(
                      () => _showConfirmPassword = !_showConfirmPassword),
                  child: Icon(
                    _showConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    size: 18,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1F2E) : const Color(0xFFF3F4F6),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style:
                      const TextStyle(color: Colors.red, fontSize: 12)),
            ],
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _onPasswordContinue,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF166C46),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: _loading
                      ? (_message != null
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              Colors.white)),
                                ),
                                const SizedBox(width: 10),
                                Text(_message!,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white)),
                              ],
                            )
                          : const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                          Colors.white))))
                      : const Text('Continue →',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onPasswordContinue() async {
    final password = _passwordCtrl.text;
    final confirmPassword = _confirmPasswordCtrl.text;
    if (password.length < 8) {
      setState(
          () => _error = 'Password must be at least 8 characters.');
      return;
    }
    if (password != confirmPassword) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {_loading = true;_error = null;});
    try {
      final api = ref.read(onboardingApiServiceProvider);
      log('[auth] createPassword sessionId=${widget.sessionId}');
      final res = await api.createPassword(CreatePasswordRequest(
        sessionId: widget.sessionId,
        password: password,
        confirmPassword: confirmPassword,
      ));
      if (!mounted) return;
      log('[auth] createPassword → isSuccess=${res.isSuccess} errorCode=${res.errorCode}');
      if (!res.isSuccess || res.data == null) {
        setState(() {_loading = false;_error = res.errorMessage ?? 'Failed to set password.';});
        return;
      }
      setState(() => _message = 'Finalizing your account...');
      final ready = await _waitForPinStage(api);
      if (!mounted) return;
      setState(() {_loading = false;_message = null;});
      if (ready) {
        setState(() => _step = 2);
      } else {
        setState(() => _error = 'Account setup is still processing. Please try again in a moment.');
      }
    } catch (e) {
      log('[auth] createPassword error: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Network error. Please try again.';
        });
      }
    }
  }

  // ── Create PIN ────────────────────────────────────────────────────

  Widget _buildPinStep() {
    final filled = _pin.where((d) => d.isNotEmpty).length;
    return Container(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text('Create PIN',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text(
              'Secure your account with a 4-digit PIN',
              style: TextStyle(
                  fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), height: 1.5),
            ),
            const SizedBox(height: 36),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final hasDot = i < filled;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 18,
                  height: 18,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasDot
                        ? const Color(0xFF166C46)
                        : Colors.transparent,
                    border: Border.all(
                      color: hasDot
                          ? const Color(0xFF166C46)
                          : const Color(0xFFD1D5DB),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),
            ...([['1','2','3'],['4','5','6'],['7','8','9'],['','0','⌫']].map((row) =>
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: row.map((k) => Expanded(
                    child: k.isEmpty ? const SizedBox() : GestureDetector(
                      onTap: () {
                        if (k == '⌫') {
                          final idx = _pin.lastIndexWhere((d) => d.isNotEmpty);
                          if (idx != -1) setState(() => _pin[idx] = '');
                        } else {
                          final idx = _pin.indexWhere((d) => d.isEmpty);
                          if (idx != -1) {
                            setState(() => _pin[idx] = k);
                          }
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 46,
                        decoration: BoxDecoration(
                          color: context.bgInput,
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
            const SizedBox(height: 20),
            GestureDetector(
              onTap: filled == 4 ? _onPinComplete : null,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: filled == 4 ? const Color(0xFF166C46) : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: _creatingPin
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : const Text('Proceed →',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }

  Future<bool> _waitForPinStage(OnboardingApiService api) async {
    const maxAttempts = 30;
    for (var i = 0; i < maxAttempts; i++) {
      try {
        final res = await api.getSession(widget.sessionId);
        if (!mounted) return false;
        if (res.isSuccess && res.data != null) {
          final stage = res.data!.currentStage;
          log('[auth] poll session stage=$stage');
          if (stage.index >= OnboardingStage.pinCreationPending.index) {
            return true;
          }
        }
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return false;
    }
    return false;
  }

  Future<void> _onPinComplete() async {
    setState(() { _creatingPin = true; _error = null; });
    try {
      final api = ref.read(onboardingApiServiceProvider);
      log('[auth] createPin sessionId=${widget.sessionId}');
      final res = await api.createPin(CreatePinRequest(
        sessionId: widget.sessionId,
        pin: _pin.join(),
        confirmPin: _pin.join(),
      ));
      if (!mounted) return;
      setState(() => _creatingPin = false);
      log('[auth] createPin → isSuccess=${res.isSuccess} errorCode=${res.errorCode}');
      if (res.isSuccess && res.data != null) {
        await StorageService.savePin(_pin.join());
        setState(() => _step = 3);
      } else {
        setState(() {
          _pin.fillRange(0, 4, '');
          _error = res.errorMessage ?? 'Failed to create PIN.';
        });
      }
    } catch (e) {
      log('[auth] createPin error: $e');
      if (mounted) {
        setState(() {
          _creatingPin = false;
          _pin.fillRange(0, 4, '');
          _error = 'Network error. Please try again.';
        });
      }
    }
  }

  // ── Success ─────────────────────────────────────────────────────

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle,
                color: Color(0xFF16A34A), size: 72),
            const SizedBox(height: 24),
            const Text('Account Linked!',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
            const SizedBox(height: 12),
            const Text(
              'Your RimaPay account is now linked\nto this device.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                  height: 1.5),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () {
                Navigator.of(context)
                  ..pop()
                  ..pop();
              },
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF166C46),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('Continue to Account',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
          ),
        ],
      ),
    ),
  );
  }
}

// ── Oval Overlay Painter ───────────────────────────────────────────────────────

class _OvalOverlayPainter extends CustomPainter {
  final Color color;
  const _OvalOverlayPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.55);
    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 20),
      width: size.width * 0.72,
      height: size.height * 0.52,
    );
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawOval(ovalRect, borderPaint);
  }

  @override
  bool shouldRepaint(_OvalOverlayPainter old) => old.color != color;
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
        color: _focused
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Theme.of(context).colorScheme.surface,
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

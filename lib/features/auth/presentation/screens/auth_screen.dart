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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Onboarding2.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.4),
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.9),
              ],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Header with back button and floating biometric
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button
                        GestureDetector(
                          onTap: () {
                            context.pop();
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        // Floating Biometric Button
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: GestureDetector(
                            onTap: _handleBiometricLogin,
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00B252).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFF00B252).withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // Pulse effect
                                  AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) {
                                      return Center(
                                        child: Container(
                                          width: 48 * _pulseAnimation.value,
                                          height: 48 * _pulseAnimation.value,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF00B252).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(24 * _pulseAnimation.value),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  // Icon
                                  Center(
                                    child: _isBiometricLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : AnimatedBuilder(
                                            animation: _rotationController,
                                            builder: (context, child) {
                                              return Transform.rotate(
                                                angle: _rotationController.value * 0.1,
                                                child: const Icon(
                                                  Icons.fingerprint,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              );
                                            },
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
                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom - 80, // Approximate header height
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Logo and Title
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: Column(
                                  children: [
                                    Image.asset(
                                      "assets/images/AppIcon.png",
                                      width: 96,
                                      height: 96,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'RimaPay',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Welcome Back',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sign in to your RimaPay account',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 40),
                              // Form Fields
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Phone Number Field
                                  Text(
                                    'Phone Number',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    onChanged: (value) {
                                      setState(() {
                                        _loginForm['phoneNumber'] = addLeadingZero(value);
                                      });
                                    },
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Enter phone number',
                                      // prefixIcon: Padding(
                                      //   padding: EdgeInsets.only(
                                      //     left: 20,
                                      //     right: 5,
                                      //   ),
                                      //   child: Column(
                                      //     mainAxisSize: MainAxisSize.min,
                                      //     mainAxisAlignment: MainAxisAlignment.center,
                                      //     crossAxisAlignment: CrossAxisAlignment.start,
                                      //     children: [
                                      //       Text(
                                      //         "+234",
                                      //         textAlign: TextAlign.center,
                                      //         style: TextStyle(
                                      //           color: Colors.white.withOpacity(0.6),
                                      //           fontSize: 14,
                                      //         ),
                                      //       ),
                                      //     ],
                                      //   ),
                                      // ),
                                      hintStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 14,
                                      ),
                                      fillColor: Colors.white.withOpacity(0.2),
                                      filled: true,
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Password Field
                                  Text(
                                    'Password',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    obscureText: !_showPassword,
                                    onChanged: (value) {
                                      setState(() {
                                        _loginForm['password'] = value;
                                      });
                                    },
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Enter your password',
                                      hintStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 14,
                                      ),
                                      fillColor: Colors.white.withOpacity(0.2),
                                      filled: true,
                                      suffixIcon: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _showPassword = !_showPassword;
                                          });
                                        },
                                        child: Icon(
                                          _showPassword ? Icons.visibility_off : Icons.visibility,
                                          color: Colors.white.withOpacity(0.6),
                                          size: 16,
                                        ),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                  // Forgot Password
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: GestureDetector(
                                      onTap: () {
                                        // Handle forgot password
                                      },
                                      child: const Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          color: Color(0xFF00B252),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Login Buttons
                              Column(
                                children: [
                                  // Regular Login Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: (_loginForm['phoneNumber']!.isNotEmpty && _loginForm['password']!.isNotEmpty && !_isLoading) ? _handleLoginSubmit : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF00B252),
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Text(
                                              'Sign In',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Biometric Login Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.4),
                                          width: 1,
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          // Shimmer effect
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: AnimatedBuilder(
                                              animation: _shimmerAnimation,
                                              builder: (context, child) {
                                                return Transform.translate(
                                                  offset: Offset(
                                                    _shimmerAnimation.value.dx * 200,
                                                    0,
                                                  ),
                                                  child: Container(
                                                    width: 100,
                                                    height: 48,
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          Colors.transparent,
                                                          Colors.white.withOpacity(0.1),
                                                          Colors.transparent,
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          // Button content
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: _handleBiometricLogin,
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    if (_isBiometricLoading) ...[
                                                      const SizedBox(
                                                        height: 20,
                                                        width: 20,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      const Text(
                                                        'Authenticating...',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ] else ...[
                                                      AnimatedBuilder(
                                                        animation: _rotationController,
                                                        builder: (context, child) {
                                                          return Transform.rotate(
                                                            angle: _rotationController.value * 0.1,
                                                            child: const Icon(
                                                              Icons.fingerprint,
                                                              color: Colors.white,
                                                              size: 20,
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Text(
                                                        _biometricSupported ? 'Login with Biometrics' : 'Biometric Setup Available',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Biometric status
                                  Text(
                                    _biometricSupported ? '🔒 Touch the fingerprint icon to authenticate' : '👆 Tap to set up fingerprint or face ID login',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 12,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Create Account Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account? ",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _currentFlow = Flow.start;
                                      });
                                    },
                                    child: const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        color: Color(0xFF00B252),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Skyscrapper.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.4),
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.9),
              ],
            ),
          ),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Header with back button and login button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back button - styled like login form
                        GestureDetector(
                          onTap: () {
                            context.pop();
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        // Login button
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _currentFlow = Flow.login;
                            });
                          },
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              color: Color(0xFF00B252),
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom - 80, // Approximate header height
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Logo
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: Image.asset(
                                  "assets/images/AppIcon.png",
                                  width: 96,
                                  height: 96,
                                ),
                              ),
                              const SizedBox(height: 32),
                              // Title
                              const Text(
                                'Choose Your Account Type',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              // Subtitle
                              Text(
                                'Select the account type that best suits your needs',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 48),
                              // Account Type Options
                              Column(
                                children: [
                                  _buildAccountTypeCard(
                                    title: 'Personal Account',
                                    subtitle: 'For individual users and personal banking',
                                    icon: Icons.person_outline,
                                    onTap: () {
                                      setState(() {
                                        _currentFlow = Flow.personal;
                                      });
                                      context.pushNamed("personal-account");
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _buildAccountTypeCard(
                                    title: 'Business Account',
                                    subtitle: 'For businesses and organizations',
                                    icon: Icons.business_outlined,
                                    onTap: () {
                                      setState(() {
                                        _currentFlow = Flow.business;
                                      });
                                      context.pushNamed("business-account");
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24), // Extra padding at bottom
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF00B252).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00B252).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.white.withOpacity(0.6),
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
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}

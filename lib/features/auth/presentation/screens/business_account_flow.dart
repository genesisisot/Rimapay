import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rimapay/shared/widgets/noise_painter.dart';
import 'package:rimapay/core/theme/app_colors.dart';

// ─── Step enum ───────────────────────────────────────────────────────────────

enum BusinessAccountStep {
  phoneEntry, // 1. Phone number
  otpVerification, // 2. OTP verification
  emailAddress, // 3. Email address
  createPassword, // 4. Password + confirm
  transactionPin, // 5. Transaction PIN + confirm
  ninBvn, // 6. NIN or BVN
  photoCapture, // 7. Photo capture
  businessDetails, // 8. Business details
  businessAddress, // 9. Business address
  pepDeclaration, // 10. PEP declaration
  sourcesOfRevenue, // 11. Sources of revenue
  success, // Final success/approval
}

// ─── Data class ──────────────────────────────────────────────────────────────

class BusinessInfo {
  String phoneNumber = '';
  String emailAddress = '';
  String password = '';
  String pin = '';
  String idType = 'bvn'; // 'bvn' or 'nin'
  String idNumber = '';
  String businessName = '';
  String businessType = '';
  String rcBnNumber = '';
  String industry = '';
  String streetAddress = '';
  String state = '';
  String lga = '';
  bool? isPep;
  List<String> revenueSources = [];
  String otherRevenueSource = '';
}

// ─── Widget ──────────────────────────────────────────────────────────────────

class BusinessAccountFlow extends ConsumerStatefulWidget {
  const BusinessAccountFlow({super.key});

  @override
  ConsumerState<BusinessAccountFlow> createState() =>
      _BusinessAccountFlowState();
}

class _BusinessAccountFlowState extends ConsumerState<BusinessAccountFlow>
    with TickerProviderStateMixin {
  // ── Step state ─────────────────────────────────────────────────────────────
  BusinessAccountStep _currentStep = BusinessAccountStep.phoneEntry;

  // ── Business info ──────────────────────────────────────────────────────────
  final BusinessInfo _businessInfo = BusinessInfo();

  // ── OTP ────────────────────────────────────────────────────────────────────
  final List<String> _otp = List.filled(6, '');

  // ── PIN ────────────────────────────────────────────────────────────────────
  final List<String> _pin = List.filled(4, '');
  final List<String> _confirmPin = List.filled(4, '');
  bool _showConfirmPin = false;

  // ── Phone numpad ───────────────────────────────────────────────────────────
  String _phoneDigits = '';

  // ── ID verification ────────────────────────────────────────────────────────
  String _idType = 'bvn';
  String _idDigits = '';

  // ── Password ───────────────────────────────────────────────────────────────
  String _password = '';
  String _confirmPassword = '';
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // ── UI state ───────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 0;
  Timer? _resendTimer;

  // ── Revenue sources ────────────────────────────────────────────────────────
  final List<String> _selectedRevenueSources = [];
  final TextEditingController _otherRevenueController = TextEditingController();

  // ── Controllers ────────────────────────────────────────────────────────────
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _rcBnController = TextEditingController();
  final TextEditingController _industryController = TextEditingController();
  final TextEditingController _streetAddressController = TextEditingController();

  // ── Animation ──────────────────────────────────────────────────────────────
  late AnimationController _pageAnimController;
  late AnimationController _congratsConfettiCtrl;
  late List<_CParticle> _confettiParticles;

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _pageAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _congratsConfettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    final rng = math.Random();
    _confettiParticles = List.generate(70, (_) => _CParticle(rng));
  }

  @override
  void dispose() {
    _pageAnimController.dispose();
    _congratsConfettiCtrl.dispose();
    _resendTimer?.cancel();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
    _rcBnController.dispose();
    _industryController.dispose();
    _streetAddressController.dispose();
    _otherRevenueController.dispose();
    super.dispose();
  }

  // ─── Navigation ─────────────────────────────────────────────────────────────

  void _goBack() {
    if (_currentStep == BusinessAccountStep.transactionPin && _showConfirmPin) {
      setState(() {
        _showConfirmPin = false;
        for (int i = 0; i < _confirmPin.length; i++) {
          _confirmPin[i] = '';
        }
      });
      return;
    }
    final steps = BusinessAccountStep.values;
    final idx = steps.indexOf(_currentStep);
    if (idx > 0) {
      _animateTo(steps[idx - 1]);
    } else {
      context.pop();
    }
  }

  void _animateTo(BusinessAccountStep step) {
    if (step == BusinessAccountStep.success) {
      _congratsConfettiCtrl.reset();
      _congratsConfettiCtrl.forward();
    }
    _pageAnimController.reset();
    setState(() => _currentStep = step);
    _pageAnimController.forward();
  }

  void _nextStep() {
    final steps = BusinessAccountStep.values;
    final idx = steps.indexOf(_currentStep);
    if (idx < steps.length - 1) {
      _animateTo(steps[idx + 1]);
    }
  }

  // ─── Step meta ───────────────────────────────────────────────────────────────

  String get _stepTitle {
    switch (_currentStep) {
      case BusinessAccountStep.phoneEntry:
        return 'Phone Number';
      case BusinessAccountStep.otpVerification:
        return 'Verify Phone';
      case BusinessAccountStep.emailAddress:
        return 'Email Address';
      case BusinessAccountStep.createPassword:
        return 'Set Up Password';
      case BusinessAccountStep.transactionPin:
        return 'Transaction PIN';
      case BusinessAccountStep.ninBvn:
        return 'NIN or BVN';
      case BusinessAccountStep.photoCapture:
        return 'Photo Capture';
      case BusinessAccountStep.businessDetails:
        return 'Business Details';
      case BusinessAccountStep.businessAddress:
        return 'Business Address';
      case BusinessAccountStep.pepDeclaration:
        return 'PEP Declaration';
      case BusinessAccountStep.sourcesOfRevenue:
        return 'Sources of Revenue';
      case BusinessAccountStep.success:
        return 'Account Approved';
    }
  }

  bool get _showHeader => _currentStep != BusinessAccountStep.success;

  int get _totalSteps =>
      BusinessAccountStep.values.length - 1; // exclude success

  int get _currentStepIndex {
    final idx = BusinessAccountStep.values.indexOf(_currentStep);
    return idx < _totalSteps ? idx : _totalSteps - 1;
  }

  // ─── Resend timer ──────────────────────────────────────────────────────────

  void _startResendTimer() {
    _resendCountdown = 45;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendCountdown > 0) {
            _resendCountdown--;
          } else {
            timer.cancel();
            _isResending = false;
          }
        });
      }
    });
  }

  // ─── Snackbar ──────────────────────────────────────────────────────────────

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : const Color(0xFF166C46),
    ));
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _goBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F8F3),
        body: Column(
          children: [
            if (_showHeader) _buildHeader(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final statusH = MediaQuery.of(context).padding.top;
    final steps = BusinessAccountStep.values;
    final currentIdx = steps.indexOf(_currentStep);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF073D25), Color(0xFF0B4F2F), Color(0xFF073D25)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: NoisePainter(opacity: 0.04, seed: 3)),
          ),
          Padding(
            padding: EdgeInsets.only(
              top: statusH + 14,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: _goBack,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Progress pills
                    Expanded(
                      child: Row(
                        children: List.generate(_totalSteps, (i) {
                          final done = i <= currentIdx;
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              height: 5,
                              decoration: BoxDecoration(
                                color: done
                                    ? const Color(0xFFD4AF37)
                                    : Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Step counter
                    Text(
                      '${currentIdx + 1}/$_totalSteps',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _stepTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    fontFamily: 'Effra',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step router ─────────────────────────────────────────────────────────────

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case BusinessAccountStep.phoneEntry:
        return _buildPhoneEntryStep();
      case BusinessAccountStep.otpVerification:
        return _buildOtpStep();
      case BusinessAccountStep.emailAddress:
        return _buildEmailStep();
      case BusinessAccountStep.createPassword:
        return _buildCreatePasswordStep();
      case BusinessAccountStep.transactionPin:
        return _buildTransactionPinStep();
      case BusinessAccountStep.ninBvn:
        return _buildNinBvnStep();
      case BusinessAccountStep.photoCapture:
        return _buildPhotoCaptureStep();
      case BusinessAccountStep.businessDetails:
        return _buildBusinessDetailsStep();
      case BusinessAccountStep.businessAddress:
        return _buildBusinessAddressStep();
      case BusinessAccountStep.pepDeclaration:
        return _buildPepStep();
      case BusinessAccountStep.sourcesOfRevenue:
        return _buildSourcesOfRevenueStep();
      case BusinessAccountStep.success:
        return _buildSuccessStep();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 1 — Phone Number
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildPhoneEntryStep() {
    return Column(
      key: const ValueKey('phoneEntry'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What is your phone number?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                    fontFamily: 'Effra',
                  ),
                ),
                const SizedBox(height: 24),
                // Phone display
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _phoneDigits.isNotEmpty
                          ? const Color(0xFF166C46)
                          : const Color(0xFFE4E7EC),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '+234',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                            fontFamily: 'Effra',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _phoneDigits.isEmpty
                            ? '801 234 5678'
                            : _formatPhoneDisplay(_phoneDigits),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _phoneDigits.isEmpty
                              ? const Color(0xFFD1D5DB)
                              : const Color(0xFF111827),
                          fontFamily: 'Effra',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildNumPad(
                  onDigit: (d) {
                    if (_phoneDigits.length < 10) {
                      setState(() => _phoneDigits += d);
                    }
                  },
                  onDelete: () {
                    if (_phoneDigits.isNotEmpty) {
                      setState(() => _phoneDigits =
                          _phoneDigits.substring(0, _phoneDigits.length - 1));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        _buildCTA(
          label: 'Continue',
          onTap: () {
            if (_phoneDigits.length == 10) {
              _businessInfo.phoneNumber = '0$_phoneDigits';
              _nextStep();
            } else {
              _snack('Please enter a valid 10-digit phone number',
                  isError: true);
            }
          },
        ),
      ],
    );
  }

  String _formatPhoneDisplay(String digits) {
    if (digits.length <= 3) return digits;
    if (digits.length <= 6) {
      return '${digits.substring(0, 3)} ${digits.substring(3)}';
    }
    return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 2 — OTP Verification
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildOtpStep() {
    final filled = _otp.where((d) => d.isNotEmpty).length;
    return Column(
      key: const ValueKey('otpVerification'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outline,
                      color: Color(0xFF16A34A), size: 34),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Enter verification code',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    fontFamily: 'Effra',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'We sent a code to +234 $_phoneDigits',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Effra',
                  ),
                ),
                const SizedBox(height: 20),
                // 6 boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) {
                    final hasDigit = _otp[i].isNotEmpty;
                    final isActive = i == filled;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 46,
                      height: 52,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF16A34A)
                              : hasDigit
                                  ? const Color(0xFF16A34A).withOpacity(0.5)
                                  : const Color(0xFFE5E7EB),
                          width: isActive ? 2 : 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          hasDigit ? '•' : '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                // Resend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Didn't receive code? ",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                          fontFamily: 'Effra',
                        )),
                    GestureDetector(
                      onTap: (_resendCountdown > 0 || _isResending)
                          ? null
                          : () {
                              setState(() => _isResending = true);
                              _startResendTimer();
                            },
                      child: _isResending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                      Color(0xFF16A34A))))
                          : Text(
                              _resendCountdown > 0
                                  ? 'Resend in ${_resendCountdown}s'
                                  : 'Resend',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Effra',
                                color: _resendCountdown > 0
                                    ? const Color(0xFF6B7280)
                                    : const Color(0xFF16A34A),
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildNumPad(
                  onDigit: (d) {
                    final idx = _otp.indexWhere((o) => o.isEmpty);
                    if (idx != -1) setState(() => _otp[idx] = d);
                  },
                  onDelete: () {
                    final idx = _otp.lastIndexWhere((o) => o.isNotEmpty);
                    if (idx != -1) setState(() => _otp[idx] = '');
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        _buildCTA(label: 'Continue', onTap: _nextStep),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 3 — Email Address
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildEmailStep() {
    return Column(
      key: const ValueKey('emailAddress'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your business email address',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                    fontFamily: 'Effra',
                  ),
                ),
                const SizedBox(height: 24),
                _sectionLabel('Email Address'),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF111827),
                    fontFamily: 'Effra',
                  ),
                  decoration: _inputDec(hint: 'e.g. business@company.com'),
                  onChanged: (v) => _businessInfo.emailAddress = v.trim(),
                ),
              ],
            ),
          ),
        ),
        _buildCTA(
          label: 'Continue',
          onTap: () {
            if (_emailController.text.contains('@') &&
                _emailController.text.contains('.')) {
              _nextStep();
            } else {
              _snack('Please enter a valid email address', isError: true);
            }
          },
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 4 — Create Password
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildCreatePasswordStep() {
    final strength = _calculatePasswordStrength(_password);
    return Column(
      key: const ValueKey('createPassword'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create a password to secure your account',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                    fontFamily: 'Effra',
                  ),
                ),
                const SizedBox(height: 24),
                _sectionLabel('Password'),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF111827),
                    fontFamily: 'Effra',
                  ),
                  decoration: _inputDec(hint: 'Min 8 characters').copyWith(
                    suffixIcon: GestureDetector(
                      onTap: () =>
                          setState(() => _showPassword = !_showPassword),
                      child: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                  onChanged: (v) => setState(() => _password = v),
                ),
                const SizedBox(height: 8),
                // Strength indicator
                if (_password.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: strength,
                            minHeight: 4,
                            backgroundColor: const Color(0xFFE5E7EB),
                            valueColor: AlwaysStoppedAnimation(
                                _getStrengthColor(strength)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _getStrengthLabel(strength),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getStrengthColor(strength),
                          fontFamily: 'Effra',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Min 8 chars with uppercase, lowercase & number',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                      fontFamily: 'Effra',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _sectionLabel('Confirm Password'),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_showConfirmPassword,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF111827),
                    fontFamily: 'Effra',
                  ),
                  decoration:
                      _inputDec(hint: 'Re-enter your password').copyWith(
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
                  ),
                  onChanged: (v) => setState(() => _confirmPassword = v),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        _buildCTA(
          label: 'Continue',
          onTap: _onPasswordContinue,
        ),
      ],
    );
  }

  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    double s = 0;
    if (password.length >= 8) s += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(password)) s += 0.25;
    if (RegExp(r'[0-9]').hasMatch(password)) s += 0.25;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) s += 0.25;
    return s;
  }

  String _getStrengthLabel(double strength) {
    if (strength <= 0.25) return 'Weak';
    if (strength <= 0.5) return 'Fair';
    if (strength <= 0.75) return 'Strong';
    return 'Very Strong';
  }

  Color _getStrengthColor(double strength) {
    if (strength <= 0.25) return Colors.red;
    if (strength <= 0.5) return Colors.orange;
    if (strength <= 0.75) return const Color(0xFF16A34A);
    return const Color(0xFF166C46);
  }

  void _onPasswordContinue() {
    if (_password.length < 8) {
      _snack('Password must be at least 8 characters', isError: true);
      return;
    }
    if (_password != _confirmPassword) {
      _snack('Passwords do not match. Please try again.', isError: true);
      return;
    }
    _businessInfo.password = _password;
    _nextStep();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 5 — Transaction PIN (Create + Confirm combined)
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildTransactionPinStep() {
    if (!_showConfirmPin) {
      return _buildPinEntry(
        key: const ValueKey('createPin'),
        title: 'Create a PIN',
        subtitle: 'Set up a 4-digit transaction PIN',
        icon: Icons.shield_outlined,
        pinList: _pin,
        onDigit: (d) {
          final idx = _pin.indexWhere((p) => p.isEmpty);
          if (idx != -1) setState(() => _pin[idx] = d);
        },
        onDelete: () {
          final idx = _pin.lastIndexWhere((p) => p.isNotEmpty);
          if (idx != -1) setState(() => _pin[idx] = '');
        },
        onContinue: () {
          if (_pin.every((p) => p.isNotEmpty)) {
            setState(() => _showConfirmPin = true);
          }
        },
      );
    } else {
      return _buildPinEntry(
        key: const ValueKey('confirmPin'),
        title: 'Confirm your PIN',
        subtitle: 'Re-enter your 4-digit PIN to confirm',
        icon: Icons.shield,
        pinList: _confirmPin,
        onDigit: (d) {
          final idx = _confirmPin.indexWhere((p) => p.isEmpty);
          if (idx != -1) setState(() => _confirmPin[idx] = d);
        },
        onDelete: () {
          final idx = _confirmPin.lastIndexWhere((p) => p.isNotEmpty);
          if (idx != -1) setState(() => _confirmPin[idx] = '');
        },
        onContinue: () {
          if (_confirmPin.join() != _pin.join()) {
            _snack('PINs do not match. Please try again.', isError: true);
            setState(() {
              for (int i = 0; i < _confirmPin.length; i++) {
                _confirmPin[i] = '';
              }
            });
            return;
          }
          _businessInfo.pin = _pin.join();
          _nextStep();
        },
      );
    }
  }

  Widget _buildPinEntry({
    required Key key,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<String> pinList,
    required void Function(String) onDigit,
    required VoidCallback onDelete,
    required VoidCallback onContinue,
  }) {
    final filled = pinList.where((d) => d.isNotEmpty).length;
    return Column(
      key: key,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: const Color(0xFF16A34A), size: 34),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    fontFamily: 'Effra',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Effra',
                  ),
                ),
                const SizedBox(height: 36),
                // 4 dot indicators
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
                            ? const Color(0xFF16A34A)
                            : Colors.transparent,
                        border: Border.all(
                          color: hasDot
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFD1D5DB),
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 40),
                _buildNumPad(onDigit: onDigit, onDelete: onDelete),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        _buildCTA(label: 'Continue', onTap: onContinue),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 6 — NIN or BVN
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildNinBvnStep() {
    const maxLen = 11;
    final filled = _idDigits.length;

    return Column(
      key: const ValueKey('ninBvn'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verify your identity with your NIN or BVN',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                    fontFamily: 'Effra',
                  ),
                ),
                const SizedBox(height: 20),
                // BVN / NIN toggle
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: ['bvn', 'nin'].map((type) {
                      final selected = _idType == type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _idType = type;
                            _idDigits = '';
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF16A34A)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Center(
                              child: Text(
                                type.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Effra',
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                // Label
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _idType == 'bvn'
                          ? 'Bank Verification Number (BVN)'
                          : 'National Identification Number (NIN)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                        fontFamily: 'Effra',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // 11 individual boxes
                Row(
                  children: List.generate(maxLen, (i) {
                    final hasDigit = i < filled;
                    final isActive = i == filled;
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        height: 44,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive
                                ? const Color(0xFF16A34A)
                                : hasDigit
                                    ? const Color(0xFF16A34A).withOpacity(0.4)
                                    : const Color(0xFFE5E7EB),
                            width: isActive ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            hasDigit ? _idDigits[i] : '',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  _idType == 'bvn'
                      ? 'Dial *565*0# on any network to retrieve your BVN'
                      : 'Dial *346# to retrieve your NIN',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                    fontFamily: 'Effra',
                  ),
                ),
                const SizedBox(height: 20),
                _buildNumPad(
                  onDigit: (d) {
                    if (_idDigits.length < maxLen) {
                      setState(() => _idDigits += d);
                    }
                  },
                  onDelete: () {
                    if (_idDigits.isNotEmpty) {
                      setState(() => _idDigits =
                          _idDigits.substring(0, _idDigits.length - 1));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        _buildCTA(
          label: 'Continue',
          onTap: () {
            if (_idDigits.length == 11) {
              _businessInfo.idType = _idType;
              _businessInfo.idNumber = _idDigits;
              _nextStep();
            } else {
              _snack('Please enter a valid 11-digit ${_idType.toUpperCase()}',
                  isError: true);
            }
          },
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 7 — Photo Capture
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildPhotoCaptureStep() {
    return Column(
      key: const ValueKey('photoCapture'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FAF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF166C46).withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.camera_alt_outlined,
                          color: Color(0xFF166C46), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Take a clear selfie for identity verification.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF166C46),
                            height: 1.4,
                            fontFamily: 'Effra',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Camera placeholder
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    height: 300,
                    color: Colors.black87,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white54, size: 44),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Camera preview will appear here',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                            fontFamily: 'Effra',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Tip chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _tipChip('Good lighting'),
                    _tipChip('No glasses'),
                    _tipChip('Face forward'),
                    _tipChip('Plain background'),
                  ],
                ),
              ],
            ),
          ),
        ),
        _buildCTA(
          label: 'Take Photo',
          onTap: () {
            // Mock delay simulating photo capture
            setState(() => _isLoading = true);
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted) {
                setState(() => _isLoading = false);
                _nextStep();
              }
            });
          },
          loading: _isLoading,
        ),
      ],
    );
  }

  Widget _tipChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontFamily: 'Effra',
          )),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 8 — Business Details
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildBusinessDetailsStep() {
    return Column(
      key: const ValueKey('businessDetails'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tell us about your business',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                    fontFamily: 'Effra',
                  ),
                ),
                const SizedBox(height: 24),
                _sectionLabel('Business Name'),
                const SizedBox(height: 8),
                TextField(
                  controller: _businessNameController,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF111827),
                    fontFamily: 'Effra',
                  ),
                  decoration: _inputDec(hint: 'e.g. Ayo Ventures Ltd'),
                  onChanged: (v) => _businessInfo.businessName = v.trim(),
                ),
                const SizedBox(height: 16),
                _sectionLabel('Business Type'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showOptionsSheet(
                    'Business Type',
                    [
                      'Sole Proprietorship',
                      'Partnership',
                      'LLC',
                      'PLC',
                    ],
                    (v) => setState(() => _businessInfo.businessType = v),
                  ),
                  child: _dropdownField(
                    value: _businessInfo.businessType.isEmpty
                        ? null
                        : _businessInfo.businessType,
                    hint: 'Select business type',
                  ),
                ),
                const SizedBox(height: 16),
                _sectionLabel('RC/BN Number'),
                const SizedBox(height: 8),
                TextField(
                  controller: _rcBnController,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF111827),
                    fontFamily: 'Effra',
                  ),
                  decoration:
                      _inputDec(hint: 'e.g. RC1234567 or BN1234567'),
                  onChanged: (v) => _businessInfo.rcBnNumber = v.trim(),
                ),
                const SizedBox(height: 16),
                _sectionLabel('Industry'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showOptionsSheet(
                    'Industry',
                    [
                      'Technology',
                      'Finance',
                      'Agriculture',
                      'Manufacturing',
                      'Retail',
                      'Healthcare',
                      'Education',
                      'Transportation',
                      'Real Estate',
                      'Others',
                    ],
                    (v) => setState(() {
                      _businessInfo.industry = v;
                      _industryController.text = v;
                    }),
                  ),
                  child: _dropdownField(
                    value: _businessInfo.industry.isEmpty
                        ? null
                        : _businessInfo.industry,
                    hint: 'Select industry',
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        _buildCTA(label: 'Continue', onTap: _nextStep),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 9 — Business Address
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildBusinessAddressStep() {
    final states = [
      'Abia',
      'Adamawa',
      'Akwa Ibom',
      'Anambra',
      'Bauchi',
      'Bayelsa',
      'Benue',
      'Borno',
      'Cross River',
      'Delta',
      'Ebonyi',
      'Edo',
      'Ekiti',
      'Enugu',
      'FCT',
      'Gombe',
      'Imo',
      'Jigawa',
      'Kaduna',
      'Kano',
      'Katsina',
      'Kebbi',
      'Kogi',
      'Kwara',
      'Lagos',
      'Nasarawa',
      'Niger',
      'Ogun',
      'Ondo',
      'Osun',
      'Oyo',
      'Plateau',
      'Rivers',
      'Sokoto',
      'Taraba',
      'Yobe',
      'Zamfara',
    ];

    return Column(
      key: const ValueKey('businessAddress'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Where is your business located?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                    fontFamily: 'Effra',
                  ),
                ),
                const SizedBox(height: 24),
                _sectionLabel('Street Address'),
                const SizedBox(height: 8),
                TextField(
                  controller: _streetAddressController,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF111827),
                    fontFamily: 'Effra',
                  ),
                  decoration:
                      _inputDec(hint: 'e.g. 15 Adeola Odeku Street, VI'),
                  onChanged: (v) => _businessInfo.streetAddress = v.trim(),
                ),
                const SizedBox(height: 16),
                _sectionLabel('State'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showOptionsSheet(
                    'Select State',
                    states,
                    (v) => setState(() => _businessInfo.state = v),
                  ),
                  child: _dropdownField(
                    value: _businessInfo.state.isEmpty
                        ? null
                        : _businessInfo.state,
                    hint: 'Select state',
                  ),
                ),
                const SizedBox(height: 16),
                _sectionLabel('LGA'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showOptionsSheet(
                    'Select LGA',
                    ['Eti-Osa', 'Ikeja', 'Lagos Island', 'Surulere', 'Alimosho', 'Kosofe'],
                    (v) => setState(() => _businessInfo.lga = v),
                  ),
                  child: _dropdownField(
                    value:
                        _businessInfo.lga.isEmpty ? null : _businessInfo.lga,
                    hint: _businessInfo.state.isEmpty
                        ? 'Select state first'
                        : 'Select LGA',
                    enabled: _businessInfo.state.isNotEmpty,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        _buildCTA(label: 'Continue', onTap: _nextStep),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 10 — PEP Declaration
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildPepStep() {
    return Column(
      key: const ValueKey('pepDeclaration'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 32),
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.group,
                      color: Color(0xFF16A34A), size: 60),
                ),
                const SizedBox(height: 28),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    'Are you a Politically Exposed Person?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                      height: 1.4,
                      fontFamily: 'Effra',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    'A PEP (Politically Exposed Person) is someone who currently holds or has held an important public position, which gives them influence over public funds or decisions. This includes family members and close associates of such persons.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                      fontFamily: 'Effra',
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: ['Yes', 'No'].map((label) {
                      final val = label == 'Yes';
                      final selected = _businessInfo.isPep == val;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _businessInfo.isPep = val),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF16A34A)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFE5E7EB),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Effra',
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF374151),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildCTA(
          label: 'Continue',
          onTap: () {
            if (_businessInfo.isPep == null) {
              _snack('Please select Yes or No', isError: true);
              return;
            }
            _nextStep();
          },
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 11 — Sources of Revenue
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildSourcesOfRevenueStep() {
    const sources = [
      'Sales',
      'Services',
      'Investments',
      'Government Contracts',
      'Donations',
      'Other',
    ];

    return Column(
      key: const ValueKey('sourcesOfRevenue'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select all sources of revenue for your business',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                    fontFamily: 'Effra',
                  ),
                ),
                const SizedBox(height: 24),
                ...sources.map((source) {
                  final isSelected = _selectedRevenueSources.contains(source);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedRevenueSources.remove(source);
                        } else {
                          _selectedRevenueSources.add(source);
                        }
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF166C46)
                              : const Color(0xFFE4E7EC),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF166C46)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF166C46)
                                    : const Color(0xFFD1D5DB),
                                width: 1.5,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 14)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            source,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF374151),
                              fontFamily: 'Effra',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (_selectedRevenueSources.contains('Other')) ...[
                  const SizedBox(height: 8),
                  _sectionLabel('Please specify'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _otherRevenueController,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF111827),
                      fontFamily: 'Effra',
                    ),
                    decoration: _inputDec(hint: 'Describe other revenue source'),
                    onChanged: (v) =>
                        _businessInfo.otherRevenueSource = v.trim(),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        _buildCTA(
          label: 'Continue',
          onTap: () {
            if (_selectedRevenueSources.isEmpty) {
              _snack('Please select at least one revenue source',
                  isError: true);
              return;
            }
            _businessInfo.revenueSources = List.from(_selectedRevenueSources);
            // Mock delay simulating submission
            setState(() => _isLoading = true);
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) {
                setState(() => _isLoading = false);
                _nextStep();
              }
            });
          },
          loading: _isLoading,
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // SUCCESS — Approval Screen with Confetti
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildSuccessStep() {
    final accountNumber =
        _phoneDigits.isNotEmpty ? '0$_phoneDigits' : '08XXXXXXXXX';
    return Stack(
      key: const ValueKey('success'),
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B4F2F), Color(0xFF073D25), Color(0xFF166C46)],
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(painter: NoisePainter(opacity: 0.05, seed: 7)),
        ),
        AnimatedBuilder(
          animation: _congratsConfettiCtrl,
          builder: (_, __) => IgnorePointer(
            child: CustomPaint(
              painter: _CConfettiPainter(
                particles: _confettiParticles,
                progress: _congratsConfettiCtrl.value,
              ),
              size: MediaQuery.of(context).size,
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Image.asset(
                'assets/images/mild.png',
                width: 64,
                height: 64,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 2),
                ),
                child: const Icon(Icons.verified_user,
                    color: Colors.white, size: 54),
              ),
              const SizedBox(height: 24),
              const Text(
                'Congratulations!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontFamily: 'Effra',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Your business account has been created successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.75),
                    height: 1.5,
                    fontFamily: 'Effra',
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.account_balance_wallet_outlined,
                                color: Color(0xFF16A34A),
                                size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Your Account Number',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                              fontFamily: 'Effra',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        accountNumber,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                          letterSpacing: 2,
                          fontFamily: 'Effra',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.business_outlined,
                                size: 14, color: Color(0xFF16A34A)),
                            SizedBox(width: 6),
                            Text(
                              'Your business account is now active',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF166534),
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Effra',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go('/home'),
                child: Container(
                  margin: EdgeInsets.fromLTRB(
                      24, 0, 24, MediaQuery.of(context).padding.bottom + 20),
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Go to Dashboard',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF166C46),
                        fontFamily: 'Effra',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // Shared Widgets
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildCTA(
      {String? label,
      bool loading = false,
      VoidCallback? onTap,
      Widget? footerContent}) {
    final enabled = !loading;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: loading ? null : onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                color: enabled ? const Color(0xFF166C46) : const Color(0xFFCCCCCC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : Text(
                        label ?? 'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Effra',
                          color:
                              enabled ? Colors.white : const Color(0xFF9CA3AF),
                        ),
                      ),
              ),
            ),
          ),
          if (footerContent != null) ...[
            const SizedBox(height: 8),
            footerContent,
          ],
        ],
      ),
    );
  }

  Widget _buildNumPad(
      {required void Function(String) onDigit,
      required VoidCallback onDelete}) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫']
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: rows
            .map((row) => Row(
                  children: row.map((key) {
                    if (key.isEmpty) return const Expanded(child: SizedBox());
                    return Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            key == '⌫' ? onDelete() : onDigit(key),
                        child: Container(
                          margin: const EdgeInsets.all(6),
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2))
                            ],
                          ),
                          child: Center(
                            child: key == '⌫'
                                ? const Icon(Icons.backspace_outlined,
                                    size: 20, color: Color(0xFF374151))
                                : Text(key,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF111827),
                                      fontFamily: 'Effra',
                                    )),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ))
            .toList(),
      ),
    );
  }

  InputDecoration _inputDec({String hint = '', Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
          color: Color(0xFFD1D5DB), fontSize: 14, fontFamily: 'Effra'),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE4E7EC))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE4E7EC))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF166C46), width: 1.5)),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF344054),
          fontFamily: 'Effra',
        ));
  }

  Widget _dropdownField({
    required String? value,
    required String hint,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value ?? hint,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Effra',
                color: value != null
                    ? const Color(0xFF111827)
                    : const Color(0xFFD1D5DB),
              ),
            ),
          ),
          Icon(Icons.keyboard_arrow_down,
              color:
                  enabled ? const Color(0xFF6B7280) : const Color(0xFFD1D5DB),
              size: 20),
        ],
      ),
    );
  }

  void _showOptionsSheet(
      String title, List<String> options, void Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    fontFamily: 'Effra',
                  )),
            ),
            const SizedBox(height: 8),
            const Divider(),
            ...options.map((o) => ListTile(
                  title: Text(o,
                      style: const TextStyle(
                          fontSize: 15, fontFamily: 'Effra')),
                  trailing:
                      const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB)),
                  onTap: () {
                    onSelect(o);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Confetti Particle & Painter (preserved)
// ══════════════════════════════════════════════════════════════════════════════

class _CParticle {
  final double x;
  final double startY;
  final double speed;
  final double size;
  final Color color;
  final double wobble;
  final double wobbleSpeed;

  static const _colors = [
    Color(0xFF1A6B35),
    Color(0xFFD4AF37),
    Color(0xFFFBBF24),
    Color(0xFF60A5FA),
    Color(0xFFF472B6),
    Color(0xFFA78BFA),
    Color(0xFFFB7185),
  ];

  _CParticle(math.Random rng)
      : x = rng.nextDouble(),
        startY = -0.1 - rng.nextDouble() * 0.3,
        speed = 0.3 + rng.nextDouble() * 0.6,
        size = 5 + rng.nextDouble() * 7,
        color = _colors[rng.nextInt(_colors.length)],
        wobble = 20 + rng.nextDouble() * 40,
        wobbleSpeed = 2 + rng.nextDouble() * 3;
}

class _CConfettiPainter extends CustomPainter {
  final List<_CParticle> particles;
  final double progress;

  const _CConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in particles) {
      final t = (progress * p.speed) % 1.0;
      if (t <= 0) continue;
      final dy = p.startY + t * 1.3;
      if (dy > 1.1) continue;
      final dx = p.x +
          math.sin(t * math.pi * 2 * p.wobbleSpeed) * p.wobble / size.width;
      paint.color = p.color.withOpacity((1 - t * 0.5).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(dx * size.width, dy * size.height);
      canvas.rotate(t * math.pi * 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.5),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CConfettiPainter old) => old.progress != progress;
}

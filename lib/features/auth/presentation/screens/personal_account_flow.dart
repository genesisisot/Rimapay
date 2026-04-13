import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:rimapay/Constants/En.dart';
import 'package:rimapay/Services/PersonAuthServices/CreatePinService.dart';
import 'package:rimapay/Services/PersonAuthServices/OtpServices.dart';
import 'package:rimapay/Services/PersonAuthServices/PersonalSignUpService.dart';
import 'package:rimapay/Services/SessionServices/GetSessionId.dart';
import 'package:rimapay/Utils/Logics.dart';

import 'package:rimapay/core/Models/CountryStateLgaModel.dart';
import 'package:rimapay/core/Utils/En.dart';
import 'package:rimapay/core/services/GetPlaceDetailsService.dart';
import 'package:rimapay/shared/widgets/noise_painter.dart';
import 'package:rimapay/core/theme/app_colors.dart';

// ─── Step enum ───────────────────────────────────────────────────────────────

enum AccountStep {
  phoneIdEntry, // 1. Phone + BVN/NIN
  otpVerification, // 2. OTP verification
  facialVerification, // 3. Face validation
  personalDetails, // 4. Personal details
  occupation, // 5. Occupation
  createPassword, // 6. Password creation
  createPin, // 7. Create PIN
  confirmPin, // 8. Confirm PIN
  accountCreated, // 9. Account created
  kycComplete, // Final completion
}

// ─── Data classes ─────────────────────────────────────────────────────────────

class PersonalInfo {
  String firstname = '';
  String lastname = '';
  String dateOfBirth = '';
  String gender = '';
  String phoneNumber = '';
  String emailAddress = '';
  String residentialAddress = '';
  String state = '';
  String lga = '';
  String bvn = '';
  String nin = '';
  double? currentLat;
  double? currentLng;
}

class Prediction {
  final String? placeId;
  final String? description;
  final String? lat;
  final String? lng;
  Prediction({this.placeId, this.description, this.lat, this.lng});
}

// ─── Widget ──────────────────────────────────────────────────────────────────

class PersonalAccountFlow extends ConsumerStatefulWidget {
  const PersonalAccountFlow({super.key});

  @override
  ConsumerState<PersonalAccountFlow> createState() =>
      _PersonalAccountFlowState();
}

class _PersonalAccountFlowState extends ConsumerState<PersonalAccountFlow>
    with TickerProviderStateMixin {
  // ── Step state ─────────────────────────────────────────────────────────────
  AccountStep _currentStep = AccountStep.phoneIdEntry;

  // ── Personal info ──────────────────────────────────────────────────────────
  final PersonalInfo _personalInfo = PersonalInfo();
  String _accountType = 'personal';

  // ── OTP / PIN ──────────────────────────────────────────────────────────────
  final List<String> _otp = List.filled(6, '');
  final List<String> _pin = List.filled(4, '');
  final List<String> _confirmPinEntry = List.filled(4, '');
  String _password = '';
  String _confirmPassword = '';

  // ── Phone numpad ───────────────────────────────────────────────────────────
  String _phoneDigits = '';

  // ── ID verification ────────────────────────────────────────────────────────
  String _idType = 'bvn'; // 'bvn' or 'nin'
  String _idDigits = '';

  // ── KYC extras ─────────────────────────────────────────────────────────────
  bool? _isPep;
  String? _occupation;
  String? _annualIncome;

  // ── UI state ───────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _acceptTerms = false;
  bool _cameraActive = false;
  String? _capturedImage;
  String? _cameraError;
  bool _permissionDenied = false;
  bool _isGettingLocation = false;
  bool _creatingPin = false;
  bool _isResending = false;
  int _resendCountdown = 0;
  Timer? _resendTimer;

  // ── Controllers ────────────────────────────────────────────────────────────
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _bvnController = TextEditingController();
  final TextEditingController _ninController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _idDigitsController = TextEditingController();
  final FocusNode _idDigitsFocus = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();

  // ── FocusNodes ─────────────────────────────────────────────────────────────
  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _birthdayFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  final TextEditingController _phoneController = TextEditingController();
  CountryStateLgaModel? selectedState;
  Local? selectedLga;
  List<Local>? locals;
  Prediction? selectedCoordinate;

  CameraController? _cameraController;

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
    _cameraController?.dispose();
    _resendTimer?.cancel();
    _addressController.dispose();
    _idDigitsController.dispose();
    _idDigitsFocus.dispose();
    _birthdayController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bvnController.dispose();
    _ninController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _birthdayFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  // ─── Navigation ─────────────────────────────────────────────────────────────

  void _goBack() {
    final steps = AccountStep.values;
    final idx = steps.indexOf(_currentStep);
    if (idx > 0) {
      _animateTo(steps[idx - 1]);
    } else {
      context.pop();
    }
  }

  void _animateTo(AccountStep step) {
    if (step == AccountStep.accountCreated || step == AccountStep.kycComplete) {
      _congratsConfettiCtrl.reset();
      _congratsConfettiCtrl.forward();
    }
    _pageAnimController.reset();
    setState(() => _currentStep = step);
    _pageAnimController.forward();
  }

  void _nextStep() {
    final steps = AccountStep.values;
    final idx = steps.indexOf(_currentStep);
    if (idx < steps.length - 1) {
      _animateTo(steps[idx + 1]);
    }
  }

  // ─── Step meta ───────────────────────────────────────────────────────────────

  String get _stepTitle {
    switch (_currentStep) {
      case AccountStep.phoneIdEntry:
        return 'Phone & ID Verification';
      case AccountStep.otpVerification:
        return 'Verify Phone';
      case AccountStep.facialVerification:
        return 'Face Verification';
      case AccountStep.personalDetails:
        return 'Personal Details';
      case AccountStep.occupation:
        return 'Occupation';
      case AccountStep.createPassword:
        return 'Create Password';
      case AccountStep.createPin:
        return 'Create PIN';
      case AccountStep.confirmPin:
        return 'Confirm PIN';
      case AccountStep.accountCreated:
        return 'Account Created';
      case AccountStep.kycComplete:
        return 'Account Verified';
    }
  }

  bool get _showHeader =>
      _currentStep != AccountStep.accountCreated &&
      _currentStep != AccountStep.kycComplete;

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Provider listeners (unchanged from original)
    ref.listen<PersonalSignupResponse?>(signupResponseStateProvider,
        (previous, next) {
      if (next != null) {
        setState(() => _isLoading = false);
        if (next.status == SUCCESS) {
          _animateTo(AccountStep.otpVerification);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                next.errmessage ?? 'Verification code sent to your phone.'),
            backgroundColor: const Color(0xFF166C46),
          ));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(next.errmessage ??
                'Failed to create account. Please try again.'),
            backgroundColor: Colors.red,
          ));
        }
      }
    });

    ref.listen(verifyOtpResponseStateProvider, (prev, next) {
      setState(() => _isLoading = false);
      if (next?.model != null) {
        _animateTo(AccountStep.createPin);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              next?.errmessage ?? 'Failed to verify OTP. Please try again.'),
          backgroundColor: Colors.red,
        ));
      }
    });

    ref.listen(resendOtpResponseStateProvider, (prev, next) {
      setState(() => _isResending = false);
      if (next?.model != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('OTP Resent Successfully'),
          backgroundColor: Colors.green,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next?.errmessage ?? 'Failed to resend OTP.'),
          backgroundColor: Colors.red,
        ));
      }
    });

    ref.listen(createPinResponseStateProvider, (prev, next) {
      setState(() => _creatingPin = false);
      if (next?.model != null) {
        _animateTo(AccountStep.accountCreated);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next?.errmessage ?? ERROR_TEXT),
          backgroundColor: Colors.red,
        ));
      }
    });

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
    final steps = AccountStep.values;
    final currentIdx = steps.indexOf(_currentStep);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
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
                        children: List.generate(steps.length, (i) {
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
                      '${currentIdx + 1}/${steps.length}',
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
      case AccountStep.phoneIdEntry:
        return _buildPhoneIdEntryStep();
      case AccountStep.otpVerification:
        return _buildOtpStep();
      case AccountStep.facialVerification:
        return _buildFacialVerificationStep();
      case AccountStep.createPassword:
        return _buildCreatePasswordStep();
      case AccountStep.createPin:
        return _buildCreatePinStep();
      case AccountStep.confirmPin:
        return _buildConfirmPinStep();
      case AccountStep.accountCreated:
        return _buildAccountCreatedStep();
      case AccountStep.personalDetails:
        return _buildPersonalDetailsStep();
      case AccountStep.occupation:
        return _buildOccupationStep();
      case AccountStep.kycComplete:
        return _buildKycCompleteStep();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 0 — Account Type Selection
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildAccountTypeStep() {
    final types = [
      {
        'id': 'personal',
        'title': 'Personal',
        'sub': 'For individuals',
        'icon': Icons.person,
        'color': const Color(0xFF16A34A),
        'badge': '',
        'features': [
          'Send & receive money',
          'Pay bills instantly',
          'Save & invest'
        ],
      },
      {
        'id': 'business',
        'title': 'Business',
        'sub': 'For entrepreneurs',
        'icon': Icons.business_center,
        'color': const Color(0xFF7C3AED),
        'badge': 'PRO',
        'features': [
          'Accept payments',
          'Invoice & track',
          'Analytics & reports'
        ],
      },
      {
        'id': 'underbanking',
        'title': 'Underbanked',
        'sub': 'Financial Inclusion',
        'icon': Icons.group,
        'color': const Color(0xFF2563EB),
        'badge': '',
        'features': ['Micro-loans', 'Savings groups', 'Financial literacy'],
      },
    ];

    return Column(
      key: const ValueKey('accountType'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select what best describes you',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 20),
                ...types.map((t) {
                  final selected = _accountType == t['id'];
                  final color = t['color'] as Color;
                  final features = t['features'] as List<String>;
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _accountType = t['id'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected ? color : const Color(0xFFE5E7EB),
                          width: selected ? 2 : 1,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(t['icon'] as IconData,
                                color: color, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      t['title'] as String,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    if ((t['badge'] as String).isNotEmpty) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF7C3AED),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          t['badge'] as String,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  t['sub'] as String,
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF6B7280)),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 4,
                                  children: features
                                      .map((f) => Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.circle,
                                                  size: 6, color: color),
                                              const SizedBox(width: 4),
                                              Text(f,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Color(0xFF374151))),
                                            ],
                                          ))
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: selected ? color : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: selected
                                      ? color
                                      : const Color(0xFFD1D5DB),
                                  width: 2),
                            ),
                            child: selected
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 14)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        _buildCTA(label: 'Continue →', onTap: _onAccountTypeContinue),
      ],
    );
  }

  void _onAccountTypeContinue() {
    if (_accountType == 'business') {
      context.pushNamed('business-account');
    } else {
      // Navigate regardless of validation
      _nextStep();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 1 — Phone/Email + BVN/NIN
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildPhoneIdEntryStep() {
    final isEmailMode = _idType == 'email';
    final isPhoneMode = _idType == 'phone';
    final isIdMode = _idType == 'bvn' || _idType == 'nin';

    return Column(
      key: const ValueKey('phoneIdEntry'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter your phone number and ID for verification',
                  style: TextStyle(
                      fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
                ),
                const SizedBox(height: 24),

                // ID VERIFICATION SECTION (BVN/NIN) - FIRST
                const Text(
                  'ID Verification',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your phone must match what is registered with your BVN/NIN',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),

                // BVN/NIN toggle
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: ['bvn', 'nin'].map((type) {
                      final selected = _idType == type;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _idType = type;
                            _idDigits = '';
                            _idDigitsController.clear();
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF16A34A)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                type.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
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
                // ID digits input
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _idType.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151)),
                    ),
                    Text(
                      _idType == 'bvn'
                          ? 'Where to find BVN?'
                          : 'Where to find NIN?',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF16A34A)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // 11 digit boxes for BVN or NIN with hidden TextField
                GestureDetector(
                  onTap: () => _idDigitsFocus.requestFocus(),
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    children: [
                      _buildIdDigitsInput(),
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0,
                          child: TextField(
                            controller: _idDigitsController,
                            focusNode: _idDigitsFocus,
                            keyboardType: TextInputType.number,
                            maxLength: 11,
                            buildCounter: (context,
                                    {required currentLength,
                                    required isFocused,
                                    maxLength}) =>
                                null,
                            onChanged: (value) {
                              setState(() {
                                _idDigits = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // PHONE NUMBER SECTION
                const Divider(color: Color(0xFFE5E7EB)),
                const SizedBox(height: 16),
                const Text(
                  'Phone Number',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Enter the phone number registered with your BVN/NIN',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),

                // Phone input using numpad style
                _buildPhoneInput(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        _buildCTA(label: 'Continue →', onTap: _onPhoneIdContinue),
      ],
    );
  }

  Widget _buildIdDigitsInput() {
    final maxLen = 11;
    final filled = _idDigits.length;
    return Column(
      children: [
        Row(
          children: List.generate(maxLen, (i) {
            final hasDigit = i < filled;
            final isActive = i == filled;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  // Focus on this box - will be handled by numpad
                },
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
                          color: Color(0xFF111827)),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPhoneInput() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _phoneFocusNode.requestFocus(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _phoneDigits.isNotEmpty
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFE5E7EB),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '+234',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF16A34A)),
                  ),
                ),
                const SizedBox(width: 12),
                Container(width: 1, height: 20, color: const Color(0xFFE5E7EB)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _phoneDigits.isEmpty
                        ? '801 234 5678'
                        : _formatPhoneDisplay(_phoneDigits),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _phoneDigits.isEmpty
                          ? const Color(0xFFD1D5DB)
                          : const Color(0xFF111827),
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 0,
          child: TextField(
            focusNode: _phoneFocusNode,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            controller: _phoneController,
            onChanged: (value) {
              final digits = value.replaceAll(RegExp(r'\D'), '');
              if (digits.length <= 10) {
                setState(() => _phoneDigits = digits);
              }
            },
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
            ),
            style: const TextStyle(color: Colors.transparent),
          ),
        ),
      ],
    );
  }

  String _formatPhoneDisplay(String digits) {
    if (digits.length <= 3) return digits;
    if (digits.length <= 6)
      return '${digits.substring(0, 3)} ${digits.substring(3)}';
    return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
  }

  void _onPhoneIdContinue() {
    // Store ID if filled
    if (_idDigits.length == 11) {
      if (_idType == 'bvn') {
        _personalInfo.bvn = _idDigits;
      } else {
        _personalInfo.nin = _idDigits;
      }
    }
    // Store phone if filled
    if (_phoneDigits.length == 10) {
      _personalInfo.phoneNumber = '0$_phoneDigits';
    }

    // Navigate regardless of validation
    _nextStep();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 3 — OTP Verification
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
                      color: Color(0xFF111827)),
                ),
                const SizedBox(height: 6),
                Text(
                  'We sent a code to +234 $_phoneDigits',
                  style:
                      const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
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
                              color: Color(0xFF111827)),
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
                        style:
                            TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                    GestureDetector(
                      onTap: (_resendCountdown > 0 || _isResending)
                          ? null
                          : _handleResendOtp,
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
        _buildCTA(
          label: 'Verify',
          onTap: _nextStep,
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 4 — Create Password
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildCreatePasswordStep() {
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
                      fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
                ),
                const SizedBox(height: 24),
                _OFloatingField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  label: 'Password',
                  hint: 'Min 8 characters',
                  obscureText: !_showPassword,
                  suffix: GestureDetector(
                    onTap: () => setState(() => _showPassword = !_showPassword),
                    child: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                  onChanged: (v) => setState(() => _password = v),
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
                _OFloatingField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocus,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  obscureText: !_showConfirmPassword,
                  suffix: GestureDetector(
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
                  onChanged: (v) => setState(() => _confirmPassword = v),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        _buildCTA(
          label: 'Continue →',
          onTap: _onPasswordContinue,
        ),
      ],
    );
  }

  void _onPasswordContinue() {
    // Navigate regardless of validation
    _nextStep();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 5 — Create PIN
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildCreatePinStep() {
    final filled = _pin.where((d) => d.isNotEmpty).length;
    return Column(
      key: const ValueKey('createPin'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_outlined,
                      color: Color(0xFF16A34A), size: 34),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Create a PIN',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Secure your account with a 4-digit PIN',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
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
                _buildNumPad(
                  onDigit: (d) {
                    final idx = _pin.indexWhere((p) => p.isEmpty);
                    if (idx != -1) setState(() => _pin[idx] = d);
                  },
                  onDelete: () {
                    final idx = _pin.lastIndexWhere((p) => p.isNotEmpty);
                    if (idx != -1) setState(() => _pin[idx] = '');
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        _buildCTA(
          label: 'Continue →',
          onTap: _nextStep,
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 6 — Confirm PIN
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildConfirmPinStep() {
    final filled = _confirmPinEntry.where((d) => d.isNotEmpty).length;
    return Column(
      key: const ValueKey('confirmPin'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield,
                      color: Color(0xFF16A34A), size: 34),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Confirm your PIN',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Re-enter your 4-digit PIN to confirm',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
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
                _buildNumPad(
                  onDigit: (d) {
                    final idx = _confirmPinEntry.indexWhere((p) => p.isEmpty);
                    if (idx != -1) setState(() => _confirmPinEntry[idx] = d);
                  },
                  onDelete: () {
                    final idx =
                        _confirmPinEntry.lastIndexWhere((p) => p.isNotEmpty);
                    if (idx != -1) setState(() => _confirmPinEntry[idx] = '');
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        _buildCTA(
          label: 'Set PIN',
          onTap: _nextStep,
        ),
      ],
    );
  }

  void _onConfirmPin() {
    if (_confirmPinEntry.join() != _pin.join()) {
      _snack('PINs do not match. Please try again.', isError: true);
      setState(() {
        for (int i = 0; i < _confirmPinEntry.length; i++) {
          _confirmPinEntry[i] = '';
        }
      });
      return;
    }
    _handlePinSet();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 7 — Account Created (Congratulations)
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildAccountCreatedStep() {
    return Stack(
      key: const ValueKey('accountCreated'),
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFE8F5E9), Color(0xFFF0FDF4), Colors.white],
            ),
          ),
        ),
        // Confetti
        AnimatedBuilder(
          animation: _congratsConfettiCtrl,
          builder: (context, _) => IgnorePointer(
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.check, color: Color(0xFF16A34A), size: 52),
              ),
              const SizedBox(height: 28),
              const Text(
                'Congratulations!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Your profile has been created.\nContinue to complete your verification.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15, color: Color(0xFF6B7280), height: 1.5),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _nextStep,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('Continue',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
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
  // STEP 8 (Optional) — Personal Details
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildPersonalDetailsStep() {
    return Column(
      key: const ValueKey('personalDetails'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tell us about yourself',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 20),
                _OFloatingField(
                  controller: _firstNameController,
                  focusNode: _firstNameFocus,
                  label: 'First Name',
                  hint: 'e.g. Amina',
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (v) => _personalInfo.firstname = v.trim(),
                ),
                const SizedBox(height: 12),
                _OFloatingField(
                  controller: _lastNameController,
                  focusNode: _lastNameFocus,
                  label: 'Last Name',
                  hint: 'e.g. Ibrahim',
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (v) => _personalInfo.lastname = v.trim(),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickDOB,
                  child: _OFloatingField(
                    controller: _birthdayController,
                    focusNode: _birthdayFocus,
                    label: 'Date of Birth',
                    hint: 'DD-MM-YYYY',
                    readOnly: true,
                    suffix: const Icon(Icons.calendar_today_outlined,
                        size: 18, color: Color(0xFF9CA3AF)),
                    onChanged: (_) {},
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _showOptionsSheet(
                      'Gender', ['Male', 'Female', 'Other'], (v) {
                    setState(() => _personalInfo.gender = v);
                  }),
                  child: _OFloatingFieldStatic(
                    label: 'Gender',
                    value: _personalInfo.gender.isEmpty
                        ? null
                        : _personalInfo.gender,
                    hint: 'Select gender',
                    suffix: const Icon(Icons.keyboard_arrow_down,
                        size: 20, color: Color(0xFF9CA3AF)),
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _showAddressPicker,
                  child: _OFloatingFieldStatic(
                    label: 'Address',
                    value: _personalInfo.residentialAddress.isEmpty
                        ? null
                        : _personalInfo.residentialAddress,
                    hint: 'Search address',
                    suffix: _isGettingLocation
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                        Color(0xFF16A34A)))))
                        : IconButton(
                            onPressed: _onLocateMePressed,
                            icon: const Icon(Icons.my_location,
                                color: Color(0xFF16A34A), size: 20)),
                  ),
                ),
                if (_personalInfo.residentialAddress.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _showStatePicker,
                    child: _OFloatingFieldStatic(
                      label: 'State',
                      value: _personalInfo.state.isEmpty
                          ? null
                          : _personalInfo.state,
                      hint: 'Select State',
                      suffix: const Icon(Icons.keyboard_arrow_down,
                          size: 20, color: Color(0xFF9CA3AF)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: selectedState == null ? null : _showLgaPicker,
                    child: _OFloatingFieldStatic(
                      label: 'L.G.A',
                      value:
                          _personalInfo.lga.isEmpty ? null : _personalInfo.lga,
                      hint: selectedState == null
                          ? 'Select state first'
                          : 'Select L.G.A',
                      suffix: const Icon(Icons.keyboard_arrow_down,
                          size: 20, color: Color(0xFF9CA3AF)),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        _buildCTA(label: 'Continue →', onTap: _onPersonalDetailsContinue),
      ],
    );
  }

  void _onPersonalDetailsContinue() {
    // Navigate regardless of validation
    _nextStep();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 8 — ID Verification
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildIdVerificationStep() {
    final maxLen = 11;
    final filled = _idDigits.length;
    return Column(
      key: const ValueKey('idVerification'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please provide your own BVN/NIN to verify your account opening application',
                  style: TextStyle(
                      fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
                ),
                const SizedBox(height: 20),
                // NIN / BVN toggle
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: ['nin', 'bvn'].map((type) {
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
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
                const SizedBox(height: 20),
                // Label row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _idType.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151)),
                    ),
                    Text(
                      'Bank Verification Number Sample >',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF16A34A)),
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
                                color: Color(0xFF111827)),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF16A34A)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Forgot BVN?',
                        style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF16A34A),
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 24),
                _buildNumPad(
                  onDigit: (d) {
                    if (_idDigits.length < maxLen)
                      setState(() => _idDigits += d);
                  },
                  onDelete: () {
                    if (_idDigits.isNotEmpty)
                      setState(() => _idDigits =
                          _idDigits.substring(0, _idDigits.length - 1));
                  },
                ),
              ],
            ),
          ),
        ),
        // Licensed footer
        const _CbnFooter(),
        _buildCTA(
          label: 'Continue →',
          onTap: _nextStep,
        ),
      ],
    );
  }

  void _onIdContinue() {
    if (_idType == 'bvn') {
      _personalInfo.bvn = _idDigits;
      _bvnController.text = _idDigits;
    } else {
      _personalInfo.nin = _idDigits;
      _ninController.text = _idDigits;
    }
    _nextStep();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 9 — Residential Address
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildResidentialAddressStep() {
    final locations = getCountryLocation();
    final houseCtrl = TextEditingController();
    final areaCtrl = TextEditingController();

    return Column(
      key: const ValueKey('residentialAddress'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Where do you live?',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                const SizedBox(height: 20),
                _sectionLabel('Address'),
                const SizedBox(height: 8),
                GooglePlacesAutoCompleteTextFormField(
                  textEditingController: _addressController,
                  googleAPIKey: GOOGLE_API_KEY,
                  debounceTime: 600,
                  countries: const ['ng'],
                  onSuggestionClicked: (p) {
                    _addressController.text = p.description ?? '';
                    setState(() =>
                        _personalInfo.residentialAddress = p.description ?? '');
                  },
                  onChanged: (e) =>
                      setState(() => _personalInfo.residentialAddress = e),
                  onPlaceDetailsWithCoordinatesReceived: (p) async {
                    setState(() {
                      selectedCoordinate = Prediction(
                        description: p.description,
                        lat: p.lat,
                        lng: p.lng,
                        placeId: p.placeId,
                      );
                    });
                    if (p.placeId != null) {
                      final det = await ref.read(
                          locationDetailsProvider(p.placeId ?? '').future);
                      if (det != null) {
                        final locs = getCountryLocation();
                        final svc = ref.read(locationDetailsServiceProvider);
                        final st = svc.findMatchingState(det.state, locs);
                        if (st != null) {
                          setState(() {
                            selectedState = st;
                            _personalInfo.state = st.state?.name ?? '';
                            locals = st.state?.locals;
                            if (det.localGovernment != null && locals != null) {
                              selectedLga = svc.findMatchingLGA(
                                  det.localGovernment!, locals!);
                              _personalInfo.lga = selectedLga?.name ?? '';
                            }
                          });
                        }
                      }
                    }
                  },
                  decoration: _inputDec(
                      hint: 'e.g. 15, Adeola Odeku Street',
                      suffix: _isGettingLocation
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                          Color(0xFF16A34A)))))
                          : IconButton(
                              onPressed: _onLocateMePressed,
                              icon: const Icon(Icons.my_location,
                                  color: Color(0xFF16A34A), size: 20))),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('House No.'),
                          const SizedBox(height: 8),
                          TextField(
                              controller: houseCtrl,
                              decoration: _inputDec(hint: 'No.')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('Area / Landstack'),
                          const SizedBox(height: 8),
                          TextField(
                              controller: areaCtrl,
                              decoration:
                                  _inputDec(hint: 'e.g. Victoria Island')),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _sectionLabel('State'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    final opts = locations
                        .map((l) => l.state?.name ?? '')
                        .where((n) => n.isNotEmpty)
                        .toList();
                    _showSearchSheet('Select State', opts, (v) {
                      final match = locations.firstWhere(
                          (l) => l.state?.name == v,
                          orElse: () => locations.first);
                      setState(() {
                        selectedState = match;
                        _personalInfo.state = v;
                        locals = match.state?.locals;
                        selectedLga = null;
                        _personalInfo.lga = '';
                      });
                    });
                  },
                  child: _dropdownField(
                    label: '',
                    value: selectedState?.state?.name,
                    hint: 'Select State',
                    icon: null,
                  ),
                ),
                const SizedBox(height: 14),
                _sectionLabel('L.G.A'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: selectedState == null
                      ? null
                      : () {
                          final opts = (locals ?? [])
                              .map((l) => l.name ?? '')
                              .where((n) => n.isNotEmpty)
                              .toList();
                          _showSearchSheet('Select L.G.A', opts, (v) {
                            final match = (locals ?? []).firstWhere(
                                (l) => l.name == v,
                                orElse: () => locals!.first);
                            setState(() {
                              selectedLga = match;
                              _personalInfo.lga = v;
                            });
                          });
                        },
                  child: _dropdownField(
                    label: '',
                    value: selectedLga?.name,
                    hint: selectedState == null
                        ? 'Select state first'
                        : 'Select L.G.A',
                    icon: null,
                    enabled: selectedState != null,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        _buildCTA(label: 'Continue →', onTap: _nextStep),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 10 — PEP
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildPepStep() {
    return Column(
      key: const ValueKey('pep'),
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
                    'Are you a Politically Exposed Person or a family member/close associate of a PEP?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        height: 1.4),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 28),
                  child: Text(
                    'A PEP (Politically Exposed Person) is someone who currently holds or has held an important public position, which gives them influence over public funds or decisions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: ['Yes', 'No'].map((label) {
                      final val = label == 'Yes';
                      final selected = _isPep == val;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isPep = val),
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
        const _CbnFooter(),
        _buildCTA(label: 'Continue →', onTap: _nextStep),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 9 (Optional) — Occupation
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildOccupationStep() {
    const occupations = [
      'Farmer',
      'Business man/woman',
      'Civil servant',
      'Teacher',
      'Healthcare worker',
      'Engineer',
      'Others'
    ];
    const incomes = [
      'Below ₦100,000',
      '₦100,000 - ₦500,000',
      '₦500,000 - ₦1,000,000',
      'Above ₦1,000,000'
    ];

    return Column(
      key: const ValueKey('sourceOfIncome'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Provide details of your source of income',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                const SizedBox(height: 24),
                _sectionLabel('Occupation'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showOptionsSheet('Occupation', occupations,
                      (v) => setState(() => _occupation = v)),
                  child: _dropdownField(
                      label: '',
                      value: _occupation,
                      hint: 'Select your occupation',
                      icon: null),
                ),
                const SizedBox(height: 20),
                _sectionLabel('Annual Income'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showOptionsSheet('Annual Income', incomes,
                      (v) => setState(() => _annualIncome = v)),
                  child: _dropdownField(
                      label: '',
                      value: _annualIncome,
                      hint: 'Select your annual income',
                      icon: null),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        _buildCTA(
          label: 'Continue →',
          onTap: _nextStep,
        ),
      ],
    );
  }

  // ═══════════════════���══════════════════════════════════════════════════════════
  // STEP 12 — Facial Verification
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildFacialVerificationStep() {
    return Column(
      key: const ValueKey('facialVerification'),
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Camera preview or dark background
              if (_cameraActive &&
                  _cameraController != null &&
                  _cameraController!.value.isInitialized)
                Positioned.fill(child: CameraPreview(_cameraController!))
              else
                Container(color: Colors.black87),

              // Oval cutout overlay
              Positioned.fill(
                child: CustomPaint(
                  painter: _OvalOverlayPainter(color: const Color(0xFFD4AF37)),
                ),
              ),

              // Top instruction card
              Positioned(
                top: 20,
                left: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1), blurRadius: 8)
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.remove_red_eye_outlined,
                            color: Color(0xFF16A34A), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text('Face Verification',
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF111827))),
                                Text('10%',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF16A34A))),
                              ],
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: 0.1,
                                minHeight: 4,
                                backgroundColor: const Color(0xFFE5E7EB),
                                valueColor: const AlwaysStoppedAnimation(
                                    Color(0xFF16A34A)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom instruction
              Positioned(
                bottom: 20,
                left: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1), blurRadius: 8)
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Remove glasses if wearing any',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827)),
                      ),
                      const SizedBox(height: 4),
                      Text('Hold still...',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade500)),
                      const SizedBox(height: 16),
                      GestureDetector(
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
                              _cameraActive ? 'Capture' : 'Start Camera',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            _animateTo(AccountStep.personalDetails),
                        child: const Text('Skip for now',
                            style: TextStyle(
                                color: Color(0xFF6B7280), fontSize: 13)),
                      ),
                    ],
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
                                color: Colors.white, fontSize: 14),
                            textAlign: TextAlign.center),
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
  // KYC Complete — Account Verified
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildKycCompleteStep() {
    // Generate a display account number from the phone digits
    final accountNumber =
        _phoneDigits.isNotEmpty ? '0$_phoneDigits' : '08XXXXXXXXX';

    return Stack(
      key: const ValueKey('kycComplete'),
      children: [
        // Green gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B4F2F), Color(0xFF073D25), Color(0xFF166C46)],
            ),
          ),
        ),
        // Subtle noise texture
        Positioned.fill(
          child: CustomPaint(painter: NoisePainter(opacity: 0.05, seed: 7)),
        ),
        // Confetti reuse
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
              // RimaPay logo
              Image.asset(
                'assets/images/AppIcon.png',
                width: 64,
                height: 64,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),
              // Shield / verified icon
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
                'You Have Been Verified!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Your identity has been confirmed.\nWelcome to RimaPay!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.75),
                      height: 1.5),
                ),
              ),
              const SizedBox(height: 36),
              // Account number card
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
                                color: Color(0xFF6B7280)),
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.phone_outlined,
                                size: 14, color: Color(0xFF16A34A)),
                            SizedBox(width: 6),
                            Text(
                              'Your phone number is also your account number',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF166534),
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      Row(
                        children: const [
                          Icon(Icons.info_outline,
                              size: 14, color: Color(0xFF6B7280)),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'You can receive transfers using your phone number or this account number',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6B7280),
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Go to Dashboard button
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
                          color: Color(0xFF166C46)),
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

  // ─── Shared UI helpers ───────────────────────────────────────────────────────

  Widget _buildCTA({String? label, bool loading = false, VoidCallback? onTap}) {
    // Always treat as enabled — onTap may be null only during loading
    final enabled = !loading;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: GestureDetector(
        onTap: loading ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: enabled ? AppColors.goldGradient : null,
            color: enabled ? null : const Color(0xFFCCCCCC),
            borderRadius: BorderRadius.circular(12),
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
                      color: enabled ? Colors.white : const Color(0xFF9CA3AF),
                    ),
                  ),
          ),
        ),
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
                        onTap: () => key == '⌫' ? onDelete() : onDigit(key),
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
                                        color: Color(0xFF111827))),
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
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5)),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required void Function(String) onChanged,
    String? Function(String?)? validator,
    TextInputType keyboard = TextInputType.text,
    TextCapitalization capitalize = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          validator: validator,
          keyboardType: keyboard,
          textCapitalization: capitalize,
          style: const TextStyle(
              fontSize: 14, color: Color(0xFF111827), fontFamily: 'Effra'),
          decoration: _inputDec(
              hint: hint,
              suffix: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(icon, color: const Color(0xFF9CA3AF), size: 18))),
        ),
      ],
    );
  }

  Widget _passwordField({
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required void Function(String) onChanged,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          obscureText: obscure,
          onChanged: onChanged,
          validator: validator,
          style: const TextStyle(
              fontSize: 14, color: Color(0xFF111827), fontFamily: 'Effra'),
          decoration: _inputDec(hint: hint).copyWith(
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF9CA3AF), size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdownField({
    required String label,
    required String? value,
    required String hint,
    required IconData? icon,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: const Color(0xFF9CA3AF), size: 18),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              value ?? hint,
              style: TextStyle(
                fontSize: 14,
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

  Widget _sectionLabel(String label) {
    return Text(label,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151)));
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
                      color: Color(0xFF111827))),
            ),
            const SizedBox(height: 8),
            const Divider(),
            ...options.map((o) => ListTile(
                  title: Text(o, style: const TextStyle(fontSize: 15)),
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

  void _showSearchSheet(
      String title, List<String> options, void Function(String) onSelect) {
    final searchCtrl = TextEditingController();
    List<String> filtered = List.from(options);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
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
                        fontSize: 17, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: searchCtrl,
                  decoration: _inputDec(hint: 'Search...').copyWith(
                    prefixIcon: const Icon(Icons.search,
                        color: Color(0xFF9CA3AF), size: 18),
                  ),
                  onChanged: (q) {
                    setS(() {
                      filtered = options
                          .where(
                              (o) => o.toLowerCase().contains(q.toLowerCase()))
                          .toList();
                    });
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => ListTile(
                    title:
                        Text(filtered[i], style: const TextStyle(fontSize: 14)),
                    onTap: () {
                      onSelect(filtered[i]);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddressPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
            top: 12, bottom: MediaQuery.of(context).padding.bottom + 12),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Search Address',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GooglePlacesAutoCompleteTextFormField(
                textEditingController: _addressController,
                googleAPIKey: GOOGLE_API_KEY,
                debounceTime: 600,
                countries: const ['ng'],
                onSuggestionClicked: (p) {
                  _addressController.text = p.description ?? '';
                  setState(() {
                    _personalInfo.residentialAddress = p.description ?? '';
                  });
                },
                onChanged: (e) =>
                    setState(() => _personalInfo.residentialAddress = e),
                onPlaceDetailsWithCoordinatesReceived: (p) async {
                  setState(() {
                    selectedCoordinate = Prediction(
                      description: p.description,
                      lat: p.lat,
                      lng: p.lng,
                      placeId: p.placeId,
                    );
                  });
                  if (p.placeId != null) {
                    final det = await ref
                        .read(locationDetailsProvider(p.placeId ?? '').future);
                    if (det != null) {
                      final locs = getCountryLocation();
                      final svc = ref.read(locationDetailsServiceProvider);
                      final st = svc.findMatchingState(det.state, locs);
                      if (st != null) {
                        setState(() {
                          selectedState = st;
                          _personalInfo.state = st.state?.name ?? '';
                          locals = st.state?.locals;
                          if (det.localGovernment != null && locals != null) {
                            selectedLga = svc.findMatchingLGA(
                                det.localGovernment!, locals!);
                            _personalInfo.lga = selectedLga?.name ?? '';
                          }
                        });
                      }
                    }
                  }
                },
                decoration: _inputDec(hint: 'Search address...').copyWith(
                  prefixIcon: const Icon(Icons.search,
                      color: Color(0xFF9CA3AF), size: 18),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.my_location,
                      color: Color(0xFF16A34A), size: 20),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await _onLocateMePressed();
                    },
                    child: const Text(
                      'Use current location',
                      style: TextStyle(
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showStatePicker() {
    final locs = getCountryLocation();
    final opts = locs
        .map((l) => l.state?.name ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
    _showSearchSheet('Select State', opts, (v) {
      final match =
          locs.firstWhere((l) => l.state?.name == v, orElse: () => locs.first);
      setState(() {
        selectedState = match;
        _personalInfo.state = v;
        locals = match.state?.locals;
        selectedLga = null;
        _personalInfo.lga = '';
      });
    });
  }

  void _showLgaPicker() {
    if (selectedState == null) return;
    final opts = (locals ?? [])
        .map((l) => l.name ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
    _showSearchSheet('Select L.G.A', opts, (v) {
      final match = (locals ?? [])
          .firstWhere((l) => l.name == v, orElse: () => locals!.first);
      setState(() {
        selectedLga = match;
        _personalInfo.lga = v;
      });
    });
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _pickDOB() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF16A34A)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final formatted =
          '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
      setState(() {
        _birthdayController.text = formatted;
        _personalInfo.dateOfBirth = formatted;
      });
    }
  }

  // ─── Existing backend methods (unchanged) ────────────────────────────────────

  void _handleOtpSubmit() async {
    if (_otp.any((d) => d.isEmpty)) return;
    setState(() => _isLoading = true);
    final session = getSessionId();
    final params = OtpParams(
      method: 'validateOtp',
      otpCode: _otp.join(),
      requestType: REQUEST_TYPE,
      sessionId: session,
    );
    ref.read(verifyOtpProvider(params));
  }

  Future<void> _handleResendOtp() async {
    if (_resendCountdown > 0 || _isResending) return;
    setState(() => _isResending = true);
    final session = getSessionId();
    final params = OtpParams(
      method: 'resendOtp',
      requestType: REQUEST_TYPE,
      sessionId: session,
    );
    ref.read(resendOtpProvider(params));
    _startResendCountdown();
  }

  void _startResendCountdown() {
    _resendCountdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _handlePinSet() {
    if (_pin.any((d) => d.isEmpty)) return;
    setState(() => _creatingPin = true);
    final session = getSessionId();
    final params = CreatePinParams(
      requestType: REQUEST_TYPE,
      method: 'createSoftToken',
      sentConfirmPIN: _pin.join(),
      sentPIN: _pin.join(),
      sessionId: session,
    );
    ref.read(createPinProvider(params));
  }

  // ─── Validation ──────────────────────────────────────────────────────────────

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim()))
      return 'Please enter a valid email address';
    return null;
  }

  String? _validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    if (value.trim().length < 2)
      return '$fieldName must be at least 2 characters';
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value.trim()))
      return '$fieldName contains invalid characters';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value))
      return 'Must contain uppercase, lowercase, and number';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _password) return 'Passwords do not match';
    return null;
  }

  String? _validateDateOfBirth(String? value) {
    if (value == null || value.trim().isEmpty)
      return 'Date of birth is required';
    try {
      final parts = value.split('-');
      if (parts.length != 3) return 'Please select a valid date';
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final birthDate = DateTime(year, month, day);
      final eighteenYearsAgo = DateTime(
          DateTime.now().year - 18, DateTime.now().month, DateTime.now().day);
      if (birthDate.isAfter(eighteenYearsAgo))
        return 'You must be at least 18 years old';
      return null;
    } catch (_) {
      return 'Please select a valid date';
    }
  }

  // ─── Location ────────────────────────────────────────────────────────────────

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _snack('Location services are disabled');
      return null;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _snack('Location permissions are denied');
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _snack('Location permissions are permanently denied');
      return null;
    }
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _onLocateMePressed() async {
    setState(() => _isGettingLocation = true);
    try {
      final position = await getCurrentLocation();
      if (position != null) {
        try {
          final placemarks = await placemarkFromCoordinates(
              position.latitude, position.longitude);
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            String address = [
              p.street,
              p.subLocality,
              p.locality,
              p.administrativeArea,
              p.country
            ].where((s) => s?.isNotEmpty == true).join(', ');
            setState(() {
              _addressController.text = address;
              _personalInfo.residentialAddress = address;
              selectedCoordinate = Prediction(
                  lat: position.latitude.toString(),
                  lng: position.longitude.toString(),
                  description: address);
              _personalInfo.currentLat = position.latitude;
              _personalInfo.currentLng = position.longitude;
            });
          }
        } catch (_) {
          setState(() {
            _addressController.text =
                'Current Location (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
            _personalInfo.residentialAddress = _addressController.text;
          });
        }
      }
    } catch (_) {
      _snack('Failed to get your location', isError: true);
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  // ─── Camera ──────────────────────────────────────────────────────────────────

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
      _cameraController = CameraController(front, ResolutionPreset.medium);
      await _cameraController!.initialize();
      if (mounted)
        setState(() {
          _cameraActive = true;
          _cameraError = null;
        });
    } catch (e) {
      setState(() {
        _cameraError = 'Failed to initialize camera: $e';
        _cameraActive = false;
      });
    }
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      await _initializeCamera();
    } else {
      setState(() {
        _permissionDenied = true;
        _cameraError = 'Camera permission denied.';
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;
    try {
      final image = await _cameraController!.takePicture();
      setState(() {
        _capturedImage = image.path;
        _cameraActive = false;
      });
      _cameraController?.dispose();
      _cameraController = null;
      // Navigate to personal details after face validation
      if (mounted) _animateTo(AccountStep.personalDetails);
    } catch (e) {
      setState(() => _cameraError = 'Failed to capture photo: $e');
    }
  }
}

// ─── Floating label input (matches airtime screen design) ────────────────────

class _OFloatingField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final void Function(String)? onChanged;
  final Widget? suffix;
  final IconData? prefixIcon;
  final bool obscureText;
  final bool readOnly;

  const _OFloatingField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.suffix,
    this.prefixIcon,
    this.obscureText = false,
    this.readOnly = false,
  });

  @override
  State<_OFloatingField> createState() => _OFloatingFieldState();
}

class _OFloatingFieldState extends State<_OFloatingField> {
  bool _focused = false;
  bool _hasValue = false;

  @override
  void initState() {
    super.initState();
    _focused = widget.focusNode.hasFocus;
    _hasValue = widget.controller.text.isNotEmpty;
    widget.focusNode.addListener(_onFocus);
    widget.controller.addListener(_onValue);
  }

  void _onFocus() => setState(() => _focused = widget.focusNode.hasFocus);
  void _onValue() {
    final v = widget.controller.text.isNotEmpty;
    if (v != _hasValue) setState(() => _hasValue = v);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    widget.controller.removeListener(_onValue);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _focused || _hasValue;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focused
              ? const Color(0xFF16A34A)
              : _hasValue
                  ? const Color(0xFF16A34A).withOpacity(0.4)
                  : const Color(0xFFE4E7EC),
          width: _focused ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          // Floating label
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            top: isActive ? 9 : 20,
            left: 16,
            right: widget.suffix != null ? 52 : 16,
            child: IgnorePointer(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  fontSize: isActive ? 11 : 15,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  color: isActive
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF9CA3AF),
                ),
                child: Text(widget.label),
              ),
            ),
          ),
          // TextField
          Positioned(
            left: 14,
            right: widget.suffix != null ? 48 : 14,
            top: isActive ? 28 : 18,
            bottom: 6,
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              keyboardType: widget.keyboardType,
              textCapitalization: widget.textCapitalization,
              obscureText: widget.obscureText,
              readOnly: widget.readOnly,
              onChanged: widget.onChanged,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF101828),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: true,
                fillColor: Colors.transparent,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (widget.suffix != null)
            Positioned(
              right: 14,
              top: 0,
              bottom: 0,
              child: Center(child: widget.suffix!),
            ),
        ],
      ),
    );
  }
}

// Static version for tap-only fields (gender, DOB display, etc.)
class _OFloatingFieldStatic extends StatelessWidget {
  final String label;
  final String? value;
  final String hint;
  final Widget? suffix;

  const _OFloatingFieldStatic({
    required this.label,
    required this.value,
    required this.hint,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasValue
              ? const Color(0xFF16A34A).withOpacity(0.4)
              : const Color(0xFFE4E7EC),
        ),
      ),
      child: Stack(
        children: [
          // Label
          AnimatedPositioned(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            top: hasValue ? 9 : 20,
            left: 16,
            right: suffix != null ? 52 : 16,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: TextStyle(
                fontSize: hasValue ? 11 : 15,
                fontWeight: FontWeight.w500,
                height: 1.2,
                color: hasValue
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF9CA3AF),
              ),
              child: Text(hasValue ? label : hint),
            ),
          ),
          // Value
          if (hasValue)
            Positioned(
              left: 16,
              right: suffix != null ? 48 : 16,
              top: 28,
              bottom: 6,
              child: Text(
                value!,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF101828),
                ),
              ),
            ),
          if (suffix != null)
            Positioned(
              right: 14,
              top: 0,
              bottom: 0,
              child: Center(child: suffix!),
            ),
        ],
      ),
    );
  }
}

// ─── Supporting widgets ───────────────────────────────────────────────────────

class _CbnFooter extends StatelessWidget {
  const _CbnFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.verified, color: Color(0xFF16A34A), size: 14),
          SizedBox(width: 5),
          Text('Licensed by the CBN',
              style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Oval overlay painter (facial verification) ───────────────────────────────

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

// ─── Confetti ─────────────────────────────────────────────────────────────────

class _CParticle {
  final double x;
  final double startY;
  final double speed;
  final double size;
  final Color color;
  final double wobble;
  final double wobbleSpeed;

  static const _colors = [
    Color(0xFF16A34A),
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

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:rimapay/Utils/Logics.dart';
import 'package:rimapay/core/providers/auth_provider.dart';
import 'package:rimapay/core/services/storage_service.dart';
import 'package:rimapay/features/onboarding/data/onboarding_dtos.dart';
import 'package:rimapay/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:rimapay/features/profile/data/profile_dtos.dart';
import 'package:rimapay/features/profile/presentation/providers/profile_provider.dart';

import 'package:rimapay/core/Models/CountryStateLgaModel.dart';
import 'package:rimapay/core/Utils/En.dart';
import 'package:rimapay/core/services/GetPlaceDetailsService.dart';
import 'package:rimapay/shared/widgets/noise_painter.dart';
import 'package:rimapay/shared/widgets/rimapay_logo.dart';
import 'package:rimapay/core/theme/app_colors.dart';

/// Temporary build marker so we can confirm which deployment is actually
/// running in the browser (shown tiny under the phone-step button).
const String kBuildTag = 'build #11 · 2026-06-09';

// ─── Step enum ───────────────────────────────────────────────────────────────

enum AccountStep {
  phoneEntry, // 1. Enter phone number
  otpVerification, // 2. OTP verification
  idEntry, // 3. Enter BVN/NIN
  facialVerification, // 4. Face validation
  createPassword, // 5. Create & Confirm password
  createPin, // 6. Create PIN
  confirmPin, // 7. Confirm PIN
  accountCreatedSuccess, // 8. After PIN - with account number + 2 CTAs
  residentialAddress, // 9. Complete Profile flow
  pepDeclaration, // 10. Complete Profile flow
  sourceOfIncome, // 11. Complete Profile flow
  profileCompletedSuccess, // 12. Final - Profile completed
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
  final String accountType;
  const PersonalAccountFlow({super.key, this.accountType = 'personal'});

  @override
  ConsumerState<PersonalAccountFlow> createState() =>
      _PersonalAccountFlowState();
}

class _PersonalAccountFlowState extends ConsumerState<PersonalAccountFlow>
    with TickerProviderStateMixin {
  // ── Step state ─────────────────────────────────────────────────────────────
  AccountStep _currentStep = AccountStep.phoneEntry;

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
  String _idType = 'bvn'; // 'bvn', 'nin', or 'noid'
  String _idDigits = '';
  bool _isUnderbankedMode = false; // set when user picks "No ID"

  bool get _isUnderbanked =>
      widget.accountType == 'underbanked' || _isUnderbankedMode;

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
  bool _verifyingFace = false;
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
    // Start each signup attempt from a clean onboarding session.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingProvider.notifier).reset();
    });
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
    // Underbanked: skip idEntry on backward nav
    if (_isUnderbanked && _currentStep == AccountStep.facialVerification) {
      _animateTo(AccountStep.otpVerification);
      return;
    }
    if (_isUnderbanked && _currentStep == AccountStep.sourceOfIncome) {
      _animateTo(AccountStep.accountCreatedSuccess);
      return;
    }
    final steps = AccountStep.values;
    final idx = steps.indexOf(_currentStep);
    if (idx > 0) {
      _animateTo(steps[idx - 1]);
    } else {
      context.pop();
    }
  }

  void _animateTo(AccountStep step) {
    if (step == AccountStep.accountCreatedSuccess ||
        step == AccountStep.profileCompletedSuccess) {
      _congratsConfettiCtrl.reset();
      _congratsConfettiCtrl.forward();
    }
    _pageAnimController.reset();
    setState(() => _currentStep = step);
    _pageAnimController.forward();
  }

  void _nextStep() {
    // Underbanked: skip idEntry and pepDeclaration
    if (_isUnderbanked) {
      if (_currentStep == AccountStep.otpVerification) {
        _animateTo(AccountStep.facialVerification);
        return;
      }
      if (_currentStep == AccountStep.accountCreatedSuccess) {
        _animateTo(AccountStep.residentialAddress);
        return;
      }
      if (_currentStep == AccountStep.residentialAddress) {
        _animateTo(AccountStep.sourceOfIncome);
        return;
      }
    }
    final steps = AccountStep.values;
    final idx = steps.indexOf(_currentStep);
    if (idx < steps.length - 1) {
      _animateTo(steps[idx + 1]);
    }
  }

  // ─── Step meta ───────────────────────────────────────────────────────────────

  String get _stepTitle {
    switch (_currentStep) {
      case AccountStep.phoneEntry:
        return 'Phone Number';
      case AccountStep.otpVerification:
        return 'Verify Phone';
      case AccountStep.idEntry:
        return 'ID Verification';
      case AccountStep.facialVerification:
        return 'Face Verification';
      case AccountStep.createPassword:
        return 'Create Password';
      case AccountStep.createPin:
        return 'Create PIN';
      case AccountStep.confirmPin:
        return 'Confirm PIN';
      case AccountStep.accountCreatedSuccess:
        return 'Account Created';
      case AccountStep.residentialAddress:
        return 'Residential Address';
      case AccountStep.pepDeclaration:
        return 'PEP Declaration';
      case AccountStep.sourceOfIncome:
        return 'Source of Income';
      case AccountStep.profileCompletedSuccess:
        return 'Account Verified';
    }
  }

  bool get _showHeader =>
      _currentStep != AccountStep.accountCreatedSuccess &&
      _currentStep != AccountStep.profileCompletedSuccess;

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Onboarding API calls are driven directly from each step's handler
    // (initiate / verifyOtp / submitIdentity / validateFace / createPassword /
    // createPin) via [onboardingProvider]; navigation stays local to this flow.
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
      case AccountStep.phoneEntry:
        return _buildPhoneEntryStep();
      case AccountStep.otpVerification:
        return _buildOtpStep();
      case AccountStep.idEntry:
        return _buildIdVerificationStep();
      case AccountStep.facialVerification:
        return Stack(
          fit: StackFit.expand,
          children: [
            _buildFacialVerificationStep(),
            if (_verifyingFace) _buildFaceVerifyingOverlay(),
          ],
        );
      case AccountStep.createPassword:
        return _buildCreatePasswordStep();
      case AccountStep.createPin:
        return _buildCreatePinStep();
      case AccountStep.confirmPin:
        return _buildConfirmPinStep();
      case AccountStep.accountCreatedSuccess:
        return _buildAccountCreatedSuccessStep();
      case AccountStep.residentialAddress:
        return _buildResidentialAddressStep();
      case AccountStep.pepDeclaration:
        return _buildPepStep();
      case AccountStep.sourceOfIncome:
        return _buildOccupationStep();
      case AccountStep.profileCompletedSuccess:
        return _buildProfileCompletedSuccessStep();
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
                      fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
                ),
                const SizedBox(height: 24),
                _buildPhoneInput(),
                const SizedBox(height: 24),
                _buildNumPad(
                  onDigit: (d) {
                    if (_phoneDigits.length < 11) {
                      setState(() => _phoneDigits += d);
                    }
                  },
                  onDelete: () {
                    if (_phoneDigits.isNotEmpty) {
                      setState(() => _phoneDigits = _phoneDigits.substring(
                          0, _phoneDigits.length - 1));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        _buildCTA(
          label: 'Continue →',
          loading: _isLoading,
          onTap: _onPhoneContinue,
          footerContent: Text(
            kBuildTag,
            style: const TextStyle(fontSize: 10, color: Color(0xFFB0B7C3)),
          ),
        ),
      ],
    );
  }

  void _onPhoneContinue() async {
    final phoneNum = _phoneDigits.startsWith('0') ? _phoneDigits : '0$_phoneDigits';
    if (phoneNum.length < 11) {
      _snack('Enter a valid phone number.', isError: true);
      return;
    }
    _personalInfo.phoneNumber = phoneNum;
    setState(() => _isLoading = true);
    final ok = await ref.read(onboardingProvider.notifier).beginOnboarding(
          phoneNumber: phoneNum,
          email: _personalInfo.emailAddress.isNotEmpty
              ? _personalInfo.emailAddress
              : null,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      final st = ref.read(onboardingProvider);
      // Surface a resume/resend problem (e.g. backend resend-otp failing)
      // rather than hiding it behind a "Resuming…" toast on a code-less screen.
      if (st.error != null) {
        _snack(st.error!, isError: true);
      } else if (st.justResumed) {
        _snack('Resuming your application…');
      }
      _animateTo(_accountStepForOnboardingStep(st.currentStep));
    } else {
      _snack(
          ref.read(onboardingProvider).error ??
              'Failed to send verification code. Please try again.',
          isError: true);
    }
  }

  /// Maps the onboarding provider's step (which may have advanced via a resumed
  /// session) to the matching screen in this flow, so a returning user lands
  /// exactly where they left off instead of always on the OTP screen.
  AccountStep _accountStepForOnboardingStep(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.initialEntry:
        return AccountStep.phoneEntry;
      case OnboardingStep.otpVerification:
        return AccountStep.otpVerification;
      case OnboardingStep.identitySubmission:
        return AccountStep.idEntry;
      case OnboardingStep.facialValidation:
        return AccountStep.facialVerification;
      case OnboardingStep.createPassword:
        return AccountStep.createPassword;
      case OnboardingStep.createPin:
        return AccountStep.createPin;
      case OnboardingStep.completed:
        return AccountStep.accountCreatedSuccess;
    }
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '+234',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151)),
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
            ),
          ),
        ],
      ),
    );
  }

  String _formatPhoneDisplay(String digits) {
    if (digits.length <= 3) return digits;
    if (digits.length <= 6)
      return '${digits.substring(0, 3)} ${digits.substring(3)}';
    return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6)}';
  }

  void _showForgotIdSheet() {
    final isBvn = _idType == 'bvn';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 12, 24, MediaQuery.of(context).padding.bottom + 28),
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
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FAF4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.help_outline_rounded,
                      color: Color(0xFF166C46), size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  isBvn ? 'Retrieve your BVN' : 'Retrieve your NIN',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FAF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF166C46).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isBvn ? 'Dial this USSD code:' : 'Dial one of these USSD codes:',
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  if (isBvn) ...[
                    _ussdRow('*565*0#', 'Works on any network'),
                  ] else ...[
                    _ussdRow('*346#', 'MTN'),
                    const SizedBox(height: 10),
                    _ussdRow('*3082#', '9mobile'),
                    const SizedBox(height: 10),
                    _ussdRow('*346*3#', 'Airtel'),
                    const SizedBox(height: 10),
                    _ussdRow('*346*6#', 'Glo'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Color(0xFFF97316), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isBvn
                          ? 'Your BVN was issued when you opened your first bank account. It is an 11-digit number.'
                          : 'Your NIN was issued by NIMC. Visit any NIMC office or agent to enroll if you don\'t have one.',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF78350F),
                          height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF166C46),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('Got it',
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

  Widget _ussdRow(String code, String network) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF166C46).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(code,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF166C46),
                  letterSpacing: 0.5)),
        ),
        const SizedBox(width: 12),
        Text(network,
            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
      ],
    );
  }

  void _showNoIdConfirmSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
            24, 12, 24, MediaQuery.of(context).padding.bottom + 24),
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
                    borderRadius: BorderRadius.circular(999)),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.account_balance_wallet_outlined,
                  color: Color(0xFFF97316), size: 26),
            ),
            const SizedBox(height: 16),
            Text('Open Underbanked Account?',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 10),
            Text(
              'You\'re about to open a financial inclusion (underbanked) account. This account is designed for those without formal ID documents.',
              style: TextStyle(
                  fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), height: 1.5),
            ),
            const SizedBox(height: 16),
            _limitRow(Icons.swap_horiz, '₦10,000 daily transaction limit'),
            _limitRow(Icons.savings_outlined, '₦100,000 maximum balance'),
            _limitRow(Icons.upgrade, 'Upgrade anytime by adding BVN/NIN'),
            _limitRow(Icons.check_circle_outline, 'Access to savings & micro-loans'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text('Cancel',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85))),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _isUnderbankedMode = true;
                        _idDigits = '';
                      });
                      _animateTo(AccountStep.facialVerification);
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text('Yes, Continue',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
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

  Widget _limitRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF166C46)),
          const SizedBox(width: 10),
          Text(text,
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85))),
        ],
      ),
    );
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
    if (_phoneDigits.length >= 10) {
      _personalInfo.phoneNumber = _phoneDigits.startsWith('0')
          ? _phoneDigits
          : '0$_phoneDigits';
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
          label: 'Continue →',
          loading: _isLoading,
          onTap: _handleOtpSubmit,
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
          loading: _isLoading,
          onTap: _onPasswordContinue,
        ),
      ],
    );
  }

  void _onPasswordContinue() async {
    if (_password != _confirmPassword) {
      _snack('Passwords do not match. Please try again.', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    final ok = await ref.read(onboardingProvider.notifier).createPassword(
          password: _password,
          confirmPassword: _confirmPassword,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      _animateTo(AccountStep.createPin);
    } else {
      _snack(
          ref.read(onboardingProvider).error ??
              'Failed to set password. Please try again.',
          isError: true);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 7 — Create PIN
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
          loading: _creatingPin,
          onTap: _onConfirmPin,
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

  Widget _buildAccountCreatedSuccessStep() {
    final accountNumber = ref.read(onboardingProvider).accountNumber ??
        (_phoneDigits.isNotEmpty ? '0$_phoneDigits' : '08XXXXXXXXX');
    return Stack(
      key: const ValueKey('accountCreatedSuccess'),
      children: [
        Container(
          decoration: BoxDecoration(
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
              const RimapayLogo(
                width: 64,
                height: 64,
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
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Your account has been created successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.75),
                      height: 1.5),
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
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/home'),
                      child: Container(
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
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => _animateTo(AccountStep.residentialAddress),
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Center(
                          child: Text(
                            'Complete Profile',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // Profile Completed Success Screen
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildProfileCompletedSuccessStep() {
    return Stack(
      key: const ValueKey('profileCompletedSuccess'),
      children: [
        Container(
          decoration: BoxDecoration(
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
              const RimapayLogo(
                width: 64,
                height: 64,
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
                child: const Icon(Icons.check_circle,
                    color: Colors.white, size: 54),
              ),
              const SizedBox(height: 24),
              const Text(
                'Profile Completed!',
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
                  'Your profile is now complete.\nWelcome to RimaPay!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.75),
                      height: 1.5),
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
    final isUnderbanked = widget.accountType == 'underbanked';

    return Column(
      key: const ValueKey('idVerification'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isUnderbanked) ...[
                  const Text(
                    'Please provide your own BVN/NIN to verify your account opening application',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
                  ),
                ] else ...[
                  const Text(
                    'Provide your BVN or NIN if you have one. This step is optional for underbanked accounts.',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
                  ),
                ],
                const SizedBox(height: 20),
                // BVN / NIN / No ID toggle
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: ['bvn', 'nin', 'noid'].map((type) {
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
                                  ? (type == 'noid'
                                      ? const Color(0xFFF97316)
                                      : const Color(0xFF16A34A))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Center(
                              child: Text(
                                type == 'noid' ? 'No ID' : type.toUpperCase(),
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

                // "No ID" callout
                if (_idType == 'noid') ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFFB923C).withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: Color(0xFFF97316), size: 18),
                            SizedBox(width: 8),
                            Text('Underbanked Account',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF78350F))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Without BVN or NIN, your account will have limited features:\n• ₦10,000 daily transaction limit\n• No international transfers\n• You can upgrade anytime by adding your BVN/NIN later',
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF78350F),
                              height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  // Label row with dynamic forgot link
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
                            color: Color(0xFF374151)),
                      ),
                      GestureDetector(
                        onTap: _showForgotIdSheet,
                        child: Text(
                          'Forgot ${_idType.toUpperCase()}?',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.w600),
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
                                  color: Color(0xFF111827)),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
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
              ],
            ),
          ),
        ),
        // Licensed footer
        const _CbnFooter(),
        _buildCTA(
          label: _idType == 'noid'
              ? 'Open Underbanked Account'
              : (isUnderbanked ? 'Continue without ID →' : 'Continue →'),
          loading: _isLoading,
          onTap: _idType == 'noid' ? _showNoIdConfirmSheet : _onIdContinue,
        ),
      ],
    );
  }

  void _onIdContinue() async {
    if (_idDigits.length != 11) {
      _snack('Enter a valid 11-digit ${_idType.toUpperCase()}.', isError: true);
      return;
    }
    if (_idType == 'bvn') {
      _personalInfo.bvn = _idDigits;
      _bvnController.text = _idDigits;
    } else {
      _personalInfo.nin = _idDigits;
      _ninController.text = _idDigits;
    }
    setState(() => _isLoading = true);
    final ok = await ref.read(onboardingProvider.notifier).submitIdentity(
          identityNumber: _idDigits,
          documentType: _idType == 'nin'
              ? IdentityDocumentType.nin
              : IdentityDocumentType.bvn,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      final st = ref.read(onboardingProvider);
      if ((st.validatedFirstName ?? '').isNotEmpty) {
        _personalInfo.firstname = st.validatedFirstName!;
      }
      if ((st.validatedLastName ?? '').isNotEmpty) {
        _personalInfo.lastname = st.validatedLastName!;
      }
      _animateTo(AccountStep.facialVerification);
    } else {
      _snack(
          ref.read(onboardingProvider).error ??
              'Identity verification failed. Please check your details.',
          isError: true);
    }
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
          loading: _isLoading,
          onTap: _onCompleteProfile,
        ),
      ],
    );
  }

  /// Final profile-completion step: submit the collected KYC profile to the
  /// Profile API (`/api/v1/profile/create`) using the identityUserId produced
  /// during onboarding, then show the completed screen.
  void _onCompleteProfile() async {
    final st = ref.read(onboardingProvider);
    final identityUserId = st.identityUserId;
    if (identityUserId == null || identityUserId.isEmpty) {
      // Account is already created during onboarding; nothing to submit here.
      _animateTo(AccountStep.profileCompletedSuccess);
      return;
    }
    final idNumber = _personalInfo.bvn.isNotEmpty
        ? _personalInfo.bvn
        : (_personalInfo.nin.isNotEmpty ? _personalInfo.nin : null);
    final docType = _personalInfo.bvn.isNotEmpty
        ? 'BVN'
        : (_personalInfo.nin.isNotEmpty ? 'NIN' : null);
    final address = [
      _personalInfo.residentialAddress,
      _personalInfo.lga,
      _personalInfo.state,
    ].where((p) => p.trim().isNotEmpty).join(', ');
    setState(() => _isLoading = true);
    final ok = await ref.read(profileProvider.notifier).createProfile(
          CreateProfileRequest(
            identityUserId: identityUserId,
            firstName: _personalInfo.firstname.isNotEmpty
                ? _personalInfo.firstname
                : null,
            lastName: _personalInfo.lastname.isNotEmpty
                ? _personalInfo.lastname
                : null,
            email: _personalInfo.emailAddress.isNotEmpty
                ? _personalInfo.emailAddress
                : null,
            phoneNumber: _personalInfo.phoneNumber.isNotEmpty
                ? _personalInfo.phoneNumber
                : null,
            dateOfBirth: _personalInfo.dateOfBirth.isNotEmpty
                ? _personalInfo.dateOfBirth
                : null,
            gender:
                _personalInfo.gender.isNotEmpty ? _personalInfo.gender : null,
            address: address.isNotEmpty ? address : null,
            identityNumber: idNumber,
            documentType: docType,
          ),
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      _animateTo(AccountStep.profileCompletedSuccess);
    } else {
      _snack(
          ref.read(profileProvider).error ??
              'Failed to save your profile. Please try again.',
          isError: true);
    }
  }

  // ═══════════════════���══════════════════════════════════════════════════════════
  // STEP 12 — Facial Verification
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildFacialVerificationStep() {
    // Underbanked: simple photo upload — no liveness detection
    if (_isUnderbanked) {
      return Column(
        key: const ValueKey('facialVerification'),
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
                            'Take a clear selfie — no glasses, good lighting, face centered.',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF166C46),
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Camera preview or placeholder
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      height: 300,
                      color: Colors.black87,
                      child: _cameraActive &&
                              _cameraController != null &&
                              _cameraController!.value.isInitialized
                          ? CameraPreview(_cameraController!)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.person,
                                      color: Colors.white54, size: 44),
                                ),
                                const SizedBox(height: 14),
                                const Text('Camera preview will appear here',
                                    style: TextStyle(
                                        color: Colors.white54, fontSize: 13)),
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
                  if (_cameraError != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_cameraError!,
                          style: const TextStyle(
                              color: Color(0xFFB91C1C), fontSize: 13)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _buildCTA(
            label: _cameraActive ? 'Take Photo' : 'Start Camera',
            onTap: _cameraActive ? _capturePhoto : _requestCameraPermission,
          ),
        ],
      );
    }

    // Standard: liveness detection with oval overlay
    return Column(
      key: const ValueKey('facialVerification'),
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_cameraActive &&
                  _cameraController != null &&
                  _cameraController!.value.isInitialized)
                Positioned.fill(child: CameraPreview(_cameraController!))
              else
                Container(color: Colors.black87),

              Positioned.fill(
                child: CustomPaint(
                  painter: _OvalOverlayPainter(color: const Color(0xFFD4AF37)),
                ),
              ),

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
                              child: const LinearProgressIndicator(
                                value: 0.1,
                                minHeight: 4,
                                backgroundColor: Color(0xFFE5E7EB),
                                valueColor: AlwaysStoppedAnimation(
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

  /// Full-screen "verifying" overlay shown while the captured selfie is being
  /// checked by the backend. Blocks interaction and reassures the user to wait.
  Widget _buildFaceVerifyingOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xE60B1F14),
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FaceScanLoader(),
              SizedBox(height: 22),
              Text(
                'Verifying your face',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827)),
              ),
              SizedBox(height: 8),
              Text(
                'Hold on a moment — this can take a few seconds.\nPlease don\'t close or refresh the page.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
              ),
            ],
          ),
        ),
      ),
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
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
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
              const RimapayLogo(
                width: 64,
                height: 64,
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

  Widget _buildCTA({String? label, bool loading = false, VoidCallback? onTap, Widget? footerContent}) {
    // Always treat as enabled — onTap may be null only during loading
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
      hintStyle: TextStyle(
          color: Theme.of(context).dividerColor, fontSize: 14, fontFamily: 'Effra'),
      suffixIcon: suffix,
      filled: true,
      fillColor: Theme.of(context).cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor)),
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
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface));
  }

  void _showOptionsSheet(
      String title, List<String> options, void Function(String) onSelect) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
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
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(title,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface)),
            ),
            const SizedBox(height: 8),
            Divider(color: Theme.of(context).dividerColor),
            ...options.map((o) => ListTile(
                  title: Text(o, style: const TextStyle(fontSize: 15)),
                  trailing: Icon(Icons.chevron_right,
                      color: Theme.of(context).dividerColor),
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
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
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
                    prefixIcon: Icon(Icons.search,
                        color: Theme.of(context).dividerColor, size: 18),
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
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
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
                color: Theme.of(context).dividerColor,
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
    final ok =
        await ref.read(onboardingProvider.notifier).verifyOtp(_otp.join());
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      _animateTo(_isUnderbanked
          ? AccountStep.facialVerification
          : AccountStep.idEntry);
    } else {
      _snack(
          ref.read(onboardingProvider).error ??
              'Failed to verify OTP. Please try again.',
          isError: true);
    }
  }

  Future<void> _handleResendOtp() async {
    if (_resendCountdown > 0 || _isResending) return;
    setState(() => _isResending = true);
    final ok = await ref.read(onboardingProvider.notifier).resendOtp();
    if (!mounted) return;
    setState(() => _isResending = false);
    if (ok) {
      _snack('OTP resent successfully');
      _startResendCountdown();
    } else {
      _snack(ref.read(onboardingProvider).error ?? 'Failed to resend OTP.',
          isError: true);
    }
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

  void _handlePinSet() async {
    if (_pin.any((d) => d.isEmpty)) return;
    setState(() => _creatingPin = true);
    final ok = await ref.read(onboardingProvider.notifier).createPin(
          pin: _pin.join(),
          confirmPin: _confirmPinEntry.join(),
        );
    if (!mounted) return;
    setState(() => _creatingPin = false);
    if (ok) {
      // Keep the PIN locally for in-app transaction verification.
      await StorageService.savePin(_pin.join());
      // Best-effort: authenticate with the phone + password just set so the
      // user lands signed in. Safe to ignore failures (e.g. missing client
      // secret) — they can still sign in from the login screen.
      final onboardingState = ref.read(onboardingProvider);
      if (_password.isNotEmpty && mounted) {
        final phoneNum = _phoneDigits.startsWith('0') ? _phoneDigits : '0$_phoneDigits';
        await legacy_provider.Provider.of<AuthProvider>(context, listen: false)
            .loginWithCredentials(
          phoneNumber: phoneNum,
          password: _password,
        );
      }
      // Always save user data from onboarding (fallback if login fails).
      if (mounted) {
        final phoneNum = _phoneDigits.startsWith('0') ? _phoneDigits : '0$_phoneDigits';
        legacy_provider.Provider.of<AuthProvider>(context, listen: false)
            .saveOnboardingUser(
          phoneNumber: phoneNum,
          firstName: onboardingState.firstName,
          lastName: onboardingState.lastName,
          accountNumber: onboardingState.accountNumber,
          identityUserId: onboardingState.identityUserId,
        );
      }
      if (!mounted) return;
      _animateTo(AccountStep.accountCreatedSuccess);
    } else {
      _snack(
          ref.read(onboardingProvider).error ??
              'Failed to create PIN. Please try again.',
          isError: true);
    }
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
      _cameraController = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false, // face capture only — avoids mic prompt/failure on web
      );
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
    // On web there is no permission_handler camera flow — the browser shows its
    // own permission prompt when the camera stream starts. Go straight to init.
    if (kIsWeb) {
      await _initializeCamera();
      return;
    }
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
      final bytes = await image.readAsBytes();
      setState(() {
        _capturedImage = image.path;
        _cameraActive = false;
        _isLoading = true;
        _verifyingFace = true;
      });
      _cameraController?.dispose();
      _cameraController = null;
      final ok = await ref.read(onboardingProvider.notifier).validateFace(
            capturedImageBase64: base64Encode(bytes),
            livenessCheckPassed: true,
          );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _verifyingFace = false;
      });
      if (ok) {
        final st = ref.read(onboardingProvider);
        final c = st.confidenceScore;
        String pct = '';
        if (c != null) {
          final v = c <= 1 ? c * 100 : c;
          pct = ' • ${v.clamp(0, 100).toStringAsFixed(0)}% match';
        }
        _snack(st.facialMatch ? 'Face matched ✓$pct' : 'Face captured$pct');
        _animateTo(AccountStep.createPassword);
      } else {
        _snack(
            ref.read(onboardingProvider).error ??
                'Face verification failed. Please try again.',
            isError: true);
      }
    } catch (e) {
      setState(() {
        _cameraError = 'Failed to capture photo: $e';
        _isLoading = false;
        _verifyingFace = false;
      });
    }
  }
}

// ─── Animated face-scan loader (shown while validate-face runs) ───────────────

class _FaceScanLoader extends StatefulWidget {
  const _FaceScanLoader();

  @override
  State<_FaceScanLoader> createState() => _FaceScanLoaderState();
}

class _FaceScanLoaderState extends State<_FaceScanLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF166C46);
    return SizedBox(
      width: 96,
      height: 96,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Expanding pulse rings
              ...[0.0, 0.5].map((offset) {
                final t = (_c.value + offset) % 1.0;
                return Opacity(
                  opacity: (1 - t) * 0.45,
                  child: Container(
                    width: 50 + t * 46,
                    height: 50 + t * 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: green, width: 2),
                    ),
                  ),
                );
              }),
              const SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(green),
                ),
              ),
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: Color(0x1F166C46),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.face_retouching_natural,
                    color: green, size: 30),
              ),
            ],
          );
        },
      ),
    );
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
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
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

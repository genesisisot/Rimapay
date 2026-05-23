import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rimapay/shared/widgets/noise_painter.dart';
import 'package:rimapay/core/theme/app_colors.dart';

enum BusinessAccountStep {
  phoneEntry,
  otpVerification,
  bvnVerification,
  selfieLiveness,
  createPin,
  confirmPin,
  createPassword,
  businessType,
  businessDetails,
  cacDetails,
  directorInfo,
  documentUpload,
  reviewSubmit,
  autoCheckProcessing,
  autoCheckFail,
  manualReviewPending,
  rejection,
  approval,
}

class BusinessInfo {
  String phoneNumber = '';
  String emailAddress = '';
  String? bvn;
  String? nin;
  String? selfieImage;
  String? pin;
  String? password;
  String businessType = '';
  String businessName = '';
  String industry = '';
  String businessAddress = '';
  String state = '';
  String lga = '';
  String? rcNumber;
  DateTime? dateOfIncorporation;
  List<DirectorInfo> directors = [];
  List<UploadedDocument> documents = [];
}

class DirectorInfo {
  String fullName = '';
  String? dateOfBirth;
  String? ownershipPercentage;
  String? bvn;
}

class UploadedDocument {
  final String title;
  final String? filePath;
  final String? fileName;
  final String? fileSize;
  bool isUploaded;

  UploadedDocument({
    required this.title,
    this.filePath,
    this.fileName,
    this.fileSize,
    this.isUploaded = false,
  });
}

class BusinessAccountFlow extends ConsumerStatefulWidget {
  const BusinessAccountFlow({super.key});

  @override
  ConsumerState<BusinessAccountFlow> createState() =>
      _BusinessAccountFlowState();
}

class _BusinessAccountFlowState extends ConsumerState<BusinessAccountFlow>
    with TickerProviderStateMixin {
  BusinessAccountStep _currentStep = BusinessAccountStep.phoneEntry;
  final BusinessInfo _businessInfo = BusinessInfo();
  final List<String> _otp = List.filled(6, '');
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isResending = false;
  int _resendCountdown = 0;
  Timer? _resendTimer;
  double _passwordStrength = 0;
  String _passwordStrengthLabel = '';
  bool _addNinToggle = false;
  String _bvnDigits = '';
  final List<String> _pin = List.filled(4, '');
  final List<String> _confirmPinEntry = List.filled(4, '');
  bool _processingStarted = false;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bvnController = TextEditingController();
  final TextEditingController _ninController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessAddressController = TextEditingController();
  final TextEditingController _industryController = TextEditingController();
  final TextEditingController _rcNumberController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _ownershipController = TextEditingController();
  final TextEditingController _directorBvnController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _lgaController = TextEditingController();

  late AnimationController _pageAnimController;
  late AnimationController _congratsConfettiCtrl;
  late List<_CParticle> _confettiParticles;

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
    _bvnController.dispose();
    _ninController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _industryController.dispose();
    _rcNumberController.dispose();
    _dobController.dispose();
    _fullNameController.dispose();
    _ownershipController.dispose();
    _directorBvnController.dispose();
    super.dispose();
  }

  void _animateTo(BusinessAccountStep step) {
    if (step == BusinessAccountStep.autoCheckProcessing) {
      _processingStarted = false;
    }
    if (step == BusinessAccountStep.approval) {
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
      BusinessAccountStep next = steps[idx + 1];
      if (_currentStep == BusinessAccountStep.businessDetails &&
          _businessInfo.businessType == 'sole_trader') {
        next = BusinessAccountStep.directorInfo;
      }
      _animateTo(next);
    }
  }

  void _goBack() {
    final steps = BusinessAccountStep.values;
    final idx = steps.indexOf(_currentStep);
    if (idx > 0) {
      _animateTo(steps[idx - 1]);
    } else {
      context.pop();
    }
  }

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

  @override
  Widget build(BuildContext context) {
    if (_currentStep == BusinessAccountStep.autoCheckProcessing && !_processingStarted) {
      _processingStarted = true;
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          _animateTo(BusinessAccountStep.approval);
        }
      });
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _pageAnimController,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.95 + (0.05 * _pageAnimController.value),
            child: Opacity(
              opacity: _pageAnimController.value,
              child: child,
            ),
          );
        },
        child: _buildCurrentStep(),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case BusinessAccountStep.phoneEntry:
        return _buildPhoneEntryScreen(key: const ValueKey('phoneEntry'));
      case BusinessAccountStep.otpVerification:
        return _buildOtpVerificationScreen(key: const ValueKey('otp'));
      case BusinessAccountStep.bvnVerification:
        return _buildBvnVerificationScreen(key: const ValueKey('bvn'));
      case BusinessAccountStep.selfieLiveness:
        return _buildSelfieLivenessScreen(key: const ValueKey('selfie'));
      case BusinessAccountStep.createPin:
        return _buildCreatePinScreen(key: const ValueKey('createPin'));
      case BusinessAccountStep.confirmPin:
        return _buildConfirmPinScreen(key: const ValueKey('confirmPin'));
      case BusinessAccountStep.createPassword:
        return _buildCreatePasswordScreen(key: const ValueKey('createPassword'));
      case BusinessAccountStep.businessType:
        return _buildBusinessTypeScreen(key: const ValueKey('businessType'));
      case BusinessAccountStep.businessDetails:
        return _buildBusinessDetailsScreen(key: const ValueKey('businessDetails'));
      case BusinessAccountStep.cacDetails:
        return _buildCacDetailsScreen(key: const ValueKey('cacDetails'));
      case BusinessAccountStep.directorInfo:
        return _buildDirectorInfoScreen(key: const ValueKey('directorInfo'));
      case BusinessAccountStep.documentUpload:
        return _buildDocumentUploadScreen(key: const ValueKey('documents'));
      case BusinessAccountStep.reviewSubmit:
        return _buildReviewSubmitScreen(key: const ValueKey('review'));
      case BusinessAccountStep.autoCheckProcessing:
        return _buildAutoCheckProcessingScreen(key: const ValueKey('processing'));
      case BusinessAccountStep.autoCheckFail:
        return _buildAutoCheckFailScreen(key: const ValueKey('fail'));
      case BusinessAccountStep.manualReviewPending:
        return _buildManualReviewPendingScreen(key: const ValueKey('pending'));
      case BusinessAccountStep.rejection:
        return _buildRejectionScreen(key: const ValueKey('rejection'));
      case BusinessAccountStep.approval:
        return _buildApprovalScreen(key: const ValueKey('approval'));
    }
  }

  Widget _buildHeader() {
    final statusH = MediaQuery.of(context).padding.top;
    final steps = BusinessAccountStep.values;
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
                const SizedBox(height: 24),
                Text(
                  _getStepTitle(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStepSubtitle(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case BusinessAccountStep.phoneEntry:
        return 'Enter phone number';
      case BusinessAccountStep.otpVerification:
        return 'Enter verification code';
      case BusinessAccountStep.bvnVerification:
        return 'Verify your identity';
      case BusinessAccountStep.selfieLiveness:
        return 'Take a selfie';
      case BusinessAccountStep.createPin:
        return 'Create PIN';
      case BusinessAccountStep.confirmPin:
        return 'Confirm PIN';
      case BusinessAccountStep.createPassword:
        return 'Create Password';
      case BusinessAccountStep.businessType:
        return 'What type of business?';
      case BusinessAccountStep.businessDetails:
        return 'About your business';
      case BusinessAccountStep.cacDetails:
        return 'CAC Registration';
      case BusinessAccountStep.directorInfo:
        return 'Director & ownership';
      case BusinessAccountStep.documentUpload:
        return 'Upload your documents';
      case BusinessAccountStep.reviewSubmit:
        return 'Review your application';
      default:
        return '';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case BusinessAccountStep.phoneEntry:
        return "We'll send a verification code to this number";
      case BusinessAccountStep.otpVerification:
        return 'We sent a 6-digit code to your phone';
      case BusinessAccountStep.bvnVerification:
        return 'Your BVN helps us confirm who you are';
      case BusinessAccountStep.selfieLiveness:
        return 'Position your face in the oval';
      case BusinessAccountStep.createPin:
        return 'Secure your account with a 4-digit PIN';
      case BusinessAccountStep.confirmPin:
        return 'Re-enter your 4-digit PIN to confirm';
      case BusinessAccountStep.createPassword:
        return 'Create a password to secure your account';
      case BusinessAccountStep.businessType:
        return 'This helps us set the right account limits';
      case BusinessAccountStep.businessDetails:
        return 'Tell us about your business';
      case BusinessAccountStep.cacDetails:
        return 'Enter your CAC details';
      case BusinessAccountStep.directorInfo:
        return 'Tell us who owns the business';
      case BusinessAccountStep.documentUpload:
        return 'JPG, PNG or PDF — max 5MB each';
      case BusinessAccountStep.reviewSubmit:
        return 'Confirm everything before submitting';
      default:
        return '';
    }
  }

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF667085),
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          onTap: onTap,
          validator: validator,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF101828),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              color: Color(0xFFD1D1D1),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1A6B35), width: 1.5),
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(String text, {VoidCallback? onPressed, bool isLoading = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: isLoading ? null : (onPressed ?? _nextStep),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A6B35),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBottomCTA({
    required String label,
    required VoidCallback onTap,
    bool loading = false,
    Widget? footerContent,
  }) {
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
                        label,
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
            const SizedBox(height: 12),
            footerContent,
          ],
        ],
      ),
    );
  }

  Widget _buildSecondaryButton(String text, {VoidCallback? onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: onPressed ?? _nextStep,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1A6B35),
            side: const BorderSide(color: Color(0xFF1A6B35)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumPad({
    required void Function(String) onDigit,
    required VoidCallback onDelete,
  }) {
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

  Widget _buildInfoCallout({
    required String text,
    bool isGreen = false,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGreen ? const Color(0xFFF0FAF4) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: isGreen
            ? const Border(
                left: BorderSide(color: Color(0xFF1A6B35), width: 3),
              )
            : null,
      ),
      child: Row(
        children: [
          Icon(
            icon ?? (isGreen ? Icons.lock_outline : Icons.info_outline),
            size: 20,
            color: isGreen ? const Color(0xFF1A6B35) : const Color(0xFF667085),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF667085),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDividerWithLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF667085),
              ),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
        ],
      ),
    );
  }

  // Screen 1: Phone Number Input
  Widget _buildPhoneEntryScreen({Key? key}) {
    return Column(
      key: key,
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextInput(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'Enter phone number',
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        _buildBottomCTA(label: 'Continue', onTap: _nextStep),
      ],
    );
  }

  // Screen 2: OTP Verification
  Widget _buildOtpVerificationScreen({Key? key}) {
    String maskedPhone = _phoneController.text.isNotEmpty
        ? '+234 ${_phoneController.text.substring(0, 3)} XXX ${_phoneController.text.substring(6)}'
        : '+234 XXX XXXX';

    return Column(
      key: key,
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: 'We sent a 6-digit code to ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF667085),
                        ),
                      ),
                      TextSpan(
                        text: maskedPhone,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A6B35),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    return Container(
                      width: 44,
                      height: 52,
                      margin: EdgeInsets.only(right: index < 5 ? 8 : 0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFDDDDDD),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _otp[index],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF101828),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                Center(
                  child: _isResending
                      ? Text(
                          'Resend code in 0:$_resendCountdown',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF667085),
                          ),
                        )
                      : TextButton(
                          onPressed: () {
                            setState(() => _isResending = true);
                            _startResendTimer();
                          },
                          child: const Text(
                            'Resend OTP',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1A6B35),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
        _buildBottomCTA(
          label: 'Verify',
          onTap: _nextStep,
          footerContent: TextButton(
            onPressed: () => _animateTo(BusinessAccountStep.phoneEntry),
            child: const Text(
              'Wrong number? Go back',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF1A6B35),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Screen 3: BVN Verification
  Widget _buildBvnVerificationScreen({Key? key}) {
    final maxLen = 11;
    final filled = _bvnDigits.length;
    return Column(
      key: key,
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dial 565*0# on any network to get your BVN',
                  style: TextStyle(
                      fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
                ),
                const SizedBox(height: 24),
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
                                ? const Color(0xFF1A6B35)
                                : hasDigit
                                    ? const Color(0xFF1A6B35).withOpacity(0.4)
                                    : const Color(0xFFE5E7EB),
                            width: isActive ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            hasDigit ? _bvnDigits[i] : '',
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
                if (_addNinToggle) ...[
                  const SizedBox(height: 24),
                  const Text(
                    'National Identification Number (NIN)',
                    style: TextStyle(
                        fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 12),
                  _buildTextInput(
                    controller: _ninController,
                    label: '',
                    hint: 'Enter 11-digit NIN',
                    keyboardType: TextInputType.number,
                  ),
                ],
                const SizedBox(height: 24),
                _buildInfoCallout(
                  text: 'Your BVN is encrypted and never shared with third parties.',
                  isGreen: true,
                ),
                const SizedBox(height: 24),
                _buildNumPad(
                  onDigit: (d) {
                    if (_bvnDigits.length < maxLen) {
                      setState(() => _bvnDigits += d);
                    }
                  },
                  onDelete: () {
                    if (_bvnDigits.isNotEmpty) {
                      setState(() => _bvnDigits =
                          _bvnDigits.substring(0, _bvnDigits.length - 1));
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () {
                setState(() => _addNinToggle = !_addNinToggle);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF1A6B35)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _addNinToggle ? 'Remove NIN' : 'Also add NIN',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1A6B35),
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _addNinToggle ? Icons.remove : Icons.add,
                      size: 14,
                      color: const Color(0xFF1A6B35),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        _buildBottomCTA(label: 'Continue', onTap: _nextStep),
      ],
    );
  }

  // Screen 4: Selfie + Liveness Check
  Widget _buildSelfieLivenessScreen({Key? key}) {
    return Column(
      key: key,
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 320,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          width: 200,
                          height: 270,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF1A6B35),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(140),
                          ),
                        ),
                      ),
                      const Center(
                        child: Icon(
                          Icons.face,
                          size: 48,
                          color: Color(0xFF98A2B3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FAF4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF1A6B35)),
                  ),
                  child: const Text(
                    'Look straight ahead',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A6B35),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTipChip('Good lighting'),
                    const SizedBox(width: 8),
                    _buildTipChip('No glasses'),
                    const SizedBox(width: 8),
                    _buildTipChip('Face forward'),
                  ],
                ),
              ],
            ),
          ),
        ),
        _buildBottomCTA(
          label: 'Start Camera',
          onTap: _nextStep,
          footerContent: const Text(
            'RimaPay needs camera access to complete this step',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF667085),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTipChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF667085),
        ),
      ),
    );
  }

  // Screen 5: Create PIN
  Widget _buildCreatePinScreen({Key? key}) {
    final filled = _pin.where((d) => d.isNotEmpty).length;
    return Column(
      key: key,
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A6B35).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_outlined,
                      color: Color(0xFF1A6B35), size: 34),
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
                            ? const Color(0xFF1A6B35)
                            : Colors.transparent,
                        border: Border.all(
                          color: hasDot
                              ? const Color(0xFF1A6B35)
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
        _buildBottomCTA(label: 'Continue', onTap: _nextStep),
      ],
    );
  }

  // Screen 6: Confirm PIN
  Widget _buildConfirmPinScreen({Key? key}) {
    final filled = _confirmPinEntry.where((d) => d.isNotEmpty).length;
    return Column(
      key: key,
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A6B35).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield,
                      color: Color(0xFF1A6B35), size: 34),
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
                            ? const Color(0xFF1A6B35)
                            : Colors.transparent,
                        border: Border.all(
                          color: hasDot
                              ? const Color(0xFF1A6B35)
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
        _buildBottomCTA(label: 'Continue', onTap: _onConfirmPin),
      ],
    );
  }

  void _onConfirmPin() {
    if (_confirmPinEntry.join() != _pin.join()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('PINs do not match. Please try again.'),
        backgroundColor: Colors.red,
      ));
      setState(() {
        for (int i = 0; i < _confirmPinEntry.length; i++) {
          _confirmPinEntry[i] = '';
        }
      });
      return;
    }
    _businessInfo.pin = _pin.join();
    _nextStep();
  }

  // Screen 7: Create Password
  Widget _buildCreatePasswordScreen({Key? key}) {
    return Column(
      key: key,
      children: [
        _buildHeader(),
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
                _buildTextInput(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Min 8 characters',
                  obscureText: !_showPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF98A2B3),
                    ),
                    onPressed: () {
                      setState(() => _showPassword = !_showPassword);
                    },
                  ),
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
                _buildTextInput(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  obscureText: !_showConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: const Color(0xFF98A2B3),
                    ),
                    onPressed: () {
                      setState(() => _showConfirmPassword = !_showConfirmPassword);
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        _buildBottomCTA(label: 'Continue', onTap: _onPasswordContinue),
      ],
    );
  }

  void _onPasswordContinue() {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Passwords do not match. Please try again.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Password must be at least 8 characters.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    _businessInfo.password = _passwordController.text;
    _nextStep();
  }

  Widget _buildPinDots(String pinString) {
    List<String> pinList = pinString.isEmpty ? [] : pinString.split('');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        bool isFilled = index < pinList.length && pinList[index].isNotEmpty;
        return GestureDetector(
          onTap: () {},
          child: Container(
            width: 14,
            height: 14,
            margin: EdgeInsets.only(right: index < 5 ? 8 : 0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? const Color(0xFF1A6B35) : const Color(0xFFE5E7EB),
            ),
          ),
        );
      }),
    );
  }

  double _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    double strength = 0;
    if (password.length >= 8) strength += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.25;
    return strength;
  }

  String _getPasswordStrengthLabel(double strength) {
    if (strength <= 0.25) return 'Weak';
    if (strength <= 0.5) return 'Fair';
    if (strength <= 0.75) return 'Strong';
    return 'Very Strong';
  }

  Color _getPasswordStrengthColor(double strength) {
    if (strength <= 0.25) return Colors.red;
    if (strength <= 0.5) return Colors.orange;
    if (strength <= 0.75) return Colors.green;
    return const Color(0xFF1A6B35);
  }

  // Screen 6: Business Type
  Widget _buildBusinessTypeScreen({Key? key}) {
    return Column(
      key: key,
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.63,
                  children: [
                    _buildBusinessTypeCard(
                      icon: Icons.person_outline,
                      label: 'Sole Trader',
                      isSelected: _businessInfo.businessType == 'sole_trader',
                      onTap: () {
                        setState(() => _businessInfo.businessType = 'sole_trader');
                      },
                    ),
                    _buildBusinessTypeCard(
                      icon: Icons.business,
                      label: 'Limited Company',
                      isSelected: _businessInfo.businessType == 'limited_company',
                      onTap: () {
                        setState(() => _businessInfo.businessType = 'limited_company');
                      },
                    ),
                    _buildBusinessTypeCard(
                      icon: Icons.handshake_outlined,
                      label: 'Partnership',
                      isSelected: _businessInfo.businessType == 'partnership',
                      onTap: () {
                        setState(() => _businessInfo.businessType = 'partnership');
                      },
                    ),
                    _buildBusinessTypeCard(
                      icon: Icons.favorite_outline,
                      label: 'NGO / Non-profit',
                      isSelected: _businessInfo.businessType == 'ngo',
                      onTap: () {
                        setState(() => _businessInfo.businessType = 'ngo');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        _buildBottomCTA(label: 'Continue', onTap: _nextStep),
      ],
    );
  }

  Widget _buildBusinessTypeCard({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FAF4) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A6B35) : const Color(0xFFEEEEEE),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 32,
                    color: const Color(0xFF1A6B35),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF101828),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1A6B35),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Screen 7: Business Details
  Widget _buildBusinessDetailsScreen({Key? key}) {
    return Column(
      key: key,
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextInput(
                  controller: _businessNameController,
                  label: 'Business Name',
                  hint: 'Enter business name',
                ),
                const SizedBox(height: 16),
                _buildTextInput(
                  controller: _industryController,
                  label: 'Industry',
                  hint: 'Select industry',
                  suffixIcon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF98A2B3),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextInput(
                  controller: _businessAddressController,
                  label: 'Business Address',
                  hint: 'Enter business address',
                ),
                const SizedBox(height: 16),
                _buildTextInput(
                  controller: _stateController,
                  label: 'State',
                  hint: 'Select state',
                  suffixIcon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF98A2B3),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextInput(
                  controller: _lgaController,
                  label: 'LGA',
                  hint: 'Select LGA',
                  suffixIcon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF98A2B3),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildBottomCTA(label: 'Continue', onTap: _nextStep),
      ],
    );
  }

  // Screen 8: CAC Details
  Widget _buildCacDetailsScreen({Key? key}) {
    return Column(
      key: key,
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextInput(
                  controller: _rcNumberController,
                  label: 'RC Number',
                  hint: 'Enter 7-digit RC Number',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildTextInput(
                  controller: _dobController,
                  label: 'Date of Incorporation',
                  hint: 'DD/MM/YYYY',
                  readOnly: true,
                  suffixIcon: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF98A2B3),
                  ),
                ),
                const SizedBox(height: 24),
                _buildInfoCallout(
                  text: 'Sole traders may not need a CAC number. Tap Skip if this doesn\'t apply to you.',
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => _animateTo(BusinessAccountStep.directorInfo),
                    child: const Text(
                      'Skip this step',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A6B35),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildBottomCTA(label: 'Continue', onTap: _nextStep),
      ],
    );
  }

  // Screen 9: Director Info
  Widget _buildDirectorInfoScreen({Key? key}) {
    return Column(
      key: key,
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Director 1',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextInput(
                  controller: _fullNameController,
                  label: 'Full Name',
                  hint: 'Enter full name',
                ),
                const SizedBox(height: 16),
                _buildTextInput(
                  controller: _dobController,
                  label: 'Date of Birth',
                  hint: 'DD/MM/YYYY',
                  readOnly: true,
                  suffixIcon: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF98A2B3),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextInput(
                  controller: _ownershipController,
                  label: 'Ownership %',
                  hint: 'Enter percentage',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildTextInput(
                  controller: _directorBvnController,
                  label: 'Director\'s BVN',
                  hint: 'Enter 11-digit BVN',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {},
                  child: Row(
                    children: const [
                      Icon(
                        Icons.add_circle_outline,
                        size: 24,
                        color: Color(0xFF1A6B35),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Add another director',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A6B35),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildBottomCTA(label: 'Continue', onTap: _nextStep),
      ],
    );
  }

  // Screen 10: Document Upload
  Widget _buildDocumentUploadScreen({Key? key}) {
    List<UploadedDocument> documents = [
      UploadedDocument(title: 'CAC Certificate or Proof of Registration'),
      UploadedDocument(title: 'Utility Bill (business address proof)'),
      UploadedDocument(title: 'Director\'s ID — Passport or NIN Slip'),
    ];

    return Column(
      key: key,
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...documents.map((doc) => _buildDocumentCard(doc)),
                if (_businessInfo.businessType == 'sole_trader') ...[
                  const SizedBox(height: 16),
                  _buildInfoCallout(
                    text: 'As a sole trader, your BVN + NIN may be sufficient. CAC upload is optional.',
                    isGreen: true,
                  ),
                ],
              ],
            ),
          ),
        ),
        _buildBottomCTA(label: 'Submit Documents', onTap: _nextStep),
      ],
    );
  }

  Widget _buildDocumentCard(UploadedDocument doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEEEEEE)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                size: 24,
                color: Color(0xFF1A6B35),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  doc.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF101828),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Required',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF98A2B3),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFFCCCCCC),
                style: BorderStyle.solid,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 32,
                  color: Color(0xFF98A2B3),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap to upload or take a photo',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF667085),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'PDF, JPG, PNG — max 5MB',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF98A2B3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Camera'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF667085),
                    side: const BorderSide(color: Color(0xFFEEEEEE)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF667085),
                    side: const BorderSide(color: Color(0xFFEEEEEE)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Screen 11: Review & Submit
  Widget _buildReviewSubmitScreen({Key? key}) {
    return Column(
      key: key,
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReviewSection(
                  'Personal Info',
                  [
                    _buildReviewRow('Full Name', _fullNameController.text),
                    _buildReviewRow('Phone Number', _phoneController.text),
                    _buildReviewRow('BVN', '*******'),
                  ],
                ),
                _buildReviewSection(
                  'Business Info',
                  [
                    _buildReviewRow('Business Name', _businessNameController.text),
                    _buildReviewRow('Type', _businessInfo.businessType),
                    _buildReviewRow('Address', _businessAddressController.text),
                    _buildReviewRow('RC Number', _rcNumberController.text),
                  ],
                ),
                _buildReviewSection(
                  'Directors',
                  [
                    _buildReviewRow('Director Name', _fullNameController.text),
                    _buildReviewRow('Ownership %', _ownershipController.text),
                  ],
                ),
                _buildReviewSection(
                  'Documents',
                  [
                    _buildReviewRow('CAC Certificate', '✓'),
                    _buildReviewRow('Utility Bill', '✓'),
                    _buildReviewRow('Director ID', '✓'),
                  ],
                ),
              ],
            ),
          ),
        ),
        _buildBottomCTA(
          label: 'Submit Application',
          onTap: _nextStep,
          footerContent: RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'By submitting you agree to ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF667085),
                  ),
                ),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1A6B35),
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(
                  text: ' and ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF667085),
                  ),
                ),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1A6B35),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewSection(String title, List<Widget> rows) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF101828),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Color(0xFF1A6B35),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1A6B35),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF667085),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF101828),
            ),
          ),
        ],
      ),
    );
  }

  // Screen 12: Auto-Check Processing
  Widget _buildAutoCheckProcessingScreen({Key? key}) {
    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1A6B35)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Verifying your details…',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF101828),
              ),
            ),
            const SizedBox(height: 32),
            _buildProcessingItem('✓', 'Identity confirmed'),
            const SizedBox(height: 12),
            _buildProcessingItem('✓', 'Business details validated'),
            const SizedBox(height: 12),
            _buildProcessingItem('⟳', 'Documents being reviewed…', isSpinning: true),
            const SizedBox(height: 32),
            const Text(
              'Please don\'t close the app',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF667085),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingItem(String icon, String label, {bool isSpinning = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isSpinning)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
            ),
          )
        else
          const Icon(
            Icons.check,
            size: 16,
            color: Color(0xFF1A6B35),
          ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF667085),
          ),
        ),
      ],
    );
  }

  // Screen 13: Auto-Check Fail
  Widget _buildAutoCheckFailScreen({Key? key}) {
    return Column(
      key: key,
      children: [
        _buildHeader(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFFEBEE),
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 32,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'We found an issue',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'One or more documents couldn\'t be verified',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF667085),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5F5),
                      borderRadius: BorderRadius.circular(8),
                      border: const Border(
                        left: BorderSide(color: Color(0xFFD32F2F), width: 3),
                      ),
                    ),
                    child: const Text(
                      'Your Director\'s ID could not be verified. Please upload a clearer, unobstructed copy.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildBottomCTA(
          label: 'Re-upload Document',
          onTap: _nextStep,
          footerContent: TextButton(
            onPressed: () {},
            child: const Text(
              'Contact RimaPay Support',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF667085),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Screen 14: Manual Review Pending
  Widget _buildManualReviewPendingScreen({Key? key}) {
    return Column(
      key: key,
      children: [
        _buildHeader(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.hourglass_empty,
                    size: 80,
                    color: Color(0xFF98A2B3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Application submitted!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A6B35),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Our compliance team is reviewing your business. This typically takes 1–3 business days.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF667085),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FAF4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.notifications_active_outlined,
                          size: 20,
                          color: Color(0xFF1A6B35),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'We\'ll notify you by SMS and email once your account is approved.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF667085),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildBottomCTA(label: 'Got it', onTap: _nextStep),
      ],
    );
  }

  // Screen 15: Rejection
  Widget _buildRejectionScreen({Key? key}) {
    return Column(
      key: key,
      children: [
        _buildHeader(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFFEBEE),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 32,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Application declined',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'We were unable to verify your business at this time.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF667085),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Reason: Director ID did not match BVN records.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildBottomCTA(
          label: 'Appeal this decision',
          onTap: _nextStep,
          footerContent: TextButton(
            onPressed: () {},
            child: const Text(
              'Contact Support',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF667085),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Screen 16: Approval
  Widget _buildApprovalScreen({Key? key}) {
    return Stack(
      key: key,
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
              Image.asset(
                'assets/images/AppIcon.png',
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
                              color: const Color(0xFF1A6B35).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.account_balance_wallet_outlined,
                                color: Color(0xFF1A6B35),
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
                        _businessInfo.phoneNumber.isNotEmpty
                            ? _businessInfo.phoneNumber
                            : '08XXXXXXXXX',
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
                            Icon(Icons.business_outlined,
                                size: 14, color: Color(0xFF1A6B35)),
                            SizedBox(width: 6),
                            Text(
                              'Your business account is now active',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF166534),
                                  fontWeight: FontWeight.w500),
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
}

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
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_places_autocomplete_text_field/google_places_autocomplete_text_field.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rimapay/Constants/En.dart';
import 'package:rimapay/Services/PersonAuthServices/OtpServices.dart';
import 'package:rimapay/Services/PersonAuthServices/PersonalSignUpService.dart';
import 'package:rimapay/Services/SessionServices/GetSessionId.dart';
import 'package:rimapay/Utils/Logics.dart';
import 'package:rimapay/core/Models/CountryStateLgaModel.dart';
import 'package:rimapay/core/Utils/En.dart';
import 'package:rimapay/core/services/GetPlaceDetailsService.dart';
import 'package:rimapay/core/theme/app_colors.dart';

enum BusinessAccountStep {
  phoneEntry,
  otpVerification,
  bvnVerification,
  selfieLiveness,
  setPinPassword,
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
  String _accountType = 'business';

  final List<String> _otp = List.filled(6, '');
  String _phoneDigits = '';

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _cameraActive = false;
  String? _capturedImage;
  String? _cameraError;
  bool _permissionDenied = false;
  bool _isResending = false;
  int _resendCountdown = 0;
  Timer? _resendTimer;
  String _password = '';
  String _confirmPassword = '';
  String _pin = '';
  String _confirmPin = '';
  bool _pinMatch = false;
  bool _passwordMatch = false;
  double _passwordStrength = 0;
  String _passwordStrengthLabel = '';

  bool _addNinToggle = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bvnController = TextEditingController();
  final TextEditingController _ninController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _businessNameController =
      TextEditingController();
  final TextEditingController _businessAddressController =
      TextEditingController();
  final TextEditingController _industryController =
      TextEditingController();
  final TextEditingController _rcNumberController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _ownershipController = TextEditingController();
  final TextEditingController _directorBvnController = TextEditingController();

  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _bvnFocusNode = FocusNode();
  final FocusNode _pinFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  CountryStateLgaModel? selectedState;
  Local? selectedLga;
  List<Local>? locals;

  CameraController? _cameraController;
  int _currentOtpIndex = 0;

  late AnimationController _pageAnimController;
  late AnimationController _processingAnimController;

  @override
  void initState() {
    super.initState();
    _pageAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _processingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _pageAnimController.dispose();
    _processingAnimController.dispose();
    _cameraController?.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildCurrentStep(),
        ),
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
      case BusinessAccountStep.setPinPassword:
        return _buildSetPinPasswordScreen(key: const ValueKey('pinPassword'));
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

  int get _currentStepIndex {
    return BusinessAccountStep.values.indexOf(_currentStep) + 1;
  }

  int get _totalSteps => 5;

  Widget _buildProgressBar(int step, int total) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                'Step $step of $total',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF667085),
                ),
              ),
              const Spacer(),
              Text(
                '$step of $total',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A6B35),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: step / total,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1A6B35)),
              minHeight: 4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF101828),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF667085),
            ),
          ),
        ],
      ],
    );
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
    List<TextInputFormatter>? inputFormatters,
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
          inputFormatters: inputFormatters,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required List<String> items,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel(label),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: TextFormField(
            controller: controller,
            readOnly: true,
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
              suffixIcon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF98A2B3),
              ),
            ),
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
          onPressed: isLoading ? null : onPressed,
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

  Widget _buildSecondaryButton(String text, {VoidCallback? onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: onPressed,
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

  Widget _buildTextLink(String text, {VoidCallback? onTap, Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: color ?? const Color(0xFF1A6B35),
          fontWeight: FontWeight.w600,
        ),
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
              style: TextStyle(
                fontSize: isGreen ? 13 : 14,
                color: const Color(0xFF667085),
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

  // Screen1: Phone Number Input

  Widget _buildPhoneEntryScreen({Key? key}) {
    return SingleChildScrollView(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            _buildHeader('Enter your phone number'),
            const SizedBox(height: 8),
            const Text(
              'We\'ll send a verification code to this number',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 32),
            _buildTextInput(
              controller: _phoneController,
              label: 'Phone Number',
              hint: 'Enter phone number',
              keyboardType: TextInputType.phone,
            ),
            const Spacer(),
            _buildPrimaryButton(
              'Continue',
              onPressed: () {
                if (_phoneController.text.length == 11) {
                  setState(() => _currentStep = BusinessAccountStep.otpVerification);
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Screen2: OTP Verification

  Widget _buildOtpVerificationScreen({Key? key}) {
    String maskedPhone = _phoneController.text.isNotEmpty
        ? '+234 ${_phoneController.text.substring(0, 3)} XXX ${_phoneController.text.substring(6)}'
        : '+234 XXX XXXX';

    return SingleChildScrollView(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Text(
              'Enter verification code',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF101828),
              ),
            ),
            const SizedBox(height: 12),
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
                bool isActive = _currentOtpIndex == index;
                bool isFilled = _otp[index].isNotEmpty;
                return Container(
                  width: 44,
                  height: 52,
                  margin: EdgeInsets.only(right: index < 5 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFF0FAF4) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isFilled || isActive
                          ? const Color(0xFF1A6B35)
                          : const Color(0xFFDDDDDD),
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
                  : GestureDetector(
                      onTap: () {
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
            const Spacer(),
            _buildPrimaryButton(
              'Verify',
              onPressed: () {
                if (_otp.every((digit) => digit.isNotEmpty)) {
                  setState(() => _currentStep = BusinessAccountStep.bvnVerification);
                }
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() => _currentStep = BusinessAccountStep.phoneEntry);
                },
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Screen3: BVN Verification

  Widget _buildBvnVerificationScreen({Key? key}) {
    return SingleChildScrollView(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            _buildProgressBar(1, 5),
            const SizedBox(height: 24),
            _buildHeader('Verify your identity'),
            const SizedBox(height: 8),
            const Text(
              'Your BVN helps us confirm who you are',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 24),
            _buildTextInput(
              controller: _bvnController,
              label: 'Bank Verification Number (BVN)',
              hint: 'Enter 11-digit BVN',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            const Text(
              'Dial 5650# on any network to get your BVN',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                setState(() => _addNinToggle = !_addNinToggle);
              },
              child: Container(
                width: double.infinity,
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Also add NIN',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF101828),
                          ),
                        ),
                        Text(
                          'National Identification Number',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF667085),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Switch(
                      value: _addNinToggle,
                      onChanged: (value) {
                        setState(() => _addNinToggle = value);
                      },
                      activeColor: const Color(0xFF1A6B35),
                    ),
                  ],
                ),
              ),
            ),
            if (_addNinToggle) ...[
              const SizedBox(height: 16),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _buildTextInput(
                  controller: _ninController,
                  label: 'National Identification Number (NIN)',
                  hint: 'Enter 11-digit NIN',
keyboardType: TextInputType.number,
            ),
              ),
            ],
            const SizedBox(height: 24),
            _buildInfoCallout(
              text: 'Your BVN is encrypted and never shared with third parties.',
              isGreen: true,
            ),
            const Spacer(),
            _buildPrimaryButton(
              'Continue',
              onPressed: () {
                if (_bvnController.text.length == 11) {
                  _businessInfo.bvn = _bvnController.text;
                  if (_addNinToggle) {
                    _businessInfo.nin = _ninController.text;
                  }
                  setState(() => _currentStep = BusinessAccountStep.selfieLiveness);
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Screen4: Selfie + Liveness Check

  Widget _buildSelfieLivenessScreen({Key? key}) {
    return SingleChildScrollView(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            _buildProgressBar(2, 5),
            const SizedBox(height: 24),
            _buildHeader('Take a selfie'),
            const SizedBox(height: 8),
            const Text(
              'Position your face in the oval and follow the prompts',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 24),
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
            const Spacer(),
            _buildPrimaryButton(
              'Start Camera',
              onPressed: () async {
                await _initCamera();
              },
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'RimaPay needs camera access to complete this step',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF667085),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
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

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'No cameras available');
        return;
      }
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _cameraActive = true);
      }
    } catch (e) {
      setState(() => _permissionDenied = true);
    }
  }

  // Screen5: Set PIN + Password

  Widget _buildSetPinPasswordScreen({Key? key}) {
    return SingleChildScrollView(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            _buildProgressBar(3, 5),
            const SizedBox(height: 24),
            _buildHeader('Secure your account'),
            const SizedBox(height: 24),
            const Text(
              'TRANSACTION PIN',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF667085),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildPinDots(_pin, (index) => _updatePin(index)),
            const SizedBox(height: 16),
            const Text(
              'Confirm PIN',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 8),
            _buildPinDots(_confirmPin, (index) => _updateConfirmPin(index)),
            if (_pinMatch) ...[
              const SizedBox(height: 8),
              const Text(
                'PINs match ✓',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1A6B35),
                ),
              ),
            ],
            _buildDividerWithLabel('AND'),
            const Text(
              'ACCOUNT PASSWORD',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF667085),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextInput(
              controller: _passwordController,
              label: 'Password',
              hint: 'Enter password',
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
            const SizedBox(height: 16),
            _buildTextInput(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              hint: 'Re-enter password',
              obscureText: !_showConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF98A2B3),
                ),
                onPressed: () {
                  setState(() => _showConfirmPassword = !_showConfirmPassword);
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: List.generate(4, (index) {
                      bool isFilled = _passwordStrength > (index * 0.25);
                      return Expanded(
                        child: Container(
                          height: 8,
                          margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                          decoration: BoxDecoration(
                            color: isFilled
                                ? _getPasswordStrengthColor(_passwordStrength)
                                : const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _passwordStrengthLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getPasswordStrengthColor(_passwordStrength),
                  ),
                ),
              ],
            ),
            const Spacer(),
            _buildPrimaryButton(
              'Continue',
              onPressed: () {
                if (_pinMatch && _passwordMatch) {
                  _businessInfo.pin = _pin;
                  _businessInfo.password = _password;
                  setState(() => _currentStep = BusinessAccountStep.businessType);
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPinDots(String pinString, Function(int) onUpdate) {
    List<String> pinList = pinString.split('');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        bool isFilled = index < pinList.length && pinList[index].isNotEmpty;
        return GestureDetector(
          onTap: () => onUpdate(index),
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

  void _updatePin(int index) {
    // Simple PIN update - would need numpad in real implementation
  }

  void _updateConfirmPin(int index) {
    // Simple PIN update - would need numpad in real implementation
  }

  // Screen6: Business Type

  Widget _buildBusinessTypeScreen({Key? key}) {
    return SingleChildScrollView(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            _buildProgressBar(4, 5),
            const SizedBox(height: 24),
            _buildHeader('What type of business?'),
            const SizedBox(height: 8),
            const Text(
              'This helps us set the right account limits',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 24),
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
            const Spacer(),
            _buildPrimaryButton(
              'Continue',
              onPressed: () {
                if (_businessInfo.businessType.isNotEmpty) {
                  setState(() => _currentStep = BusinessAccountStep.businessDetails);
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
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

  // Screen7: Business Details

  Widget _buildBusinessDetailsScreen({Key? key}) {
    return SingleChildScrollView(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            _buildProgressBar(4, 5),
            const SizedBox(height: 8),
            const Text(
              'Business Info',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 16),
            _buildHeader('About your business'),
            const SizedBox(height: 24),
            _buildTextInput(
              controller: _businessNameController,
              label: 'Business Name',
              hint: 'Enter business name',
            ),
            const SizedBox(height: 16),
            _buildDropdownField(
              controller: _industryController,
              label: 'Industry',
              hint: 'Select industry',
              items: const ['Retail', 'Tech', 'Food & Beverage', 'Logistics', 'Fashion', 'Agriculture', 'Other'],
            ),
            const SizedBox(height: 16),
            _buildTextInput(
              controller: _businessAddressController,
              label: 'Business Address',
              hint: 'Enter business address',
            ),
            const SizedBox(height: 16),
            _buildDropdownField(
              controller: TextEditingController(),
              label: 'State',
              hint: 'Select state',
              items: const ['Lagos', 'Abuja', 'Port Harcourt', 'Other'],
            ),
            const SizedBox(height: 16),
            _buildDropdownField(
              controller: TextEditingController(),
              label: 'LGA',
              hint: 'Select LGA',
              items: const [' Ikeja', 'Lagos Island', 'Victoria Island', 'Other'],
            ),
            const Spacer(),
            _buildPrimaryButton(
              'Continue',
              onPressed: () {
                _businessInfo.businessName = _businessNameController.text;
                setState(() => _currentStep = BusinessAccountStep.cacDetails);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Screen8: CAC Details

  Widget _buildCacDetailsScreen({Key? key}) {
    return SingleChildScrollView(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            _buildProgressBar(4, 5),
            const SizedBox(height: 24),
            _buildHeader('CAC Registration'),
            const SizedBox(height: 8),
            const Text(
              'Enter your Corporate Affairs Commission details',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 24),
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
              child: _buildTextLink('Skip this step', onTap: () {
                setState(() => _currentStep = BusinessAccountStep.directorInfo);
              }),
            ),
            const Spacer(),
            _buildPrimaryButton(
              'Continue',
              onPressed: () {
                _businessInfo.rcNumber = _rcNumberController.text;
                setState(() => _currentStep = BusinessAccountStep.directorInfo);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Screen9: Director Info

  Widget _buildDirectorInfoScreen({Key? key}) {
    return SingleChildScrollView(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            _buildProgressBar(4, 5),
            const SizedBox(height: 24),
            _buildHeader('Director & ownership'),
            const SizedBox(height: 8),
            const Text(
              'Tell us who owns and controls the business',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 24),
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
              suffixIcon: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Text(
                  '%',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF667085),
                  ),
                ),
              ),
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
            const Spacer(),
            _buildPrimaryButton(
              'Continue',
              onPressed: () {
                setState(() => _currentStep = BusinessAccountStep.documentUpload);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Screen10: Document Upload

  Widget _buildDocumentUploadScreen({Key? key}) {
    List<UploadedDocument> documents = [
      UploadedDocument(title: 'CAC Certificate or Proof of Registration'),
      UploadedDocument(title: 'Utility Bill (business address proof)'),
      UploadedDocument(title: 'Director\'s ID — Passport or NIN Slip'),
    ];

    return SingleChildScrollView(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            _buildProgressBar(5, 5),
            const SizedBox(height: 24),
            _buildHeader('Upload your documents'),
            const SizedBox(height: 8),
            const Text(
              'JPG, PNG or PDF — max 5MB each',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 24),
            ...documents.map((doc) => _buildDocumentCard(doc)),
            if (_businessInfo.businessType == 'sole_trader') ...[
              const SizedBox(height: 16),
              _buildInfoCallout(
                text: 'As a sole trader, your BVN + NIN may be sufficient. CAC upload is optional.',
                isGreen: true,
              ),
            ],
            const Spacer(),
            _buildPrimaryButton(
              'Submit Documents',
              onPressed: () {
                setState(() => _currentStep = BusinessAccountStep.reviewSubmit);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
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

  // Screen11: Review & Submit

  Widget _buildReviewSubmitScreen({Key? key}) {
    return SingleChildScrollView(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            _buildHeader('Review your application'),
            const SizedBox(height: 8),
            const Text(
              'Confirm everything before submitting',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 24),
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
            const Spacer(),
            _buildPrimaryButton(
              'Submit Application',
              onPressed: () {
                setState(() => _currentStep = BusinessAccountStep.autoCheckProcessing);
                _processingAnimController.forward();
                Future.delayed(const Duration(seconds: 4), () {
                  if (mounted) {
                    setState(() => _currentStep = BusinessAccountStep.manualReviewPending);
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            RichText(
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
                    text: 'RimaPay\'s Terms of Service',
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
            const SizedBox(height: 24),
          ],
        ),
      ),
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

  // Screen12: Auto-Check Processing

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
          Icon(
            Icons.check,
            size: 16,
            color: const Color(0xFF1A6B35),
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

  // Screen13: Auto-Check Fail

  Widget _buildAutoCheckFailScreen({Key? key}) {
    return Center(
      key: key,
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
            const SizedBox(height: 32),
            _buildPrimaryButton(
              'Re-upload Document',
              onPressed: () {
                setState(() => _currentStep = BusinessAccountStep.documentUpload);
              },
            ),
            const SizedBox(height: 16),
            _buildTextLink(
              'Contact RimaPay Support',
              color: const Color(0xFF667085),
            ),
          ],
        ),
      ),
    );
  }

  // Screen14: Manual Review Pending

  Widget _buildManualReviewPendingScreen({Key? key}) {
    return Center(
      key: key,
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
            const SizedBox(height: 32),
            _buildSecondaryButton('Got it', onPressed: () {
              context.go('/home');
            }),
          ],
        ),
      ),
    );
  }

  // Screen15: Rejection

  Widget _buildRejectionScreen({Key? key}) {
    return Center(
      key: key,
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
            const SizedBox(height: 32),
            _buildPrimaryButton(
              'Appeal this decision',
              onPressed: () {},
            ),
            const SizedBox(height: 16),
            _buildTextLink(
              'Contact Support',
              color: const Color(0xFF667085),
            ),
          ],
        ),
      ),
    );
  }

  // Screen16: Approval

  Widget _buildApprovalScreen({Key? key}) {
    return Container(
      key: key,
      color: const Color(0xFF1A6B35),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 40,
                    color: Color(0xFF1A6B35),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "You're approved! 🎉",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your RimaPay Business Account is now live and ready to use.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        '9012 345 678',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A6B35),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.copy,
                        size: 18,
                        color: Color(0xFF1A6B35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      context.go('/home');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1A6B35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Go to Dashboard',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextLink(
                  'Skip for now',
                  color: Colors.white,
                  onTap: () {
                    context.go('/home');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
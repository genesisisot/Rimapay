import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/onboarding_dtos.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _phoneController = TextEditingController();
  final _identityController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  IdentityDocumentType _documentType = IdentityDocumentType.bvn;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _showPin = false;
  bool _showConfirmPin = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _identityController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    ref.listen<OnboardingState>(onboardingProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        notifier.clearError();
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(state),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: _buildStepContent(state, notifier),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(OnboardingState state) {
    final showBack = state.currentStep != OnboardingStep.initialEntry &&
        state.currentStep != OnboardingStep.completed;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: [
          if (showBack)
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Color(0xFF374151), size: 17),
              ),
            ),
          const Spacer(),
          if (state.currentStep != OnboardingStep.completed)
            TextButton(
              onPressed: () {
                ref.read(onboardingProvider.notifier).reset();
                context.pop();
              },
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Color(0xFF667085),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepContent(
      OnboardingState state, OnboardingNotifier notifier) {
    switch (state.currentStep) {
      case OnboardingStep.initialEntry:
        return _buildInitiateStep(state, notifier);
      case OnboardingStep.otpVerification:
        return _buildOtpStep(state, notifier);
      case OnboardingStep.identitySubmission:
        return _buildSubmitIdentityStep(state, notifier);
      case OnboardingStep.facialValidation:
        return _buildFacialStep(state, notifier);
      case OnboardingStep.createPassword:
        return _buildPasswordStep(state, notifier);
      case OnboardingStep.createPin:
        return _buildPinStep(state, notifier);
      case OnboardingStep.completed:
        return _buildSuccessStep(state);
    }
  }

  // ── Step 1: Initiate ─────────────────────────────────────────────────────

  Widget _buildInitiateStep(
      OnboardingState state, OnboardingNotifier notifier) {
    final canSubmit = _phoneController.text.length >= 10 &&
        _identityController.text.length == 11 &&
        !state.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Create Your Account',
          style: TextStyle(
            color: Color(0xFF101828),
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your details to get started',
          style: TextStyle(
            color: Color(0xFF667085),
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 32),
        _buildSectionLabel('Phone Number'),
        const SizedBox(height: 6),
        _buildPhoneField(),
        const SizedBox(height: 20),
        _buildSectionLabel('Identification Type'),
        const SizedBox(height: 6),
        _buildDocTypeSelector(),
        const SizedBox(height: 20),
        _buildSectionLabel(
            '${_documentType == IdentityDocumentType.bvn ? 'BVN' : 'NIN'} Number'),
        const SizedBox(height: 6),
        _buildIdentityField(),
        const SizedBox(height: 20),
        _buildSectionLabel('Email (optional)'),
        const SizedBox(height: 6),
        _buildEmailField(),
        const SizedBox(height: 36),
        _buildPrimaryButton(
          label: 'Continue',
          loading: state.isLoading,
          enabled: canSubmit,
          onTap: () => notifier.initiate(
            phoneNumber: '+234${_phoneController.text}',
            identityNumber: _identityController.text,
            documentType: _documentType,
            email: _emailController.text.isEmpty
                ? null
                : _emailController.text,
          ),
        ),
      ],
    );
  }

  // ── Step 2: OTP ──────────────────────────────────────────────────────────

  Widget _buildOtpStep(OnboardingState state, OnboardingNotifier notifier) {
    final canSubmit = _otpController.text.length >= 4 && !state.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Verify Your Phone',
          style: TextStyle(
            color: Color(0xFF101828),
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          state.maskedDestination != null
              ? 'Enter the code sent to ${state.maskedDestination}'
              : 'Enter the OTP sent to your phone',
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 32),
        _buildSectionLabel('OTP Code'),
        const SizedBox(height: 6),
        _buildOtpField(),
        const SizedBox(height: 12),
        if (state.otpExpiresAt != null)
          Text(
            'Expires at ${_formatTime(state.otpExpiresAt!)}',
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 13,
            ),
          ),
        const SizedBox(height: 36),
        _buildPrimaryButton(
          label: 'Verify',
          loading: state.isLoading,
          enabled: canSubmit,
          onTap: () => notifier.verifyOtp(_otpController.text),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed:
                state.isLoading ? null : () => notifier.resendOtp(),
            child: const Text(
              'Resend Code',
              style: TextStyle(
                color: Color(0xFF166C46),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 3: Submit Identity ──────────────────────────────────────────────

  Widget _buildSubmitIdentityStep(
      OnboardingState state, OnboardingNotifier notifier) {
    final canSubmit = _identityController.text.length == 11 && !state.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        if (state.validatedFirstName != null)
          Text(
            'Welcome, ${state.validatedFirstName}!',
            style: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          )
        else
          const Text(
            'Confirm Your Identity',
            style: TextStyle(
              color: Color(0xFF101828),
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        const SizedBox(height: 8),
        const Text(
          'Please re-enter your details to confirm',
          style: TextStyle(
            color: Color(0xFF667085),
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 32),
        _buildSectionLabel('Identification Type'),
        const SizedBox(height: 6),
        _buildDocTypeSelector(),
        const SizedBox(height: 20),
        _buildSectionLabel(
            '${_documentType == IdentityDocumentType.bvn ? 'BVN' : 'NIN'} Number'),
        const SizedBox(height: 6),
        _buildIdentityField(),
        const SizedBox(height: 36),
        _buildPrimaryButton(
          label: 'Confirm',
          loading: state.isLoading,
          enabled: canSubmit,
          onTap: () => notifier.submitIdentity(
            identityNumber: _identityController.text,
            documentType: _documentType,
          ),
        ),
      ],
    );
  }

  // ── Step 4: Facial Validation ────────────────────────────────────────────

  Widget _buildFacialStep(
      OnboardingState state, OnboardingNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Face Verification',
          style: TextStyle(
            color: Color(0xFF101828),
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Take a selfie to verify your identity',
          style: TextStyle(
            color: Color(0xFF667085),
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 48),
        Center(
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF3F4F6),
              border: Border.all(
                color: const Color(0xFFD1D5DB),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ),
        const SizedBox(height: 48),
        _buildPrimaryButton(
          label: 'Capture Selfie',
          loading: state.isLoading,
          enabled: !state.isLoading,
          onTap: () {
            // TODO: Integrate camera for selfie capture
            // For now, simulate with placeholder base64
            notifier.validateFace(
              capturedImageBase64: 'placeholder',
              livenessCheckPassed: true,
            );
          },
        ),
        if (state.facialMatch)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: const Center(
              child: Text(
                'Face verified successfully!',
                style: TextStyle(
                  color: Color(0xFF166C46),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Step 5: Create Password ──────────────────────────────────────────────

  Widget _buildPasswordStep(
      OnboardingState state, OnboardingNotifier notifier) {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final canSubmit = password.length >= 8 &&
        confirm == password &&
        !state.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Create Password',
          style: TextStyle(
            color: Color(0xFF101828),
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Must be at least 8 characters with upper, lower, number & special char',
          style: TextStyle(
            color: Color(0xFF667085),
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 32),
        _buildPasswordField(
          label: 'Password',
          controller: _passwordController,
          obscure: !_showPassword,
          onToggle: () => setState(() => _showPassword = !_showPassword),
        ),
        const SizedBox(height: 20),
        _buildPasswordField(
          label: 'Confirm Password',
          controller: _confirmPasswordController,
          obscure: !_showConfirmPassword,
          onToggle: () =>
              setState(() => _showConfirmPassword = !_showConfirmPassword),
        ),
        const SizedBox(height: 36),
        _buildPrimaryButton(
          label: 'Continue',
          loading: state.isLoading,
          enabled: canSubmit,
          onTap: () => notifier.createPassword(
            password: password,
            confirmPassword: confirm,
          ),
        ),
      ],
    );
  }

  // ── Step 6: Create PIN ───────────────────────────────────────────────────

  Widget _buildPinStep(OnboardingState state, OnboardingNotifier notifier) {
    final pin = _pinController.text;
    final confirm = _confirmPinController.text;
    final canSubmit = pin.length >= 4 &&
        confirm == pin &&
        !state.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Create Transaction PIN',
          style: TextStyle(
            color: Color(0xFF101828),
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Set a 4-digit PIN for transactions',
          style: TextStyle(
            color: Color(0xFF667085),
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 32),
        _buildPinField(
          label: 'PIN',
          controller: _pinController,
          obscure: !_showPin,
          onToggle: () => setState(() => _showPin = !_showPin),
        ),
        const SizedBox(height: 20),
        _buildPinField(
          label: 'Confirm PIN',
          controller: _confirmPinController,
          obscure: !_showConfirmPin,
          onToggle: () =>
              setState(() => _showConfirmPin = !_showConfirmPin),
        ),
        const SizedBox(height: 36),
        _buildPrimaryButton(
          label: 'Finish',
          loading: state.isLoading,
          enabled: canSubmit,
          onTap: () => notifier.createPin(
            pin: pin,
            confirmPin: confirm,
          ),
        ),
      ],
    );
  }

  // ── Success ──────────────────────────────────────────────────────────────

  Widget _buildSuccessStep(OnboardingState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 80),
        const Icon(
          Icons.check_circle_outline,
          size: 96,
          color: Color(0xFF166C46),
        ),
        const SizedBox(height: 24),
        const Text(
          'Account Created!',
          style: TextStyle(
            color: Color(0xFF101828),
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your account has been set up successfully',
          style: TextStyle(
            color: Color(0xFF667085),
            fontSize: 15,
          ),
        ),
        if (state.accountNumber != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Account Number',
                  style: TextStyle(
                    color: Color(0xFF667085),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.accountNumber!,
                  style: const TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 48),
        _buildPrimaryButton(
          label: 'Go to Home',
          loading: false,
          enabled: true,
          onTap: () => context.goNamed('home'),
        ),
      ],
    );
  }

  // ── Shared Widgets ──────────────────────────────────────────────────────

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF374151),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildPhoneField() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Text(
            '+234',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 1,
            height: 18,
            color: const Color(0xFFD1D5DB),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: '801 234 5678',
                hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 14, color: Color(0xFF101828)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocTypeSelector() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.badge_outlined, size: 18, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<IdentityDocumentType>(
                value: _documentType,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: Color(0xFF9CA3AF)),
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF101828)),
                items: const [
                  DropdownMenuItem(
                    value: IdentityDocumentType.bvn,
                    child: Text('BVN'),
                  ),
                  DropdownMenuItem(
                    value: IdentityDocumentType.nin,
                    child: Text('NIN'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _documentType = v);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityField() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: _identityController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(11),
        ],
        decoration: InputDecoration(
          hintText: _documentType == IdentityDocumentType.bvn
              ? '11-digit BVN'
              : '11-digit NIN',
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        style: const TextStyle(fontSize: 14, color: Color(0xFF101828)),
      ),
    );
  }

  Widget _buildEmailField() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          hintText: 'user@example.com',
          hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 14),
        ),
        style: const TextStyle(fontSize: 14, color: Color(0xFF101828)),
      ),
    );
  }

  Widget _buildOtpField() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        decoration: const InputDecoration(
          hintText: 'Enter OTP code',
          hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 14),
        ),
        style: const TextStyle(fontSize: 18, color: Color(0xFF101828),
            letterSpacing: 4),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF374151),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            decoration: InputDecoration(
              hintText: label == 'Password' ? '••••••••' : 'Re-enter password',
              hintStyle:
                  const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              suffixIcon: GestureDetector(
                onTap: onToggle,
                child: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ),
            style: const TextStyle(fontSize: 14, color: Color(0xFF101828)),
          ),
        ),
      ],
    );
  }

  Widget _buildPinField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF374151),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            decoration: InputDecoration(
              hintText: label == 'PIN' ? '••••' : 'Re-enter PIN',
              hintStyle:
                  const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              suffixIcon: GestureDetector(
                onTap: onToggle,
                child: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ),
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF101828),
              letterSpacing: 4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required bool loading,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFF166C46), Color(0xFF166C46)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight)
              : null,
          color: enabled ? null : const Color(0xFFE4E7EC),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  color: enabled ? Colors.white : const Color(0xFF98A2B3),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

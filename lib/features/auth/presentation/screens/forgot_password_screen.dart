import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/providers/auth_provider.dart';

/// Forgot / reset password flow backed by the RIMA Identity API:
///  step 0 → POST /api/auth/forgot-password (email/phone)
///  step 1 → face verification (selfie capture via image_picker)
///  step 2 → POST /api/auth/reset-password  (email, token, newPassword)
///  step 3 → done
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const _green = Color(0xFF166C46);

  int _step = 0;
  bool _isPhoneIdentifier = false;
  final _emailCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPassword = false;

  final _imagePicker = ImagePicker();
  Uint8List? _capturedImageBytes;
  bool _faceVerified = false;
  bool _isVerifying = false;

  bool _isPhone(String s) =>
      s.isNotEmpty && s.replaceAll(RegExp(r'[+\s]'), '').characters.every((c) => c == '0' || int.tryParse(c) != null);

  /// Normalises a Nigerian phone to local format (0…).
  /// Whether the user types 080…, 23480…, or +23480… the result is always 080… .
  String _normalisePhone(String raw) {
    final d = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (d.startsWith('0')) return d;
    if (d.startsWith('234')) return '0${d.substring(3).replaceFirst(RegExp(r'^0+'), '')}';
    return '0$d';
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : _green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _sendIdentifier() async {
    final raw = _emailCtrl.text.trim();
    if (raw.isEmpty) {
      _snack('Please enter your email or phone number', error: true);
      return;
    }
    final auth = context.read<AuthProvider>();
    final message = _isPhone(raw)
        ? await auth.forgotPassword(phoneNumber: _normalisePhone(raw))
        : await auth.forgotPassword(email: raw);
    if (!mounted) return;
    if (message != null) {
      _snack(message);
      setState(() {
        _isPhoneIdentifier = _isPhone(raw);
        _capturedImageBytes = null;
        _faceVerified = false;
        _step = 1;
      });
    } else {
      _snack(auth.error ?? 'Could not send reset code.', error: true);
    }
  }

  Future<void> _captureSelfie() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      maxWidth: 640,
      maxHeight: 640,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.front,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    setState(() => _capturedImageBytes = bytes);
  }

  Future<void> _verifyFace() async {
    if (_capturedImageBytes == null) {
      _snack('Please capture a selfie first', error: true);
      return;
    }
    setState(() => _isVerifying = true);
    try {
      // Brief delay so the user sees the verifying animation
      await Future.delayed(const Duration(seconds: 2));
      final auth = context.read<AuthProvider>();
      final phone = _normalisePhone(_emailCtrl.text.trim());
      final ok = await auth.forgotPasswordFaceVerify(
        capturedImageBase64: base64Encode(_capturedImageBytes!),
        phoneNumber: phone,
      );
      if (!mounted) return;
      setState(() => _isVerifying = false);
      if (ok) {
        setState(() => _faceVerified = true);
        _snack('Face verified! Enter the reset code sent to your ${_isPhoneIdentifier ? 'phone' : 'email'}');
        setState(() => _step = 2);
      } else {
        _snack(auth.error ?? 'Face verification failed. Try again.', error: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isVerifying = false);
      _snack('Something went wrong. Please try again.', error: true);
    }
  }

  Future<void> _resetPassword() async {
    final token = _tokenCtrl.text.trim();
    final pwd = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;
    if (token.isEmpty) {
      _snack(_isPhoneIdentifier
          ? 'Enter the reset code from your phone'
          : 'Enter the reset code from your email', error: true);
      return;
    }
    if (pwd.length < 6) {
      _snack('Password must be at least 6 characters', error: true);
      return;
    }
    if (pwd != confirm) {
      _snack('Passwords do not match', error: true);
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.resetPassword(
      email: _emailCtrl.text.trim(),
      token: token,
      newPassword: pwd,
      confirmPassword: confirm,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _step = 3);
    } else {
      _snack(auth.error ?? 'Could not reset password.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
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
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: _step == 3
                    ? _buildDone()
                    : _step == 1
                        ? _buildFaceVerify()
                        : _buildForm(isLoading),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(bool isLoading) {
    final requesting = _step == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          requesting ? 'Reset your\npassword' : 'Enter reset\ncode',
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 32,
              height: 1.15,
              fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Text(
          requesting
              ? "Enter the email or phone number on your account and we'll send a reset code."
              : _isPhoneIdentifier
                  ? 'Enter the code sent to your phone and choose a new password.'
                  : 'Enter the code sent to ${_emailCtrl.text.trim()} and choose a new password.',
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 32),
        if (requesting) ...[
          _field(
            label: 'Email or Phone',
            controller: _emailCtrl,
            hint: 'you@example.com or 08012345678',
            keyboardType: TextInputType.text,
          ),
        ] else ...[
          _field(
            label: 'Reset Code',
            controller: _tokenCtrl,
            hint: _isPhoneIdentifier
                ? 'Paste the code sent to your phone'
                : 'Paste the code from your email',
          ),
          const SizedBox(height: 16),
          _field(
            label: 'New Password',
            controller: _passwordCtrl,
            hint: 'Min 6 characters',
            obscure: !_showPassword,
            suffix: GestureDetector(
              onTap: () => setState(() => _showPassword = !_showPassword),
              child: Icon(
                _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _field(
            label: 'Confirm Password',
            controller: _confirmCtrl,
            hint: 'Re-enter password',
            obscure: !_showPassword,
          ),
        ],
        const SizedBox(height: 28),
        _primaryButton(
          label: requesting ? 'Send Reset Code' : 'Reset Password',
          loading: isLoading,
          onTap: requesting ? _sendIdentifier : _resetPassword,
        ),
      ],
    );
  }

  Widget _buildFaceVerify() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        if (_isVerifying)
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(_green),
                  ),
                ),
                Icon(Icons.face_retouching_natural,
                    size: 32, color: _green),
              ],
            ),
          )
        else
          Icon(Icons.face_retouching_natural, size: 64, color: _green),
        const SizedBox(height: 16),
        Text(
          _isVerifying
              ? 'Verifying your identity…'
              : _faceVerified
                  ? 'Face Verified!'
                  : 'Face Verification',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: 8),
        Text(
          _isVerifying
              ? 'Please wait while we verify your face.'
              : 'Password reset initiated.\nCapture a selfie to verify your identity.',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              height: 1.5),
        ),
        const SizedBox(height: 24),
        if (_isVerifying)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AnimatedOpacity(
              opacity: 0.6,
              duration: const Duration(milliseconds: 500),
              child: _capturedImageBytes != null
                  ? Image.memory(
                      _capturedImageBytes!,
                      width: 240,
                      height: 240,
                      fit: BoxFit.cover,
                    )
                  : const SizedBox.shrink(),
            ),
          )
        else if (_capturedImageBytes != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              _capturedImageBytes!,
              width: 240,
              height: 240,
              fit: BoxFit.cover,
            ),
          )
        else
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt_outlined,
                    size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                const SizedBox(height: 8),
                Text('No photo yet',
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4))),
              ],
            ),
          ),
        const SizedBox(height: 24),
        if (_isVerifying)
          const SizedBox.shrink()
        else if (_capturedImageBytes == null)
          _primaryButton(
            label: 'Capture Selfie',
            loading: _isVerifying,
            onTap: _captureSelfie,
          )
        else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _outlineButton(
                label: 'Retake',
                onTap: () => setState(() => _capturedImageBytes = null),
              ),
              const SizedBox(width: 16),
              _primaryButton(
                label: 'Verify Face',
                loading: _isVerifying,
                onTap: _verifyFace,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDone() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.check_circle, color: _green, size: 72),
        const SizedBox(height: 20),
        Text('Password reset!',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 8),
        Text(
          'Your password has been updated.\nSign in with your new password.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), height: 1.5),
        ),
        const SizedBox(height: 28),
        _primaryButton(
          label: 'Back to Sign In',
          loading: false,
          onTap: () => context.pop(),
        ),
      ],
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          onChanged: (_) => setState(() {}),
          style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 14),
            suffixIcon: suffix == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: 12), child: suffix),
            suffixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
              borderSide: const BorderSide(color: _green, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _outlineButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _green, width: 1.5),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _green)),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: _green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              : Text(label,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
        ),
      ),
    );
  }
}

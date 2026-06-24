import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';

/// Forgot / reset password flow backed by the RIMA Identity API:
///  step 0 → POST /api/auth/forgot-password (email/phone)
///  step 1 → POST /api/auth/verify-face-reset (face verification)
///  step 2 → POST /api/auth/reset-password  (token, newPassword)
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
  String? _resetSessionToken;

  // step 0 fields
  final _emailCtrl = TextEditingController();

  // step 2 fields
  final _tokenCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPassword = false;

  // camera (step 1)
  CameraController? _cameraController;
  bool _cameraActive = false;
  String? _cameraError;
  bool _verifyingFace = false;

  // resend
  bool _isResending = false;
  int _resendCountdown = 0;
  Timer? _resendTimer;

  bool _isPhone(String s) =>
      s.isNotEmpty && s.replaceAll(RegExp(r'[+\s]'), '').characters.every((c) => c == '0' || int.tryParse(c) != null);

  String _normalisePhone(String raw) {
    final d = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (d.startsWith('234')) return d.replaceFirst(RegExp(r'^2340+'), '234');
    if (d.startsWith('0')) return '234${d.substring(1)}';
    return '234$d';
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _cameraController?.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : _green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Step 0: Send identifier ──────────────────────────────────────────────

  Future<void> _sendIdentifier() async {
    final raw = _emailCtrl.text.trim();
    if (raw.isEmpty) {
      _snack('Please enter your email or phone number', error: true);
      return;
    }
    final auth = context.read<AuthProvider>();
    final token = _isPhone(raw)
        ? await auth.forgotPassword(phoneNumber: _normalisePhone(raw))
        : await auth.forgotPassword(email: raw);
    if (!mounted) return;
    if (token != null) {
      _resetSessionToken = token;
      setState(() {
        _isPhoneIdentifier = _isPhone(raw);
        _step = 1;
      });
    } else {
      _snack(auth.error ?? 'Could not send reset code.', error: true);
    }
  }

  // ── Step 1: Face verification ────────────────────────────────────────────

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraError = 'No camera found');
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
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

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
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

      final auth = context.read<AuthProvider>();
      final newToken = await auth.verifyFaceReset(
        sessionToken: _resetSessionToken ?? '',
        faceImage: base64Image,
      );
      if (!mounted) return;
      setState(() => _verifyingFace = false);
      if (newToken != null) {
        _snack('Face verified. Enter the reset code sent to your phone.');
        setState(() => _step = 2);
      } else {
        _snack(auth.error ?? 'Face verification failed. Try again.', error: true);
        setState(() {
          _cameraActive = false;
          _cameraError = null;
        });
      }
    } catch (e) {
      setState(() {
        _cameraError = 'Failed to capture photo: $e';
        _verifyingFace = false;
      });
    }
  }

  // ── Step 2: Reset password ───────────────────────────────────────────────

  Future<void> _resetPassword() async {
    final token = _tokenCtrl.text.trim();
    final pwd = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;
    if (token.isEmpty) {
      _snack('Enter the reset code from your ${_isPhoneIdentifier ? "phone" : "email"}', error: true);
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
      sessionToken: _resetSessionToken ?? '',
      resetCode: token,
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

  // ── Resend reset code ─────────────────────────────────────────────

  Future<void> _handleResendResetCode() async {
    if (_resendCountdown > 0 || _isResending) return;
    setState(() => _isResending = true);
    final raw = _emailCtrl.text.trim();
    final auth = context.read<AuthProvider>();
    final newToken = await auth.forgotPassword(
      phoneNumber: _isPhoneIdentifier ? _normalisePhone(raw) : null,
      email: _isPhoneIdentifier ? null : raw,
    );
    if (!mounted) return;
    setState(() => _isResending = false);
    if (newToken != null) {
      _resetSessionToken = newToken;
    }
    _snack('Reset code resent to your ${_isPhoneIdentifier ? "phone" : "email"}.');
    _startResendCountdown();
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

  // ── Build ────────────────────────────────────────────────────────────────

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
              child: _step == 0
                  ? _buildStep0(isLoading)
                  : _step == 1
                      ? _buildStep1()
                      : _step == 3
                          ? _buildDone()
                          : _buildStep2(isLoading),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 0 UI: Enter email/phone ─────────────────────────────────────────

  Widget _buildStep0(bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reset your\npassword',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 32,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Enter the email or phone number on your account and we'll send a reset code.",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          _field(
            label: 'Email or Phone',
            controller: _emailCtrl,
            hint: 'you@example.com or 08012345678',
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 28),
          _primaryButton(
            label: 'Send Reset Code',
            loading: isLoading,
            onTap: _sendIdentifier,
          ),
        ],
      ),
    );
  }

  // ── Step 1 UI: Face verification ─────────────────────────────────────────

  Widget _buildStep1() {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_cameraActive && _cameraController != null && _cameraController!.value.isInitialized)
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
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
                            child: const Icon(Icons.remove_red_eye_outlined, color: Color(0xFF16A34A), size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text('Face Verification',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Position your face in the oval',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                          ),
                          const SizedBox(height: 4),
                          Text('Ensure good lighting',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _cameraActive ? _capturePhoto : _requestCameraPermission,
                            child: Container(
                              width: double.infinity,
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: AppColors.goldGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  _cameraActive ? 'Take Selfie' : 'Start Camera',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
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
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                textAlign: TextAlign.center),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (_verifyingFace) _buildFaceVerifyingOverlay(),
      ],
    );
  }

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
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
              ),
              SizedBox(height: 8),
              Text(
                'Hold on a moment \u2014 this can take a few seconds.\nPlease don\'t close or refresh the page.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 2 UI: Enter reset code + new password ───────────────────────────

  Widget _buildStep2(bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter reset\ncode',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 32,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isPhoneIdentifier
                ? 'Enter the code sent to your phone and choose a new password.'
                : 'Enter the code sent to ${_emailCtrl.text.trim()} and choose a new password.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          _field(
            label: 'Reset Code',
            controller: _tokenCtrl,
            hint: _isPhoneIdentifier ? 'Paste the code sent to your phone' : 'Paste the code from your email',
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Didn't receive code? ",
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              GestureDetector(
                onTap: (_resendCountdown > 0 || _isResending)
                    ? null
                    : _handleResendResetCode,
                child: _isResending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(_green)))
                    : Text(
                        _resendCountdown > 0
                            ? 'Resend in ${_resendCountdown}s'
                            : 'Resend',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _resendCountdown > 0
                              ? const Color(0xFF6B7280)
                              : _green,
                        ),
                      ),
              ),
            ],
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
                _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
          const SizedBox(height: 28),
          _primaryButton(
            label: 'Reset Password',
            loading: isLoading,
            onTap: _resetPassword,
          ),
        ],
      ),
    );
  }

  // ── Step 3 UI: Done ──────────────────────────────────────────────────────

  Widget _buildDone() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.check_circle, color: _green, size: 72),
          const SizedBox(height: 20),
          Text(
            'Password reset!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
          ),
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
      ),
    );
  }

  // ── Shared widgets ───────────────────────────────────────────────────────

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
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
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
                : Padding(padding: const EdgeInsets.only(right: 12), child: suffix),
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
                      strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              : Text(label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }
}

// ─── Oval overlay painter ────────────────────────────────────────────────────

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

// ─── Face scan loader ───────────────────────────────────────────────────────

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
                child: const Icon(Icons.face_retouching_natural, color: green, size: 30),
              ),
            ],
          );
        },
      ),
    );
  }
}
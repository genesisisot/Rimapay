import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/api_config.dart';
import '../../data/pin_api_service.dart';
import '../../data/pin_dtos.dart';

/// Two-step transaction-PIN reset backed by the RIMA Identity API:
///  step 0 → choose new PIN, POST /api/security/pin/reset/initiate (sends OTP)
///  step 1 → enter OTP, POST /api/security/pin/reset/validate
///
/// Mirrors [ChangePinScreen]; reset is for users who have forgotten their PIN,
/// so there is no "current PIN" — identity is proven via the OTP.
class ResetPinScreen extends StatefulWidget {
  const ResetPinScreen({super.key});

  @override
  State<ResetPinScreen> createState() => _ResetPinScreenState();
}

class _ResetPinScreenState extends State<ResetPinScreen> {
  static const _green = Color(0xFF166C46);

  final _pinApi = PinApiService();

  int _step = 0; // 0 = new pin, 1 = otp, 2 = done
  final _newPinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  String _reference = '';
  bool _loading = false;

  @override
  void dispose() {
    _newPinCtrl.dispose();
    _confirmPinCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : _green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _initiate() async {
    final pin = _newPinCtrl.text.trim();
    final confirm = _confirmPinCtrl.text.trim();
    if (pin.length < 4 || pin.length > 8) {
      _snack('PIN must be 4–8 digits', error: true);
      return;
    }
    if (pin != confirm) {
      _snack('PINs do not match', error: true);
      return;
    }

    setState(() => _loading = true);
    final res = await _pinApi.initiateReset(
        const InitiatePinRequest(channel: ApiConfig.defaultOtpChannel));
    if (!mounted) return;
    setState(() => _loading = false);

    if (res.isSuccess) {
      final data = res.data ?? const {};
      _reference = (data['reference'] ?? data['value'] ?? res.message ?? '')
          .toString();
      setState(() => _step = 1);
      _snack('OTP sent to your registered number');
    } else {
      _snack(res.errorMessage, error: true);
    }
  }

  Future<void> _validate() async {
    final otp = _otpCtrl.text.trim();
    if (otp.isEmpty) {
      _snack('Enter the OTP sent to you', error: true);
      return;
    }
    setState(() => _loading = true);
    final res = await _pinApi.validateReset(ValidatePinRequest(
      reference: _reference,
      otp: otp,
      newPin: _newPinCtrl.text.trim(),
      confirmPin: _confirmPinCtrl.text.trim(),
    ));
    if (!mounted) return;
    setState(() => _loading = false);

    if (res.isSuccess) {
      setState(() => _step = 2);
    } else {
      _snack(res.errorMessage, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Text('Reset Transaction PIN',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: _step == 2
              ? _buildDone()
              : (_step == 0 ? _buildPinStep() : _buildOtpStep()),
        ),
      ),
    );
  }

  Widget _buildPinStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Set a new 4-digit PIN',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 8),
        Text(
          "We'll send a one-time code to your registered number to confirm the reset.",
          style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), height: 1.5),
        ),
        const SizedBox(height: 28),
        _pinField('New PIN', _newPinCtrl),
        const SizedBox(height: 16),
        _pinField('Confirm New PIN', _confirmPinCtrl),
        const SizedBox(height: 28),
        _button('Send OTP', _loading, _initiate),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Enter the OTP',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 8),
        Text('Enter the code sent to your registered phone number.',
            style:
                TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), height: 1.5)),
        const SizedBox(height: 28),
        _pinField('OTP Code', _otpCtrl, maxLen: 8),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _loading ? null : _initiate,
          child: const Text('Resend code',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: _green)),
        ),
        const SizedBox(height: 24),
        _button('Confirm Reset', _loading, _validate),
      ],
    );
  }

  Widget _buildDone() {
    return Column(
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.check_circle, color: _green, size: 72),
        const SizedBox(height: 20),
        Text('PIN reset!',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 8),
        Text('Your transaction PIN has been reset.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
        const SizedBox(height: 28),
        _button('Done', false, () => context.pop()),
      ],
    );
  }

  Widget _pinField(String label, TextEditingController controller,
      {int maxLen = 4}) {
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
          keyboardType: TextInputType.number,
          obscureText: maxLen == 4,
          maxLength: maxLen,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
              fontSize: 18, letterSpacing: 4, color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            counterText: '',
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

  Widget _button(String label, bool loading, VoidCallback onTap) {
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

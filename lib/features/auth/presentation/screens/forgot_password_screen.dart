import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/auth_provider.dart';

/// Forgot / reset password flow backed by the RIMA Identity API:
///  step 0 → POST /api/auth/forgot-password (email)
///  step 1 → POST /api/auth/reset-password  (email, token, newPassword)
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const _green = Color(0xFF166C46);

  int _step = 0; // 0 = request email, 1 = reset with token, 2 = done
  final _emailCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPassword = false;

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

  Future<void> _sendEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _snack('Please enter a valid email address', error: true);
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.forgotPassword(email);
    if (!mounted) return;
    if (ok) {
      _snack('If that email exists, a reset code has been sent.');
      setState(() => _step = 1);
    } else {
      _snack(auth.error ?? 'Could not send reset email.', error: true);
    }
  }

  Future<void> _resetPassword() async {
    final token = _tokenCtrl.text.trim();
    final pwd = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;
    if (token.isEmpty) {
      _snack('Enter the reset code from your email', error: true);
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
      setState(() => _step = 2);
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
                child: _step == 2 ? _buildDone() : _buildForm(isLoading),
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
              ? "Enter the email on your account and we'll send a reset code."
              : 'Enter the code sent to ${_emailCtrl.text.trim()} and choose a new password.',
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 32),
        if (requesting) ...[
          _field(
            label: 'Email',
            controller: _emailCtrl,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
        ] else ...[
          _field(
            label: 'Reset Code',
            controller: _tokenCtrl,
            hint: 'Paste the code from your email',
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
          onTap: requesting ? _sendEmail : _resetPassword,
        ),
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

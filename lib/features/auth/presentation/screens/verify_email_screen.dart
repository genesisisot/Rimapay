import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/auth_provider.dart';

/// Email verification via the RIMA Identity API
/// (GET /api/auth/verify-email?token=&email=). The user pastes the token from
/// the verification email they received after registering.
class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const _green = Color(0xFF166C46);

  final _emailCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = widget.email;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : _green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _verify() async {
    final email = _emailCtrl.text.trim();
    final token = _tokenCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _snack('Enter a valid email', error: true);
      return;
    }
    if (token.isEmpty) {
      _snack('Enter the verification token from your email', error: true);
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyEmail(token: token, email: email);
    if (!mounted) return;
    if (ok) {
      setState(() => _verified = true);
    } else {
      _snack(auth.error ?? 'Could not verify email.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().isLoading;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Text('Verify Email',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: _verified ? _buildDone() : _buildForm(loading),
        ),
      ),
    );
  }

  Widget _buildForm(bool loading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.mark_email_unread_outlined, color: _green, size: 56),
        const SizedBox(height: 16),
        Text('Confirm your email',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 8),
        Text(
          'Enter the verification token sent to your email address to activate your account.',
          style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), height: 1.5),
        ),
        const SizedBox(height: 28),
        _field('Email', _emailCtrl, 'you@example.com'),
        const SizedBox(height: 16),
        _field('Verification Token', _tokenCtrl, 'Paste token from email'),
        const SizedBox(height: 28),
        _button('Verify Email', loading, _verify),
      ],
    );
  }

  Widget _buildDone() {
    return Column(
      children: [
        const SizedBox(height: 40),
        const Icon(Icons.verified, color: _green, size: 72),
        const SizedBox(height: 20),
        Text('Email verified!',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 8),
        Text('Your email has been confirmed.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
        const SizedBox(height: 28),
        _button('Continue', false, () => context.pop()),
      ],
    );
  }

  Widget _field(String label, TextEditingController controller, String hint) {
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
          style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 14),
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

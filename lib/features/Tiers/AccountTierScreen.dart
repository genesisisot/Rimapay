import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:rimapay/shared/widgets/bill_screen_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

enum TierLevel { tier1, tier2, tier3 }

class TierInfo {
  final String name;
  final String balanceLimit;
  final String transactionLimit;
  final List<String> benefits;
  final TierLevel level;

  const TierInfo({
    required this.name,
    required this.balanceLimit,
    required this.transactionLimit,
    required this.benefits,
    required this.level,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────

class AccountTiersScreen extends StatefulWidget {
  const AccountTiersScreen({super.key});

  @override
  State<AccountTiersScreen> createState() => _AccountTiersScreenState();
}

class _AccountTiersScreenState extends State<AccountTiersScreen> {
  // Mock: user is on Basic, and BVN was provided at onboarding
  final TierLevel currentTier = TierLevel.tier1;
  final bool onboardingProvidedBvn = true; // → Standard needs NIN

  static const tiers = [
    TierInfo(
      name: 'Basic',
      balanceLimit: '₦50,000',
      transactionLimit: '₦5,000/day',
      level: TierLevel.tier1,
      benefits: [
        'Mobile top-up & bill payments',
        'Basic peer-to-peer transfers',
        '24/7 in-app support',
      ],
    ),
    TierInfo(
      name: 'Standard',
      balanceLimit: '₦300,000',
      transactionLimit: '₦100,000/day',
      level: TierLevel.tier2,
      benefits: [
        'Higher transfer & balance limits',
        'Bank transfers (NIP)',
        'Scheduled & recurring payments',
        'Priority customer support',
      ],
    ),
    TierInfo(
      name: 'Premium',
      balanceLimit: '₦5,000,000',
      transactionLimit: '₦1,000,000/day',
      level: TierLevel.tier3,
      benefits: [
        'Maximum transaction limits',
        'International transfers',
        'Dedicated account manager',
        'Exclusive cashback & rewards',
      ],
    ),
  ];

  Color _tierColor(TierLevel t) {
    switch (t) {
      case TierLevel.tier1:
        return const Color(0xFF166C46);
      case TierLevel.tier2:
        return const Color(0xFF3B82F6);
      case TierLevel.tier3:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _tierIcon(TierLevel t) {
    switch (t) {
      case TierLevel.tier1:
        return Icons.star_rounded;
      case TierLevel.tier2:
        return Icons.verified_rounded;
      case TierLevel.tier3:
        return Icons.workspace_premium_rounded;
    }
  }

  void _startUpgrade(TierLevel target) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => target == TierLevel.tier2
            ? _StandardUpgradeScreen(needsNin: onboardingProvidedBvn)
            : const _PremiumUpgradeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // ── Green header ──
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF073D25), Color(0xFF0B4F2F), Color(0xFF073D25)],
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 14,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.pop(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.18)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Tiers',
                          style: TextStyle(
                            color: Theme.of(context).cardColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Effra',
                          ),
                        ),
                        Text(
                          'Upgrade to unlock higher limits',
                          style: TextStyle(
                            color: Color(0x99FFFFFF),
                            fontSize: 12,
                            fontFamily: 'Effra',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Progress stepper
                _TierStepper(current: currentTier),
              ],
            ),
          ),

          // ── Content ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: tiers.map((t) => _TierCard(
                info: t,
                isCurrent: t.level == currentTier,
                canUpgrade: t.level.index > currentTier.index,
                color: _tierColor(t.level),
                icon: _tierIcon(t.level),
                onUpgrade: () => _startUpgrade(t.level),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tier Stepper
// ─────────────────────────────────────────────────────────────────────────────

class _TierStepper extends StatelessWidget {
  final TierLevel current;
  const _TierStepper({required this.current});

  @override
  Widget build(BuildContext context) {
    final labels = ['Basic', 'Standard', 'Premium'];
    return Row(
      children: List.generate(3, (i) {
        final done = i <= current.index;
        final isLast = i == 2;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? Colors.white : Colors.white.withOpacity(0.2),
                        border: Border.all(
                          color: done ? Colors.white : Colors.white.withOpacity(0.35),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: done
                            ? Icon(
                                i == current.index
                                    ? Icons.radio_button_checked
                                    : Icons.check_rounded,
                                size: 14,
                                color: i == current.index
                                    ? const Color(0xFF0B4F2F)
                                    : const Color(0xFF0B4F2F),
                              )
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.5),
                                  fontFamily: 'Effra',
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: done ? Colors.white : Colors.white.withOpacity(0.45),
                        fontFamily: 'Effra',
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 18),
                    color: i < current.index
                        ? Colors.white
                        : Colors.white.withOpacity(0.2),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tier Card
// ─────────────────────────────────────────────────────────────────────────────

class _TierCard extends StatelessWidget {
  final TierInfo info;
  final bool isCurrent;
  final bool canUpgrade;
  final Color color;
  final IconData icon;
  final VoidCallback onUpgrade;

  const _TierCard({
    required this.info,
    required this.isCurrent,
    required this.canUpgrade,
    required this.color,
    required this.icon,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? color : Theme.of(context).dividerColor,
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Color accent top strip
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            info.name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontFamily: 'Effra',
                            ),
                          ),
                          Text(
                            'Tier ${info.level.index + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              fontFamily: 'Effra',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color,
                            fontFamily: 'Effra',
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Limits
                Row(
                  children: [
                    _LimitBox(label: 'Balance Cap', value: info.balanceLimit, color: color),
                    const SizedBox(width: 10),
                    _LimitBox(label: 'Per Day', value: info.transactionLimit, color: color),
                  ],
                ),
                const SizedBox(height: 14),

                // Benefits
                ...info.benefits.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check_rounded, size: 10, color: color),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          b,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                            fontFamily: 'Effra',
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 14),

                // CTA
                if (isCurrent)
                  Container(
                    width: double.infinity,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Current Plan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                          fontFamily: 'Effra',
                        ),
                      ),
                    ),
                  )
                else if (canUpgrade)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onUpgrade();
                    },
                    child: Container(
                      width: double.infinity,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Upgrade to ${info.name}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).cardColor,
                            fontFamily: 'Effra',
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Center(
                      child: Text(
                        'Complete lower tiers first',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                          fontFamily: 'Effra',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LimitBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _LimitBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                fontFamily: 'Effra',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'Effra',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Standard Upgrade Screen (Tier 2)
// ─────────────────────────────────────────────────────────────────────────────

class _StandardUpgradeScreen extends StatefulWidget {
  /// true = user needs to provide NIN (BVN was given at onboarding)
  /// false = user needs to provide BVN (NIN was given at onboarding)
  final bool needsNin;
  const _StandardUpgradeScreen({required this.needsNin});

  @override
  State<_StandardUpgradeScreen> createState() => _StandardUpgradeScreenState();
}

class _StandardUpgradeScreenState extends State<_StandardUpgradeScreen> {
  int _step = 0; // 0 = ID input, 1 = OTP, 2 = success

  final _idController = TextEditingController();
  final _idFocus = FocusNode();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocuses = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  String _enteredOtp = '';

  @override
  void dispose() {
    _idController.dispose();
    _idFocus.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocuses) f.dispose();
    super.dispose();
  }

  Future<void> _submitId() async {
    if (_idController.text.length != 11) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() { _loading = false; _step = 1; });
  }

  Future<void> _submitOtp() async {
    if (_enteredOtp.length != 6) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() { _loading = false; _step = 2; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF073D25), Color(0xFF0B4F2F), Color(0xFF073D25)],
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 14,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upgrade to Standard',
                      style: TextStyle(
                        color: Theme.of(context).cardColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Effra',
                      ),
                    ),
                    Text(
                      'Tier 2 · Identity Verification',
                      style: TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 12,
                        fontFamily: 'Effra',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Step dots
          if (_step < 2) ...[
            Container(
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(2, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _step ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _step
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                )),
              ),
            ),
            Divider(height: 1, color: Theme.of(context).dividerColor),
          ],

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _step == 0
                  ? _buildIdStep()
                  : _step == 1
                      ? _buildOtpStep()
                      : _buildSuccess(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdStep() {
    final label = widget.needsNin ? 'National Identification Number (NIN)' : 'Bank Verification Number (BVN)';
    final hint = '11-digit ${widget.needsNin ? "NIN" : "BVN"}';
    final note = widget.needsNin
        ? 'You provided your BVN during onboarding. Please enter your NIN to verify your identity.'
        : 'You provided your NIN during onboarding. Please enter your BVN to verify your identity.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF3B82F6)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  note,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1D4ED8),
                    fontFamily: 'Effra',
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
            fontFamily: 'Effra',
          ),
        ),
        const SizedBox(height: 10),
        BillFloatingField(
          controller: _idController,
          focusNode: _idFocus,
          label: widget.needsNin ? 'NIN' : 'BVN',
          hint: hint,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Your ${widget.needsNin ? "NIN" : "BVN"} is used solely for identity verification and is encrypted.',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            fontFamily: 'Effra',
          ),
        ),
        const SizedBox(height: 32),

        GestureDetector(
          onTap: _loading ? null : _submitId,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).cardColor,
                        fontFamily: 'Effra',
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter Verification Code',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
            fontFamily: 'Effra',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a 6-digit code to verify your ${widget.needsNin ? "NIN" : "BVN"}. Check your registered phone number.',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontFamily: 'Effra',
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        // OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => _OtpBox(
            controller: _otpControllers[i],
            focusNode: _otpFocuses[i],
            onChanged: (v) {
              if (v.isNotEmpty && i < 5) {
                FocusScope.of(context).requestFocus(_otpFocuses[i + 1]);
              }
              if (v.isEmpty && i > 0) {
                FocusScope.of(context).requestFocus(_otpFocuses[i - 1]);
              }
              _enteredOtp = _otpControllers.map((c) => c.text).join();
            },
          )),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              "Didn't receive it? ",
              style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontFamily: 'Effra'),
            ),
            GestureDetector(
              onTap: () {},
              child: const Text(
                'Resend Code',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3B82F6),
                  fontFamily: 'Effra',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        GestureDetector(
          onTap: _loading ? null : _submitOtp,
          child: Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      'Verify',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).cardColor,
                        fontFamily: 'Effra',
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.verified_rounded, size: 48, color: Color(0xFF3B82F6)),
        ),
        const SizedBox(height: 24),
        Text(
          'Upgrade Successful!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
            fontFamily: 'Effra',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'You are now on the Standard Tier.\nYour new limits are active immediately.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontFamily: 'Effra',
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        _SuccessBenefitRow(icon: Icons.account_balance_wallet_rounded, text: 'Balance cap: ₦300,000'),
        _SuccessBenefitRow(icon: Icons.swap_horiz_rounded, text: 'Daily transfers: ₦100,000'),
        _SuccessBenefitRow(icon: Icons.support_agent_rounded, text: 'Priority customer support'),
        const SizedBox(height: 40),
        GestureDetector(
          onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
          child: Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                'Back to Home',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).cardColor,
                  fontFamily: 'Effra',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium Upgrade Screen (Tier 3)
// ─────────────────────────────────────────────────────────────────────────────

class _PremiumUpgradeScreen extends StatefulWidget {
  const _PremiumUpgradeScreen();

  @override
  State<_PremiumUpgradeScreen> createState() => _PremiumUpgradeScreenState();
}

class _PremiumUpgradeScreenState extends State<_PremiumUpgradeScreen> {
  int _step = 0; // 0 = govt doc, 1 = address doc, 2 = review, 3 = success

  String? _govDocType;
  String? _govDocName;
  String? _addressDocType;
  String? _addressDocName;

  bool _loading = false;

  static const govDocTypes = [
    'National ID Card',
    "International Passport",
    "Driver's License",
    "Voter's Card",
  ];

  static const addressDocTypes = [
    'Utility Bill',
    'Bank Statement',
    'Tenancy Agreement',
    'Government-Issued Letter',
  ];

  void _mockPickFile(String docType, bool isGov) {
    // Mock file selection
    setState(() {
      if (isGov) {
        _govDocType = docType;
        _govDocName = '${docType.replaceAll(' ', '_')}_scan.pdf';
      } else {
        _addressDocType = docType;
        _addressDocName = '${docType.replaceAll(' ', '_')}_scan.pdf';
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() { _loading = false; _step = 3; });
  }

  @override
  Widget build(BuildContext context) {
    final stepTitles = [
      'Government ID',
      'Address Document',
      'Review & Submit',
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF073D25), Color(0xFF0B4F2F), Color(0xFF073D25)],
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 14,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_step > 0 && _step < 3) {
                      setState(() => _step--);
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upgrade to Premium',
                      style: TextStyle(
                        color: Theme.of(context).cardColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Effra',
                      ),
                    ),
                    Text(
                      _step < 3 ? 'Step ${_step + 1} of 3 · ${stepTitles[_step.clamp(0, 2)]}' : 'Complete',
                      style: TextStyle(
                        color: Color(0x99FFFFFF),
                        fontSize: 12,
                        fontFamily: 'Effra',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Step progress
          if (_step < 3) ...[
            Container(
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: List.generate(3, (i) {
                  final done = i <= _step;
                  return Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 4,
                            decoration: BoxDecoration(
                              color: done
                                  ? const Color(0xFF8B5CF6)
                                  : Theme.of(context).dividerColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        if (i < 2) const SizedBox(width: 4),
                      ],
                    ),
                  );
                }),
              ),
            ),
            Divider(height: 1, color: Theme.of(context).dividerColor),
          ],

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _step == 0
                  ? _buildDocStep(
                      title: 'Government-Issued ID',
                      subtitle: 'Upload a clear photo or scan of your government-issued ID.',
                      docTypes: govDocTypes,
                      selectedType: _govDocType,
                      selectedFile: _govDocName,
                      isGov: true,
                      onNext: () => setState(() => _step = 1),
                    )
                  : _step == 1
                      ? _buildDocStep(
                          title: 'Proof of Address',
                          subtitle: 'Upload a document showing your current address, dated within the last 3 months.',
                          docTypes: addressDocTypes,
                          selectedType: _addressDocType,
                          selectedFile: _addressDocName,
                          isGov: false,
                          onNext: () => setState(() => _step = 2),
                        )
                      : _step == 2
                          ? _buildReview()
                          : _buildSuccess(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocStep({
    required String title,
    required String subtitle,
    required List<String> docTypes,
    required String? selectedType,
    required String? selectedFile,
    required bool isGov,
    required VoidCallback onNext,
  }) {
    final color = const Color(0xFF8B5CF6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
            fontFamily: 'Effra',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontFamily: 'Effra',
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),

        // Document type selector
        Text(
          'Document Type',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
            fontFamily: 'Effra',
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: docTypes.map((type) {
            final selected = selectedType == type;
            return GestureDetector(
              onTap: () => setState(() {
                if (isGov) _govDocType = type;
                else _addressDocType = type;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? color.withOpacity(0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? color : Theme.of(context).dividerColor,
                    width: selected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                    fontFamily: 'Effra',
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Upload area
        Text(
          'Upload Document',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
            fontFamily: 'Effra',
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: selectedType == null
              ? null
              : () => _mockPickFile(selectedType, isGov),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: selectedFile != null
                  ? color.withOpacity(0.04)
                  : Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selectedFile != null
                    ? color.withOpacity(0.3)
                    : const Color(0xFFD1D5DB),
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: selectedFile != null
                        ? color.withOpacity(0.1)
                        : Theme.of(context).dividerColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    selectedFile != null
                        ? Icons.check_circle_rounded
                        : Icons.cloud_upload_outlined,
                    size: 26,
                    color: selectedFile != null ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  selectedFile != null ? selectedFile! : 'Tap to upload',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selectedFile != null ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                    fontFamily: 'Effra',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedFile != null
                      ? 'Tap to change'
                      : selectedType == null
                          ? 'Select a document type first'
                          : 'JPG, PNG or PDF · Max 5MB',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    fontFamily: 'Effra',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        GestureDetector(
          onTap: (selectedType != null && selectedFile != null) ? onNext : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              gradient: (selectedType != null && selectedFile != null)
                  ? const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                    )
                  : null,
              color: (selectedType != null && selectedFile != null)
                  ? null
                  : const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(14),
              boxShadow: (selectedType != null && selectedFile != null)
                  ? [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: (selectedType != null && selectedFile != null)
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  fontFamily: 'Effra',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review & Submit',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
            fontFamily: 'Effra',
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Review the documents you uploaded before submitting for verification.',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontFamily: 'Effra',
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),

        _ReviewItem(
          icon: Icons.badge_rounded,
          label: 'Government ID',
          docType: _govDocType ?? '',
          fileName: _govDocName ?? '',
          color: const Color(0xFF8B5CF6),
          onEdit: () => setState(() => _step = 0),
        ),
        const SizedBox(height: 12),
        _ReviewItem(
          icon: Icons.home_work_rounded,
          label: 'Proof of Address',
          docType: _addressDocType ?? '',
          fileName: _addressDocName ?? '',
          color: const Color(0xFF8B5CF6),
          onEdit: () => setState(() => _step = 1),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.schedule_rounded, size: 18, color: Color(0xFFea580c)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Verification typically takes 1–2 business days. You will be notified once complete.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9a3412),
                    fontFamily: 'Effra',
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        GestureDetector(
          onTap: _loading ? null : _submit,
          child: Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: _loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      'Submit for Verification',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).cardColor,
                        fontFamily: 'Effra',
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.workspace_premium_rounded, size: 48, color: Color(0xFF8B5CF6)),
        ),
        const SizedBox(height: 24),
        Text(
          'Documents Submitted!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
            fontFamily: 'Effra',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your documents are under review.\nWe\'ll notify you within 1–2 business days.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontFamily: 'Effra',
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        _SuccessBenefitRow(icon: Icons.account_balance_wallet_rounded, text: 'Balance cap: ₦5,000,000 (after approval)'),
        _SuccessBenefitRow(icon: Icons.swap_horiz_rounded, text: 'Daily transfers: ₦1,000,000'),
        _SuccessBenefitRow(icon: Icons.star_rounded, text: 'Dedicated account manager'),
        const SizedBox(height: 40),
        GestureDetector(
          onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
          child: Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                'Back to Home',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).cardColor,
                  fontFamily: 'Effra',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared small widgets
// ─────────────────────────────────────────────────────────────────────────────

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 54,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
          fontFamily: 'Effra',
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: Theme.of(context).cardColor,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
          ),
        ),
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String docType;
  final String fileName;
  final Color color;
  final VoidCallback onEdit;

  const _ReviewItem({
    required this.icon,
    required this.label,
    required this.docType,
    required this.fileName,
    required this.color,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    fontFamily: 'Effra',
                  ),
                ),
                Text(
                  docType,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontFamily: 'Effra',
                  ),
                ),
                Text(
                  fileName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontFamily: 'Effra',
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: const Text(
              'Edit',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8B5CF6),
                fontFamily: 'Effra',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessBenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _SuccessBenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF166C46)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
                fontFamily: 'Effra',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

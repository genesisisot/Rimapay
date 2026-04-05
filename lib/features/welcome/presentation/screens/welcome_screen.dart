import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:rimapay/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

import '../../../../../shared/widgets/noise_painter.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _Slide {
  final String id;
  final String title;
  final String subtitle;
  final String description;

  _Slide({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
  });
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  final List<_Slide> _slidesEn = [
    _Slide(
      id: 'heritage',
      title: 'We are Indigenous,\nmade for us, by us',
      subtitle: 'Nigerian Heritage',
      description:
          'Built by Nigerians, for Nigerians. Experience financial freedom rooted in our rich culture and unwavering spirit of excellence.',
    ),
    _Slide(
      id: 'market',
      title: 'RimaPay is\nfor Everyone',
      subtitle: 'Every Nigerian',
      description:
          'From corporate professionals to market entrepreneurs - financial freedom for all Nigerians, everywhere.',
    ),
    _Slide(
      id: 'seamless',
      title: 'Payments Made\nSeamless',
      subtitle: 'Effortless Experience',
      description:
          'Tap, pay, done. Experience the future of payments with instant, secure, and intuitive transactions.',
    ),
  ];

  final List<_Slide> _slidesHa = [
    _Slide(
      id: 'heritage',
      title: "Mu 'Yan Gida Ne,\nAnyi Mana, Muka Yi",
      subtitle: 'Gado na Najeriya',
      description:
          "An gina shi da Najeriyawa, don Najeriyawa. Warewar yancin kudi mai tushe a cikin al'adunmu da ruhun kwazo.",
    ),
    _Slide(
      id: 'market',
      title: 'RimaPay Yake\nGa Kowa',
      subtitle: 'Kowane Najeriyawa',
      description:
          "Daga kwararrun ma'aikata zuwa yan kasuwa — yancin kudi ga duk Najeriyawa, ko'ina suke.",
    ),
    _Slide(
      id: 'seamless',
      title: 'Biyan Kudi Ya Zama\nSauki',
      subtitle: 'Kwarewa Mai Sauki',
      description:
          "Taba, biya, an gama. Kwarewar makomar biyan kudi tare da ma'amaloli na nan take, aminci, da sauki.",
    ),
  ];

  List<_Slide> get slides => _lang == 'ha' ? _slidesHa : _slidesEn;

  late final AnimationController _progressController;
  late final AnimationController _orb1Controller;
  late final AnimationController _orb2Controller;
  Timer? _autoAdvanceTimer;

  int _currentIndex = 0;
  bool _getStartedPressed = false;
  String _lang = 'en';

  static const Duration slideDuration = Duration(seconds: 6);

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: slideDuration,
    );

    _orb1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _orb2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 11),
    )..repeat(reverse: true);

    _startSlideTimer();
    _progressController.forward();
  }

  void _startSlideTimer() {
    _autoAdvanceTimer?.cancel();
    _progressController.stop();
    _progressController.reset();
    _progressController.forward();

    _autoAdvanceTimer = Timer(slideDuration, () {
      final next = (_currentIndex + 1) % slides.length;
      _goToSlide(next);
    });
  }

  void _goToSlide(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
    _startSlideTimer();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _progressController.dispose();
    _orb1Controller.dispose();
    _orb2Controller.dispose();
    super.dispose();
  }

  void _showGetStartedSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _GetStartedSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slide = slides[_currentIndex];
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF073D25),
      body: Stack(
        children: [
          // ── Green gradient background ──
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF052219),
                    Color(0xFF073D25),
                    Color(0xFF0B4F2F),
                    Color(0xFF073D25),
                  ],
                  stops: [0.0, 0.3, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // ── Noise texture overlay ──
          Positioned.fill(
            child: CustomPaint(
              painter: NoisePainter(opacity: 0.055, seed: 7),
            ),
          ),

          // ── Floating orb 1 (top-right) ──
          AnimatedBuilder(
            animation: _orb1Controller,
            builder: (_, __) {
              final dy = _orb1Controller.value * 40;
              final dx = sin(_orb1Controller.value * pi) * 25;
              return Positioned(
                top: size.height * 0.08 + dy,
                right: -60 + dx,
                child: _buildOrb(260, const Color(0xFF166C46), 0.18),
              );
            },
          ),

          // ── Floating orb 2 (bottom-left) ──
          AnimatedBuilder(
            animation: _orb2Controller,
            builder: (_, __) {
              final dy = _orb2Controller.value * 50;
              return Positioned(
                bottom: size.height * 0.18 - dy,
                left: -80,
                child: _buildOrb(220, const Color(0xFF0B4F2F), 0.22),
              );
            },
          ),

          // ── Main content ──
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Left: Logo + name
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.18)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(6),
                                child: Image.asset(
                                  'assets/images/AppIcon.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.account_balance_wallet,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'RimaPay',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Hero slide text
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    key: ValueKey(slide.id),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Language toggle above the title
                        _LangToggle(
                          lang: _lang,
                          onToggle: (l) => setState(() => _lang = l),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            slide.subtitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: size.width * 0.78,
                          child: Text(
                            slide.description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.78),
                              fontSize: 15,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Pagination dots
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: List.generate(slides.length, (i) {
                      final active = i == _currentIndex;
                      return GestureDetector(
                        onTap: () => _goToSlide(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          margin: const EdgeInsets.only(right: 6),
                          height: 7,
                          width: active ? 28 : 7,
                          decoration: BoxDecoration(
                            color:
                                active ? Colors.white : Colors.white38,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 28),

                // Buttons — side by side
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Sign up
                      Expanded(
                        child: GestureDetector(
                          onTapDown: (_) =>
                              setState(() => _getStartedPressed = true),
                          onTapUp: (_) {
                            setState(() => _getStartedPressed = false);
                            context.pushNamed('auth',
                                queryParameters: {'mode': 'signup'});
                          },
                          onTapCancel: () =>
                              setState(() => _getStartedPressed = false),
                          child: AnimatedScale(
                            scale: _getStartedPressed ? 0.97 : 1.0,
                            duration: const Duration(milliseconds: 100),
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: AppColors.goldGradient,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.goldPrimary.withOpacity(0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  _lang == 'ha' ? 'Yi Rajista' : 'Sign up',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Log in
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.pushNamed('auth',
                              queryParameters: {'mode': 'login'}),
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.13),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.22)),
                            ),
                            child: Center(
                              child: Text(
                                _lang == 'ha' ? 'Ina da asusun riga' : 'Log in',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Compliance logos
                const _ComplianceBar(),

                const SizedBox(height: 10),
              ],
            ),
          ),

          // Progress bar at very bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _progressController,
              builder: (_, __) => LinearProgressIndicator(
                value: _progressController.value,
                minHeight: 3,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF166C46)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withOpacity(opacity * 1.5),
              color.withOpacity(0),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Language Toggle ───────────────────────────────────────────────────────────

class _LangToggle extends StatelessWidget {
  final String lang;
  final void Function(String) onToggle;

  const _LangToggle({required this.lang, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tab('English', 'en'),
          _tab('Hausa', 'ha'),
        ],
      ),
    );
  }

  Widget _tab(String label, String value) {
    final active = lang == value;
    return GestureDetector(
      onTap: () => onToggle(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? const Color(0xFF0B4F2F) : Colors.white70,
          ),
        ),
      ),
    );
  }
}

// ── Compliance Bar ────────────────────────────────────────────────────────────

class _ComplianceBar extends StatelessWidget {
  const _ComplianceBar();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // NDIC
              Image.asset(
                'assets/images/NDIC.png',
                height: 48,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
              Container(
                width: 1,
                height: 36,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                color: Colors.white.withOpacity(0.2),
              ),
              // Authorized text
              Text(
                'AUTHORIZED AND\nREGULATED BY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 10),
              // CBN
              Image.asset(
                'assets/images/CBN.png',
                height: 50,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'YOUR DEPOSITS ARE PROTECTED',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Licensed by CBN',
              style: TextStyle(
                color: const Color(0xFF166C46).withOpacity(0.9),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              ' • ',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
              ),
            ),
            Text(
              'Insured by NDIC',
              style: TextStyle(
                color: const Color(0xFF166C46).withOpacity(0.9),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Bottom Sheet ──────────────────────────────────────────────────────────────

class _GetStartedSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFE4E7EC),
              borderRadius: BorderRadius.circular(999),
            ),
          ),

          const Text(
            'Welcome to RimaPay',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose how you want to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 28),

          _SheetOption(
            icon: Icons.person_add_outlined,
            iconBg: const Color(0xFFF2F7F3),
            iconColor: const Color(0xFF166C46),
            title: 'Open New Account',
            subtitle: 'Create a new RimaPay account',
            onTap: () {
              Navigator.pop(context);
              context.pushNamed('auth', queryParameters: {'mode': 'signup'});
            },
          ),

          const SizedBox(height: 12),

          _SheetOption(
            icon: Icons.login_outlined,
            iconBg: const Color(0xFFfff3ee),
            iconColor: const Color(0xFFff6b35),
            title: 'Sign In',
            subtitle: 'Access your existing account',
            onTap: () {
              Navigator.pop(context);
              context.pushNamed('auth', queryParameters: {'mode': 'login'});
            },
          ),

          const SizedBox(height: 12),

          _SheetOption(
            icon: Icons.devices_outlined,
            iconBg: const Color(0xFFf5f3ff),
            iconColor: const Color(0xFF8B5CF6),
            title: 'Change Device',
            subtitle: 'Transfer your account to this device',
            onTap: () => Navigator.pop(context),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFBFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE4E7EC)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF667085),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}

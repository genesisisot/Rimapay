import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/noise_painter.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  String _lang = 'en';
  bool _signUpPressed = false;
  bool _loginPressed = false;

  late final AnimationController _glowController;
  late final AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF041810),
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF031209),
                    Color(0xFF062A19),
                    Color(0xFF0A3820),
                    Color(0xFF062A19),
                  ],
                  stops: [0.0, 0.35, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // Noise texture overlay
          Positioned.fill(
            child: CustomPaint(
              painter: NoisePainter(opacity: 0.04, seed: 7),
            ),
          ),

          // Glowing Nigeria map — upper-right quadrant
          Positioned(
            top: size.height * 0.04,
            right: -size.width * 0.10,
            width: size.width * 0.70,
            height: size.width * 0.70,
            child: AnimatedBuilder(
              animation: Listenable.merge([_glowController, _particleController]),
              builder: (_, __) => CustomPaint(
                painter: _NigeriaMapPainter(
                  pulse: _glowController.value,
                  particlePhase: _particleController.value,
                ),
              ),
            ),
          ),

          // Main scrollable content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top bar ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo
                      SizedBox(
                        width: 58,
                        height: 58,
                        child: Image.asset(
                          'assets/images/AppIcon.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.account_balance,
                            color: Color(0xFFD4AF37),
                            size: 38,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Language toggle (top-right, matching reference)
                      _LangToggle(
                        lang: _lang,
                        onToggle: (l) => setState(() => _lang = l),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Hero headline ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Big lime-green headline
                      Text(
                        _lang == 'ha'
                            ? "Anyi Mana,\nMuka Yi"
                            : "made for us\nby us",
                        style: const TextStyle(
                          color: Color(0xFFC6F135),
                          fontSize: 48,
                          height: 1.06,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Gold underline accent
                      Container(
                        width: 42,
                        height: 3.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Subtitle — contained within left ~60% so map shows through
                      SizedBox(
                        width: size.width * 0.58,
                        child: Text(
                          _lang == 'ha'
                              ? "Sabis na kudi mai aminci, da sauri kuma abin dogaro don ku."
                              : "Safe, fast and reliable\nfinancial services\nbuilt for you.",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.70),
                            fontSize: 15.5,
                            height: 1.55,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Trust badges ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TrustBadge(
                          icon: Icons.verified_user_outlined,
                          topLine: _lang == 'ha' ? "Ajiya" : "Deposits",
                          midLine: _lang == 'ha' ? "Insured by" : "Insured by",
                          highlight: "NDIC",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TrustBadge(
                          icon: Icons.account_balance_outlined,
                          topLine: _lang == 'ha' ? "Ƙarƙashin" : "Regulated by",
                          midLine: "Central Bank",
                          highlight: "of Nigeria",
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Action buttons ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    children: [
                      // Sign up — gold
                      Expanded(
                        child: GestureDetector(
                          onTapDown: (_) =>
                              setState(() => _signUpPressed = true),
                          onTapUp: (_) {
                            setState(() => _signUpPressed = false);
                            context.pushNamed('auth',
                                queryParameters: {'mode': 'signup'});
                          },
                          onTapCancel: () =>
                              setState(() => _signUpPressed = false),
                          child: AnimatedScale(
                            scale: _signUpPressed ? 0.97 : 1.0,
                            duration: const Duration(milliseconds: 100),
                            child: Container(
                              height: 78,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFE8C84A),
                                    Color(0xFFD4AF37),
                                    Color(0xFFBF9B30),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFD4AF37)
                                        .withOpacity(0.38),
                                    blurRadius: 22,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person_add_outlined,
                                        color: Colors.white, size: 22),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _lang == 'ha'
                                              ? 'Yi Rajista'
                                              : 'Sign up',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          _lang == 'ha'
                                              ? 'Ƙirƙiri asusun ku'
                                              : 'Create your account',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.80),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Log in — bordered
                      Expanded(
                        child: GestureDetector(
                          onTapDown: (_) =>
                              setState(() => _loginPressed = true),
                          onTapUp: (_) {
                            setState(() => _loginPressed = false);
                            context.pushNamed('auth',
                                queryParameters: {'mode': 'login'});
                          },
                          onTapCancel: () =>
                              setState(() => _loginPressed = false),
                          child: AnimatedScale(
                            scale: _loginPressed ? 0.97 : 1.0,
                            duration: const Duration(milliseconds: 100),
                            child: Container(
                              height: 78,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF166C46),
                                  width: 1.5,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.login_rounded,
                                        color: Colors.white, size: 22),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _lang == 'ha' ? 'Shiga' : 'Log in',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          _lang == 'ha'
                                              ? 'Barka da komowa'
                                              : 'Welcome back',
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.55),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Compliance section ────────────────────────────────────────
                const _ComplianceBar(),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nigeria Map CustomPainter ─────────────────────────────────────────────────

class _NigeriaMapPainter extends CustomPainter {
  final double pulse;
  final double particlePhase;

  // Normalized Nigeria outline points (0–1 space, top-left origin)
  static const List<Offset> _outline = [
    Offset(0.20, 0.28), // NW
    Offset(0.28, 0.10), // North-west ridge
    Offset(0.40, 0.04), // North (near Sokoto–Kano)
    Offset(0.52, 0.07), // North-center
    Offset(0.60, 0.03), // North-east (Chad left)
    Offset(0.66, 0.13), // Chad basin notch bottom
    Offset(0.72, 0.05), // Chad right ridge
    Offset(0.84, 0.20), // NE corner
    Offset(0.93, 0.36), // East upper
    Offset(0.90, 0.54), // East center (Benue area)
    Offset(0.82, 0.68), // SE direction
    Offset(0.74, 0.83), // South-east coast
    Offset(0.60, 0.94), // South coast center
    Offset(0.44, 0.90), // Niger Delta
    Offset(0.30, 0.84), // South-west coast
    Offset(0.16, 0.74), // West coast (Lagos area)
    Offset(0.09, 0.60), // West
    Offset(0.10, 0.44), // West upper
    Offset(0.20, 0.28), // Close back to NW
  ];

  _NigeriaMapPainter({required this.pulse, required this.particlePhase});

  @override
  void paint(Canvas canvas, Size size) {
    final pts =
        _outline.map((p) => Offset(p.dx * size.width, p.dy * size.height)).toList();

    // Build smooth closed path
    final path = _buildSmoothPath(pts);

    // Outer glow layers (largest to smallest for depth)
    for (int layer = 6; layer >= 1; layer--) {
      final baseOpacity = 0.025 + (pulse * 0.02);
      final glowPaint = Paint()
        ..color = const Color(0xFF00FF88).withOpacity(baseOpacity * layer)
        ..style = PaintingStyle.stroke
        ..strokeWidth = layer * 7.0
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, layer * 5.0);
      canvas.drawPath(path, glowPaint);
    }

    // Inner bright outline
    final outlinePaint = Paint()
      ..color = const Color(0xFF00FF88).withOpacity(0.75 + pulse * 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, outlinePaint);

    // Dot particles scattered inside map area
    _drawParticles(canvas, size);
  }

  Path _buildSmoothPath(List<Offset> pts) {
    final path = Path();
    if (pts.isEmpty) return path;

    // Move to midpoint before first point for smooth start
    final m0 = Offset(
        (pts.last.dx + pts[0].dx) / 2, (pts.last.dy + pts[0].dy) / 2);
    path.moveTo(m0.dx, m0.dy);

    for (int i = 0; i < pts.length - 1; i++) {
      final curr = pts[i];
      final next = pts[(i + 1) % pts.length];
      final mid = Offset((curr.dx + next.dx) / 2, (curr.dy + next.dy) / 2);
      path.quadraticBezierTo(curr.dx, curr.dy, mid.dx, mid.dy);
    }
    path.close();
    return path;
  }

  void _drawParticles(Canvas canvas, Size size) {
    final rng = Random(19);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 55; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final offset = (particlePhase + i / 55.0) % 1.0;
      final flicker = (sin(offset * pi * 2) * 0.5 + 0.5);
      final opacity = flicker * 0.55 * (0.5 + pulse * 0.5);
      final radius = rng.nextDouble() * 1.8 + 0.3;

      paint.color = const Color(0xFF00FF88).withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_NigeriaMapPainter old) =>
      old.pulse != pulse || old.particlePhase != particlePhase;
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
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: active ? const Color(0xFF0B4F2F) : Colors.white70,
          ),
        ),
      ),
    );
  }
}

// ── Trust Badge ───────────────────────────────────────────────────────────────

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String topLine;
  final String midLine;
  final String highlight;

  const _TrustBadge({
    required this.icon,
    required this.topLine,
    required this.midLine,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withOpacity(0.13)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.75), size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topLine,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                Text(
                  midLine,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                Text(
                  highlight,
                  style: const TextStyle(
                    color: Color(0xFF4EC97A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
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

// ── Compliance Bar ────────────────────────────────────────────────────────────

class _ComplianceBar extends StatelessWidget {
  const _ComplianceBar();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // NDIC + CBN logo card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 22),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.09),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Colors.white.withOpacity(0.13)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/NDIC.png',
                height: 44,
                errorBuilder: (_, __, ___) => const SizedBox(width: 60),
              ),
              Container(
                width: 1,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 14),
                color: Colors.white.withOpacity(0.18),
              ),
              Text(
                'AUTHORIZED AND\nREGULATED BY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(width: 14),
              Image.asset(
                'assets/images/CBN.png',
                height: 46,
                errorBuilder: (_, __, ___) => const SizedBox(width: 60),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // "YOUR DEPOSITS ARE PROTECTED"
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined,
                color: Colors.white.withOpacity(0.85), size: 14),
            const SizedBox(width: 5),
            Text(
              'YOUR DEPOSITS ARE ',
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const Text(
              'PROTECTED',
              style: TextStyle(
                color: Color(0xFF4EC97A),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // "Licensed by CBN • Insured by NDIC"
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline,
                color: const Color(0xFF4EC97A).withOpacity(0.85), size: 11),
            const SizedBox(width: 4),
            Text(
              'Licensed by CBN',
              style: TextStyle(
                color: const Color(0xFF4EC97A).withOpacity(0.85),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '  •  ',
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 11,
              ),
            ),
            Text(
              'Insured by NDIC',
              style: TextStyle(
                color: const Color(0xFF4EC97A).withOpacity(0.85),
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

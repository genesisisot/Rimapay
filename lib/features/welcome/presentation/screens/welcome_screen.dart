import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:rimapay/core/providers/app_state_provider.dart';

/// Usage:
/// WelcomeScreen(
///   onCreateAccount: () => print('create account'),
///   onLogin: () => print('login'),
///   onSkip: () => print('skip'),
/// );

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({
    super.key,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _Slide {
  final String id;
  final String imageAsset;
  final String title;
  final String subtitle;
  final String description;

  _Slide({
    required this.id,
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.description,
  });
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  final List<_Slide> slides = [
    _Slide(
      id: 'heritage',
      imageAsset: 'assets/images/Onboarding1.png',
      title: 'We are Indigenous,\nmade for us, by us',
      subtitle: 'Nigerian Heritage',
      description: 'Built by Nigerians, for Nigerians. Experience financial freedom rooted in our rich culture and unwavering spirit of excellence.',
    ),
    _Slide(
      id: 'market',
      imageAsset: 'assets/images/Onboarding2.png',
      title: 'RimaPay is\nfor Everyone',
      subtitle: 'Every Nigerian',
      description: 'From corporate professionals to market entrepreneurs - financial freedom for all Nigerians, everywhere.',
    ),
    _Slide(
      id: 'seamless',
      imageAsset: 'assets/images/Onboarding3.png',
      title: 'Payments Made\nSeamless',
      subtitle: 'Effortless Experience',
      description: 'Tap, pay, done. Experience the future of payments with instant, secure, and intuitive transactions.',
    ),
  ];

  // controllers
  late final PageController _pageController;
  late final AnimationController _progressController; // fills in 6s
  late final AnimationController _bgFadeController; // optional for bg crossfade
  Timer? _autoAdvanceTimer;

  int _currentIndex = 0;
  String _currentLanguage = 'EN';

  static const Duration slideDuration = Duration(seconds: 6);
  static const Curve slideCurve = Curves.easeInOut;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _progressController = AnimationController(
      vsync: this,
      duration: slideDuration,
    );
    _bgFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // start progress and auto-advance
    _startSlideTimer();
    _progressController.forward();

    // optional: ensure fade controller is complete initially
    _bgFadeController.value = 1.0;
  }

  void _startSlideTimer() {
    _autoAdvanceTimer?.cancel();
    _progressController.stop();
    _progressController.reset();
    _progressController.forward();

    _autoAdvanceTimer = Timer(slideDuration, () {
      final next = (_currentIndex + 1) % slides.length;
      _goToPage(next, animate: true);
    });
  }

  void _goToPage(int page, {bool animate = true}) {
    if (page == _currentIndex) return;
    _bgFadeController.reverse().then((_) => _bgFadeController.forward()); // small crossfade effect

    if (animate) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 600),
        curve: slideCurve,
      );
    } else {
      _pageController.jumpToPage(page);
    }

    setState(() {
      _currentIndex = page;
    });

    // reset progress timer
    _startSlideTimer();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    _progressController.dispose();
    _bgFadeController.dispose();
    super.dispose();
  }

  void _toggleLanguage() {
    setState(() {
      _currentLanguage = _currentLanguage == 'EN' ? 'HA' : 'EN';
    });
  }

  // Floating dot builder depending on slide
  List<Widget> _floatingDotsForSlide(int index, Size screen) {
    // use Positioned + ScaleTransition + FadeTransition
    final dots = <Widget>[];

    AnimationController pulseController({
      required int seconds,
    }) {
      final c = AnimationController(
        vsync: this,
        duration: Duration(seconds: seconds),
      )..repeat(reverse: true);
      return c;
    }

    // We'll create small controllers for each dot and dispose them when the widget tree disposes.
    // For simplicity and to avoid many controllers, we'll use TweenAnimationBuilder
    // which loops by rebuilding via Timer (we call setState in timer below).
    // But simpler: use animated implicit widgets - use TweenAnimationBuilder with onEnd loop.
    // We'll implement simple pulsing TweenAnimationBuilder widgets below.

    Widget pulsingDot({
      double top = 100,
      double left = 20,
      double right = double.nan,
      Color color = Colors.white,
      double size = 8,
      int durationSeconds = 4,
      double beginScale = 0.8,
      double endScale = 1.25,
      double opacity = 0.6,
    }) {
      return Positioned(
        top: top,
        left: left.isNaN ? null : left,
        right: right.isNaN ? null : right,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: beginScale, end: endScale),
          duration: Duration(seconds: durationSeconds),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
          onEnd: () {
            // reverse by rebuilding with swapped tween (use setState to flip)
            // Achieve repeating effect by toggling the tween endpoints in a micro state change.
            // For simplicity: call setState to trigger rebuild, causing TweenAnimationBuilder to restart.
            if (mounted) setState(() {});
          },
        ),
      );
    }

    final h = screen.height;
    switch (index) {
      case 0:
        dots.add(pulsingDot(top: h * 0.22, right: 40, color: Colors.greenAccent.withOpacity(0.55)));
        dots.add(pulsingDot(top: h * 0.33, left: 18, color: Colors.yellowAccent.withOpacity(0.5), size: 6));
        break;
      case 1:
        dots.add(pulsingDot(top: h * 0.22, left: 36, color: Colors.orangeAccent.withOpacity(0.45)));
        dots.add(pulsingDot(top: h * 0.33, right: 22, color: Colors.yellowAccent.withOpacity(0.45), size: 6));
        break;
      case 2:
        dots.add(pulsingDot(top: h * 0.22, right: 60, color: Colors.blueAccent.withOpacity(0.5)));
        dots.add(pulsingDot(top: h * 0.33, left: 40, color: Colors.purpleAccent.withOpacity(0.5)));
        break;
    }

    return dots;
  }

  Widget _buildBackgroundStack() {
    // We'll stack images for crossfade. Use AnimatedBuilder on _pageController to get fractional offset,
    // but simpler: use PageView with FadeTransition driven by _bgFadeController on top gradient.
    return PageView.builder(
      controller: _pageController,
      itemCount: slides.length,
      onPageChanged: (page) {
        setState(() {
          _currentIndex = page;
        });
        _startSlideTimer();
      },
      itemBuilder: (context, index) {
        final slide = slides[index];
        return Stack(
          fit: StackFit.expand,
          children: [
            // Background image with fade/fallback
            // Use FadeInImage to show a placeholder if asset is not immediately available.
            // Placeholder: transparent image or local small image.
            Positioned.fill(
              child: FadeInImage(
                placeholder: const AssetImage('assets/images/Onboarding1.png'),
                image: AssetImage(slide.imageAsset),
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 800),
                fadeOutDuration: const Duration(milliseconds: 200),
              ),
            ),

            // layered gradients for legibility (approximation of your Netflix-style)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromRGBO(0, 0, 0, 0.3), // 0%
                      Color.fromRGBO(0, 0, 0, 0.45), // 20%
                      Color.fromRGBO(0, 0, 0, 0.75), // 60%
                      Color.fromRGBO(0, 0, 0, 0.92), // 100%
                    ],
                    stops: [0.0, 0.2, 0.6, 1.0],
                  ),
                ),
              ),
            ),

            // radial overlay near bottom to highlight text area
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, 1.0),
                    radius: 1.1,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.35),
                      Colors.black.withOpacity(0.1),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final slide = slides[_currentIndex];
    final screen = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background PageView with images & overlays
          _buildBackgroundStack(),

          // Floating dots per-slide
          ..._floatingDotsForSlide(_currentIndex, screen),

          // Foreground content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      // Logo + title
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          shadows: [Shadow(blurRadius: 4.0, color: Colors.black)],
                        ),
                      ),
                      const Spacer(),

                      // Language toggle
                      GestureDetector(
                        onTap: _toggleLanguage,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.language, color: Colors.white, size: 18),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.white,
                                child: Text(
                                  _currentLanguage,
                                  style: const TextStyle(
                                    color: Color(0xFF00B252),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Indicators
                      Row(
                        children: List.generate(slides.length, (i) {
                          final selected = i == _currentIndex;
                          return GestureDetector(
                            onTap: () => _goToPage(i, animate: true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              height: 8,
                              width: selected ? 28 : 8,
                              decoration: BoxDecoration(
                                color: selected ? Colors.white : Colors.white38,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(width: 12),

                      // Skip
                      InkWell(
                        onTap: () {
                          _goToPage(2, animate: true);
                        },
                        child: const Text(
                          'Skip',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Animated hero text area (fade/slide)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 700),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: Padding(
                    key: ValueKey(slide.id),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Title: keep break lines with RichText
                        Text(
                          slide.title,
                          textAlign: TextAlign.start,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Subtitle pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            slide.subtitle,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Description
                        SizedBox(
                          width: screen.width * 0.78,
                          child: Text(
                            slide.description,
                            textAlign: TextAlign.start,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            context.pushNamed('auth', queryParameters: {"mode": 'login'});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Text(
                              'Sign In',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            context.pushNamed('auth', queryParameters: {"mode": 'signup'});
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00B252),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 10,
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Branding placeholder (CBN/NDIC)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    margin: EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.asset(
                      "assets/images/NI.jpeg",
                      width: double.infinity,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Text(
                        "NDIC",
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Footer text
                Padding(
                  padding: const EdgeInsets.only(bottom: 22),
                  child: Text(
                    'By continuing, you agree to our Terms of Service and Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Progress bar bottom (fills over slideDuration)
          Positioned(
            bottom: 8,
            left: 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _progressController.value,
                    minHeight: 4,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00B252)),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple branding placeholder for CBN / NDIC logos
class CBNNDICBranding extends StatelessWidget {
  const CBNNDICBranding({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // replace these with your real assets
        _smallBrand('assets/b39136286f74d1d584407f38c9a71afdd287aec4.png', 'CBN'),
        const SizedBox(width: 12),
        _smallBrand('assets/620bde3872bcbf74c5f18aa6510617bd6ce22cfb.png', 'NDIC'),
      ],
    );
  }

  Widget _smallBrand(String asset, String alt) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Image.asset(
        asset,
        width: 48,
        height: 24,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Text(
          alt,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ),
    );
  }
}

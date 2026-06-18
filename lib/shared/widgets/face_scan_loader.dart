import 'package:flutter/material.dart';

/// Animated face-scan loader with expanding pulse rings, circular progress,
/// and a face icon — same design as the onboarding face-verification overlay.
class FaceScanLoader extends StatefulWidget {
  const FaceScanLoader({super.key});

  @override
  State<FaceScanLoader> createState() => _FaceScanLoaderState();
}

class _FaceScanLoaderState extends State<FaceScanLoader>
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
              // Expanding pulse rings
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
                child: const Icon(Icons.face_retouching_natural,
                    color: green, size: 30),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Gold‑bordered oval overlay used as a face‑positioning guide for selfie capture.
/// Draws a semi‑transparent dim layer over the whole camera area, cuts out a
/// clear oval in the centre, and outlines it with a gold stroke — identical to
/// the onboarding personal‑account flow.
class OvalOverlayPainter extends CustomPainter {
  final Color color;
  const OvalOverlayPainter({required this.color});

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
  bool shouldRepaint(OvalOverlayPainter old) => old.color != color;
}

/// Full-screen "verifying" overlay shown while a selfie is being checked.
/// Blocks interaction and reassures the user to wait.
class FaceVerifyOverlay extends StatelessWidget {
  const FaceVerifyOverlay({super.key});

  @override
  Widget build(BuildContext context) {
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
              FaceScanLoader(),
              SizedBox(height: 22),
              Text(
                'Verifying your face',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827)),
              ),
              SizedBox(height: 8),
              Text(
                'Hold on a moment — this can take a few seconds.\nPlease don\'t close or refresh the page.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

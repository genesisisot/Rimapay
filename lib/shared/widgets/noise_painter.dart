import 'dart:math';
import 'package:flutter/material.dart';

/// A CustomPainter that renders a subtle noise/grain texture.
/// Used on the welcome and home hero sections to match the access jjoobb design.
class NoisePainter extends CustomPainter {
  final double opacity;
  final int seed;

  NoisePainter({this.opacity = 0.06, this.seed = 42});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);
    final paint = Paint()..color = Colors.white.withOpacity(opacity);

    // Draw ~2000 tiny dots randomly across the surface
    for (int i = 0; i < 2000; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 1.0 + 0.3;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(NoisePainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.seed != seed;
}

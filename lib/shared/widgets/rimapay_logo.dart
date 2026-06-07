import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class RimapayLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit fit;
  const RimapayLogo({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/mild.png',
      width: width,
      height: height,
      fit: fit,

      errorBuilder: (_, __, ___) => Icon(
        Icons.account_balance,
        color: AppColors.goldPrimary,
        size: (width ?? 48) > 64 ? 80 : (width ?? 48),
      ),
    );
  }
}

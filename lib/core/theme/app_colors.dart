import 'package:flutter/material.dart';

class AppColors {
  // RIMA MFB Forest Green Primary Palette
  static const Color primary50  = Color(0xFFE8F0EB);
  static const Color primary100 = Color(0xFFD4E6DA);
  static const Color primary200 = Color(0xFFA8CCB5);
  static const Color primary300 = Color(0xFF7CB391);
  static const Color primary400 = Color(0xFF4D9A6E);
  static const Color primary500 = Color(0xFF166C46); // Main brand color
  static const Color primary600 = Color(0xFF0E5C37);
  static const Color primary700 = Color(0xFF0B4F2F);
  static const Color primary800 = Color(0xFF09422A);
  static const Color primary900 = Color(0xFF073D25);

  // Named dark background constants
  static const Color background900 = Color(0xFF073D25);
  static const Color background800 = Color(0xFF0B4F2F);
  static const Color background700 = Color(0xFF0E5C37);

  // Gold Palette — RIMA MFB brand accent / CTA color
  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldDark    = Color(0xFFBF9B30);
  static const Color goldLight   = Color(0xFFE8C84A);
  static const Color goldShadow  = Color(0xFFD3AF37);

  // Accent Colors
  static const Color accentBlue   = Color(0xFF3B82F6);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPink   = Color(0xFFEC4899);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentYellow = Color(0xFFEAB308);

  // Sophisticated Neutrals
  static const Color neutral0   = Color(0xFFFFFFFF);
  static const Color neutral50  = Color(0xFFFAFBFC);
  static const Color neutral100 = Color(0xFFF4F6F8);
  static const Color neutral200 = Color(0xFFE4E7EC);
  static const Color neutral300 = Color(0xFFD0D5DD);
  static const Color neutral400 = Color(0xFF98A2B3);
  static const Color neutral500 = Color(0xFF667085);
  static const Color neutral600 = Color(0xFF475467);
  static const Color neutral700 = Color(0xFF344054);
  static const Color neutral800 = Color(0xFF1D2939);
  static const Color neutral900 = Color(0xFF101828);
  static const Color neutral950 = Color(0xFF0C111D);

  // Utility
  static const Color offWhite  = Color(0xFFF2F2E8);
  static const Color paleGreen = Color(0xFFF2F7F3);
  static const Color mutedGray = Color(0xFFCFCFC5);

  // Status Colors
  static const Color success    = Color(0xFF166C46);
  static const Color success500 = Color(0xFF166C46);
  static const Color warning    = Color(0xFFEAB308);
  static const Color warning500 = Color(0xFFEAB308);
  static const Color error      = Color(0xFFD33B31);
  static const Color error500   = Color(0xFFD33B31);
  static const Color info       = Color(0xFF3B82F6);
  static const Color info500    = Color(0xFF3B82F6);

  // Glass Effect Colors
  static const Color glassBackground = Color(0x1AFFFFFF);
  static const Color glassBorder     = Color(0x33FFFFFF);

  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary400, primary600, primary800],
    stops: [0.0, 0.5, 1.0],
  );

  // Gold gradient — used for all primary CTAs
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [goldLight, goldPrimary, goldDark],
  );

  static const LinearGradient darkBgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [background900, background800, background700],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentBlue, accentPurple],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentPink, accentOrange],
  );

  // Shadow Colors
  static Color shadowColor    = neutral900.withOpacity(0.1);
  static Color floatingShadow = primary500.withOpacity(0.15);
  static Color glowShadow     = primary500.withOpacity(0.3);
  static Color goldGlow       = goldPrimary.withOpacity(0.3);

  // Tier Colors
  static const Color tier0     = accentYellow;
  static const Color tier1     = accentBlue;
  static const Color tier2     = accentPurple;
  static const Color tier3Gold = Color(0xFFD4AF37);

  // BoxShadow Presets
  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: neutral900.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: neutral900.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: neutral900.withOpacity(0.1),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // Service Category Colors
  static const Map<String, Color> serviceColors = {
    'airtime':     accentPurple,
    'data':        accentOrange,
    'electricity': accentYellow,
    'cable':       accentPink,
    'loans':       primary500,
    'transfer':    accentBlue,
    'bills':       neutral500,
  };
}

import 'package:flutter/material.dart';

class AppColors {
  // RimaPay Green Primary Palette
  static const Color primary50 = Color(0xFFE6F9EE);

  static const Color primary100 = Color(0xFFE0F6EB); // very light tint
  static const Color primary200 = Color(0xFFB3E9CC); // soft minty green
  static const Color primary300 = Color(0xFF80DDAA); // lighter brand green

  static const Color primary400 = Color(0xFF4DD978);
  static const Color primary500 = Color(0xFF00B252); // Main brand color
  static const Color primary600 = Color(0xFF00A047);
  static const Color primary700 = Color(0xFF008A3C);
  static const Color primary800 = Color(0xFF007432);
  static const Color primary900 = Color(0xFF005E27);

  // Accent Colors
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentYellow = Color(0xFFEAB308);

  // Sophisticated Neutrals
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFFAFBFC);
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

  // Status Colors
  static const Color success = Color(0xFF00B252);
  static const Color success500 = Color(0xFF00B252); // Added for consistency
  static const Color warning = Color(0xFFEAB308);
  static const Color warning500 = Color(0xFFEAB308); // Added for consistency
  static const Color error = Color(0xFFEF4444);
  static const Color error500 = Color(0xFFEF4444); // Added for consistency
  static const Color info = Color(0xFF3B82F6);
  static const Color info500 = Color(0xFF3B82F6); // Added for consistency

  // Glass Effect Colors
  static const Color glassBackground = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary400, primary600, primary800],
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
  static Color shadowColor = neutral900.withOpacity(0.1);
  static Color floatingShadow = primary500.withOpacity(0.15);
  static Color glowShadow = primary500.withOpacity(0.3);

  // Tier Colors
  static const Color tier0 = accentYellow;
  static const Color tier1 = accentBlue;
  static const Color tier2 = accentPurple;
  static const Color tier3Gold = Color(0xFFFFD700);

  // BoxShadow Presets
  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: neutral900.withOpacity(0.05),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: neutral900.withOpacity(0.08),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: neutral900.withOpacity(0.1),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  // Service Category Colors
  static const Map<String, Color> serviceColors = {
    'airtime': accentPurple,
    'data': accentOrange,
    'electricity': accentYellow,
    'cable': accentPink,
    'loans': primary500,
    'transfer': accentBlue,
    'bills': neutral500,
  };
}
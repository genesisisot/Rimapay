import 'package:flutter/material.dart';

class AppSpacing {
  // Base spacing unit
  static const double unit = 4.0;
  
  // Spacing scale
  static const double xs = unit * 1; // 4px
  static const double sm = unit * 2; // 8px
  static const double md = unit * 3; // 12px
  static const double lg = unit * 4; // 16px
  static const double xl = unit * 5; // 20px
  static const double xxl = unit * 6; // 24px
  static const double xxxl = unit * 8; // 32px
  
  // Additional spacing constants used in SettingsScreen
  static const double space8 = 8.0; // Missing constant from SettingsScreen
  
  // Mobile-optimized spacing
  static const double mobile1 = 6.0;
  static const double mobile2 = 10.0;
  static const double mobile3 = 14.0;
  static const double mobile4 = 18.0;
  static const double mobile5 = 22.0;
  static const double mobile6 = 28.0;
  
  // Container spacing
  static const double containerPadding = lg;
  static const double sectionSpacing = xxl;
  static const double cardPadding = lg;
  
  // Element spacing
  static const double buttonPadding = md;
  static const double inputPadding = md;
  static const double listItemSpacing = sm;
  
  // Safe area constants
  static const double safeAreaTop = 44.0;
  static const double safeAreaBottom = 84.0;
  static const double bottomNavHeight = 72.0;
  
  // Border radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;
  static const double radiusFull = 999.0;
  
  // Responsive spacing based on screen width
  static double responsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 320) return 8.0;
    if (screenWidth < 375) return 12.0;
    if (screenWidth < 430) return 16.0;
    return 20.0;
  }
  
  static double responsiveGap(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 320) return 6.0;
    if (screenWidth < 375) return 8.0;
    if (screenWidth < 430) return 12.0;
    return 16.0;
  }
  
  static double responsiveCardPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 320) return 10.0;
    if (screenWidth < 375) return 12.0;
    if (screenWidth < 430) return 16.0;
    return 20.0;
  }
  
  // Edge insets for common patterns
  static EdgeInsets get containerInsets => const EdgeInsets.all(containerPadding);
  static EdgeInsets get cardInsets => const EdgeInsets.all(cardPadding);
  static EdgeInsets get buttonInsets => const EdgeInsets.symmetric(
    horizontal: lg, 
    vertical: md,
  );
  
  static EdgeInsets responsiveContainerInsets(BuildContext context) {
    final padding = responsivePadding(context);
    return EdgeInsets.all(padding);
  }
  
  static EdgeInsets responsiveHorizontalInsets(BuildContext context) {
    final padding = responsivePadding(context);
    return EdgeInsets.symmetric(horizontal: padding);
  }
  
  // Animation durations
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  
  // Common sizes
  static const double buttonHeight = 48.0;
  static const double inputHeight = 48.0;
  static const double iconSize = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double avatarSize = 40.0;
  static const double logoSize = 64.0;
  
  // Glass effect constants
  static const double blurRadius = 20.0;
  static const double glassBorderWidth = 1.0;
  
  // Shadow constants
  static const double shadowBlurRadius = 8.0;
  static const double shadowSpreadRadius = 0.0;
  static const Offset shadowOffset = Offset(0, 2);
}
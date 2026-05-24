import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.fontFamily,

      // Explicit divider color so Theme.of(context).dividerColor is always correct
      dividerColor: AppColors.neutral200,

      // Color scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary500,
        primaryContainer: AppColors.primary400,
        secondary: AppColors.accentBlue,
        secondaryContainer: AppColors.neutral100,
        surface: AppColors.neutral0,
        error: AppColors.error,
        onPrimary: AppColors.neutral0,
        onSecondary: AppColors.neutral0,
        onSurface: AppColors.neutral900,
        onError: AppColors.neutral0,
        outlineVariant: AppColors.neutral200,
      ),
      
      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.neutral0,
        foregroundColor: AppColors.neutral900,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: AppTextStyles.heading3,
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary500,
          foregroundColor: AppColors.neutral0,
          textStyle: AppTextStyles.buttonMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          elevation: 2,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          padding: AppSpacing.buttonInsets,
        ),
      ),
      
      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary500,
          textStyle: AppTextStyles.buttonMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          padding: AppSpacing.buttonInsets,
        ),
      ),
      
      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary500,
          backgroundColor: AppColors.neutral0,
          textStyle: AppTextStyles.buttonMedium,
          side: const BorderSide(color: AppColors.primary500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          padding: AppSpacing.buttonInsets,
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.neutral200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.neutral200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary500, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
        hintStyle: const TextStyle(
          fontFamily: 'Effra',
          fontSize: 14,
          color: AppColors.neutral400,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Effra',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.neutral600,
        ),
      ),
      
      // Card theme
      cardTheme: CardThemeData(
        color: AppColors.neutral0,
        elevation: 2,
        shadowColor: AppColors.shadowColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        margin: const EdgeInsets.all(AppSpacing.sm),
      ),
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.neutral0,
        selectedItemColor: AppColors.primary500,
        unselectedItemColor: AppColors.neutral400,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTextStyles.labelSmall,
        unselectedLabelStyle: AppTextStyles.labelSmall,
      ),
      
      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary500,
        foregroundColor: AppColors.neutral0,
        elevation: 4,
        shape: CircleBorder(),
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.neutral100,
        selectedColor: AppColors.primary400,
        labelStyle: AppTextStyles.labelMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),
      
      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary500;
          }
          return AppColors.neutral300;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary200;
          }
          return AppColors.neutral200;
        }),
      ),
      
      // Slider theme
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primary500,
        inactiveTrackColor: AppColors.neutral200,
        thumbColor: AppColors.primary500,
        overlayColor: AppColors.primary100,
      ),
      
      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary500,
        linearTrackColor: AppColors.neutral200,
        circularTrackColor: AppColors.neutral200,
      ),
      
      // Divider theme
      dividerTheme: const DividerThemeData(
        color: AppColors.neutral200,
        thickness: 1,
        space: 1,
      ),
      
      // Text theme
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.display1,
        displayMedium: AppTextStyles.display2,
        headlineLarge: AppTextStyles.heading1,
        headlineMedium: AppTextStyles.heading2,
        headlineSmall: AppTextStyles.heading3,
        titleLarge: AppTextStyles.heading4,
        titleMedium: AppTextStyles.labelLarge,
        titleSmall: AppTextStyles.labelMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),
    );
  }
  
  // Dark mode palette constants
  static const Color _darkBg       = Color(0xFF0F1117); // page background
  static const Color _darkSurface  = Color(0xFF1A1F2E); // cards, sheets
  static const Color _darkSurface2 = Color(0xFF242938); // elevated cards
  static const Color _darkBorder   = Color(0xFF2D3348); // dividers, borders
  static const Color _darkText     = Color(0xFFE8EAF0); // primary text
  static const Color _darkSubtext  = Color(0xFF8892A4); // secondary text
  static const Color _darkInput    = Color(0xFF1A1F2E); // input fill

  static ThemeData get darkTheme {
    return lightTheme.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBg,
      dividerColor: _darkBorder,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary400,
        primaryContainer: AppColors.primary800,
        secondary: AppColors.accentBlue,
        secondaryContainer: Color(0xFF1A1F2E),
        surface: _darkBg,
        surfaceContainerHighest: _darkSurface2,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: _darkText,
        onError: Colors.white,
        outline: _darkBorder,
        outlineVariant: _darkBorder,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: _darkSurface,
        foregroundColor: _darkText,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: AppTextStyles.heading3,
      ),

      cardTheme: CardThemeData(
        color: _darkSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: const BorderSide(color: _darkBorder),
        ),
        margin: const EdgeInsets.all(AppSpacing.sm),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary400, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
        hintStyle: const TextStyle(
          fontFamily: 'Effra',
          fontSize: 14,
          color: _darkSubtext,
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Effra',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _darkSubtext,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _darkSurface,
        selectedItemColor: AppColors.primary400,
        unselectedItemColor: _darkSubtext,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTextStyles.labelSmall,
        unselectedLabelStyle: AppTextStyles.labelSmall,
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: _darkSurface,
        modalBackgroundColor: _darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: _darkSurface,
        titleTextStyle: TextStyle(
          color: _darkText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: 'Effra',
        ),
        contentTextStyle: TextStyle(
          color: _darkSubtext,
          fontSize: 14,
          fontFamily: 'Effra',
        ),
      ),

      drawerTheme: const DrawerThemeData(
        backgroundColor: _darkSurface,
      ),

      dividerTheme: const DividerThemeData(
        color: _darkBorder,
        thickness: 1,
        space: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: _darkSurface2,
        selectedColor: AppColors.primary800,
        labelStyle: AppTextStyles.labelMedium.copyWith(color: _darkText),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary400;
          return _darkSubtext;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary800;
          return _darkSurface2;
        }),
      ),

      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: _darkText,
        iconColor: _darkSubtext,
      ),

      textTheme: const TextTheme(
        displayLarge: AppTextStyles.display1,
        displayMedium: AppTextStyles.display2,
        headlineLarge: AppTextStyles.heading1,
        headlineMedium: AppTextStyles.heading2,
        headlineSmall: AppTextStyles.heading3,
        titleLarge: AppTextStyles.heading4,
        titleMedium: AppTextStyles.labelLarge,
        titleSmall: AppTextStyles.labelMedium,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ).apply(
        bodyColor: _darkText,
        displayColor: _darkText,
      ),
    );
  }
}
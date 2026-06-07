import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Riverpod provider — true = dark mode, false = light mode
final darkModeProvider = StateProvider<bool>((ref) => false);

/// Proper theme provider with persistence and system-mode support
final themeProvider = ChangeNotifierProvider<ThemeProvider>((ref) => ThemeProvider());

enum AppThemeMode {
  light,
  dark,
  system,
}

class ThemeProvider extends ChangeNotifier {
  static const String _themePreferenceKey = 'theme_mode';
  
  AppThemeMode _themeMode = AppThemeMode.light;
  bool _isInitialized = false;
  Brightness _systemBrightness = Brightness.light;

  AppThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;
  
  // Get the actual ThemeMode for MaterialApp
  ThemeMode get materialThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  // Updated isDarkMode getter to properly handle all cases
  bool get isDarkMode {
    switch (_themeMode) {
      case AppThemeMode.dark:
        return true;
      case AppThemeMode.light:
        return false;
      case AppThemeMode.system:
        return _systemBrightness == Brightness.dark;
    }
  }

  bool get isLightMode => _themeMode == AppThemeMode.light;
  bool get isSystemMode => _themeMode == AppThemeMode.system;

  // Update system brightness (called from main app when system theme changes)
  void updateSystemBrightness(Brightness brightness) {
    if (_systemBrightness != brightness) {
      _systemBrightness = brightness;
      // Only notify if we're in system mode
      if (_themeMode == AppThemeMode.system) {
        notifyListeners();
      }
    }
  }

  // Initialize theme from storage
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themePreferenceKey);
      
      if (savedTheme != null) {
        switch (savedTheme) {
          case 'light':
            _themeMode = AppThemeMode.light;
            break;
          case 'dark':
            _themeMode = AppThemeMode.dark;
            break;
          case 'system':
            _themeMode = AppThemeMode.system;
            break;
          default:
            _themeMode = AppThemeMode.light;
        }
      } else {
        _themeMode = AppThemeMode.system;
      }
    } catch (e) {
      _themeMode = AppThemeMode.system;
      debugPrint('Error loading theme preference: $e');
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  // Set theme mode
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePreferenceKey, mode.name);
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  // Toggle between light and dark (ignoring system)
  Future<void> toggleTheme() async {
    if (_themeMode == AppThemeMode.light || 
        (_themeMode == AppThemeMode.system && _systemBrightness == Brightness.light)) {
      await setThemeMode(AppThemeMode.dark);
    } else {
      await setThemeMode(AppThemeMode.light);
    }
  }

  // Enable dark mode
  Future<void> enableDarkMode() async {
    await setThemeMode(AppThemeMode.dark);
  }

  // Enable light mode
  Future<void> enableLightMode() async {
    await setThemeMode(AppThemeMode.light);
  }

  // Enable system mode
  Future<void> enableSystemMode() async {
    await setThemeMode(AppThemeMode.system);
  }

  // Reset to default (system)
  Future<void> resetToDefault() async {
    await setThemeMode(AppThemeMode.system);
  }

  // Check if current theme matches system theme
  bool isCurrentThemeSystemDefault(BuildContext context) {
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    updateSystemBrightness(systemBrightness);
    
    if (_themeMode == AppThemeMode.system) {
      return true;
    } else if (_themeMode == AppThemeMode.dark && systemBrightness == Brightness.dark) {
      return true;
    } else if (_themeMode == AppThemeMode.light && systemBrightness == Brightness.light) {
      return true;
    }
    
    return false;
  }

  // Get current effective brightness
  Brightness getCurrentBrightness(BuildContext context) {
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    updateSystemBrightness(systemBrightness);
    
    switch (_themeMode) {
      case AppThemeMode.light:
        return Brightness.light;
      case AppThemeMode.dark:
        return Brightness.dark;
      case AppThemeMode.system:
        return systemBrightness;
    }
  }

  // Helper method to get theme name for UI display
  String getThemeName() {
    switch (_themeMode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }

  // Helper method to get theme description
  String getThemeDescription() {
    switch (_themeMode) {
      case AppThemeMode.light:
        return 'Always use light theme';
      case AppThemeMode.dark:
        return 'Always use dark theme';
      case AppThemeMode.system:
        return 'Follow system settings';
    }
  }

  // Get current effective theme description (what's actually showing)
  String getCurrentThemeDescription(BuildContext context) {
    final systemBrightness = MediaQuery.of(context).platformBrightness;
    updateSystemBrightness(systemBrightness);
    
    if (_themeMode == AppThemeMode.system) {
      return systemBrightness == Brightness.dark 
          ? 'System (Dark)' 
          : 'System (Light)';
    }
    return getThemeDescription();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
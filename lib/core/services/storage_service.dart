import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';

class StorageService {
  static const String _userKey = 'rimapay_user';
  static const String _transactionsKey = 'rimapay_transactions';
  static const String _beneficiariesKey = 'rimapay_beneficiaries';
  static const String _settingsKey = 'rimapay_settings';
  static const String _pinKey = 'rimapay_pin';
  static const String _languageKey = 'rimapay_language';
  static const String _themeKey = 'rimapay_theme';
  static const String _biometricEnabledKey = 'rimapay_biometric_enabled';
  static const String _accessTokenKey = 'rimapay_access_token';
  static const String _refreshTokenKey = 'rimapay_refresh_token';

  static SharedPreferences? _prefs;
  
  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  static SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('StorageService not initialized. Call initialize() first.');
    }
    return _prefs!;
  }
  
  // User Management
  static Future<void> saveUser(User user) async {
    await initialize();
    final userJson = {
      'id': user.id,
      'email': user.email,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'phoneNumber': user.phoneNumber,
      'accountType': user.accountType.name,
      'tierLevel': user.tierLevel.name,
      'isVerified': user.isVerified,
      'bvnVerified': user.bvnVerified,
      'balance': user.balance,
      'profileImageUrl': user.profileImageUrl,
    };
    await prefs.setString(_userKey, jsonEncode(userJson));
  }
  
  static Future<User?> getUser() async {
    await initialize();
    final userString = prefs.getString(_userKey);
    if (userString == null) return null;
    
    try {
      final userJson = jsonDecode(userString) as Map<String, dynamic>;
      return User(
        id: userJson['id'],
        email: userJson['email'],
        firstName: userJson['firstName'],
        lastName: userJson['lastName'],
        phoneNumber: userJson['phoneNumber'],
        accountType: AccountType.values.firstWhere(
          (type) => type.name == userJson['accountType'],
          orElse: () => AccountType.basic,
        ),
        tierLevel: TierLevel.values.firstWhere(
          (tier) => tier.name == userJson['tierLevel'],
          orElse: () => TierLevel.tier0,
        ),
        isVerified: userJson['isVerified'] ?? false,
        bvnVerified: userJson['bvnVerified'] ?? false,
        balance: (userJson['balance'] ?? 0.0).toDouble(),
        profileImageUrl: userJson['profileImageUrl'],
      );
    } catch (e) {
      debugPrint('Error parsing user data: $e');
      return null;
    }
  }
  
  static Future<void> clearUser() async {
    await initialize();
    await prefs.remove(_userKey);
  }

  // Auth Token Management (used by DioClient for Bearer auth + 401 refresh)
  static Future<void> saveTokens({
    required String? accessToken,
    required String? refreshToken,
  }) async {
    await initialize();
    if (accessToken != null && accessToken.isNotEmpty) {
      await prefs.setString(_accessTokenKey, accessToken);
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
  }

  static Future<String?> getAccessToken() async {
    await initialize();
    return prefs.getString(_accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    await initialize();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<void> clearTokens() async {
    await initialize();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }
  
  // Transaction Management
  static Future<void> saveTransactions(List<Map<String, dynamic>> transactions) async {
    await initialize();
    await prefs.setString(_transactionsKey, jsonEncode(transactions));
  }
  
  static Future<List<Map<String, dynamic>>> getTransactions() async {
    await initialize();
    final transactionsString = prefs.getString(_transactionsKey);
    if (transactionsString == null) return [];
    
    try {
      final List<dynamic> transactionsList = jsonDecode(transactionsString);
      return transactionsList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error parsing transactions: $e');
      return [];
    }
  }
  
  // Beneficiaries Management
  static Future<void> saveBeneficiaries(List<Map<String, dynamic>> beneficiaries) async {
    await initialize();
    await prefs.setString(_beneficiariesKey, jsonEncode(beneficiaries));
  }
  
  static Future<List<Map<String, dynamic>>> getBeneficiaries() async {
    await initialize();
    final beneficiariesString = prefs.getString(_beneficiariesKey);
    if (beneficiariesString == null) return [];
    
    try {
      final List<dynamic> beneficiariesList = jsonDecode(beneficiariesString);
      return beneficiariesList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error parsing beneficiaries: $e');
      return [];
    }
  }
  
  // Settings Management
  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    await initialize();
    await prefs.setString(_settingsKey, jsonEncode(settings));
  }
  
  static Future<Map<String, dynamic>> getSettings() async {
    await initialize();
    final settingsString = prefs.getString(_settingsKey);
    if (settingsString == null) return {};
    
    try {
      return jsonDecode(settingsString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error parsing settings: $e');
      return {};
    }
  }
  
  // PIN Management (encrypted storage recommended in production)
  static Future<void> savePin(String pin) async {
    await initialize();
    // In production, this should be encrypted
    await prefs.setString(_pinKey, pin);
  }
  
  static Future<String?> getPin() async {
    await initialize();
    return prefs.getString(_pinKey);
  }
  
  static Future<bool> verifyPin(String enteredPin) async {
    final savedPin = await getPin();
    return savedPin == enteredPin;
  }
  
  static Future<void> clearPin() async {
    await initialize();
    await prefs.remove(_pinKey);
  }
  
  // Language Preference
  static Future<void> saveLanguage(String languageCode) async {
    await initialize();
    await prefs.setString(_languageKey, languageCode);
  }
  
  static Future<String> getLanguage() async {
    await initialize();
    return prefs.getString(_languageKey) ?? 'en';
  }
  
  // Theme Preference
  static Future<void> saveTheme(String theme) async {
    await initialize();
    await prefs.setString(_themeKey, theme);
  }
  
  static Future<String> getTheme() async {
    await initialize();
    return prefs.getString(_themeKey) ?? 'light';
  }
  
  // Biometric Settings
  static Future<void> setBiometricEnabled(bool enabled) async {
    await initialize();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }
  
  static Future<bool> isBiometricEnabled() async {
    await initialize();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }
  
  // First Time User Check
  static Future<bool> isFirstTimeUser() async {
    await initialize();
    return prefs.getBool('first_time_user') ?? true;
  }
  
  static Future<void> setFirstTimeUser(bool isFirstTime) async {
    await initialize();
    await prefs.setBool('first_time_user', isFirstTime);
  }
  
  // Clear All Data
  static Future<void> clearAllData() async {
    await initialize();
    await prefs.clear();
  }
  
  // Backup and Restore
  static Future<Map<String, dynamic>> exportUserData() async {
    await initialize();
    final user = await getUser();
    final transactions = await getTransactions();
    final beneficiaries = await getBeneficiaries();
    final settings = await getSettings();
    
    return {
      'user': user?.copyWith().toString(),
      'transactions': transactions,
      'beneficiaries': beneficiaries,
      'settings': settings,
      'exportDate': DateTime.now().toIso8601String(),
    };
  }
  
  static Future<bool> importUserData(Map<String, dynamic> data) async {
    try {
      await initialize();
      
      // Import transactions
      if (data['transactions'] != null) {
        await saveTransactions(List<Map<String, dynamic>>.from(data['transactions']));
      }
      
      // Import beneficiaries
      if (data['beneficiaries'] != null) {
        await saveBeneficiaries(List<Map<String, dynamic>>.from(data['beneficiaries']));
      }
      
      // Import settings
      if (data['settings'] != null) {
        await saveSettings(Map<String, dynamic>.from(data['settings']));
      }
      
      return true;
    } catch (e) {
      debugPrint('Error importing user data: $e');
      return false;
    }
  }
}
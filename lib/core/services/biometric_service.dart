import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

// Auth result enum to match what AuthScreen expects
enum AuthResult {
  success,
  failure,
  cancelled,
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  error,
}

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static bool _isInitialized = false;

  // Initialize biometric service
  static Future<void> initialize() async {
    _isInitialized = true;
  }

  // Check if biometric authentication is available (method used by AuthScreen)
  static Future<bool> isAvailable() async {
    try {
      if (!_isInitialized) await initialize();
      
      final bool isAvailable = await _localAuth.isDeviceSupported();
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      
      return isAvailable && canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  // Authenticate for transactions
  static Future<AuthResult> authenticateForTransaction({
    required double amount,
    required String recipient,
  }) async {
    // Format amount for display
    String formattedAmount = amount.toStringAsFixed(2);
    
    // Truncate recipient if too long for better UI
    String displayRecipient = recipient.length > 20 
        ? '${recipient.substring(0, 17)}...' 
        : recipient;
    
    String reason = 'Authenticate to send ₦$formattedAmount to $displayRecipient';
    
    return await authenticateWithResult(reason);
  }

  // Check if biometric is enabled/enrolled (method used by AuthScreen)
  static Future<bool> isEnabled() async {
    try {
      if (!_isInitialized) await initialize();
      
      final List<BiometricType> availableBiometrics = await getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Authenticate for login (method used by AuthScreen)
  static Future<AuthResult> authenticateForLogin() async {
    return await authenticateWithResult('Authenticate to access your RimaPay account');
  }

  // Get auth result message (method used by AuthScreen)
  static String getAuthResultMessage(AuthResult result) {
    switch (result) {
      case AuthResult.success:
        return 'Authentication successful';
      case AuthResult.failure:
        return 'Authentication failed';
      case AuthResult.cancelled:
        return 'Authentication cancelled';
      case AuthResult.notAvailable:
        return 'Biometric authentication is not available';
      case AuthResult.notEnrolled:
        return 'No biometric credentials are enrolled';
      case AuthResult.lockedOut:
        return 'Too many failed attempts. Please try again later';
      case AuthResult.permanentlyLockedOut:
        return 'Biometric authentication is permanently disabled';
      case AuthResult.error:
        return 'An error occurred during authentication';
    }
  }

  // Internal method to authenticate and return AuthResult
  static Future<AuthResult> authenticateWithResult(String reason) async {
    try {
      if (!_isInitialized) await initialize();
      
      if (!await isAvailable()) {
        return AuthResult.notAvailable;
      }

      if (!await isEnabled()) {
        return AuthResult.notEnrolled;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      return didAuthenticate ? AuthResult.success : AuthResult.failure;
    } on PlatformException catch (e) {
      switch (e.code) {
        case auth_error.notAvailable:
          return AuthResult.notAvailable;
        case auth_error.notEnrolled:
          return AuthResult.notEnrolled;
        case auth_error.lockedOut:
          return AuthResult.lockedOut;
        case auth_error.permanentlyLockedOut:
          return AuthResult.permanentlyLockedOut;
        // case auth_error.userCancel:
        //   return AuthResult.cancelled;
        case auth_error.biometricOnlyNotSupported:
          return AuthResult.notAvailable;
        // case auth_error.deviceNotSupported:
        //   return AuthResult.notAvailable;
        default:
          return AuthResult.error;
      }
    } catch (e) {
      return AuthResult.error;
    }
  }

  // Legacy method for backward compatibility
  static Future<bool> isBiometricAvailable() async {
    return await isAvailable();
  }

  // Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      if (!_isInitialized) await initialize();
      
      final List<BiometricType> biometrics = await _localAuth.getAvailableBiometrics();
      
      // Filter out unsupported types and return valid ones
      return biometrics.where((type) => 
        type == BiometricType.fingerprint ||
        type == BiometricType.face ||
        type == BiometricType.iris ||
        type == BiometricType.strong
      ).toList();
    } catch (e) {
      return [];
    }
  }

  // Authenticate using biometric (legacy method)
  static Future<bool> authenticateWithBiometric(String reason) async {
    final result = await authenticateWithResult(reason);
    return result == AuthResult.success;
  }

  // Check if biometric is enrolled (legacy method)
  static Future<bool> isBiometricEnrolled() async {
    return await isEnabled();
  }

  // Get biometric type name for UI display
  static String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Biometric';
      case BiometricType.weak:
        return 'None';
      default:
        return 'Unknown';
    }
  }

  // Get primary biometric type
  static Future<BiometricType> getPrimaryBiometricType() async {
    final availableBiometrics = await getAvailableBiometrics();
    
    if (availableBiometrics.isEmpty) {
      return BiometricType.weak;
    }
    
    // Prioritize Face ID, then fingerprint, then strong biometric, then iris
    if (availableBiometrics.contains(BiometricType.face)) {
      return BiometricType.face;
    } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return BiometricType.fingerprint;
    } else if (availableBiometrics.contains(BiometricType.strong)) {
      return BiometricType.strong;
    } else if (availableBiometrics.contains(BiometricType.iris)) {
      return BiometricType.iris;
    }
    
    return availableBiometrics.first;
  }

  // Get description for current biometric type
  static Future<String> getBiometricDescription() async {
    final primaryType = await getPrimaryBiometricType();
    
    switch (primaryType) {
      case BiometricType.fingerprint:
        return 'Use your fingerprint to quickly and securely access your account';
      case BiometricType.face:
        return 'Use Face ID to quickly and securely access your account';
      case BiometricType.iris:
        return 'Use iris recognition to quickly and securely access your account';
      case BiometricType.strong:
        return 'Use biometric authentication to quickly and securely access your account';
      default:
        return 'Biometric authentication is not available on this device';
    }
  }

  // Stop biometric authentication
  static Future<void> stopAuthentication() async {
    try {
      await _localAuth.stopAuthentication();
    } catch (e) {
      // Ignore errors when stopping authentication
      print('Error stopping authentication: $e');
    }
  }

  // Get icon name for biometric type (useful for UI)
  static Future<String> getBiometricIcon() async {
    final primaryType = await getPrimaryBiometricType();
    
    switch (primaryType) {
      case BiometricType.fingerprint:
        return 'fingerprint';
      case BiometricType.face:
        return 'face';
      case BiometricType.iris:
        return 'iris';
      case BiometricType.strong:
        return 'security';
      default:
        return 'security';
    }
  }

  // Check if device supports biometric authentication
  static Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  // Check if user can check biometrics
  static Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  // Get detailed biometric status for debugging
  static Future<Map<String, dynamic>> getBiometricStatus() async {
    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await getAvailableBiometrics();
      final primaryType = await getPrimaryBiometricType();
      
      return {
        'isDeviceSupported': isDeviceSupported,
        'canCheckBiometrics': canCheckBiometrics,
        'availableBiometrics': availableBiometrics.map((e) => e.toString()).toList(),
        'primaryType': primaryType.toString(),
        'isAvailable': isDeviceSupported && canCheckBiometrics,
        'isEnabled': availableBiometrics.isNotEmpty,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'isAvailable': false,
        'isEnabled': false,
      };
    }
  }

  // Authenticate with custom options
  static Future<AuthResult> authenticateWithOptions({
    required String reason,
    bool biometricOnly = true,
    bool stickyAuth = true,
    bool sensitiveTransaction = false,
    bool useErrorDialogs = true,
  }) async {
    try {
      if (!_isInitialized) await initialize();
      
      if (!await isAvailable()) {
        return AuthResult.notAvailable;
      }

      if (!await isEnabled()) {
        return AuthResult.notEnrolled;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: stickyAuth,
          sensitiveTransaction: sensitiveTransaction,
          useErrorDialogs: useErrorDialogs,
        ),
      );

      return didAuthenticate ? AuthResult.success : AuthResult.failure;
    } on PlatformException catch (e) {
      switch (e.code) {
        case auth_error.notAvailable:
          return AuthResult.notAvailable;
        case auth_error.notEnrolled:
          return AuthResult.notEnrolled;
        case auth_error.lockedOut:
          return AuthResult.lockedOut;
        case auth_error.permanentlyLockedOut:
          return AuthResult.permanentlyLockedOut;
        // case auth_error.userCancel:
        //   return AuthResult.cancelled;
        case auth_error.biometricOnlyNotSupported:
          return AuthResult.notAvailable;
        // case auth_error.deviceNotSupported:
        //   return AuthResult.notAvailable;
        default:
          return AuthResult.error;
      }
    } catch (e) {
      return AuthResult.error;
    }
  }
}
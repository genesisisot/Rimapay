import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/biometric_service.dart';
import '../../features/auth/data/auth_api_service.dart';
import '../../features/auth/data/auth_dtos.dart';
import '../network/api_response.dart';

enum TierLevel { tier0, tier1, tier2, tier3 }
enum AccountType { underbanking, basic, premium, business }

class User {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final AccountType accountType;
  final TierLevel tierLevel;
  final bool isVerified;
  final bool bvnVerified;
  final double balance;
  final String? profileImageUrl;
  final bool hasBiometricEnabled; // ADDED: Biometric support
  final String? accountNumber;
  
  User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    required this.accountType,
    required this.tierLevel,
    required this.isVerified,
    required this.bvnVerified,
    this.balance = 0.0,
    this.profileImageUrl,
    this.hasBiometricEnabled = false, // ADDED: Default to false
    this.accountNumber,
  });
  
  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    if (firstName != null) return firstName!;
    if (lastName != null) return lastName!;
    return email.split('@').first;
  }
  
  String get initials {
    if (firstName != null && lastName != null) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    }
    if (firstName != null) return firstName![0].toUpperCase();
    return email[0].toUpperCase();
  }
  
  String get formattedBalance => '₦${balance.toStringAsFixed(2)}';
  
  Map<String, String> get tierLimits {
    switch (tierLevel) {
      case TierLevel.tier0:
        return {
          'daily': '₦5,000',
          'monthly': '₦20,000',
        };
      case TierLevel.tier1:
        return {
          'daily': '₦50,000',
          'monthly': '₦200,000',
        };
      case TierLevel.tier2:
        return {
          'daily': '₦200,000',
          'monthly': '₦1,000,000',
        };
      case TierLevel.tier3:
        return {
          'daily': '₦5,000,000',
          'monthly': '₦20,000,000',
        };
    }
  }
  
  String get tierName {
    switch (tierLevel) {
      case TierLevel.tier0:
        return 'Underbanking Account';
      case TierLevel.tier1:
        return 'Basic Tier';
      case TierLevel.tier2:
        return 'Premium Tier';
      case TierLevel.tier3:
        return 'Elite Tier';
    }
  }
  
  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    AccountType? accountType,
    TierLevel? tierLevel,
    bool? isVerified,
    bool? bvnVerified,
    double? balance,
    String? profileImageUrl,
    bool? hasBiometricEnabled,
    String? accountNumber,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      accountType: accountType ?? this.accountType,
      tierLevel: tierLevel ?? this.tierLevel,
      isVerified: isVerified ?? this.isVerified,
      bvnVerified: bvnVerified ?? this.bvnVerified,
      balance: balance ?? this.balance,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      hasBiometricEnabled: hasBiometricEnabled ?? this.hasBiometricEnabled,
      accountNumber: accountNumber ?? this.accountNumber,
    );
  }

  // ADDED: Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'accountType': accountType.toString(),
      'tierLevel': tierLevel.toString(),
      'isVerified': isVerified,
      'bvnVerified': bvnVerified,
      'balance': balance,
      'profileImageUrl': profileImageUrl,
      'hasBiometricEnabled': hasBiometricEnabled,
      'accountNumber': accountNumber,
    };
  }

  // ADDED: Create from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      phoneNumber: json['phoneNumber'],
      accountType: AccountType.values.firstWhere(
        (e) => e.toString() == json['accountType'],
        orElse: () => AccountType.basic,
      ),
      tierLevel: TierLevel.values.firstWhere(
        (e) => e.toString() == json['tierLevel'],
        orElse: () => TierLevel.tier1,
      ),
      isVerified: json['isVerified'] ?? false,
      bvnVerified: json['bvnVerified'] ?? false,
      balance: (json['balance'] ?? 0.0).toDouble(),
      profileImageUrl: json['profileImageUrl'],
      hasBiometricEnabled: json['hasBiometricEnabled'] ?? false,
      accountNumber: json['accountNumber'],
    );
  }
}

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  String? _errorMessage; // ADDED: For biometric errors
  
  User? get user => _user;
  User? get currentUser => _user; // ADDED: Alias for compatibility
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get errorMessage => _errorMessage; // ADDED: For biometric errors
  
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Check if user is stored locally
      final userData = await StorageService.getUser();
      if (userData != null) {
        _user = userData;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock user data
      _user = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        firstName: 'John',
        lastName: 'Doe',
        phoneNumber: '+2348123456789',
        accountType: AccountType.basic,
        tierLevel: TierLevel.tier1,
        isVerified: true,
        bvnVerified: true,
        balance: 125450.75,
        hasBiometricEnabled: false, // ADDED: Default biometric state
      );
      
      await StorageService.saveUser(_user!);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Real login against the RIMA Identity API (`POST /api/auth/login`).
  /// Supply phoneNumber OR email plus the password the user set during
  /// onboarding. On success the access/refresh tokens and user are persisted.
  Future<bool> loginWithCredentials({
    String? phoneNumber,
    String? email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await AuthApiService().login(LoginRequest(
        phoneNumber: phoneNumber,
        email: email,
        password: password,
      ));
      if (res.isSuccess && res.data != null) {
        final d = res.data!;
        await StorageService.saveTokens(
          accessToken: d.token,
          refreshToken: d.refreshToken,
        );
        _user = User(
          id: d.userId ?? '',
          email: d.email ?? (email ?? ''),
          firstName: d.firstName,
          lastName: d.lastName,
          phoneNumber: phoneNumber,
          accountType: AccountType.basic,
          tierLevel: TierLevel.tier1,
          isVerified: d.emailConfirmed,
          bvnVerified: false,
        );
        await StorageService.saveUser(_user!);
        return true;
      }
      _error = res.errorMessage ?? 'Login failed. Please try again.';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// POST /api/auth/forgot-password — request a password reset code by email.
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await AuthApiService().forgotPassword(email);
      if (res.isSuccess) return true;
      _error = res.errorMessage ?? 'Could not send reset email.';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// POST /api/auth/reset-password — set a new password using the emailed token.
  Future<bool> resetPassword({
    required String email,
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await AuthApiService().resetPassword(ResetPasswordRequest(
        email: email,
        token: token,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      ));
      if (res.isSuccess) return true;
      _error = res.errorMessage ?? 'Could not reset password.';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// GET /api/auth/verify-email — confirm an email address with its token.
  Future<bool> verifyEmail({
    required String token,
    required String email,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await AuthApiService().verifyEmail(token: token, email: email);
      if (res.isSuccess) return true;
      _error = res.errorMessage ?? 'Could not verify email.';
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password, String firstName, String lastName, String phoneNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      
      _user = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        accountType: AccountType.basic,
        tierLevel: TierLevel.tier1,
        isVerified: false,
        bvnVerified: false,
        balance: 0.0,
        hasBiometricEnabled: false, // ADDED: Default biometric state
      );
      
      await StorageService.saveUser(_user!);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void setUnderbankingUser() {
    _user = User(
      id: 'underbanking_user',
      email: 'underbanking@rimapay.com',
      firstName: 'Guest',
      lastName: 'User',
      accountType: AccountType.underbanking,
      tierLevel: TierLevel.tier0,
      isVerified: false,
      bvnVerified: false,
      balance: 0.0,
      hasBiometricEnabled: false, // ADDED: Default biometric state
    );
    StorageService.saveUser(_user!);
    notifyListeners();
  }
  
  /// Save user data directly from onboarding (bypasses login).
  Future<void> saveOnboardingUser({
    required String phoneNumber,
    String? firstName,
    String? lastName,
    String? email,
    String? accountNumber,
    String? identityUserId,
  }) async {
    _user = User(
      id: identityUserId ?? phoneNumber,
      email: email ?? '',
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      accountType: AccountType.basic,
      tierLevel: TierLevel.tier1,
      isVerified: true,
      bvnVerified: true,
      accountNumber: accountNumber,
    );
    await StorageService.saveUser(_user!);
    notifyListeners();
  }

  Future<void> logout() async {
    _user = null;
    _error = null;
    _errorMessage = null; // ADDED: Clear biometric errors
    await StorageService.clearUser();
    notifyListeners();
  }

  /// DELETE /api/auth/delete-account
  Future<ApiResponse<void>> deleteAccount() async {
    final res = await AuthApiService().deleteAccount();
    if (res.isSuccess) {
      await logout();
    }
    return res;
  }
  
  void updateBalance(double newBalance) {
    if (_user != null) {
      _user = _user!.copyWith(balance: newBalance);
      StorageService.saveUser(_user!);
      notifyListeners();
    }
  }
  
  void updateTier(TierLevel newTier) {
    if (_user != null) {
      _user = _user!.copyWith(tierLevel: newTier);
      StorageService.saveUser(_user!);
      notifyListeners();
    }
  }
  
  void updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? profileImageUrl,
  }) {
    if (_user != null) {
      _user = _user!.copyWith(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        profileImageUrl: profileImageUrl,
      );
      StorageService.saveUser(_user!);
      notifyListeners();
    }
  }

  // ADDED: Enable biometric authentication
  Future<bool> enableBiometric() async {
    if (_user == null) {
      _errorMessage = 'No user logged in';
      return false;
    }

    _errorMessage = null;
    notifyListeners();

    try {
      // Check if biometric is available
      final isAvailable = await BiometricService.isAvailable();
      if (!isAvailable) {
        _errorMessage = 'Biometric authentication is not available on this device';
        notifyListeners();
        return false;
      }

      // Check if biometric is enabled/enrolled
      final isEnabled = await BiometricService.isEnabled();
      if (!isEnabled) {
        _errorMessage = 'Please set up biometric authentication in your device settings first';
        notifyListeners();
        return false;
      }

      // Test biometric authentication
      final result = await BiometricService.authenticateForLogin();
      
      if (result == AuthResult.success) {
        _user = _user!.copyWith(hasBiometricEnabled: true);
        await StorageService.saveUser(_user!);
        notifyListeners();
        return true;
      } else {
        _errorMessage = BiometricService.getAuthResultMessage(result);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to enable biometric authentication: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // ADDED: Disable biometric authentication
  Future<bool> disableBiometric() async {
    if (_user == null) {
      _errorMessage = 'No user logged in';
      return false;
    }

    try {
      _user = _user!.copyWith(hasBiometricEnabled: false);
      await StorageService.saveUser(_user!);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to disable biometric authentication: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // ADDED: Toggle biometric authentication
  Future<bool> toggleBiometric(bool enable) async {
    if (enable) {
      return await enableBiometric();
    } else {
      return await disableBiometric();
    }
  }

  // ADDED: Check if user can use biometric login
  Future<bool> canUseBiometricLogin() async {
    if (_user == null || !_user!.hasBiometricEnabled) {
      return false;
    }

    try {
      final isAvailable = await BiometricService.isAvailable();
      final isEnabled = await BiometricService.isEnabled();
      return isAvailable && isEnabled;
    } catch (e) {
      return false;
    }
  }

  // ADDED: Biometric login
  Future<bool> biometricLogin() async {
    if (!await canUseBiometricLogin()) {
      _errorMessage = 'Biometric login is not available';
      notifyListeners();
      return false;
    }

    try {
      final result = await BiometricService.authenticateForLogin();
      
      if (result == AuthResult.success) {
        // User is already loaded, just return success
        return true;
      } else {
        _errorMessage = BiometricService.getAuthResultMessage(result);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Biometric login failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // ADDED: Clear error messages
  void clearError() {
    _error = null;
    _errorMessage = null;
    notifyListeners();
  }
}
import 'dart:convert';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rimapay/Models/UserDataModel.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Your UserData model should be imported here
// import 'models/user_data.dart';

// SharedPreferences provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// UserData state notifier
class UserDataNotifier extends StateNotifier<UserData?> {
  final SharedPreferences _prefs;
  static const String _userDataKey = 'user_data';

  UserDataNotifier(this._prefs) : super(null) {
    _loadUserData();
  }

  // Load user data from SharedPreferences
  void _loadUserData() {
    final userDataJson = _prefs.getString(_userDataKey);
    if (userDataJson != null) {
      try {
        final Map<String, dynamic> userDataMap = jsonDecode(userDataJson);
        state = UserData.fromJson(userDataMap);
      } catch (e) {
        // Handle JSON parsing error
        log('Error loading user data: $e');
        state = null;
      }
    }
  }

  // Save user data to SharedPreferences
  Future<bool> saveUserData(UserData userData) async {
    try {
      final userDataJson = jsonEncode(userData.toJson());
      final success = await _prefs.setString(_userDataKey, userDataJson);
      if (success) {
        state = userData;
      }
      refreshUserData();
      return success;
    } catch (e) {
      log('Error saving user data: $e');
      return false;
    }
  }

  // Get current user data
  UserData? getUserData() {
    return state;
  }

  // Update specific field in user data
  Future<bool> updateUserData(String key, dynamic value) async {
    if (state == null) return false;

    try {
      UserData updatedUserData;
      
      switch (key) {
        case 'id':
          updatedUserData = state!.copyWith(id: value as String?);
          break;
        case 'accountName':
          updatedUserData = state!.copyWith(accountName: value as String?);
          break;
        case 'accountNumber':
          updatedUserData = state!.copyWith(accountNumber: value as String?);
          break;
        case 'accountTier':
          updatedUserData = state!.copyWith(accountTier: value as String?);
          break;
        case 'accountTransferLimit':
          updatedUserData = state!.copyWith(accountTransferLimit: value as String?);
          break;
        case 'customerTitle':
          updatedUserData = state!.copyWith(customerTitle: value as String?);
          break;
        case 'accountType':
          updatedUserData = state!.copyWith(accountType: value as String?);
          break;
        case 'customerType':
          updatedUserData = state!.copyWith(customerType: value as String?);
          break;
        case 'customerPhoto':
          updatedUserData = state!.copyWith(customerPhoto: value as String?);
          break;
        case 'gender':
          updatedUserData = state!.copyWith(gender: value as String?);
          break;
        case 'dateOfBirth':
          updatedUserData = state!.copyWith(dateOfBirth: value as DateTime?);
          break;
        case 'nationality':
          updatedUserData = state!.copyWith(nationality: value as String?);
          break;
        case 'occupation':
          updatedUserData = state!.copyWith(occupation: value as String?);
          break;
        case 'employeeNumber':
          updatedUserData = state!.copyWith(employeeNumber: value as String?);
          break;
        case 'residentAddress':
          updatedUserData = state!.copyWith(residentAddress: value as String?);
          break;
        case 'residentCountry':
          updatedUserData = state!.copyWith(residentCountry: value as int?);
          break;
        case 'residentState':
          updatedUserData = state!.copyWith(residentState: value as String?);
          break;
        case 'residentLga':
          updatedUserData = state!.copyWith(residentLga: value as String?);
          break;
        case 'residentCity':
          updatedUserData = state!.copyWith(residentCity: value as String?);
          break;
        case 'phone':
          updatedUserData = state!.copyWith(phone: value as String?);
          break;
        case 'authToken':
          updatedUserData = state!.copyWith(authToken: value as String?);
          break;
        case 'email':
          updatedUserData = state!.copyWith(email: value as String?);
          break;
        case 'latitude':
          updatedUserData = state!.copyWith(latitude: value as String?);
          break;
        case 'longitude':
          updatedUserData = state!.copyWith(longitude: value as String?);
          break;
        case 'maritalstatus':
          updatedUserData = state!.copyWith(maritalstatus: value as String?);
          break;
        case 'nextkinlastname':
          updatedUserData = state!.copyWith(nextkinlastname: value as String?);
          break;
        case 'nextkinfirstname':
          updatedUserData = state!.copyWith(nextkinfirstname: value as String?);
          break;
        case 'nextofkinstatus':
          updatedUserData = state!.copyWith(nextofkinstatus: value as String?);
          break;
        case 'nextkinphone':
          updatedUserData = state!.copyWith(nextkinphone: value as String?);
          break;
        case 'maidenname':
          updatedUserData = state!.copyWith(maidenname: value as String?);
          break;
        case 'political':
          updatedUserData = state!.copyWith(political: value as String?);
          break;
        case 'accountofficer':
          updatedUserData = state!.copyWith(accountofficer: value as String?);
          break;
        case 'accountBranch':
          updatedUserData = state!.copyWith(accountBranch: value as String?);
          break;
        case 'bvnstatus':
          updatedUserData = state!.copyWith(bvnstatus: value as String?);
          break;
        case 'loaneligibility':
          updatedUserData = state!.copyWith(loaneligibility: value as String?);
          break;
        case 'riskPermission':
          updatedUserData = state!.copyWith(riskPermission: value as String?);
          break;
        case 'docUploadstatus':
          updatedUserData = state!.copyWith(docUploadstatus: value as String?);
          break;
        case 'accountStatus':
          updatedUserData = state!.copyWith(accountStatus: value as String?);
          break;
        case 'password':
          updatedUserData = state!.copyWith(password: value as String?);
          break;
        case 'pin':
          updatedUserData = state!.copyWith(pin: value as String?);
          break;
        case 'accountPackage':
          updatedUserData = state!.copyWith(accountPackage: value as String?);
          break;
        case 'customerInternetBankingId':
          updatedUserData = state!.copyWith(customerInternetBankingId: value as String?);
          break;
        case 'datecreated':
          updatedUserData = state!.copyWith(datecreated: value as DateTime?);
          break;
        default:
          log('Unknown key: $key');
          return false;
      }

      return await saveUserData(updatedUserData);
    } catch (e) {
      log('Error updating user data: $e');
      return false;
    }
  }

  // Update multiple fields at once
  Future<bool> updateMultipleFields(Map<String, dynamic> updates) async {
    if (state == null) return false;

    try {
      UserData updatedUserData = state!;
      
      for (final entry in updates.entries) {
        final key = entry.key;
        final value = entry.value;
        
        switch (key) {
          case 'id':
            updatedUserData = updatedUserData.copyWith(id: value as String?);
            break;
          case 'accountName':
            updatedUserData = updatedUserData.copyWith(accountName: value as String?);
            break;
          case 'accountNumber':
            updatedUserData = updatedUserData.copyWith(accountNumber: value as String?);
            break;
          case 'accountTier':
            updatedUserData = updatedUserData.copyWith(accountTier: value as String?);
            break;
          case 'accountTransferLimit':
            updatedUserData = updatedUserData.copyWith(accountTransferLimit: value as String?);
            break;
          case 'customerTitle':
            updatedUserData = updatedUserData.copyWith(customerTitle: value as String?);
            break;
          case 'accountType':
            updatedUserData = updatedUserData.copyWith(accountType: value as String?);
            break;
          case 'customerType':
            updatedUserData = updatedUserData.copyWith(customerType: value as String?);
            break;
          case 'customerPhoto':
            updatedUserData = updatedUserData.copyWith(customerPhoto: value as String?);
            break;
          case 'gender':
            updatedUserData = updatedUserData.copyWith(gender: value as String?);
            break;
          case 'dateOfBirth':
            updatedUserData = updatedUserData.copyWith(dateOfBirth: value as DateTime?);
            break;
          case 'nationality':
            updatedUserData = updatedUserData.copyWith(nationality: value as String?);
            break;
          case 'occupation':
            updatedUserData = updatedUserData.copyWith(occupation: value as String?);
            break;
          case 'employeeNumber':
            updatedUserData = updatedUserData.copyWith(employeeNumber: value as String?);
            break;
          case 'residentAddress':
            updatedUserData = updatedUserData.copyWith(residentAddress: value as String?);
            break;
          case 'residentCountry':
            updatedUserData = updatedUserData.copyWith(residentCountry: value as int?);
            break;
          case 'residentState':
            updatedUserData = updatedUserData.copyWith(residentState: value as String?);
            break;
          case 'residentLga':
            updatedUserData = updatedUserData.copyWith(residentLga: value as String?);
            break;
          case 'residentCity':
            updatedUserData = updatedUserData.copyWith(residentCity: value as String?);
            break;
          case 'phone':
            updatedUserData = updatedUserData.copyWith(phone: value as String?);
            break;
          case 'authToken':
            updatedUserData = updatedUserData.copyWith(authToken: value as String?);
            break;
          case 'email':
            updatedUserData = updatedUserData.copyWith(email: value as String?);
            break;
          case 'latitude':
            updatedUserData = updatedUserData.copyWith(latitude: value as String?);
            break;
          case 'longitude':
            updatedUserData = updatedUserData.copyWith(longitude: value as String?);
            break;
          case 'maritalstatus':
            updatedUserData = updatedUserData.copyWith(maritalstatus: value as String?);
            break;
          case 'nextkinlastname':
            updatedUserData = updatedUserData.copyWith(nextkinlastname: value as String?);
            break;
          case 'nextkinfirstname':
            updatedUserData = updatedUserData.copyWith(nextkinfirstname: value as String?);
            break;
          case 'nextofkinstatus':
            updatedUserData = updatedUserData.copyWith(nextofkinstatus: value as String?);
            break;
          case 'nextkinphone':
            updatedUserData = updatedUserData.copyWith(nextkinphone: value as String?);
            break;
          case 'maidenname':
            updatedUserData = updatedUserData.copyWith(maidenname: value as String?);
            break;
          case 'political':
            updatedUserData = updatedUserData.copyWith(political: value as String?);
            break;
          case 'accountofficer':
            updatedUserData = updatedUserData.copyWith(accountofficer: value as String?);
            break;
          case 'accountBranch':
            updatedUserData = updatedUserData.copyWith(accountBranch: value as String?);
            break;
          case 'bvnstatus':
            updatedUserData = updatedUserData.copyWith(bvnstatus: value as String?);
            break;
          case 'loaneligibility':
            updatedUserData = updatedUserData.copyWith(loaneligibility: value as String?);
            break;
          case 'riskPermission':
            updatedUserData = updatedUserData.copyWith(riskPermission: value as String?);
            break;
          case 'docUploadstatus':
            updatedUserData = updatedUserData.copyWith(docUploadstatus: value as String?);
            break;
          case 'accountStatus':
            updatedUserData = updatedUserData.copyWith(accountStatus: value as String?);
            break;
          case 'password':
            updatedUserData = updatedUserData.copyWith(password: value as String?);
            break;
          case 'pin':
            updatedUserData = updatedUserData.copyWith(pin: value as String?);
            break;
          case 'accountPackage':
            updatedUserData = updatedUserData.copyWith(accountPackage: value as String?);
            break;
          case 'customerInternetBankingId':
            updatedUserData = updatedUserData.copyWith(customerInternetBankingId: value as String?);
            break;
          case 'datecreated':
            updatedUserData = updatedUserData.copyWith(datecreated: value as DateTime?);
            break;
          default:
            log('Unknown key: $key');
            continue;
        }
      }

      return await saveUserData(updatedUserData);
    } catch (e) {
      log('Error updating multiple fields: $e');
      return false;
    }
  }

  // Delete user data from SharedPreferences
  Future<bool> deleteUserData() async {
    try {
      final success = await _prefs.remove(_userDataKey);
      if (success) {
        state = null;
      }
        refreshUserData();
      return success;
    } catch (e) {
      log('Error deleting user data: $e');
      return false;
    }
  }

  // Check if user data exists
  bool hasUserData() {
    return state != null;
  }

  // Clear all user data (same as delete but with different naming)
  Future<bool> clearUserData() async {
    return await deleteUserData();
  }

  // Refresh user data from SharedPreferences
  void refreshUserData() {
    _loadUserData();
  }
}

// UserData provider
final userDataProvider = StateNotifierProvider<UserDataNotifier, UserData?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UserDataNotifier(prefs);
});

// Convenience providers for specific user data fields
final userIdProvider = Provider<String?>((ref) {
  final userData = ref.watch(userDataProvider);
  return userData?.id;
});

final userNameProvider = Provider<String?>((ref) {
  final userData = ref.watch(userDataProvider);
  return userData?.accountName;
});

final userEmailProvider = Provider<String?>((ref) {
  final userData = ref.watch(userDataProvider);
  return userData?.email;
});

final userPhoneProvider = Provider<String?>((ref) {
  final userData = ref.watch(userDataProvider);
  return userData?.phone;
});

final userAccountNumberProvider = Provider<String?>((ref) {
  final userData = ref.watch(userDataProvider);
  return userData?.accountNumber;
});

// Helper class for easier access to UserData operations
class UserDataHelper {
  final WidgetRef ref;

  UserDataHelper(this.ref);

  // Get current user data
  UserData? get userData => ref.read(userDataProvider);

  // Save user data
  Future<bool> saveUserData(UserData userData) async {
    return await ref.read(userDataProvider.notifier).saveUserData(userData);
  }

  // Update single field
  Future<bool> updateField(String key, dynamic value) async {
    return await ref.read(userDataProvider.notifier).updateUserData(key, value);
  }

  // Update multiple fields
  Future<bool> updateFields(Map<String, dynamic> updates) async {
    return await ref.read(userDataProvider.notifier).updateMultipleFields(updates);
  }

  // Delete user data
  Future<bool> deleteUserData() async {
    return await ref.read(userDataProvider.notifier).deleteUserData();
  }

  // Check if user data exists
  bool get hasUserData => ref.read(userDataProvider.notifier).hasUserData();

  // Refresh user data
  void refreshUserData() {
    ref.read(userDataProvider.notifier).refreshUserData();
  }
}
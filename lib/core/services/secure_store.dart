import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keystore/Keychain-backed storage for biometric settings and secrets.
///
/// - Biometric login: a snapshot of the signed-in user, restored after a
///   fingerprint unlocks the saved refresh-token session.
/// - Biometric transactions: the transaction PIN, released only after a
///   successful fingerprint check and sent as `transactionPin`/`pin`.
class SecureStore {
  SecureStore._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _bioLoginKey = 'rimapay_bio_login_enabled';
  static const _bioTxnKey = 'rimapay_bio_txn_enabled';
  static const _txnPinKey = 'rimapay_txn_pin';
  static const _bioUserKey = 'rimapay_bio_user';

  // ── Biometric login ─────────────────────────────────────────────────────

  static Future<bool> isBiometricLoginEnabled() async =>
      (await _read(_bioLoginKey)) == 'true';

  static Future<void> setBiometricLogin(bool enabled,
      {Map<String, dynamic>? user}) async {
    if (enabled) {
      if (user != null) await saveBiometricUser(user);
      await _storage.write(key: _bioLoginKey, value: 'true');
    } else {
      await _storage.delete(key: _bioLoginKey);
      await _storage.delete(key: _bioUserKey);
    }
  }

  static Future<void> saveBiometricUser(Map<String, dynamic> user) =>
      _storage.write(key: _bioUserKey, value: jsonEncode(user));

  static Future<Map<String, dynamic>?> getBiometricUser() async {
    final raw = await _read(_bioUserKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  // ── Biometric transactions ──────────────────────────────────────────────

  static Future<bool> isBiometricTxnEnabled() async =>
      (await _read(_bioTxnKey)) == 'true' && (await _read(_txnPinKey)) != null;

  static Future<void> setBiometricTxn(bool enabled, {String? pin}) async {
    if (enabled && pin != null) {
      await _storage.write(key: _txnPinKey, value: pin);
      await _storage.write(key: _bioTxnKey, value: 'true');
    } else {
      await _storage.delete(key: _bioTxnKey);
      await _storage.delete(key: _txnPinKey);
    }
  }

  static Future<String?> getTransactionPin() => _read(_txnPinKey);

  /// Keeps the stored PIN in sync after a successful PIN change/reset.
  static Future<void> updateTransactionPinIfEnabled(String newPin) async {
    if ((await _read(_bioTxnKey)) == 'true') {
      await _storage.write(key: _txnPinKey, value: newPin);
    }
  }

  static Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }
}

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import '../encryption/password_crypto.dart';
import '../services/auth_initializer.dart';
import '../services/secure_storage_service.dart';

class AuthManager {
  AuthManager({
    SecureStorageService? secureStorageService,
    AuthInitializer? authInitializer,
  }) : _secureStorage = secureStorageService ?? SecureStorageService(),
       _authInitializer = authInitializer ?? AuthInitializer();

  final SecureStorageService _secureStorage;
  final AuthInitializer _authInitializer;

  static String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> hasPinSet() => _secureStorage.hasPinSet();

  static String? validatePin(String pin) => RegExp(r'^\d{4,8}$').hasMatch(pin)
      ? null
      : 'Use 4 to 8 digits for your PIN.';

  Future<void> setPin(String pin) async {
    final error = validatePin(pin);
    if (error != null) throw ArgumentError(error);
    final hash = await compute(createPinVerifier, pin);
    await _secureStorage.writePinHash(hash);
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _secureStorage.readPinHash();
    if (stored == null) return false;
    if (stored.startsWith('v2\$')) {
      return compute(verifyModernPin, (pin, stored));
    }
    final valid = PasswordCrypto.constantEquals(
      utf8.encode(_hashPin(pin)),
      utf8.encode(stored),
    );
    if (valid) {
      // Upgrade old verifiers after successful authentication, retaining access
      // to legacy PINs even if they predate the new creation rules.
      await _secureStorage.writePinHash(await compute(createPinVerifier, pin));
    }
    return valid;
  }

  Future<bool> canUseBiometrics() => _authInitializer.canCheckBiometrics();

  Future<bool> canUseDeviceAuthentication() async {
    try {
      return await _authInitializer.localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// True when device supports biometrics and at least one is enrolled.
  Future<bool> hasEnrolledBiometrics() async {
    try {
      final list = await _authInitializer.localAuth.getAvailableBiometrics();
      return list.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Returns true if authenticated, false if failed, null if user cancelled.
  Future<bool?> authenticateWithBiometrics() async {
    try {
      final ok = await _authInitializer.localAuth.authenticate(
        localizedReason: 'Unlock your document vault',
        biometricOnly: false,
        persistAcrossBackgrounding: false,
      );
      return ok;
    } on LocalAuthException catch (e) {
      if (e.code == LocalAuthExceptionCode.userCanceled ||
          e.code == LocalAuthExceptionCode.systemCanceled ||
          e.code == LocalAuthExceptionCode.timeout) {
        return null;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

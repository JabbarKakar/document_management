import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';

import '../services/auth_initializer.dart';
import '../services/secure_storage_service.dart';

class AuthManager {
  AuthManager({
    SecureStorageService? secureStorageService,
    AuthInitializer? authInitializer,
  })  : _secureStorage = secureStorageService ?? SecureStorageService(),
        _authInitializer = authInitializer ?? AuthInitializer();

  final SecureStorageService _secureStorage;
  final AuthInitializer _authInitializer;

  static String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> hasPinSet() => _secureStorage.hasPinSet();

  Future<void> setPin(String pin) async {
    if (pin.length < 4) {
      throw ArgumentError('PIN must be at least 4 digits');
    }
    final hash = _hashPin(pin);
    await _secureStorage.writePinHash(hash);
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _secureStorage.readPinHash();
    if (stored == null) return false;
    return _hashPin(pin) == stored;
  }

  Future<bool> canUseBiometrics() => _authInitializer.canCheckBiometrics();

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

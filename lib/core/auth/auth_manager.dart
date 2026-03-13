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

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _authInitializer.localAuth.authenticate(
        localizedReason: 'Unlock your document vault',
        persistAcrossBackgrounding: false,
      );
    } catch (_) {
      return false;
    }
  }
}

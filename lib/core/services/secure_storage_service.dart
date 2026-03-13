import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._(this._storage);

  factory SecureStorageService() {
    const storage = FlutterSecureStorage();
    return SecureStorageService._(storage);
  }

  final FlutterSecureStorage _storage;

  static const String _encryptionKeyKey = 'encryption_key';
  static const String _firstLaunchKey = 'has_run_before';
  static const String _pinHashKey = 'pin_hash';
  static const String _lockTimeoutKey = 'lock_timeout_seconds';
  static const int _defaultLockTimeoutSeconds = 60;

  Future<String?> readEncryptionKey() {
    return _storage.read(key: _encryptionKeyKey);
  }

  Future<void> writeEncryptionKey(String key) {
    return _storage.write(key: _encryptionKeyKey, value: key);
  }

  Future<bool> isFirstLaunch() async {
    final value = await _storage.read(key: _firstLaunchKey);
    return value != 'true';
  }

  Future<void> markLaunched() {
    return _storage.write(key: _firstLaunchKey, value: 'true');
  }

  Future<bool> hasPinSet() async {
    final value = await _storage.read(key: _pinHashKey);
    return value != null && value.isNotEmpty;
  }

  Future<void> writePinHash(String hash) {
    return _storage.write(key: _pinHashKey, value: hash);
  }

  Future<String?> readPinHash() {
    return _storage.read(key: _pinHashKey);
  }

  Future<int> getLockTimeoutSeconds() async {
    final value = await _storage.read(key: _lockTimeoutKey);
    if (value == null) return _defaultLockTimeoutSeconds;
    return int.tryParse(value) ?? _defaultLockTimeoutSeconds;
  }

  Future<void> setLockTimeoutSeconds(int seconds) {
    return _storage.write(key: _lockTimeoutKey, value: seconds.toString());
  }
}


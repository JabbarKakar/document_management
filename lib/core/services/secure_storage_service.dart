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
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _expiryRemindersEnabledKey = 'expiry_reminders_enabled';
  static const String _themeModeKey = 'theme_mode';
  static const int _defaultLockTimeoutSeconds = 60;

  /// `system` | `light` | `dark`. Default system.
  Future<String> getThemeModePreference() async {
    final v = await _storage.read(key: _themeModeKey);
    if (v == 'light' || v == 'dark' || v == 'system') {
      return v!;
    }
    return 'system';
  }

  Future<void> setThemeModePreference(String mode) {
    return _storage.write(key: _themeModeKey, value: mode);
  }

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

  Future<bool> getBiometricEnabled() async {
    final value = await _storage.read(key: _biometricEnabledKey);
    return value == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) {
    return _storage.write(
      key: _biometricEnabledKey,
      value: enabled ? 'true' : 'false',
    );
  }

  /// Default true. When false, no expiry notifications are scheduled (Module 8).
  Future<bool> getExpiryRemindersEnabled() async {
    final value = await _storage.read(key: _expiryRemindersEnabledKey);
    if (value == null) return true;
    return value == 'true';
  }

  Future<void> setExpiryRemindersEnabled(bool enabled) {
    return _storage.write(
      key: _expiryRemindersEnabledKey,
      value: enabled ? 'true' : 'false',
    );
  }
}


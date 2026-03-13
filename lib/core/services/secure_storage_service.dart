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
}


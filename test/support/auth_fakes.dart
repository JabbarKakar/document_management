import 'package:document_management/core/auth/auth_manager.dart';
import 'package:document_management/core/services/secure_storage_service.dart';

class MemorySecurityStorage extends SecureStorageService {
  String? verifier;
  String? attempts;
  String? encryptionKey;
  int timeout = 60;
  @override
  Future<String?> readPinHash() async => verifier;
  @override
  Future<void> writePinHash(String hash) async {
    verifier = hash;
  }

  @override
  Future<bool> hasPinSet() async => verifier != null;
  @override
  Future<String?> readPinAttempts() async => attempts;
  @override
  Future<void> writePinAttempts(String value) async {
    attempts = value;
  }

  @override
  Future<int> getLockTimeoutSeconds() async => timeout;
  @override
  Future<void> setLockTimeoutSeconds(int seconds) async {
    timeout = seconds;
  }

  @override
  Future<String?> readEncryptionKey() async => encryptionKey;
}

class FakeAuthManager extends AuthManager {
  String pin = '1234';
  bool pinSet = true;
  bool available = true;
  bool? deviceResult = true;
  int pinChecks = 0;
  int deviceChecks = 0;
  @override
  Future<bool> hasPinSet() async => pinSet;
  @override
  Future<bool> canUseDeviceAuthentication() async => available;
  @override
  Future<bool> verifyPin(String value) async {
    pinChecks++;
    return value == pin;
  }

  @override
  Future<bool?> authenticateWithBiometrics() async {
    deviceChecks++;
    return deviceResult;
  }

  @override
  Future<void> setPin(String value) async {
    pin = value;
    pinSet = true;
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/auth/auth_manager.dart';
import '../../../../core/services/secure_storage_service.dart';

class AuthStateProvider extends ChangeNotifier
    with WidgetsBindingObserver {
  AuthStateProvider({
    required AuthManager authManager,
    SecureStorageService? secureStorageService,
  })  : _authManager = authManager,
        _secureStorage = secureStorageService ?? SecureStorageService();

  final AuthManager _authManager;
  final SecureStorageService _secureStorage;

  bool _isLocked = true;
  bool _needsPinSetup = false;
  DateTime? _lastActivityAt;
  String? _errorMessage;
  bool _biometricAvailable = false;
  bool _biometricEnrolled = false;
  bool _biometricEnabled = false;

  bool get isLocked => _isLocked;
  bool get needsPinSetup => _needsPinSetup;
  String? get errorMessage => _errorMessage;
  bool get biometricAvailable => _biometricAvailable;
  bool get biometricEnrolled => _biometricEnrolled;
  bool get biometricEnabled => _biometricEnabled;

  Future<void> init() async {
    _biometricAvailable = await _authManager.canUseBiometrics();
    _biometricEnrolled = await _authManager.hasEnrolledBiometrics();
    _biometricEnabled = await _secureStorage.getBiometricEnabled();
    final pinSet = await _authManager.hasPinSet();
    _needsPinSetup = !pinSet;
    _isLocked = true;
    _errorMessage = null;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _recordUnlock() {
    _lastActivityAt = DateTime.now();
    _isLocked = false;
    _clearError();
    notifyListeners();
  }

  Future<bool> setPin(String pin, String confirmPin) async {
    if (pin.length < 4) {
      _errorMessage = 'PIN must be at least 4 digits';
      notifyListeners();
      return false;
    }
    if (pin != confirmPin) {
      _errorMessage = 'PINs do not match';
      notifyListeners();
      return false;
    }
    try {
      await _authManager.setPin(pin);
      _needsPinSetup = false;
      _recordUnlock();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> unlockWithPin(String pin) async {
    final ok = await _authManager.verifyPin(pin);
    if (ok) {
      _recordUnlock();
      return true;
    }
    _errorMessage = 'Wrong PIN';
    notifyListeners();
    return false;
  }

  Future<bool> unlockWithBiometrics() async {
    if (!_biometricEnabled) return false;
    final result = await _authManager.authenticateWithBiometrics();
    if (result == true) {
      _recordUnlock();
      return true;
    }
    if (result == false) {
      _errorMessage = 'Authentication failed';
      notifyListeners();
    }
    return false;
  }

  /// Turn on fingerprint / Face ID in the app, then try to authenticate once.
  /// Returns true if auth succeeded (and vault unlocks).
  Future<bool> enableBiometricAndUnlock() async {
    await _secureStorage.setBiometricEnabled(true);
    _biometricEnabled = true;
    notifyListeners();

    final result = await _authManager.authenticateWithBiometrics();
    if (result == true) {
      _recordUnlock();
      return true;
    }
    if (result == false) {
      _errorMessage =
          'Could not verify. Add a fingerprint or Face ID in device settings, then try again.';
      notifyListeners();
    }
    return false;
  }

  void lock() {
    _isLocked = true;
    _clearError();
    notifyListeners();
  }

  /// Returns `null` on success, or an error message string.
  Future<String?> changePin({
    required String currentPin,
    required String newPin,
    required String confirmPin,
  }) async {
    if (newPin.length < 4) {
      return 'New PIN must be at least 4 digits';
    }
    if (newPin != confirmPin) {
      return 'New PINs do not match';
    }
    final ok = await _authManager.verifyPin(currentPin);
    if (!ok) {
      return 'Current PIN is incorrect';
    }
    try {
      await _authManager.setPin(newPin);
    } catch (e) {
      return e.toString();
    }
    return null;
  }

  /// Turn biometric unlock on or off. Turning on runs one biometric prompt.
  Future<void> setBiometricUnlockEnabled(bool enabled) async {
    if (enabled) {
      if (!_biometricAvailable || !_biometricEnrolled) {
        return;
      }
      final result = await _authManager.authenticateWithBiometrics();
      if (result != true) {
        if (result == false) {
          _errorMessage = 'Could not verify biometrics';
          notifyListeners();
        }
        return;
      }
      await _secureStorage.setBiometricEnabled(true);
      _biometricEnabled = true;
    } else {
      await _secureStorage.setBiometricEnabled(false);
      _biometricEnabled = false;
    }
    notifyListeners();
  }

  void recordActivity() {
    _lastActivityAt = DateTime.now();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_needsPinSetup || _isLocked) return;
    _checkAutoLock();
  }

  Future<void> _checkAutoLock() async {
    if (_lastActivityAt == null) return;
    final timeoutSeconds = await _secureStorage.getLockTimeoutSeconds();
    final elapsed = DateTime.now().difference(_lastActivityAt!).inSeconds;
    if (elapsed >= timeoutSeconds) {
      lock();
    }
  }
}

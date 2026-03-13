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

  bool get isLocked => _isLocked;
  bool get needsPinSetup => _needsPinSetup;
  String? get errorMessage => _errorMessage;
  bool get biometricAvailable => _biometricAvailable;

  Future<void> init() async {
    _biometricAvailable = await _authManager.canUseBiometrics();
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
    final ok = await _authManager.authenticateWithBiometrics();
    if (ok) {
      _recordUnlock();
      return true;
    }
    _errorMessage = 'Authentication failed';
    notifyListeners();
    return false;
  }

  void lock() {
    _isLocked = true;
    _clearError();
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

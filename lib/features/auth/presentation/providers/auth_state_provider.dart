import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../../../../core/auth/auth_manager.dart';
import '../../../../core/services/secure_storage_service.dart';

class AuthStateProvider extends ChangeNotifier with WidgetsBindingObserver {
  AuthStateProvider({
    required AuthManager authManager,
    SecureStorageService? secureStorageService,
    DateTime Function()? now,
    this.onLocked,
  }) : _authManager = authManager,
       _secureStorage = secureStorageService ?? SecureStorageService(),
       _now = now ?? DateTime.now;

  final AuthManager _authManager;
  final SecureStorageService _secureStorage;
  final DateTime Function() _now;
  final VoidCallback? onLocked;
  Timer? _idleTimer;
  bool _disposed = false;
  bool _initialized = false;
  bool _busy = false;
  bool _isLocked = true;
  bool _needsPinSetup = false;
  bool _deviceAuthAvailable = false;
  int _timeoutSeconds = 60;
  int _failedAttempts = 0;
  DateTime? _blockedUntil;
  DateTime? _lastActivityAt;
  String? _errorMessage;

  bool get initialized => _initialized;
  bool get isBusy => _busy;
  bool get isLocked => _isLocked;
  bool get needsPinSetup => _needsPinSetup;
  bool get deviceAuthAvailable => _deviceAuthAvailable;
  String? get errorMessage => _errorMessage;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> init() async {
    if (_busy) return;
    _busy = true;
    _errorMessage = null;
    _notify();
    try {
      _deviceAuthAvailable = await _authManager.canUseDeviceAuthentication();
      _needsPinSetup = !await _authManager.hasPinSet();
      _timeoutSeconds = (await _secureStorage.getLockTimeoutSeconds()).clamp(
        30,
        900,
      );
      final attempts = await _secureStorage.readPinAttempts();
      if (attempts != null) {
        final data = jsonDecode(attempts) as Map<String, dynamic>;
        _failedAttempts = (data['count'] as int).clamp(0, 100);
        _blockedUntil = DateTime.tryParse(data['until'] as String? ?? '');
      }
      _initialized = true;
    } catch (_) {
      _errorMessage = 'Could not read vault security settings. Please retry.';
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<void> _saveAttempts() => _secureStorage.writePinAttempts(
    jsonEncode({
      'count': _failedAttempts,
      'until': _blockedUntil?.toIso8601String(),
    }),
  );

  Future<void> _recordUnlock() async {
    _failedAttempts = 0;
    _blockedUntil = null;
    await _saveAttempts();
    if (_disposed) return;
    _lastActivityAt = _now();
    _isLocked = false;
    _errorMessage = null;
    _armTimer();
  }

  String? _validatePair(String pin, String confirmation) =>
      AuthManager.validatePin(pin) ??
      (pin != confirmation ? 'PINs do not match.' : null);

  Future<bool> _perform(Future<bool> Function() action) async {
    if (_busy || !_initialized) return false;
    _busy = true;
    _errorMessage = null;
    _notify();
    try {
      return await action();
    } catch (_) {
      _errorMessage = 'Could not complete authentication. Please try again.';
      return false;
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<bool> setPin(String pin, String confirmPin) => _perform(() async {
    if (!_needsPinSetup) return false;
    _errorMessage = _validatePair(pin, confirmPin);
    if (_errorMessage != null) return false;
    await _authManager.setPin(pin);
    _needsPinSetup = false;
    await _recordUnlock();
    return true;
  });

  Future<bool> _verifyPin(String pin) async {
    if (_blockedUntil != null && _now().isBefore(_blockedUntil!)) {
      final seconds = _blockedUntil!.difference(_now()).inSeconds + 1;
      _errorMessage =
          'Too many attempts. Try again in $seconds seconds, or use device unlock.';
      return false;
    }
    if (await _authManager.verifyPin(pin)) return true;
    _failedAttempts++;
    if (_failedAttempts >= 5) {
      final delay = min(300, 30 * (1 << min(4, _failedAttempts - 5)));
      _blockedUntil = _now().add(Duration(seconds: delay));
    }
    await _saveAttempts();
    _errorMessage = _failedAttempts >= 5
        ? 'Too many attempts. Wait before trying again, or use device unlock.'
        : 'Incorrect PIN.';
    return false;
  }

  Future<bool> unlockWithPin(String pin) => _perform(() async {
    if (_needsPinSetup || !await _verifyPin(pin)) return false;
    await _recordUnlock();
    return true;
  });

  /// Device credentials are an independent unlock method by product policy.
  Future<bool> unlockWithDevice() => _perform(() async {
    if (!_deviceAuthAvailable || _needsPinSetup) return false;
    final result = await _authManager.authenticateWithBiometrics();
    if (result != true) {
      if (result == false) _errorMessage = 'Device authentication failed.';
      return false;
    }
    await _recordUnlock();
    return true;
  });

  /// Always requires a fresh OS authentication, never just an unlocked session.
  Future<bool> resetPinWithDevice(String pin, String confirmPin) =>
      _perform(() async {
        _errorMessage = _validatePair(pin, confirmPin);
        if (_errorMessage != null) return false;
        if (!_deviceAuthAvailable || _needsPinSetup) return false;
        final result = await _authManager.authenticateWithBiometrics();
        if (result != true) {
          if (result == false) {
            _errorMessage =
                'Device authentication failed. Your PIN was not changed.';
          }
          return false;
        }
        await _authManager.setPin(pin);
        await _recordUnlock();
        return true;
      });

  Future<String?> changePin({
    required String currentPin,
    required String newPin,
    required String confirmPin,
  }) async {
    final ok = await _perform(() async {
      requireUnlocked();
      _errorMessage = _validatePair(newPin, confirmPin);
      if (_errorMessage != null || !await _verifyPin(currentPin)) return false;
      requireUnlocked();
      await _authManager.setPin(newPin);
      await _recordUnlock();
      return true;
    });
    return ok
        ? null
        : (_errorMessage ?? 'PIN was not changed. Please try again.');
  }

  void lock() {
    _idleTimer?.cancel();
    _isLocked = true;
    _errorMessage = null;
    onLocked?.call();
    _notify();
  }

  void requireUnlocked() {
    _checkAutoLock();
    if (!_initialized || _isLocked || _needsPinSetup) {
      throw StateError('Vault locked. Unlock to continue.');
    }
  }

  Future<void> enforceAutoLockIfNeeded() async => _checkAutoLock();

  void recordActivity() {
    _checkAutoLock();
    if (_isLocked) return;
    _lastActivityAt = _now();
    _armTimer();
  }

  Future<void> setLockTimeoutSeconds(int seconds) async {
    requireUnlocked();
    await _secureStorage.setLockTimeoutSeconds(seconds);
    _timeoutSeconds = seconds.clamp(30, 900);
    _checkAutoLock();
    _armTimer();
  }

  void _checkAutoLock() {
    if (_isLocked || _lastActivityAt == null) return;
    if (_now().difference(_lastActivityAt!) >=
        Duration(seconds: _timeoutSeconds)) {
      lock();
    }
  }

  void _armTimer() {
    _idleTimer?.cancel();
    if (_isLocked || _disposed || _lastActivityAt == null) return;
    final remaining =
        Duration(seconds: _timeoutSeconds) -
        _now().difference(_lastActivityAt!);
    _idleTimer = Timer(remaining.isNegative ? Duration.zero : remaining, lock);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Do not refresh activity merely because the app backgrounds.
    if (state == AppLifecycleState.resumed) _checkAutoLock();
  }

  @override
  void dispose() {
    _disposed = true;
    _idleTimer?.cancel();
    super.dispose();
  }
}

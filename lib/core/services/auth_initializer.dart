import 'package:local_auth/local_auth.dart';

class AuthInitializer {
  AuthInitializer() : _localAuth = LocalAuthentication();

  final LocalAuthentication _localAuth;

  LocalAuthentication get localAuth => _localAuth;

  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }
}


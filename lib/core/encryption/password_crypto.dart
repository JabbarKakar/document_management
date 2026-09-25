import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Version 1 recovery packages: authenticated header, random salt and nonce,
/// PBKDF2-HMAC-SHA256 (600,000 rounds), AES-256-GCM (128-bit tag).
/// These synchronous functions run in a worker isolate at application call sites.
abstract final class PasswordCrypto {
  static const rounds = 600000;
  static final _magic = utf8.encode('DVBACK01');

  static Uint8List randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }

  static Uint8List derive(String password, Uint8List salt) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, rounds, 32));
    return derivator.process(Uint8List.fromList(utf8.encode(password)));
  }

  static Uint8List seal(Uint8List plain, String password) {
    final salt = randomBytes(16);
    final nonce = randomBytes(12);
    final header = Uint8List.fromList([..._magic, ...salt, ...nonce]);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(
          KeyParameter(derive(password, salt)),
          128,
          nonce,
          header,
        ),
      );
    return Uint8List.fromList([...header, ...cipher.process(plain)]);
  }

  static Uint8List open(Uint8List package, String password) {
    if (package.length < 52 || !constantEquals(package.sublist(0, 8), _magic)) {
      throw const FormatException('Unsupported or damaged recovery backup.');
    }
    try {
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          false,
          AEADParameters(
            KeyParameter(
              derive(password, Uint8List.sublistView(package, 8, 24)),
            ),
            128,
            Uint8List.sublistView(package, 24, 36),
            Uint8List.sublistView(package, 0, 36),
          ),
        );
      return cipher.process(Uint8List.sublistView(package, 36));
    } on InvalidCipherTextException {
      throw const FormatException('Incorrect password or damaged backup.');
    }
  }

  static bool constantEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }
    return difference == 0;
  }
}

String createPinVerifier(String pin) {
  final salt = PasswordCrypto.randomBytes(16);
  return 'v2\$${base64Encode(salt)}\$${base64Encode(PasswordCrypto.derive(pin, salt))}';
}

bool verifyModernPin((String, String) input) {
  final parts = input.$2.split('\$');
  if (parts.length != 3 || parts[0] != 'v2') return false;
  try {
    final salt = base64Decode(parts[1]);
    final expected = base64Decode(parts[2]);
    if (salt.length != 16 || expected.length != 32) return false;
    return PasswordCrypto.constantEquals(
      PasswordCrypto.derive(input.$1, salt),
      expected,
    );
  } on FormatException {
    return false;
  }
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart';

import 'password_crypto.dart';

import '../services/secure_storage_service.dart';

/// New files use AES-256-GCM with an authenticated header and random nonce.
/// The v1 CBC reader remains for existing vaults until explicit migration.
class VaultEncryptionService {
  VaultEncryptionService(this._secureStorage);

  final SecureStorageService _secureStorage;

  static const String _magic = 'DM_ENC_v1';
  static const String _authenticatedMagic = 'DM_ENC_v2';

  enc.Key? _cachedKey;
  int _generation = 0;

  static Uint8List _hexToBytes(String hex) {
    if (hex.length % 2 != 0) {
      throw FormatException('Invalid hex key length');
    }
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }

  Future<enc.Key> _loadKey() async {
    if (_cachedKey != null) return _cachedKey!;
    final generation = _generation;
    final hex = await _secureStorage.readEncryptionKey();
    if (generation != _generation) {
      throw StateError('Vault locked during decryption.');
    }
    if (hex == null || hex.isEmpty) {
      throw StateError('Encryption key not available');
    }
    final keyBytes = _hexToBytes(hex);
    if (keyBytes.length != 32) {
      throw StateError('Encryption key must be 256-bit (32 bytes)');
    }
    _cachedKey = enc.Key(keyBytes);
    return _cachedKey!;
  }

  /// Clears the in-memory key material (e.g. after backgrounding if desired).
  void clearKeyFromMemory() {
    _generation++;
    _cachedKey = null;
  }

  Future<Uint8List> encryptDocumentBytes(Uint8List plain) async {
    final key = await _loadKey();
    final nonce = PasswordCrypto.randomBytes(12);
    final header = Uint8List.fromList([...utf8.encode(_authenticatedMagic), ...nonce]);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key.bytes), 128, nonce, header));
    return Uint8List.fromList([...header, ...cipher.process(plain)]);
  }

  Future<Uint8List> decryptDocumentBytes(Uint8List stored) async {
    if (isAuthenticated(stored)) {
      if (stored.length < 37) throw const FormatException('Truncated vault file.');
      final key = await _loadKey();
      try {
        final cipher = GCMBlockCipher(AESEngine())
          ..init(false, AEADParameters(KeyParameter(key.bytes), 128,
              Uint8List.sublistView(stored, 9, 21), Uint8List.sublistView(stored, 0, 21)));
        return cipher.process(Uint8List.sublistView(stored, 21));
      } on InvalidCipherTextException {
        throw const FormatException('Vault file integrity check failed.');
      }
    }
    final magicBytes = utf8.encode(_magic);
    if (stored.length < magicBytes.length + 16) throw const FormatException('Unsupported or truncated vault file.');
    for (var i = 0; i < magicBytes.length; i++) {
      if (stored[i] != magicBytes[i]) {
        throw const FormatException('Unsupported vault file. Legacy plaintext requires explicit migration.');
      }
    }
    final ivStart = magicBytes.length;
    final iv = enc.IV(Uint8List.sublistView(stored, ivStart, ivStart + 16));
    final cipherStart = ivStart + 16;
    if (cipherStart >= stored.length) {
      throw const FormatException('Truncated vault file.');
    }
    final cipherBytes = Uint8List.sublistView(stored, cipherStart);
    final key = await _loadKey();
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final plain = encrypter.decryptBytes(enc.Encrypted(cipherBytes), iv: iv);
    return Uint8List.fromList(plain);
  }

  static bool isAuthenticated(Uint8List stored) => stored.length >= 9 &&
      PasswordCrypto.constantEquals(stored.sublist(0, 9), utf8.encode(_authenticatedMagic));
}

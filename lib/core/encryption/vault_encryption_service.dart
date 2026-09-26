import 'dart:convert';
import 'package:flutter/foundation.dart';

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

  Future<Uint8List> encryptDocumentBytes(Uint8List plain) =>
      _transform(plain, true);
  Future<Uint8List> decryptDocumentBytes(Uint8List stored) =>
      _transform(stored, false);

  Future<Uint8List> _transform(Uint8List bytes, bool encrypt) async {
    final generation = _generation;
    final key = await _loadKey();
    final input = (bytes, key.bytes, encrypt);
    final result = bytes.length > 64 * 1024
        ? await compute(_transformVaultBytes, input)
        : _transformVaultBytes(input);
    if (generation != _generation) {
      throw StateError('Vault locked during encryption.');
    }
    return result;
  }

  static bool isAuthenticated(Uint8List stored) =>
      stored.length >= 9 &&
      PasswordCrypto.constantEquals(
        stored.sublist(0, 9),
        utf8.encode(_authenticatedMagic),
      );
}

Uint8List _transformVaultBytes((Uint8List, Uint8List, bool) input) {
  final (bytes, key, encrypt) = input;
  if (encrypt) {
    final nonce = PasswordCrypto.randomBytes(12);
    final header = Uint8List.fromList([
      ...utf8.encode(VaultEncryptionService._authenticatedMagic),
      ...nonce,
    ]);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), 128, nonce, header));
    return Uint8List.fromList([...header, ...cipher.process(bytes)]);
  }
  if (VaultEncryptionService.isAuthenticated(bytes)) {
    if (bytes.length < 37) throw const FormatException('Truncated vault file.');
    try {
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          false,
          AEADParameters(
            KeyParameter(key),
            128,
            Uint8List.sublistView(bytes, 9, 21),
            Uint8List.sublistView(bytes, 0, 21),
          ),
        );
      return cipher.process(Uint8List.sublistView(bytes, 21));
    } on InvalidCipherTextException {
      throw const FormatException('Vault file integrity check failed.');
    }
  }
  final magic = utf8.encode(VaultEncryptionService._magic);
  if (bytes.length <= magic.length + 16 ||
      !PasswordCrypto.constantEquals(bytes.sublist(0, magic.length), magic)) {
    throw const FormatException(
      'Unsupported vault file. Legacy plaintext requires explicit migration.',
    );
  }
  final iv = enc.IV(
    Uint8List.sublistView(bytes, magic.length, magic.length + 16),
  );
  final cipher = enc.Encrypter(enc.AES(enc.Key(key), mode: enc.AESMode.cbc));
  return Uint8List.fromList(
    cipher.decryptBytes(
      enc.Encrypted(Uint8List.sublistView(bytes, magic.length + 16)),
      iv: iv,
    ),
  );
}

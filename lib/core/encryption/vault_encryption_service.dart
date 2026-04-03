import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;

import '../services/secure_storage_service.dart';

/// AES-256-CBC encryption for vault documents.
/// File format: [magic 8 bytes][IV 16 bytes][ciphertext].
/// Legacy unencrypted files are detected (no magic) and returned as plain bytes.
class VaultEncryptionService {
  VaultEncryptionService(this._secureStorage);

  final SecureStorageService _secureStorage;

  static const String _magic = 'DM_ENC_v1';

  enc.Key? _cachedKey;

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
    final hex = await _secureStorage.readEncryptionKey();
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
    _cachedKey = null;
  }

  Future<Uint8List> encryptDocumentBytes(Uint8List plain) async {
    final key = await _loadKey();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encryptBytes(plain, iv: iv);
    final magicBytes = utf8.encode(_magic);
    final out = Uint8List(
      magicBytes.length + iv.bytes.length + encrypted.bytes.length,
    );
    var o = 0;
    out.setRange(o, o + magicBytes.length, magicBytes);
    o += magicBytes.length;
    out.setRange(o, o + iv.bytes.length, iv.bytes);
    o += iv.bytes.length;
    out.setRange(o, out.length, encrypted.bytes);
    return out;
  }

  Future<Uint8List> decryptDocumentBytes(Uint8List stored) async {
    final magicBytes = utf8.encode(_magic);
    if (stored.length < magicBytes.length + 16) {
      return stored;
    }
    for (var i = 0; i < magicBytes.length; i++) {
      if (stored[i] != magicBytes[i]) {
        return stored;
      }
    }
    final ivStart = magicBytes.length;
    final iv = enc.IV(Uint8List.sublistView(stored, ivStart, ivStart + 16));
    final cipherStart = ivStart + 16;
    if (cipherStart >= stored.length) {
      return stored;
    }
    final cipherBytes = Uint8List.sublistView(stored, cipherStart);
    final key = await _loadKey();
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final plain = encrypter.decryptBytes(
      enc.Encrypted(cipherBytes),
      iv: iv,
    );
    return Uint8List.fromList(plain);
  }
}

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../encryption/vault_encryption_service.dart';

class EncryptedFileStorageService {
  EncryptedFileStorageService(
    this._vaultRootPath,
    this._encryption, {
    this.requireUnlocked,
  });

  final String _vaultRootPath;
  final VaultEncryptionService _encryption;
  final void Function()? requireUnlocked;

  void _validatePath(String path) {
    final root = p.normalize(p.absolute(_vaultRootPath));
    final target = p.normalize(p.absolute(path));
    if (!p.isWithin(root, target) || p.dirname(target) != root) {
      throw const FileSystemException('File is outside the vault.');
    }
  }

  Future<String> saveBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    requireUnlocked?.call();
    final encrypted = await _encryption.encryptDocumentBytes(bytes);
    requireUnlocked?.call();
    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final extension = p
        .extension(fileName)
        .replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '');
    final safeName = '$id${extension.length <= 10 ? extension : '.bin'}';
    final filePath = p.join(_vaultRootPath, safeName);
    final file = File(filePath);
    try {
      await file.writeAsBytes(encrypted, flush: true);
    } catch (_) {
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
      rethrow;
    }
    return file.path;
  }

  Future<Uint8List> readDecryptedBytes(String filePath) async {
    requireUnlocked?.call();
    _validatePath(filePath);
    if (await FileSystemEntity.isLink(filePath)) {
      throw const FileSystemException(
        'Vault file must not be a symbolic link.',
      );
    }
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }
    final raw = await file.readAsBytes();
    final bytes = await _encryption.decryptDocumentBytes(raw);
    requireUnlocked?.call();
    return bytes;
  }

  Future<int> storedLength(String path) async {
    requireUnlocked?.call();
    _validatePath(path);
    return File(path).length();
  }

  Future<void> deleteFile(String filePath) async {
    // Internal cleanup must remain possible if the session locks mid-write.
    _validatePath(filePath);
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

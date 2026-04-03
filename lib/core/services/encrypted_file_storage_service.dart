import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../encryption/vault_encryption_service.dart';

class EncryptedFileStorageService {
  EncryptedFileStorageService(
    this._vaultRootPath,
    this._encryption,
  );

  final String _vaultRootPath;
  final VaultEncryptionService _encryption;

  Future<String> saveBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final encrypted = await _encryption.encryptDocumentBytes(bytes);
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    final filePath = p.join(_vaultRootPath, safeName);
    final file = File(filePath);
    await file.writeAsBytes(encrypted, flush: true);
    return file.path;
  }

  Future<Uint8List> readDecryptedBytes(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }
    final raw = await file.readAsBytes();
    return _encryption.decryptDocumentBytes(raw);
  }

  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}


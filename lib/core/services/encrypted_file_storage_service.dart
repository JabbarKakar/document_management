import 'dart:io';
import 'dart:convert';
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

  Future<String> sealMetadata(String value) async {
    requireUnlocked?.call();
    final bytes = await _encryption.encryptDocumentBytes(
      Uint8List.fromList(utf8.encode(value)),
    );
    requireUnlocked?.call();
    return base64Encode(bytes);
  }

  Future<String> openMetadata(String value) async {
    requireUnlocked?.call();
    final raw = base64Decode(value);
    if (!VaultEncryptionService.isAuthenticated(raw)) {
      throw const FormatException('Unsupported metadata encryption.');
    }
    final bytes = await _encryption.decryptDocumentBytes(raw);
    requireUnlocked?.call();
    return utf8.decode(bytes);
  }

  /// Returns a newly staged path, or null for an already authenticated file.
  /// Legacy plaintext is accepted only in this explicit upgrade operation.
  Future<String?> stageAuthenticatedUpgrade(String path) async {
    requireUnlocked?.call();
    _validatePath(path);
    if (await FileSystemEntity.isLink(path)) {
      throw const FileSystemException('Invalid vault link.');
    }
    final raw = await File(path).readAsBytes();
    if (p.basename(path).startsWith('v2_') &&
        !VaultEncryptionService.isAuthenticated(raw)) {
      throw const FormatException('Vault file integrity check failed.');
    }
    if (VaultEncryptionService.isAuthenticated(raw)) {
      await _encryption.decryptDocumentBytes(raw);
      requireUnlocked?.call();
      return null;
    }
    final legacyEncrypted =
        raw.length >= 9 &&
        utf8.decode(raw.sublist(0, 9), allowMalformed: true) == 'DM_ENC_v1';
    final Uint8List plain;
    if (legacyEncrypted) {
      plain = await _encryption.decryptDocumentBytes(raw);
    } else {
      // Only historically supported file signatures; damaged encrypted headers
      // must never be treated as a plaintext document.
      final header = latin1.decode(raw.take(12).toList());
      final recognized =
          header.startsWith('%PDF-') ||
          header.startsWith('\u00ff\u00d8\u00ff') ||
          header.startsWith('\u0089PNG\r\n\u001a\n') ||
          header.startsWith('GIF8') ||
          header.startsWith('BM') ||
          (header.startsWith('RIFF') && header.endsWith('WEBP')) ||
          (header.length >= 12 && header.substring(4, 8) == 'ftyp');
      if (!recognized) {
        throw const FormatException(
          'Unrecognized legacy file. Restore it from backup.',
        );
      }
      plain = raw;
    }
    final staged = await saveBytes(bytes: plain, fileName: p.basename(path));
    try {
      final verified = await readDecryptedBytes(staged);
      if (verified.length != plain.length) {
        throw const FormatException('Upgrade verification failed.');
      }
      for (var i = 0; i < plain.length; i++) {
        if (verified[i] != plain[i]) {
          throw const FormatException('Upgrade verification failed.');
        }
      }
      return staged;
    } catch (_) {
      await deleteFile(staged);
      rethrow;
    }
  }

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
    final safeName = 'v2_$id${extension.length <= 10 ? extension : '.bin'}';
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
    if (p.basename(filePath).startsWith('v2_') &&
        !VaultEncryptionService.isAuthenticated(raw)) {
      throw const FormatException('Vault file integrity check failed.');
    }
    final bytes = await _encryption.decryptDocumentBytes(raw);
    requireUnlocked?.call();
    return bytes;
  }

  Future<int> storedLength(String path) async {
    requireUnlocked?.call();
    _validatePath(path);
    return File(path).length();
  }

  Future<List<String>> oldUnreferencedFiles(Set<String> referenced) async {
    requireUnlocked?.call();
    final candidates = <String>[];
    final cutoff = DateTime.now().subtract(const Duration(days: 1));
    final names = RegExp(r'^(v2_)?[a-f0-9]{32}(\.[a-zA-Z0-9]{1,9})?$');
    await for (final entry in Directory(
      _vaultRootPath,
    ).list(followLinks: false)) {
      requireUnlocked?.call();
      if (entry is! File ||
          !names.hasMatch(p.basename(entry.path)) ||
          referenced.contains(entry.path)) {
        continue;
      }
      final stat = await entry.stat();
      if (stat.modified.isBefore(cutoff)) candidates.add(entry.path);
    }
    return candidates;
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

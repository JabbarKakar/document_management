import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

class EncryptedFileStorageService {
  EncryptedFileStorageService(this._vaultRootPath);

  final String _vaultRootPath;

  Future<String> saveBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    final filePath = p.join(_vaultRootPath, safeName);
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}


import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/documents/domain/entities/vault_document.dart';
import 'encrypted_file_storage_service.dart';

/// Module 18: exports decrypted copies through the platform share sheet.
class DocumentExportService {
  Future<void> exportDocumentsViaShare({
    required List<VaultDocument> documents,
    required EncryptedFileStorageService storage,
    String? message,
  }) async {
    if (documents.isEmpty) return;

    final tempDir = await getTemporaryDirectory();
    final List<XFile> files = [];
    final usedNames = <String>{};

    for (final doc in documents) {
      if (doc.filePath.isEmpty || !File(doc.filePath).existsSync()) continue;
      final bytes = await storage.readDecryptedBytes(doc.filePath);
      final outName = _buildSafeUniqueName(doc, usedNames);
      final outPath = p.join(tempDir.path, outName);
      final outFile = File(outPath);
      await outFile.writeAsBytes(bytes, flush: true);
      files.add(XFile(outFile.path));
    }

    if (files.isEmpty) return;
    await SharePlus.instance.share(
      ShareParams(
        files: files,
        text: message,
      ),
    );
  }

  String _buildSafeUniqueName(VaultDocument doc, Set<String> usedNames) {
    final base = doc.title.trim().isEmpty ? 'document' : doc.title.trim();
    final safeBase = base.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    final extFromPath = p.extension(doc.filePath);
    final fallbackExt = doc.fileType == VaultDocumentFileType.pdf ? '.pdf' : '.bin';
    final ext = extFromPath.isNotEmpty ? extFromPath : fallbackExt;

    var candidate = '$safeBase$ext';
    var i = 2;
    while (usedNames.contains(candidate.toLowerCase())) {
      candidate = '${safeBase}_$i$ext';
      i++;
    }
    usedNames.add(candidate.toLowerCase());
    return candidate;
  }
}

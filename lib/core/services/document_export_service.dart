import 'dart:io';
import 'dart:async';
import 'dart:ui';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/documents/domain/entities/vault_document.dart';
import 'encrypted_file_storage_service.dart';

/// Module 18: exports decrypted copies through the platform share sheet.
class DocumentExportService {
  Future<ShareResult> exportDocumentsViaShare({
    required List<VaultDocument> documents,
    required EncryptedFileStorageService storage,
    String? message,
    Rect? sharePositionOrigin,
  }) async {
    if (documents.isEmpty) throw ArgumentError('No documents selected.');

    final tempDir = await getTemporaryDirectory();
    final session = await tempDir.createTemp('vault_export_');
    final List<XFile> files = [];
    final usedNames = <String>{};
    var shared = false;
    try {
    for (final doc in documents) {
      final bytes = await storage.readDecryptedBytes(doc.filePath);
      final outName = _buildSafeUniqueName(doc, usedNames);
      final outPath = p.join(session.path, outName);
      final outFile = File(outPath);
      await outFile.writeAsBytes(bytes, flush: true);
      files.add(XFile(outFile.path));
    }

    storage.requireUnlocked?.call();
    final result = await SharePlus.instance.share(ShareParams(
      files: files, text: message, sharePositionOrigin: sharePositionOrigin));
    shared = result.status != ShareResultStatus.dismissed;
    return result;
    } finally {
      if (shared) {
        // Android receivers may read after the chooser returns. Give them a
        // bounded grace period; a cold start also removes abandoned sessions.
        Timer(const Duration(minutes: 10), () async {
          try { if (await session.exists()) await session.delete(recursive: true); } catch (_) {}
        });
      } else {
        try { if (await session.exists()) await session.delete(recursive: true); } catch (_) {}
      }
    }
  }

  static Future<void> cleanupAbandonedExports() async {
    final temp = await getTemporaryDirectory();
    await for (final entry in temp.list(followLinks: false)) {
      final name = p.basename(entry.path);
      if (entry is Directory && name.startsWith('vault_export_')) {
        try { await entry.delete(recursive: true); } catch (_) {}
      } else if (entry is File && RegExp(r'^vault_view_\d+_\d+\.pdf$').hasMatch(name)) {
        try { await entry.delete(); } catch (_) {}
      }
    }
  }

  String _buildSafeUniqueName(VaultDocument doc, Set<String> usedNames) {
    final base = doc.title.trim().isEmpty ? 'document' : doc.title.trim();
    final safeBase = base.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
    final extFromPath = p.extension(doc.filePath);
    final fallbackExt = doc.fileType == VaultDocumentFileType.pdf
        ? '.pdf'
        : '.bin';
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

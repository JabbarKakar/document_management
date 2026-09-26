import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import '../../features/documents/data/models/vault_document_model.dart';
import '../../features/documents/domain/document_history.dart';
import 'document_metadata_codec.dart';
import 'encrypted_file_storage_service.dart';

class VaultMaintenanceReport {
  const VaultMaintenanceReport(this.completed, this.failedIds);
  final int completed;
  final List<int> failedIds;
}

/// Resumable per-document upgrade: originals survive until the new references
/// and encrypted metadata have committed together. It also verifies v2 files.
class VaultMaintenanceService {
  VaultMaintenanceService(this.isar, this.storage);
  final Isar isar;
  final EncryptedFileStorageService storage;
  bool _busy = false;

  Future<List<String>> findCleanupCandidates() async {
    storage.requireUnlocked?.call();
    final models = await isar
        .collection<VaultDocumentModel>()
        .where()
        .findAll();
    final referenced = <String>{};
    for (final model in models) {
      referenced.add(model.filePath);
      referenced.addAll(
        model.versionRecords.map(DocumentVersion.decode).map((v) => v.path),
      );
    }
    return storage.oldUnreferencedFiles(referenced);
  }

  Future<int> cleanupUnreferencedFiles() async {
    if (_busy) throw StateError('Vault maintenance is already running.');
    _busy = true;
    var count = 0;
    try {
      // Re-read references after confirmation; never reuse a stale UI list.
      for (final path in await findCleanupCandidates()) {
        storage.requireUnlocked?.call();
        await storage.deleteFile(path);
        count++;
      }
      return count;
    } finally {
      _busy = false;
    }
  }

  Future<VaultMaintenanceReport> upgradeAndVerify({
    void Function(int, int)? onProgress,
  }) async {
    if (_busy) throw StateError('Vault maintenance is already running.');
    _busy = true;
    var completed = 0;
    final failed = <int>[];
    try {
      storage.requireUnlocked?.call();
      final collection = isar.collection<VaultDocumentModel>();
      final snapshots = await collection.where().findAll();
      final codec = DocumentMetadataCodec(storage);
      for (final snapshot in snapshots) {
        storage.requireUnlocked?.call();
        final staged = <String, String>{};
        var committed = false;
        try {
          final paths = {
            snapshot.filePath,
            ...snapshot.versionRecords
                .map(DocumentVersion.decode)
                .map((v) => v.path),
          };
          for (final path in paths) {
            final replacement = await storage.stageAuthenticatedUpgrade(path);
            if (replacement != null) staged[path] = replacement;
          }
          await isar.writeTxn(() async {
            storage.requireUnlocked?.call();
            final current = await collection.get(snapshot.id);
            if (current == null ||
                current.filePath != snapshot.filePath ||
                !listEquals(current.versionRecords, snapshot.versionRecords)) {
              throw StateError('Document changed during upgrade. Retry.');
            }
            final model = await codec.decode(current);
            model.filePath = staged[model.filePath] ?? model.filePath;
            model.versionRecords = model.versionRecords
                .map(DocumentVersion.decode)
                .map(
                  (v) => DocumentVersion(
                    path: staged[v.path] ?? v.path,
                    typeIndex: v.typeIndex,
                    createdAt: v.createdAt,
                  ).encode(),
                )
                .toList();
            await collection.put(await codec.encode(model));
          });
          committed = true;
          completed++;
        } catch (_) {
          failed.add(snapshot.id);
        } finally {
          for (final path in committed ? staged.keys : staged.values) {
            try {
              await storage.deleteFile(path);
            } catch (_) {
              /* Preserve a safe orphan on failure. */
            }
          }
        }
        onProgress?.call(completed + failed.length, snapshots.length);
      }
      return VaultMaintenanceReport(completed, failed);
    } finally {
      _busy = false;
    }
  }
}

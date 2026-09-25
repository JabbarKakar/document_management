import 'dart:typed_data';

import 'package:isar/isar.dart';

import '../../../../core/services/encrypted_file_storage_service.dart';
import '../../../../core/services/staged_file_commit.dart';
import '../../../../core/services/document_metadata_codec.dart';
import '../../domain/entities/vault_document.dart';
import '../../domain/document_history.dart';
import '../../domain/repositories/document_repository.dart';
import '../models/vault_document_model.dart';
import '../services/document_import_validation.dart';

class IsarDocumentRepository implements DocumentRepository {
  IsarDocumentRepository({
    required Isar isar,
    required EncryptedFileStorageService fileStorageService,
  }) : _isar = isar,
       _fileStorageService = fileStorageService;

  final Isar _isar;
  final EncryptedFileStorageService _fileStorageService;
  late final _codec = DocumentMetadataCodec(_fileStorageService);
  Future<VaultDocumentModel?> _get(int id) async {
    final m = await _collection.get(id);
    return m == null ? null : _codec.decode(m);
  }
  Future<int> _put(VaultDocumentModel m) async => _collection.put(await _codec.encode(m));

  IsarCollection<VaultDocumentModel> get _collection =>
      _isar.collection<VaultDocumentModel>();

  @override
  Future<List<VaultDocument>> getAllDocuments() async {
    final models = await Future.wait((await _collection.where().sortByCreatedAtDesc().findAll()).map(_codec.decode));
    return models
        .where((m) => m.deletedAt == null)
        .map((m) => m.toEntity())
        .toList();
  }

  @override
  Future<List<VaultDocument>> searchDocuments({
    String? query,
    int? categoryId,
  }) async {
    final q = query?.trim().toLowerCase();

    final allModels = await Future.wait((await _collection.where().findAll()).map(_codec.decode));

    final filtered = allModels.where((m) {
      if (m.deletedAt != null) return false;
      if (categoryId != null && m.categoryId != categoryId) {
        return false;
      }
      if (q == null || q.isEmpty) {
        return true;
      }
      final inTitle = m.title.toLowerCase().contains(q);
      final inNotes = (m.notes ?? '').toLowerCase().contains(q);
      return inTitle || inNotes;
    }).toList();

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered.map((m) => m.toEntity()).toList();
  }

  @override
  Future<VaultDocument> addDocument({
    required String title,
    required Uint8List fileBytes,
    required String originalFileName,
    VaultDocumentFileType fileType = VaultDocumentFileType.other,
    int? categoryId,
    DateTime? expiryDate,
    String? notes,
  }) async {
    final now = DateTime.now();
    await validateDocumentImport(fileBytes, originalFileName, fileType);
    final storedPath = await _fileStorageService.saveBytes(
      bytes: fileBytes,
      fileName: '${now.millisecondsSinceEpoch}_$originalFileName',
    );

    final model = VaultDocumentModel()
      ..title = title
      ..filePath = storedPath
      ..createdAt = now
      ..categoryId = categoryId
      ..expiryDate = expiryDate
      ..notes = notes
      ..fileType = fileType;
    _event(model, 'Created');

    final id = await commitStagedFile(
      commit: () => _isar.writeTxn<int>(() async {
        _fileStorageService.requireUnlocked?.call();
        return _put(model);
      }),
      rollbackFile: () => _fileStorageService.deleteFile(storedPath),
    );

    model.id = id;
    return model.toEntity();
  }

  @override
  Future<VaultDocument> updateDocumentMetadata({
    required int id,
    required String title,
    int? categoryId,
    DateTime? expiryDate,
    String? notes,
  }) async {
    final updated = await _isar.writeTxn<VaultDocumentModel>(() async {
      _fileStorageService.requireUnlocked?.call();
      final m = await _get(id);
      if (m == null) {
        throw StateError('Document $id not found');
      }
      m.title = title;
      m.categoryId = categoryId;
      m.expiryDate = expiryDate;
      m.notes = notes;
      _event(m, 'Metadata updated');
      await _put(m);
      return m;
    });
    return updated.toEntity();
  }

  @override
  Future<VaultDocument> replaceDocumentFile({
    required int id,
    required Uint8List fileBytes,
    required String originalFileName,
    required VaultDocumentFileType fileType,
  }) async {
    final now = DateTime.now();
    await validateDocumentImport(fileBytes, originalFileName, fileType);
    final newPath = await _fileStorageService.saveBytes(
      bytes: fileBytes,
      fileName: '${now.millisecondsSinceEpoch}_$originalFileName',
    );

    final evictedPaths = <String>[];
    final updated = await commitStagedFile(
      commit: () => _isar.writeTxn<VaultDocumentModel>(() async {
        _fileStorageService.requireUnlocked?.call();
        final m = await _get(id);
        if (m == null) {
          throw StateError('Document $id not found');
        }
        if (m.deletedAt != null) {
          throw StateError('Restore this document from Trash first.');
        }
        final versions = m.versionRecords.map(DocumentVersion.decode).toList();
        versions.insert(
          0,
          DocumentVersion(
            path: m.filePath,
            typeIndex: m.fileType.index,
            createdAt: m.updatedAt ?? m.createdAt,
          ),
        );
        while (versions.length > VaultRetention.previousVersions) {
          evictedPaths.add(versions.removeLast().path);
        }
        m.versionRecords = versions.map((v) => v.encode()).toList();
        m.filePath = newPath;
        m.fileType = fileType;
        m.extractedText = null;
        _event(m, 'File replaced');
        await _put(m);
        return m;
      }),
      rollbackFile: () => _fileStorageService.deleteFile(newPath),
      cleanupSuperseded: () async {
        for (final path in evictedPaths) {
          await _fileStorageService.deleteFile(path);
        }
      },
    );
    return updated.toEntity();
  }

  @override
  Future<void> deleteDocument(VaultDocument document) async {
    await _isar.writeTxn(() async {
      _fileStorageService.requireUnlocked?.call();
      final m = await _get(document.id);
      if (m == null || m.deletedAt != null) return;
      m.deletedAt = DateTime.now();
      _event(m, 'Moved to Trash');
      await _put(m);
    });
  }

  @override
  Future<List<VaultDocument>> getTrash() async {
    final models = await Future.wait((await _collection.where().findAll()).map(_codec.decode));
    final trash = models.where((m) => m.deletedAt != null).toList()
      ..sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!));
    return trash.map((m) => m.toEntity()).toList();
  }

  @override
  Future<VaultDocument> restoreDocument(int id) => _change(id, (m) {
    m.deletedAt = null;
    _event(m, 'Restored from Trash');
  });

  @override
  Future<void> permanentlyDeleteDocument(int id) async {
    final paths = <String>[];
    await _isar.writeTxn(() async {
      _fileStorageService.requireUnlocked?.call();
      final m = await _get(id);
      if (m == null) return;
      if (m.deletedAt == null) {
        throw StateError('Move to Trash before permanently deleting.');
      }
      paths.add(m.filePath);
      paths.addAll(
        m.versionRecords.map(DocumentVersion.decode).map((v) => v.path),
      );
      await _collection.delete(id);
    });
    for (final path in paths) {
      try {
        await _fileStorageService.deleteFile(path);
      } catch (_) {
        /* Integrity check can retry. */
      }
    }
  }

  @override
  Future<VaultDocument> restoreVersion(int id, String path) async {
    // Verify the requested content is readable before swapping pointers.
    await _fileStorageService.readDecryptedBytes(path);
    return _change(id, (m) {
      if (m.deletedAt != null) throw StateError('Restore from Trash first.');
      final versions = m.versionRecords.map(DocumentVersion.decode).toList();
      final selected = versions.indexWhere((v) => v.path == path);
      if (selected < 0) throw StateError('Version is no longer available.');
      final version = versions.removeAt(selected);
      versions.insert(
        0,
        DocumentVersion(
          path: m.filePath,
          typeIndex: m.fileType.index,
          createdAt: m.updatedAt ?? m.createdAt,
        ),
      );
      m.filePath = version.path;
      m.fileType = VaultDocumentFileType.values[version.typeIndex];
      m.versionRecords = versions.map((v) => v.encode()).toList();
      m.extractedText = null;
      _event(m, 'Previous file version restored');
    });
  }

  @override
  Future<VaultDocument> updateOrganization(
    int id, {
    bool? favorite,
    List<String>? tags,
    List<int>? reminderOffsets,
    bool? remindersDisabled,
    String? extractedText,
    String? expectedFilePath,
  }) => _change(id, (m) {
    if (expectedFilePath != null && m.filePath != expectedFilePath) {
      throw StateError('The document changed. Extract text from its current file.');
    }
    if (favorite != null) m.isFavorite = favorite;
    if (tags != null) {
      m.tags =
          tags
              .map((t) => t.trim().toLowerCase())
              .where((t) => t.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      if (m.tags.length > 20 || m.tags.any((t) => t.length > 40)) {
        throw const FormatException(
          'Use up to 20 tags, each at most 40 characters.',
        );
      }
    }
    if (reminderOffsets != null) {
      if (reminderOffsets.length > 5 ||
          reminderOffsets.any((d) => d < 0 || d > 365)) {
        throw const FormatException(
          'Use up to five reminder offsets between 0 and 365 days.',
        );
      }
      m.reminderOffsets = reminderOffsets.toSet().toList()
        ..sort((a, b) => b.compareTo(a));
    }
    if (remindersDisabled != null) m.remindersDisabled = remindersDisabled;
    if (extractedText != null) {
      if (extractedText.length > 1024 * 1024) throw const FormatException('Search text exceeds 1 MB.');
      m.extractedText = extractedText;
    }
    _event(
      m,
      extractedText == null
          ? 'Organization or reminder settings updated'
          : 'Search text extracted',
    );
  });

  @override
  Future<void> recordActivity(int id, String action) async {
    await _change(id, (m) => _event(m, action, updateModified: false));
  }

  Future<VaultDocument> _change(
    int id,
    void Function(VaultDocumentModel) update,
  ) async {
    final model = await _isar.writeTxn(() async {
      _fileStorageService.requireUnlocked?.call();
      final m = await _get(id);
      if (m == null) throw StateError('Document no longer exists.');
      update(m);
      await _put(m);
      return m;
    });
    return model.toEntity();
  }

  void _event(
    VaultDocumentModel model,
    String action, {
    bool updateModified = true,
  }) {
    final now = DateTime.now();
    if (updateModified) model.updatedAt = now;
    model.activityRecords = [
      DocumentActivity(action, now).encode(),
      ...model.activityRecords,
    ].take(200).toList();
  }
}


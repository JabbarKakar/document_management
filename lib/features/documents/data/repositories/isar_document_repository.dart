import 'dart:typed_data';

import 'package:isar/isar.dart';

import '../../../../core/services/encrypted_file_storage_service.dart';
import '../../domain/entities/vault_document.dart';
import '../../domain/repositories/document_repository.dart';
import '../models/vault_document_model.dart';

class IsarDocumentRepository implements DocumentRepository {
  IsarDocumentRepository({
    required Isar isar,
    required EncryptedFileStorageService fileStorageService,
  })  : _isar = isar,
        _fileStorageService = fileStorageService;

  final Isar _isar;
  final EncryptedFileStorageService _fileStorageService;

  IsarCollection<VaultDocumentModel> get _collection =>
      _isar.collection<VaultDocumentModel>();

  @override
  Future<List<VaultDocument>> getAllDocuments() async {
    final models = await _collection.where().sortByCreatedAtDesc().findAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<VaultDocument>> searchDocuments({
    String? query,
    int? categoryId,
  }) async {
    final q = query?.trim().toLowerCase();

    final allModels = await _collection.where().findAll();

    final filtered = allModels.where((m) {
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

    final id = await _isar.writeTxn<int>(() async {
      return await _collection.put(model);
    });

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
      final m = await _collection.get(id);
      if (m == null) {
        throw StateError('Document $id not found');
      }
      m.title = title;
      m.categoryId = categoryId;
      m.expiryDate = expiryDate;
      m.notes = notes;
      await _collection.put(m);
      return m;
    });
    return updated.toEntity();
  }

  @override
  Future<void> deleteDocument(VaultDocument document) async {
    await _fileStorageService.deleteFile(document.filePath);
    await _isar.writeTxn(() => _collection.delete(document.id));
  }
}


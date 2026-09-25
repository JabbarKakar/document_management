import 'dart:typed_data';

import '../entities/vault_document.dart';

abstract class DocumentRepository {
  Future<List<VaultDocument>> getAllDocuments();

  Future<List<VaultDocument>> searchDocuments({String? query, int? categoryId});

  Future<VaultDocument> addDocument({
    required String title,
    required Uint8List fileBytes,
    required String originalFileName,
    VaultDocumentFileType fileType,
    int? categoryId,
    DateTime? expiryDate,
    String? notes,
  });

  Future<VaultDocument> updateDocumentMetadata({
    required int id,
    required String title,
    int? categoryId,
    DateTime? expiryDate,
    String? notes,
  });

  Future<VaultDocument> replaceDocumentFile({
    required int id,
    required Uint8List fileBytes,
    required String originalFileName,
    required VaultDocumentFileType fileType,
  });

  Future<void> deleteDocument(VaultDocument document);
  Future<List<VaultDocument>> getTrash();
  Future<VaultDocument> restoreDocument(int id);
  Future<void> permanentlyDeleteDocument(int id);
  Future<VaultDocument> restoreVersion(int id, String path);
  Future<VaultDocument> updateOrganization(
    int id, {
    bool? favorite,
    List<String>? tags,
    List<int>? reminderOffsets,
    bool? remindersDisabled,
    String? extractedText,
    String? expectedFilePath,
  });
  Future<void> recordActivity(int id, String action);
}

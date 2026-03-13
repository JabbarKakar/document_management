import 'dart:typed_data';

import '../entities/vault_document.dart';

abstract class DocumentRepository {
  Future<List<VaultDocument>> getAllDocuments();

  Future<List<VaultDocument>> searchDocuments({
    String? query,
    int? categoryId,
  });

  Future<VaultDocument> addDocument({
    required String title,
    required Uint8List fileBytes,
    required String originalFileName,
    VaultDocumentFileType fileType,
    int? categoryId,
    DateTime? expiryDate,
    String? notes,
  });

  Future<void> deleteDocument(VaultDocument document);
}


import 'dart:convert';
import '../../features/documents/data/models/vault_document_model.dart';
import 'encrypted_file_storage_service.dart';

/// Sensitive free text is encrypted; dates/category IDs remain queryable.
class DocumentMetadataCodec {
  DocumentMetadataCodec(this.storage);
  final EncryptedFileStorageService storage;

  Future<VaultDocumentModel> decode(VaultDocumentModel model) async {
    storage.requireUnlocked?.call();
    final encoded = model.encryptedMetadata;
    if (encoded == null) return model;
    final data = jsonDecode(await storage.openMetadata(encoded)) as Map<String, dynamic>;
    if (data['version'] != 1) throw const FormatException('Unsupported document metadata.');
    if (data['filePath'] != model.filePath) throw const FormatException('Document metadata does not match its file.');
    model.title = data['title'] as String;
    model.notes = data['notes'] as String?;
    model.tags = (data['tags'] as List).cast<String>();
    model.extractedText = data['extractedText'] as String?;
    model.activityRecords = (data['activity'] as List).cast<String>();
    return model;
  }

  Future<VaultDocumentModel> encode(VaultDocumentModel model) async {
    final copy = VaultDocumentModel.fromEntity(model.toEntity());
    copy.encryptedMetadata = await storage.sealMetadata(jsonEncode({
      'version': 1, 'filePath': model.filePath, 'title': model.title, 'notes': model.notes,
      'tags': model.tags, 'extractedText': model.extractedText, 'activity': model.activityRecords,
    }));
    copy.title = '';
    copy.notes = null;
    copy.tags = [];
    copy.extractedText = null;
    copy.activityRecords = [];
    return copy;
  }
}
